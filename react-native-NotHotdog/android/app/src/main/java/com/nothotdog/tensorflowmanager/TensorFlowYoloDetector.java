package com.nothotdog.tensorflowmanager;

import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.graphics.Canvas;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import org.tensorflow.contrib.android.TensorFlowInferenceInterface;

public class TensorFlowYoloDetector {
  private static final String YOLO_MODEL_FILE = "file:///android_asset/quantized_yolov2-tiny-hotdog.pb";
  private static final int YOLO_INPUT_SIZE = 416;
  private static final String YOLO_INPUT_NAME = "input";
  private static final String YOLO_OUTPUT_NAMES = "output";
  private static final int YOLO_BLOCK_SIZE = 32;

  private static final int NUM_CLASSES = 1;
  private static final int NUM_BOXES_PER_BLOCK = 5;

  private static final double[] ANCHORS = {
      0.57273, 0.677385, 1.87446, 2.06253, 3.33843, 5.47434, 7.88282, 3.52778, 9.77052, 9.16828
  };

  private int[] intValues;
  private float[] floatValues;

  private String inputName;
  private String[] outputNames;
  private int inputSize;
  private int blockSize;

  private TensorFlowInferenceInterface inferenceInterface;

  public TensorFlowYoloDetector(ReactContext context) {
    this.inputName = YOLO_INPUT_NAME;
    this.inputSize = YOLO_INPUT_SIZE;
    this.outputNames = YOLO_OUTPUT_NAMES.split(",");
    this.blockSize = YOLO_BLOCK_SIZE;
    this.inferenceInterface = new TensorFlowInferenceInterface(context.getAssets(), YOLO_MODEL_FILE);
  }

  public WritableArray recognizeImage(final Bitmap bitmapRaw) {
    intValues = new int[inputSize * inputSize];
    floatValues = new float[inputSize * inputSize * 3];

    Bitmap bitmap = Bitmap.createBitmap(inputSize, inputSize, Bitmap.Config.ARGB_8888);

    Matrix matrix = getTransformationMatrix(
        bitmapRaw.getWidth(), bitmapRaw.getHeight(),
        inputSize, inputSize, false);

    final Canvas canvas = new Canvas(bitmap);
    canvas.drawBitmap(bitmapRaw, matrix, null);
    bitmap.getPixels(intValues, 0, bitmap.getWidth(), 0, 0, bitmap.getWidth(), bitmap.getHeight());

    for (int i = 0; i < intValues.length; ++i) {
      floatValues[i * 3 + 0] = ((intValues[i] >> 16) & 0xFF) / 255.0f;
      floatValues[i * 3 + 1] = ((intValues[i] >> 8) & 0xFF) / 255.0f;
      floatValues[i * 3 + 2] = (intValues[i] & 0xFF) / 255.0f;
    }

    inferenceInterface.feed(inputName, floatValues, 1, inputSize, inputSize, 3);

    inferenceInterface.run(outputNames);

    final int gridWidth = bitmap.getWidth() / blockSize;
    final int gridHeight = bitmap.getHeight() / blockSize;
    final float[] output =
        new float[gridWidth * gridHeight * (NUM_CLASSES + 5) * NUM_BOXES_PER_BLOCK];

    inferenceInterface.fetch(outputNames[0], output);

    WritableArray results = Arguments.createArray();

    for (int y = 0; y < gridHeight; ++y) {
      for (int x = 0; x < gridWidth; ++x) {
        for (int b = 0; b < NUM_BOXES_PER_BLOCK; ++b) {
          final int offset =
              (gridWidth * (NUM_BOXES_PER_BLOCK * (NUM_CLASSES + 5))) * y
                  + (NUM_BOXES_PER_BLOCK * (NUM_CLASSES + 5)) * x
                  + (NUM_CLASSES + 5) * b;

          final float confidence = expit(output[offset + 4]);

          int detectedClass = -1;
          float maxClass = 0;

          final float[] classes = new float[NUM_CLASSES];
          for (int c = 0; c < NUM_CLASSES; ++c) {
            classes[c] = output[offset + 5 + c];
          }
          softmax(classes);

          for (int c = 0; c < NUM_CLASSES; ++c) {
            if (classes[c] > maxClass) {
              detectedClass = c;
              maxClass = classes[c];
            }
          }

          final float confidenceInClass = maxClass * confidence;
          if (confidenceInClass > 0.5) {
            final float xPos = (x + expit(output[offset + 0])) * blockSize;
            final float yPos = (y + expit(output[offset + 1])) * blockSize;

            final float w = (float) (Math.exp(output[offset + 2]) * ANCHORS[2 * b + 0]) * blockSize;
            final float h = (float) (Math.exp(output[offset + 3]) * ANCHORS[2 * b + 1]) * blockSize;

            WritableMap rect = Arguments.createMap();
            rect.putDouble("x", (double)Math.max(0, xPos - w / 2));
            rect.putDouble("y", (double)Math.max(0, yPos - h / 2));
            rect.putDouble("w", w);
            rect.putDouble("h", h);

            WritableMap result = Arguments.createMap();
            result.putMap("rect", rect);
            result.putDouble("confidenceInClass", confidenceInClass);
            result.putDouble("detectedClass", detectedClass);

            results.pushMap(result);
          }
        }
      }
    }

    return results;
  }


  private float expit(final float x) {
    return (float) (1. / (1. + Math.exp(-x)));
  }

  private void softmax(final float[] vals) {
    float max = Float.NEGATIVE_INFINITY;
    for (final float val : vals) {
      max = Math.max(max, val);
    }
    float sum = 0.0f;
    for (int i = 0; i < vals.length; ++i) {
      vals[i] = (float) Math.exp(vals[i] - max);
      sum += vals[i];
    }
    for (int i = 0; i < vals.length; ++i) {
      vals[i] = vals[i] / sum;
    }
  }

  public static Matrix getTransformationMatrix(final int srcWidth,
                                               final int srcHeight,
                                               final int dstWidth,
                                               final int dstHeight,
                                               final boolean maintainAspectRatio)
  {
      final Matrix matrix = new Matrix();

      if (srcWidth != dstWidth || srcHeight != dstHeight) {
          final float scaleFactorX = dstWidth / (float) srcWidth;
          final float scaleFactorY = dstHeight / (float) srcHeight;

          if (maintainAspectRatio) {
            final float scaleFactor = Math.max(scaleFactorX, scaleFactorY);
            matrix.postScale(scaleFactor, scaleFactor);
          } else {
            matrix.postScale(scaleFactorX, scaleFactorY);
          }
      }

      matrix.invert(new Matrix());
      return matrix;
  }
}
