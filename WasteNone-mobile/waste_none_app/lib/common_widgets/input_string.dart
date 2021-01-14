import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InputStringPopup extends StatefulWidget {
  InputStringPopup({@required this.title});

  final String title;

  @override
  State<StatefulWidget> createState() {
    return InputStringPopupState(title: this.title);
  }
}

class InputStringPopupState extends State<InputStringPopup> {
  InputStringPopupState({@required this.title}) {}

  final String title;

  bool _firstPress = true;
  TextEditingController inputStringController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          width: 120,
          child: TextField(
            // decoration: new InputDecoration( labelText: "quantity",),
            // style: TextStyle(fontSize: ),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.text,
            inputFormatters: {FilteringTextInputFormatter.singleLineFormatter}.toList(),
            controller: inputStringController,
          ),
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: const Text('YES'),
            onPressed: () {
              if (_firstPress) {
                _firstPress = false;
                Navigator.of(context).pop(inputStringController.text);
              }
            }),
        FlatButton(
            child: const Text('NO'),
            onPressed: () {
              Navigator.of(context).pop(null);
            }),
      ],
    );
  }
}
