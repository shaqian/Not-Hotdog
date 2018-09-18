import 'package:flutter/material.dart';

class BndBox extends StatelessWidget {
  final List<Map<String, dynamic>> rects;

  BndBox(this.rects);

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBox() {
      return rects.map((rect) {
        return Positioned(
          left: rect["x"],
          top: rect["y"],
          width: rect["w"],
          height: rect["h"],
          child: Container(
            padding: EdgeInsets.only(top: 10.0, left: 10.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: Color.fromRGBO(37, 213, 253, 1.0),
                width: 5.0,
              ),
            ),
            child: Text(
              (rect["confidence"] * 100).toStringAsFixed(2) + "%",
              style: TextStyle(
                color: Color.fromRGBO(37, 213, 253, 1.0),
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList();
    }

    return Stack(
      children: _renderBox(),
    );
  }
}
