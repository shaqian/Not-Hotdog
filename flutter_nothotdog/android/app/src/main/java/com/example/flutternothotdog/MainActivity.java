package com.example.flutternothotdog;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import com.nothotdog.tensorflow.TensorflowManager;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "nothotdog.com/tensorflow";

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(
        new MethodCallHandler() {
          @Override
          public void onMethodCall(MethodCall call, Result result) {
            if (call.method.equals("loadModel")) {
              TensorflowManager.loadModel(getApplicationContext(), result);
            } if (call.method.equals("recognizeImage")) {
              String path = call.argument("path");
              TensorflowManager.recognizeImage(path, result);
            }
          }
        });
  }
}
