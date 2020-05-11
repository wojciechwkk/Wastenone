import 'package:flutter/material.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_auth.dart';

import 'home_page.dart';
import 'log_in/log_in_page.dart';

class LandingSemaphorePage extends StatelessWidget {
  LandingSemaphorePage({@required this.auth});
  final AuthBase auth;


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WasteNoneUser>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot){
        if( snapshot.connectionState == ConnectionState.active ){
          WasteNoneUser user = snapshot.data;
          if (user == null) {
            return LogInPage(
              auth: auth,
            );
          }

          return HomePage(
            auth: auth,
          );
        }
        else {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      }
    );
  }
}
