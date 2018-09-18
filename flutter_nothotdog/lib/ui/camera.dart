import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

typedef void Callback(String str);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback getImage;
  final Callback hideButton;
  final bool showButton;

  Camera(this.cameras, this.showButton, this.hideButton, this.getImage);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController controller;
  String filePath;

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((extDir) {
      filePath = '${extDir.path}/image.jpg';
      File(filePath).exists().then((val) {
        if (val) File(filePath).delete();
      });
    });

    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future takePicture() async {
    if (controller.value.isTakingPicture) return;
    try {
      await controller
          .takePicture(filePath)
          .then((value) => widget.getImage(filePath));
    } on CameraException catch (e) {
      print('Error: $e.code\nError Message: $e.message');
    }
  }

  void onTakePictureButtonPressed() {
    widget.hideButton("");
    takePicture();
  }

  @override
  Widget build(BuildContext context) {
    Widget _renderButton() {
      return Container(
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Container(
          width: 70.0,
          height: 70.0,
          decoration: BoxDecoration(
            color: Colors.yellow,
            borderRadius: BorderRadius.circular(40.0),
          ),
          child: OutlineButton(
            highlightColor: Colors.yellow,
            highlightedBorderColor: Colors.black,
            borderSide: BorderSide(width: 5.0, color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40.0),
            ),
            onPressed: onTakePictureButtonPressed,
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    var tmp = MediaQuery.of(context).size;
    var screenSize = {
      "height": tmp.height > tmp.width ? tmp.height : tmp.width,
      "width": tmp.height > tmp.width ? tmp.width : tmp.height
    };
    tmp = controller.value.previewSize;
    var previewSize = {
      "height": tmp.height > tmp.width ? tmp.height : tmp.width,
      "width": tmp.height > tmp.width ? tmp.width : tmp.height
    };
    var screenRatio = screenSize["height"] / screenSize["width"];
    var previewRatio = previewSize["height"] / previewSize["width"];

    return Stack(
      children: <Widget>[
        OverflowBox(
          maxHeight: screenRatio > previewRatio
              ? screenSize["height"]
              : (previewSize["height"] *
                  screenSize["width"] /
                  previewSize["width"]),
          maxWidth: screenRatio > previewRatio
              ? (previewSize["width"] *
                  screenSize["height"] /
                  previewSize["height"])
              : screenSize["width"],
          child: CameraPreview(controller),
        ),
        widget.showButton ? _renderButton() : Container(),
      ],
    );
  }
}
