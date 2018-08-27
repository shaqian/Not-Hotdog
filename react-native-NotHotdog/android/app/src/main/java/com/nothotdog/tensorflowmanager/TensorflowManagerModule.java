package com.nothotdog.tensorflowmanager;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.support.annotation.Nullable;

import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import java.io.FileInputStream;
import java.io.InputStream;

public class TensorflowManagerModule extends ReactContextBaseJavaModule {
    public static final String REACT_CLASS = "TensorflowManager";
    private static ReactApplicationContext reactContext = null;
    private TensorFlowYoloDetector detector;
    private boolean loadSucceeded;

    public TensorflowManagerModule(ReactApplicationContext context) {
        super(context);
        reactContext = context;
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    private void sendEvent(ReactContext reactContext,
                           String eventName,
                           @Nullable WritableArray params) {
        reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, params);
    }

    @ReactMethod
    public void loadModel(final Callback callback) {
        new Thread(new Runnable() {
            public void run() {
                try {
                    detector = new TensorFlowYoloDetector(reactContext);
                    loadSucceeded = true;
                    callback.invoke();
                } catch (Exception e) {
                    loadSucceeded = false;
                    callback.invoke("Couldn't load model");
                }
            }
        }).start();
    }

    @ReactMethod
    public void recognizeImage(final String str, final Callback callback)  {
        if (!loadSucceeded) {
            callback.invoke("Couldn't load model");
            return;
        }

        new Thread(new Runnable() {
            public void run() {
                try {
                    InputStream inputStream = new FileInputStream(str.replace("file://",""));
                    Bitmap bitmap = BitmapFactory.decodeStream(inputStream);
                    WritableArray results = detector.recognizeImage(bitmap);
                    sendEvent(reactContext, "predictions", results);
                } catch (Exception e) {
                    callback.invoke("Running model failed");
                }
            }
        }).start();
    }
}
