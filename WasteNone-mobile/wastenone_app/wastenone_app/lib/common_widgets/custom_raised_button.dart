import 'package:flutter/material.dart';

class CustomRaisedButton extends StatelessWidget {
  CustomRaisedButton(
      {this.child,
      this.color: Colors.white,
      this.borderRadius: 2.0,
      this.height: 40,
      this.onPressed})
      : assert(child != null),
        assert(color != null);

  final Widget child;
  final Color color;
  final double borderRadius;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: this.height,
      child: RaisedButton(
          color: this.color,
          child: this.child,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(this.borderRadius),
            ),
          ),
          onPressed: this.onPressed),
    );
  }
}
