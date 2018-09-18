# Not Hotdog React Native App

## Demo

> The app shows the bounding box and confidence (if there's any) when you click on the preview image. 

* iOS

![ios](../images/rn_demo.gif)

* Android

![android](../images/demo-android.jpg)

## Dependencies

* TensorFlow Mobile: [iOS](https://www.tensorflow.org/mobile/ios_build#using_cocoapods), [Android](https://www.tensorflow.org/mobile/android_build#adding_tensorflow_to_your_apps_using_android_studio)
* [react-native-camera](https://github.com/react-native-community/react-native-camera)
* [react-native-share](https://github.com/react-native-community/react-native-share)
* [react-native-fs](https://github.com/itinance/react-native-fs)
* [react-native-svg](https://github.com/react-native-community/react-native-svg)
* [react-native-animatable](https://github.com/oblador/react-native-animatable)

## Prerequisites

Copy *quantized_yolov2-tiny-hotdog.pb* in *../yolo* directory to

* react-native-NotHotdog/android/app/src/main/assets
* react-native-NotHotdog/ios/NotHotdog/data

## Installation 

* For iOS, TensorFlow Mobile is installed using POD:

```
cd react-native-NotHotdog/ios
pod install
```

* Install other dependencies:

```
cd react-native-NotHotdog/
npm install
```

## Run the App

### iOS

* In simulator:

```
react-native run-ios
```

* On device:

  Refer to [Running your app on iOS devices]( https://facebook.github.io/react-native/docs/running-on-device.html#running-your-app-on-ios-devices) in React Native official guide.


### Android

> Taking picture in the Android app is much slower than in iOS app due to some limitation in react-native-camera.

* Install the hotdog.apk (released version) in ./react-native-NotHotdog directory. 

* In simulator:

```
react-native run-android
```

* On device:

  Refer to [Running your app on Android devices]( https://facebook.github.io/react-native/docs/running-on-device.html#running-your-app-on-android-devices) in React Native official guide.


### Native Module in React Native

I created my own native module to interact with Tensorflow Mobile.

* iOS:

  The native code is in *react-native-NotHotdog/ios/NotHotdog/TensorflowManager.mm*

* Android:

  The native code is in *react-native-NotHotdog/android/app/src/main/java/com/nothotdog/tensorflowmanager/*

Thanks to:

* [TensorFlow Android example](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/examples/android/src/org/tensorflow/demo/)

* [TensorFlow iOS example](https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/ios/simple)

* [yolov2_tf_ios](https://github.com/jeffxtang/yolov2_tf_ios)


## TODO

* Improve image capturing in Android.
* Upgrade to Tensorflow Lite (if applicable)
