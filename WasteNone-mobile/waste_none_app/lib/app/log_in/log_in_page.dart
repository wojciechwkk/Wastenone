import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_auth.dart';

import 'log_in_button.dart';
import 'social_log_in_button.dart';

class LogInPage extends StatelessWidget {
  LogInPage({@required this.auth});

  final AuthBase auth;

  Future<void> _logInAnonymously() async {
    try {
      await auth.logInAnonymously();
    } catch (e) {
      print(e.toString());
    }
  }
  Future<void> _logInWithGoogle() async {
    try {
      await auth.logInWihGoogle();
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WasteNone'),
        elevation: 100,
      ),
      body: _buildContent(),
    );
  }

  Container _buildContent() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(50),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 70, child: Image.asset('images/wastenone.png')),
          SizedBox(height: 140.0),
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
                    onPressed: () {}),
                SocialLogInButton(
                    //'Log in with Github',
                    assetPic: 'images/github.png',
                    height: 60,
                    onPressed: () {}),
              ]),
          SizedBox(height: 26.0),
          LogInButton(
            text: 'Log in with email',
            textColor: Colors.white,
            color: Color.fromRGBO(0, 128, 0, 100),
            onPressed: () {},
          ),
          SizedBox(height: 8.0),
          Text(
            'or',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.0),
          LogInButton(
            text: 'Check it out without authentication',
            textColor: Colors.black,
            color: Colors.grey[200],
            onPressed: _logInAnonymously,
          ),
        ],
      ),
    );
  }
}
