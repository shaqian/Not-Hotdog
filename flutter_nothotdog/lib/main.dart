import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'ui/home.dart';
import 'package:flutter/services.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
  await _loadModel();
  runApp(new NotHotdogApp());
}

Future<Null> _loadModel() async {
  try {
    const platform = const MethodChannel('nothotdog.com/tensorflow');
    final String result = await platform.invokeMethod('loadModel');
    if (result == "Success")
      print("Successfully loaded model.");
    else
      print("Failed to load model.");
  } on PlatformException catch (e) {
    print('Error: $e.code\nError Message: $e.message');
  }
}

class NotHotdogApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Not Hotdog',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: HomePage(cameras),
    );
  }
}
