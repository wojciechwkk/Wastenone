import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waste_none_app/common_widgets/custom_raised_button.dart';

class FormSubmitButton extends CustomRaisedButton{
  FormSubmitButton({
    @required String text,
    VoidCallback onPressed,
}) : super(
    child: Text(
      text,
      style: TextStyle(color: Colors.white, fontSize: 20.0),
    ),
    height: 34.0,
    color: Colors.blue,
    borderRadius: 2.0,
    onPressed: onPressed,
    );
}