import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;

const height = 180.0;

class Prediction extends StatefulWidget {
  final bool isHotdog;
  final List<Map<String, dynamic>> rects;

  Prediction(this.rects, this.isHotdog);

  @override
  _PredictionState createState() => new _PredictionState();
}

class _PredictionState extends State<Prediction> with TickerProviderStateMixin {
  AnimationController _slideInController;
  Animation<Offset> _slideIn;
  AnimationController _pulseController;
  Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _slideInController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _slideIn = new Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(new CurvedAnimation(
      parent: _slideInController,
      curve: Curves.fastOutSlowIn,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _pulseController.forward();
      });

    _pulse = new Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(new CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    ))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _pulseController.reverse();
      });

    _slideInController.forward();
  }

  @override
  void dispose() {
    _slideInController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _renderText(text, size) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: 30.0),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 2.0,
              left: 2.0,
              child: Text(
                text,
                style: TextStyle(color: Colors.black, fontSize: size),
              ),
            ),
            Text(
              text,
              style: TextStyle(color: Colors.yellow, fontSize: size),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderImage() {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: height / 2),
      child: Image.asset(
        "images/hotdog.png",
        width: height / 2,
        height: height / 2,
      ),
    );
  }

  Widget _renderCross(width) {
    return Container(
        alignment: Alignment.topCenter,
        padding: EdgeInsets.only(top: height / 2),
        child: Padding(
          padding: EdgeInsets.only(top: height / 18, left: height / 3),
          child: Transform.rotate(
            angle: math.pi / 4.0,
            child: CustomPaint(
              painter: CrossPainter(width),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return SlideTransition(
      position: _slideIn,
      child: Container(
        alignment: Alignment.topCenter,
        height: height,
        child: Stack(
          children: <Widget>[
            CustomPaint(
              painter: BackgroundPainter(widget.isHotdog, width),
            ),
            _renderImage(),
            _renderText(widget.isHotdog ? "Hotdog!" : "Not Hotdog!", 40.0),
            !widget.isHotdog ? _renderCross(width) : Container(),
          ],
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final bool isHotdog;
  final double width;
  BackgroundPainter(this.isHotdog, this.width);

  @override
  paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(new Rect.fromLTWH(.0, .0, width, height / 2 + 2), paint);
    canvas.drawCircle(
        new Offset(width / 2, height * 2 / 3 + 10), height / 3 + 2, paint);

    paint.color =
        isHotdog ? Colors.lightGreenAccent[400] : Colors.redAccent[400];
    canvas.drawRect(new Rect.fromLTWH(.0, .0, width, height / 2), paint);
    canvas.drawCircle(
        new Offset(width / 2, height * 2 / 3 + 10), height / 3, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter old) => false;
}

class CrossPainter extends CustomPainter {
  final double width;
  CrossPainter(this.width);

  @override
  paint(Canvas canvas, Size size) {
    final paint = new Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    var height = 94.0;
    var width = 9.0;

    canvas.drawRect(
      new Rect.fromLTWH(-4.0, -4.0, width, height),
      paint,
    );
    canvas.translate(.0, height / 2);
    canvas.drawRect(
      new Rect.fromLTWH(
          -(height - width) / 2 - 4.0, -width / 2 - 4.0, height, width),
      paint,
    );

    height -= 4;
    width -= 4;
    paint.color = Colors.white;
    canvas.translate(.0, -height / 2);
    canvas.drawRect(
      new Rect.fromLTWH(-2.0, -4.0, width, height),
      paint,
    );
    canvas.translate(0.0, height / 2);
    canvas.drawRect(
      new Rect.fromLTWH(
          -(height - width) / 2 - 2.0, -width / 2 - 4.0, height, width),
      paint,
    );
  }

  @override
  bool shouldRepaint(CrossPainter old) => false;
}
