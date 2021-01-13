import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ItemQtySelectionPopup extends StatefulWidget {
  ItemQtySelectionPopup({@required this.titleText, @required this.maxQty, @required this.defaultQty});

  final String titleText;
  final int maxQty;
  final int defaultQty;

  @override
  State<StatefulWidget> createState() {
    return ItemQtySelectionPopupState(titleText: this.titleText, maxQty: this.maxQty, defaultQty: this.defaultQty);
  }
}

class ItemQtySelectionPopupState extends State<ItemQtySelectionPopup> {
  ItemQtySelectionPopupState({@required this.titleText, @required this.maxQty, @required this.defaultQty}) {
    moveQty = defaultQty;
    moveQtyController.text = defaultQty.toString();
    print('moveQty $moveQty defaultQty $defaultQty  maxQty $maxQty');
  }

  final String titleText; //'Select quantity to move'
  final int maxQty;
  final int defaultQty;

  int moveQty;
  TextEditingController moveQtyController = TextEditingController();
  bool _firstPress = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titleText),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: 135,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 120,
                child: TextField(
                  // decoration: new InputDecoration( labelText: "quantity",),
                  style: TextStyle(fontSize: 30),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                  controller: moveQtyController,
                  onChanged: (value) {
                    moveQty = int.parse(value);
                  }, // y numbers can be entered
                ),
              ),
            ),
            Slider(
              divisions: maxQty - 1, // > 1 ? maxQty - 1 : 1,
              min: 1,
              max: maxQty.toDouble(),
              value: moveQty.toDouble(),
              onChanged: (value) {
                setState(() {
                  moveQty = value.round();
                  moveQtyController.text = moveQty.toString();
                });
              },
              label: '${moveQty.toString()}',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
            child: const Text('OK'),
            onPressed: () {
              //_showMoveToAnotherFridgeLocationPopup(moveItemIndex, moveQty.toInt(), context);
              if (_firstPress) {
                _firstPress = false;
                Navigator.of(context).pop(moveQty);
              }
            }),
        FlatButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context);
            }),
      ],
    );
  }
}
