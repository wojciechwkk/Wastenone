import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SocialLogInButton extends StatelessWidget {
  SocialLogInButton({
    @required this.assetPic,
    this.height,
    this.onPressed,
  }) : assert(assetPic != null);

  final String assetPic;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: this.height,
      child: FlatButton(
          color: Colors.white, // background color,
          child: Image.asset(assetPic),
          onPressed: this.onPressed),
    );
  }
}
