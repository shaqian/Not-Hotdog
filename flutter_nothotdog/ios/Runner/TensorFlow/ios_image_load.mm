#include "ios_image_load.h"

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

using tensorflow::uint8;

std::vector<uint8> LoadImageFromFile(const char* file_name,
                                     int* out_width, int* out_height,
                                     int* out_channels) {
  FILE* file_handle = fopen(file_name, "rb");
  fseek(file_handle, 0, SEEK_END);
  const size_t bytes_in_file = ftell(file_handle);
  fseek(file_handle, 0, SEEK_SET);
  std::vector<uint8> file_data(bytes_in_file);
  fread(file_data.data(), 1, bytes_in_file, file_handle);
  fclose(file_handle);
  CFDataRef file_data_ref = CFDataCreateWithBytesNoCopy(NULL, file_data.data(),
                                                        bytes_in_file,
                                                        kCFAllocatorNull);
  CGDataProviderRef image_provider =
  CGDataProviderCreateWithCFData(file_data_ref);
  
  const char* suffix = strrchr(file_name, '.');
  if (!suffix || suffix == file_name) {
    suffix = "";
  }
  CGImageRef image;
  if (strcasecmp(suffix, ".png") == 0) {
    image = CGImageCreateWithPNGDataProvider(image_provider, NULL, true,
                                             kCGRenderingIntentDefault);
  } else if ((strcasecmp(suffix, ".jpg") == 0) ||
             (strcasecmp(suffix, ".jpeg") == 0)) {
    image = CGImageCreateWithJPEGDataProvider(image_provider, NULL, true,
                                              kCGRenderingIntentDefault);
  } else {
    CFRelease(image_provider);
    CFRelease(file_data_ref);
    fprintf(stderr, "Unknown suffix for file '%s'\n", file_name);
    out_width = 0;
    out_height = 0;
    *out_channels = 0;
    return std::vector<uint8>();
  }
  
  int width = (int)CGImageGetWidth(image);
  int height = (int)CGImageGetHeight(image);
  const int channels = 4;
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  bool rotate = false;
  
  if (width > height) {
    width = (int)CGImageGetHeight(image);
    height = (int)CGImageGetWidth(image);
    rotate = true;
  }
  
  const int bytes_per_row = (width * channels);
  const int bytes_in_image = (bytes_per_row * height);
  std::vector<uint8> result(bytes_in_image);
  const int bits_per_component = 8;

  CGContextRef context = CGBitmapContextCreate(result.data(), width, height,
                                               bits_per_component, bytes_per_row, color_space,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(color_space);
  
  if (rotate){
    CGContextTranslateCTM(context, 0.5f * width, 0.5f * height);
    CGContextRotateCTM(context, (-90.0 * M_PI/180));
    CGContextTranslateCTM(context,-0.5f * height, -0.5f * width);
    CGContextDrawImage(context, CGRectMake(0, 0, height, width), image);
  }
  else
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  
// Display image in native view to check orientation
//  CGImageRef imageRef = CGBitmapContextCreateImage(context);
//  UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
//  UIImageView *imgView = [[UIImageView alloc] initWithImage:finalImage];
//  UIView* flutterView = [UIApplication sharedApplication].delegate.window.rootViewController.view;
//  [flutterView addSubview:imgView];
  
  CGContextRelease(context);
  CFRelease(image);
  CFRelease(image_provider);
  CFRelease(file_data_ref);
  
  *out_width = width;
  *out_height = height;
  *out_channels = channels;
  return result;
}
