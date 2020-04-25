import 'package:flutter/material.dart';

import 'log_in_button.dart';
import 'social_log_in_button.dart';

class LogInPage extends StatelessWidget {
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
/*          Text(
            'Log In',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.w600,
            ),
          ),*/
          SizedBox(
              height: 70,
              child: Image.asset('images/wastenone.png')),
          SizedBox(height: 40.0),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SocialLogInButton( //'Log in with Google',
                    assetPic: 'images/google.png',
                    height: 80,
                    onPressed: () => _LogInWithGoogle()),
                SocialLogInButton( //'Log in with Twitter',
                    assetPic: 'images/twitter.png',
                    height: 80,
                    onPressed: () {}),
                SocialLogInButton( //'Log in with Github',
                  assetPic: 'images/github.png',
                  height: 80,
                  onPressed: () {},
                ),
              ]),
          SizedBox(height: 16.0),
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _LogInWithGoogle {}
//child: Text(
//'Log in with Google',
//style: TextStyle(color: Colors.black87),
//),
//shape: RoundedRectangleBorder(
//borderRadius: BorderRadius.all(
//Radius.circular(20.0),
//),
//),
//onPressed: () {});
