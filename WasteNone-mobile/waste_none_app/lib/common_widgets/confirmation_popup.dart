import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmationPopup extends StatefulWidget {
  ConfirmationPopup({@required this.title, @required this.msg});

  final String title;
  final String msg;

  @override
  State<StatefulWidget> createState() {
    return ConfirmationPopupState(title: this.title, msg: this.msg);
  }
}

class ConfirmationPopupState extends State<ConfirmationPopup> {
  ConfirmationPopupState({@required this.title, @required this.msg}) {}

  final String title;
  final String msg;

  bool _firstPress = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 100,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 220,
                child: Text(msg),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: const Text('YES'),
            onPressed: () {
              if (_firstPress) {
                _firstPress = false;
                Navigator.of(context).pop(true);
              }
            }),
        FlatButton(
            child: const Text('NO'),
            onPressed: () {
              Navigator.of(context).pop(false);
            }),
      ],
    );
  }
}
