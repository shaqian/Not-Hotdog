# Not Hotdog Flutter App

## Demo

> The app shows the bounding box and confidence (if there's any) when you click on the preview image. 

> Sharing image is not yet supported by the Flutter share plugin.

* iOS

![ios](../images/flutter_demo.gif)

## Dependencies

* TensorFlow Mobile: [iOS](https://www.tensorflow.org/mobile/ios_build#using_cocoapods), [Android](https://www.tensorflow.org/mobile/android_build#adding_tensorflow_to_your_apps_using_android_studio)
* [camera](https://pub.dartlang.org/packages/camera)
* [path_provider](https://pub.dartlang.org/packages/path_provider)
* [share](https://pub.dartlang.org/packages/share)

## Prerequisites

Copy *quantized_yolov2-tiny-hotdog.pb* in *../yolo* directory to

* flutter_nothotdog/android/app/src/main/assets/
* flutter_nothotdog/ios/Runner/TensorFlow/

## Installation 

* For iOS, TensorFlow Mobile is installed using POD:

```
cd flutter_nothotdog/ios
pod install
```

* Install other dependencies:

```
cd flutter_nothotdog/
flutter packages get
```

## Run the App

```
flutter run
```

### Or for Android: 

* Install the flutter_hotdog.apk (released version) in flutter_nothotdog directory. 

### Native Module in Flutter

I created my own native module to interact with Tensorflow Mobile.

* iOS:

  The native code is in *flutter_nothotdog/ios/Runner/TensorFlow/*

* Android:

  The native code is in *flutter_nothotdog/android/app/src/main/java/com/nothotdog/tensorflow/*

Thanks to:

* [TensorFlow Android example](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/examples/android/src/org/tensorflow/demo/)

* [TensorFlow iOS example](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/ios/simple)

* [yolov2_tf_ios](https://github.com/jeffxtang/yolov2_tf_ios)

