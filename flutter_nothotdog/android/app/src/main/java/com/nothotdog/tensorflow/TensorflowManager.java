package com.nothotdog.tensorflow;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import java.io.FileInputStream;
import java.io.InputStream;
import android.graphics.Matrix;
import io.flutter.plugin.common.MethodChannel.Result;

public class TensorflowManager {
    private static TensorFlowYoloDetector detector;
    private static boolean loadSucceeded;

    public static void loadModel(final Context context, final Result result) {
        new Thread(new Runnable()  {
            public void run() {   
                try {
                    detector = new TensorFlowYoloDetector(context);
                    loadSucceeded = true;
                    result.success("Success");
                } catch (Exception e) {
                    loadSucceeded = false;
                    result.error("Couldn't load model", e.getMessage(), null);
                }
            }
        }).start();
    }


    public static void recognizeImage(final String str, final Result result)  {
        new Thread(new Runnable()  {
            public void run() {
                if (!loadSucceeded)
                    result.error("Model is not loaded", null, null);

                try {
                    InputStream inputStream = new FileInputStream(str.replace("file://",""));
                    Bitmap bitmap = BitmapFactory.decodeStream(inputStream);

                    int width = bitmap.getWidth();
                    int height = bitmap.getHeight();
                    if (width > height) {
                        Matrix matrix = new Matrix();
                        matrix.postRotate(90);
                        bitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height, matrix, true);
                    }

                    result.success(detector.recognizeImage(bitmap));
                } catch (Exception e) {
                    result.error("Running model failed", e.getMessage(), null);
                }
            }
        }).start();
    }
}
