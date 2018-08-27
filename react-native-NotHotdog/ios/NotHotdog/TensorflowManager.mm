#import "TensorflowManager.h"

#include "tensorflow/core/framework/op_kernel.h"
#include "tensorflow/core/public/session.h"

#include <fstream>
#include <pthread.h>
#include <unistd.h>
#include <queue>
#include <sstream>
#include <string>

#include "ios_image_load.h"

namespace {
  class IfstreamInputStream : public ::google::protobuf::io::CopyingInputStream {
  public:
    explicit IfstreamInputStream(const std::string& file_name)
    : ifs_(file_name.c_str(), std::ios::in | std::ios::binary) {}
    ~IfstreamInputStream() { ifs_.close(); }
    
    int Read(void* buffer, int size) {
      if (!ifs_) {
        return -1;
      }
      ifs_.read(static_cast<char*>(buffer), size);
      return (int)ifs_.gcount();
    }
    
  private:
    std::ifstream ifs_;
  };
}

@implementation TensorflowManager{
  std::unique_ptr<tensorflow::Session> tf_session;
  bool model_load_succeeded;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"predictions"];
}

RCT_EXPORT_METHOD(loadModel:(RCTResponseSenderBlock)callback)
{
  tensorflow::Status load_status;
  
  load_status = LoadModel(@"quantized_yolov2-tiny-hotdog", @"pb", &tf_session);
  
  if (!load_status.ok()) {
    model_load_succeeded = false;
    LOG(ERROR) << "Couldn't load model: " << load_status;
    callback(@[@"Couldn't load model"]);
  } else {
    model_load_succeeded = true;
    callback(@[]);
  }
}

