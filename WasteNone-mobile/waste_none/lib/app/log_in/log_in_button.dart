import 'package:flutter/cupertino.dart';
import 'package:waste_none_app/common_widgets/custom_raised_button.dart';

class LogInButton extends CustomRaisedButton {
  LogInButton({
    @required String text,
    Color color,
    Color textColor,
    VoidCallback onPressed,
  }) :  assert( text != null ),
        super(
          child: Text(text, style: TextStyle(color: textColor, fontSize: 15.0)),
          color: color,
          onPressed: onPressed,
        );
}
