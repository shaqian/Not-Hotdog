import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class Evaluating extends StatefulWidget {
  @override
  _EvaluatingState createState() => new _EvaluatingState();
}

class _EvaluatingState extends State<Evaluating>
    with SingleTickerProviderStateMixin {
  AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 10),
    );

    _rotateController.repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  Widget _renderIndicator() {
    return AnimatedBuilder(
      animation: _rotateController,
      child: CustomPaint(
        painter: IndicatorPainter(),
      ),
      builder: (BuildContext context, Widget _widget) {
        return new Transform.rotate(
          angle: _rotateController.value * math.pi * 5,
          child: _widget,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      color: Color.fromRGBO(37, 213, 253, .5),
      padding: EdgeInsets.only(bottom: height / 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _renderIndicator(),
          SizedBox(height: height / 6),
          Stack(
            children: <Widget>[
              Positioned(
                top: 1.0,
                left: 1.0,
                child: Text(
                  "Evaluating",
                  style: TextStyle(color: Colors.black, fontSize: 30.0),
                ),
              ),
              Text(
                "Evaluating",
                style: TextStyle(color: Colors.yellow, fontSize: 30.0),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class IndicatorPainter extends CustomPainter {
  @override
  paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    var dot = 14.0;
    var radius = 60;
    for (int i = 0; i < 8; i++) {
      double x = radius * math.cos(math.pi * i / 4 + math.pi / 8);
      double y = radius * math.sin(math.pi * i / 4 + math.pi / 8);
      paint.color = Colors.black;
      canvas.drawCircle(new Offset(x, y), dot, paint);
      paint.color = Colors.yellow;
      canvas.drawCircle(new Offset(x, y), dot - 1, paint);
      dot -= .8;
    }
  }

  @override
  bool shouldRepaint(IndicatorPainter old) => false;
}
