import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import 'camera.dart';
import 'prediction.dart';
import 'share.dart';
import 'evaluating.dart';
import 'bndbox.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomePage(this.cameras);

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool showButton = true;
  String imageFile;
  Map<String, dynamic> image;
  bool showBox = false;
  static const platform = const MethodChannel('nothotdog.com/tensorflow');

  @override
  void initState() {
    super.initState();
  }

  Future<List<Map<String, dynamic>>> _recognizeImage(Size screen) async {
    if (imageFile == null) return null;

    try {
      var results = await platform.invokeMethod(
        'recognizeImage',
        {"path": imageFile},
      );

      if (results == null || results.length == 0) return [];

      results.sort((a, b) {
        if (a["confidenceInClass"] > b["confidenceInClass"])
          return -1;
        else if (a["confidenceInClass"] == b["confidenceInClass"])
          return 0;
        else
          return 1;
      });

      var newRects = [
        {
          "confidence": results[0]["confidenceInClass"],
          "x": results[0]["rect"]["x"],
          "y": results[0]["rect"]["y"],
          "w": results[0]["rect"]["w"],
          "h": results[0]["rect"]["h"]
        }
      ];

      var cnt = 0;
      for (int i = 1; i < results.length; i++) {
        var a = results[i]["rect"];
        var add = true;

        for (int j = 0; j <= cnt; j++) {
          var b = newRects[j];

          double xa1 = a["x"];
          double xa2 = a["x"] + a["w"];
          double xb1 = b["x"];
          double xb2 = b["x"] + b["w"];
          double ya1 = a["y"];
          double ya2 = a["y"] + a["h"];
          double yb1 = b["y"];
          double yb2 = b["y"] + b["h"];

          double sa = a["w"] * a["h"];
          double sb = b["w"] * b["h"];
          double si = math.max(0, math.min(xa2, xb2) - math.max(xa1, xb1)) *
              math.max(0, math.min(ya2, yb2) - math.max(ya1, yb1));
          double su = sa > sb ? sb : sa;

          var ratio = si / su;
          if (ratio > 0.5) {
            add = false;
          }
        }

        if (add) {
          cnt++;
          newRects.add({
            "confidence": results[i]["confidenceInClass"],
            "x": results[i]["rect"]["x"],
            "y": results[i]["rect"]["y"],
            "w": results[i]["rect"]["w"],
            "h": results[i]["rect"]["h"]
          });
        }
      }

      var scale = {
        "h": image["height"] / screen.height,
        "w": image["width"] / screen.width
      };
      var img;
      if (scale["h"] > scale["w"])
        img = {
          "w": screen.width,
          "h": screen.height * scale["h"] / scale["w"],
        };
      else
        img = {
          "w": screen.width * scale["w"] / scale["h"],
          "h": screen.height,
        };

      var ratioH = img["h"] / 416;
      var ratioW = img["w"] / 416;
      var difH = img["h"] - screen.height;
      var difW = img["w"] - screen.width;
      var rects = newRects
          .map((rect) => {
                "confidence": rect["confidence"],
                "x": rect["x"] * ratioW - difW / 2,
                "y": rect["y"] * ratioH - difH / 2,
                "w": rect["w"] * ratioW,
                "h": rect["h"] * ratioH
              })
          .toList();

      print(rects);
      return rects;
    } on PlatformException catch (e) {
      print('Error: $e.code\nError Message: $e.message');
      return [];
    }
  }

  void getImage(string) {
    imageCache.clear();
    new FileImage(File(string))
        .resolve(new ImageConfiguration())
        .addListener((ImageInfo info, bool _) {
      setState(() {
        image = {
          "image": info.image,
          "height": info.image.height.toDouble(),
          "width": info.image.width.toDouble()
        };
        imageFile = string;
      });
    });
  }

  void onClear() {
    setState(() {
      File(imageFile).delete();
      imageFile = null;
      image = null;
      showButton = true;
      showBox = false;
    });
  }

  void hideButton(String str) {
    setState(() {
      showButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Camera(widget.cameras, showButton, hideButton, getImage),
          image != null && image["image"] != null
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      showBox = !showBox;
                    });
                  },
                  child: Container(
                    width: size.width,
                    height: size.height,
                    child: RawImage(
                      image: image["image"],
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : Container(),
          FutureBuilder(
              future: _recognizeImage(size),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> rects,
              ) {
                if (rects.data != null) {
                  bool isHotdog = rects.data.length > 0;
                  return Stack(
                    children: <Widget>[
                      BndBox(showBox ? rects.data : []),
                      Prediction(rects.data, isHotdog),
                      ShareResult(onClear, isHotdog),
                    ],
                  );
                } else if (imageFile != null)
                  return Evaluating();
                else
                  return Container();
              }),
        ],
      ),
    );
  }
}
