import 'package:flutter/material.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_auth.dart';

class HomePage extends StatelessWidget {
  HomePage({@required this.auth});
  final AuthBase auth;

  Future<void> _logOut() async {
    try {
      await auth.logOut();
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WasteNone'), actions: <Widget>[
        FlatButton(
            child: Text('Logout', style: TextStyle(fontSize: 18)),
            onPressed: _logOut)
      ]),
    );
  }
}
