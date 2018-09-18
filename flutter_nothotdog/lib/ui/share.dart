import 'package:flutter/material.dart';
import 'package:share/share.dart';

typedef void Callback();

class ShareResult extends StatelessWidget {
  final Callback onClear;
  final bool isHotdog;
  ShareResult(this.onClear, this.isHotdog);

  Widget _renderShareButton() {
    return Container(
      width: 200.0,
      height: 55.0,
      decoration: BoxDecoration(
        color: Color.fromRGBO(37, 213, 253, 1.0),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: OutlineButton(
        highlightColor: Color.fromRGBO(37, 213, 253, 1.0),
        highlightedBorderColor: Colors.white,
        borderSide: BorderSide(
          width: 2.0,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        onPressed: () =>
            Share.share(isHotdog ? 'I got “Hotdog!”' : 'I got “Not Hotdog!”'),
        child: Text(
          "Share",
          style: TextStyle(fontSize: 25.0, color: Colors.white),
        ),
      ),
    );
  }

  Widget _renderTextButton(text, size) {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.only(top: 10.0, bottom: 20.0),
      child: FlatButton(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 1.0,
              left: 1.0,
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: size,
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: size,
              ),
            )
          ],
        ),
        onPressed: onClear,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        _renderShareButton(),
        _renderTextButton("No thanks", 20.0),
      ],
    );
  }
}
