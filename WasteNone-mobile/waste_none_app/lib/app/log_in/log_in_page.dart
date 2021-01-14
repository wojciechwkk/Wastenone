import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:waste_none_app/app/log_in/log_in_with_email_widget.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/settings_window.dart';
import 'package:waste_none_app/services/secure_storage.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';

import 'log_in_button.dart';

class LogInPage extends StatelessWidget {
  LogInPage({@required this.auth, @required this.db, @required this.userStreamCtrl});

  final AuthBase auth;
  final WNFirebaseDB db;
  StreamController<WasteNoneUser> userStreamCtrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(context),
    );
  }

  bool _LogAnonFirstPressed = true;
  SingleChildScrollView _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.only(top: 30, left: 50, right: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 50.0),
            SizedBox(height: 70, child: Image.asset('images/wastenone.png')),
            SizedBox(height: 50.0),
            LogInWithEmailOrGoogleForm(
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
                if (_LogAnonFirstPressed) {
                  _LogAnonFirstPressed = false;
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
      WasteNoneLogger().d('Logging in as an anon!');
      await _logInAndDBCreateAnon();
    } catch (e) {
      WasteNoneLogger().d(e.toString());
    }
  }

  _logInAndDBCreateAnon() async {
    WasteNoneUser user = await auth.logInAnonymously();
    String encryptionPassword = await createEncryptionPassword(user.uid);

    String defaultFridgeID = await db.createDefaultFridge(user.uid);
    user.addFridgeID(defaultFridgeID);

    // String encodedUserData = user.asEncodedString(encryptionPassword);
    await db.createUser(user);

    userStreamCtrl.sink.add(user);
  }
}
