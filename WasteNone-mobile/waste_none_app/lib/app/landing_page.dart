import 'package:flutter/material.dart';
import 'package:waste_none_app/services/auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';

import 'fridge_page.dart';
import 'log_in/log_in_page.dart';
import 'models/user.dart';

class LandingSemaphorePage extends StatelessWidget {
  LandingSemaphorePage({@required this.auth, @required this.db});

  final AuthBase auth;
  final WNFirebaseDB db;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WasteNoneUser>(
        stream: auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            WasteNoneUser user = snapshot.data;
            if (user == null) {
              return LogInPage(
                auth: auth,
                db: db,
              );
            } else {
              return FridgePage(
                auth: auth,
                db: db,
              );
            }
          } else {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        });
  }
}