RCT_EXPORT_METHOD(recognizeImage:(NSString *)image_path withCallback:(RCTResponseSenderBlock)callback)
{
  if (!model_load_succeeded) {
    callback(@[@"Couldn't load model"]);
    return;
  }
  
  image_path = [image_path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
  
  int image_width;
  int image_height;
  int image_channels;
  std::vector<tensorflow::uint8> image_data = LoadImageFromFile([image_path UTF8String],
                                                                &image_width,
                                                                &image_height,
                                                                &image_channels);
  
  const int wanted_width = 416;
  const int wanted_height = 416;
  const int wanted_channels = 3;
  const float input_mean = 0.0;
  const float input_std = 255.0f;
  
  assert(image_channels >= wanted_channels);
  
  tensorflow::Tensor image_tensor(tensorflow::DT_FLOAT,
                                  tensorflow::TensorShape({1, wanted_height, wanted_width, wanted_channels}));
  
  tensorflow::uint8* in = image_data.data();
  
  auto image_tensor_mapped = image_tensor.tensor<float, 4>();
  float* out = image_tensor_mapped.data();
  
  for (int y = 0; y < wanted_height; ++y) {
    const int in_y = (y * image_height) / wanted_height;
    tensorflow::uint8* in_row = in + (in_y * image_width * image_channels);
    float* out_row = out + (y * wanted_width * wanted_channels);
    for (int x = 0; x < wanted_width; ++x) {
      const int in_x = (x * image_width) / wanted_width;
      tensorflow::uint8* in_pixel = in_row + (in_x * image_channels);
      float* out_pixel = out_row + (x * wanted_channels);
      for (int c = 0; c < wanted_channels; ++c) {
        out_pixel[c] = (in_pixel[c] - input_mean) / input_std;
      }
    }
  }
  
  std::string input_layer = "input";
  std::string output_layer = "output";
  
  std::vector<tensorflow::Tensor> outputs;
  tensorflow::Status run_status = tf_session->Run({{input_layer, image_tensor}}, {output_layer}, {}, &outputs);
  
  if (!run_status.ok()) {
    LOG(ERROR) << "Running model failed:" << run_status;
    callback(@[@"Running model failed"]);
  } else {
    tensorflow::Tensor *output = &outputs[0];
    NSMutableArray* results = ParseOutput(output->flat<float>());
    [self sendEventWithName:@"predictions" body: results];
  }
}

#pragma mark - Private methods

bool PortableReadFileToProto(const std::string& file_name,
                             ::google::protobuf::MessageLite* proto) {
  ::google::protobuf::io::CopyingInputStreamAdaptor stream(new IfstreamInputStream(file_name));
  stream.SetOwnsCopyingStream(true);
  ::google::protobuf::io::CodedInputStream coded_stream(&stream);
  coded_stream.SetTotalBytesLimit(1024LL << 20, 512LL << 20);
  return proto->ParseFromCodedStream(&coded_stream);
}

NSString* FilePathForResourceName(NSString* name, NSString* extension) {
  NSString* file_path = [[NSBundle mainBundle] pathForResource:name ofType:extension];
  if (file_path == NULL) {
    LOG(ERROR) << "Couldn't find '" << [name UTF8String] << "."
    << [extension UTF8String] << "' in bundle.";
  }
  return file_path;
}

tensorflow::Status LoadModel(NSString* file_name, NSString* file_type,
                             std::unique_ptr<tensorflow::Session>* session) {
  tensorflow::SessionOptions options;
  
  tensorflow::Session* session_pointer = nullptr;
  tensorflow::Status session_status =
  tensorflow::NewSession(options, &session_pointer);
  if (!session_status.ok()) {
    LOG(ERROR) << "Could not create TensorFlow Session: " << session_status;
    return session_status;
  }
  session->reset(session_pointer);
  
  tensorflow::GraphDef tensorflow_graph;
  
  NSString* model_path = FilePathForResourceName(file_name, file_type);
  if (!model_path) {
    LOG(ERROR) << "Failed to find model proto at" << [file_name UTF8String]
    << [file_type UTF8String];
    return tensorflow::errors::NotFound([file_name UTF8String],
                                        [file_type UTF8String]);
  }
  const bool read_proto_succeeded =
  PortableReadFileToProto([model_path UTF8String], &tensorflow_graph);
  if (!read_proto_succeeded) {
    LOG(ERROR) << "Failed to load model proto from" << [model_path UTF8String];
    return tensorflow::errors::NotFound([model_path UTF8String]);
  }
  
  tensorflow::Status create_status = (*session)->Create(tensorflow_graph);
  if (!create_status.ok()) {
    LOG(ERROR) << "Could not create TensorFlow Graph: " << create_status;
    return create_status;
  }
  
  return tensorflow::Status::OK();
}

NSMutableArray* ParseOutput(const Eigen::TensorMap<Eigen::Tensor<float, 1, Eigen::RowMajor>, Eigen::Aligned>& output) {
  const int NUM_CLASSES = 1;
  const int NUM_BOXES_PER_BLOCK = 5;
  double ANCHORS[] = {
    0.57273, 0.677385, 1.87446, 2.06253, 3.33843, 5.47434, 7.88282, 3.52778, 9.77052, 9.16828
  };
  
  const int gridHeight = 13;
  const int gridWidth = 13;
  const int blockSize = 32;

  NSMutableArray* results = [NSMutableArray array];

  for (int y = 0; y < gridHeight; ++y) {
    for (int x = 0; x < gridWidth; ++x) {
      for (int b = 0; b < NUM_BOXES_PER_BLOCK; ++b) {
        int offset = (gridWidth * (NUM_BOXES_PER_BLOCK * (NUM_CLASSES + 5))) * y
        + (NUM_BOXES_PER_BLOCK * (NUM_CLASSES + 5)) * x
        + (NUM_CLASSES + 5) * b;
        
        float confidence = sigmoid(output(offset + 4));
        
        float classes[NUM_CLASSES];
        for (int c = 0; c < NUM_CLASSES; ++c) {
          classes[c] = output(offset + 5 + c);
        }
        
        softmax(classes, NUM_CLASSES);
        
        int detectedClass = -1;
        float maxClass = 0;
        for (int c = 0; c < NUM_CLASSES; ++c) {
          if (classes[c] > maxClass) {
            detectedClass = c;
            maxClass = classes[c];
          }
        }
        
        float confidenceInClass = maxClass * confidence;
        if (confidenceInClass > 0.5) {
          NSMutableDictionary* rect = [NSMutableDictionary dictionary];
          NSMutableDictionary* res = [NSMutableDictionary dictionary];
          
          float xPos = (x + sigmoid(output(offset + 0))) * blockSize;
          float yPos = (y + sigmoid(output(offset + 1))) * blockSize;
          
          float w = (float) (exp(output(offset + 2)) * ANCHORS[2 * b + 0]) * blockSize;
          float h = (float) (exp(output(offset + 3)) * ANCHORS[2 * b + 1]) * blockSize;
          
          [rect setObject:@(fmax(0, (xPos - w / 2))) forKey:@"x"];
          [rect setObject:@(fmax(0, (yPos - h / 2))) forKey:@"y"];
          [rect setObject:@(w) forKey:@"w"];
          [rect setObject:@(h) forKey:@"h"];
          
          [res setObject:rect forKey:@"rect"];
          [res setObject:@(confidenceInClass) forKey:@"confidenceInClass"];
          [res setObject:@(maxClass) forKey:@"detectedClass"];
          
          [results addObject:res];
        }
      }
    }
  }
  return results;
}

float sigmoid(float x) {
  return 1.0 / (1.0 + exp(-x));
}

void softmax(float vals[], int count) {
  float max = -FLT_MAX;
  for (int i=0; i<count; i++) {
    max = fmax(max, vals[i]);
  }
  float sum = 0.0;
  for (int i=0; i<count; i++) {
    vals[i] = exp(vals[i] - max);
    sum += vals[i];
  }
  for (int i=0; i<count; i++) {
    vals[i] /= sum;
  }
}

@end
