import 'package:flutter/material.dart';
import 'package:waste_none_app/app/log_in/log_in_with_email_widget.dart';
import 'package:waste_none_app/app/models/fridge.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';

import 'log_in_button.dart';
import 'social_log_in_button.dart';

class LogInPage extends StatelessWidget {
  LogInPage({@required this.auth, @required this.db});

  final AuthBase auth;
  final WNFirebaseDB db;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//      appBar: AppBar(
//        title: Text('WasteNone'),
//        elevation: 100,
//      ),
//      resizeToAvoidBottomInset: false,
      body: _buildContent(),
    );
  }

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
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SocialLogInButton(
                      //'Log in with Google',
                      assetPic: 'images/google.png',
                      height: 60,
                      onPressed: _logInWithGoogle),
                  SocialLogInButton(
                      //'Log in with Twitter',
                      assetPic: 'images/twitter.png',
                      height: 60,
                      onPressed: _logInWithTwitter),
                  SocialLogInButton(
                      //'Log in with Github',
                      assetPic: 'images/github.png',
                      height: 60,
                      onPressed: _logInWithGithub),
                ]),
            SizedBox(height: 26.0),
            LogInWithEmailForm(
              auth: auth,
              db: db,
            ),
            SizedBox(height: 16.0),
            LogInButton(
              text: 'Check it out without authentication',
              textColor: Colors.black,
              color: Colors.grey[200],
              onPressed: _logInAnonymously,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logInAnonymously() async {
    try {
      await _logInAndDBCreate();
    } catch (e) {
      print(e.toString());
    }
  }

  _logInAndDBCreate() async {
    WasteNoneUser user = await auth.logInAnonymously();
    print('logged in user: ${user.toJson()}');
    await db.createUser(user);
  }

  Future<void> _logInWithGoogle() async {
    try {
      auth.logInWihGoogle().then((user) => db.createUser(user));
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _logInWithTwitter() async {
    try {
      auth.logInWihTwitter().then((user) => db.createUser(user));
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _logInWithGithub() async {
    try {
      auth.logInWihGithub().then((user) => db.createUser(user));
    } catch (e) {
      print(e.toString());
    }
  }
}
