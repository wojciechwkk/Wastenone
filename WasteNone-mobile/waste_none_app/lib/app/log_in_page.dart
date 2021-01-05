import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waste_none_app/app/log_in/log_in_with_email_widget.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';

import 'log_in/log_in_button.dart';

class LogInPage extends StatelessWidget {
  LogInPage({@required this.auth, @required this.db, @required this.userStreamCtrl});

  final AuthBase auth;
  final WNFirebaseDB db;
  StreamController<WasteNoneUser> userStreamCtrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(),
    );
  }

  bool _buttonFirstPressed = true;
  SingleChildScrollView _buildContent() {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 70, child: Image.asset('images/wastenone.png')),
            SizedBox(height: 100.0),
            LogInWithEmailForm(
              auth: auth,
              db: db,
              userStreamCtrl: userStreamCtrl,
            ),
            SizedBox(height: 16.0),
            LogInButton(
              text: 'Check it out without authentication',
              textColor: Colors.black,
              color: Colors.grey[200],
              onPressed: () {
                if (_buttonFirstPressed) {
                  _buttonFirstPressed = false;
                  _logInAnonymously();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logInAnonymously() async {
    try {
      print('Logging in as an anon!');
      await _logInAndDBCreateAnon();
    } catch (e) {
      print(e.toString());
    }
  }

  _logInAndDBCreateAnon() async {
    WasteNoneUser user = await auth.logInAnonymously();
    String encryptionPassword = await createEncryptionPassword(user.uid);

    String defaultFridgeID = await db.createDefaultFridge(user.uid);
    user.addFridgeID(defaultFridgeID);

    String encodedUserData = user.asEncodedString(encryptionPassword);
    await db.createUser(user);

    userStreamCtrl.sink.add(user);
  }
}
