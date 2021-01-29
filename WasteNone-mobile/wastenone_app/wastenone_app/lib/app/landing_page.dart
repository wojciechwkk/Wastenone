import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';

import 'fridge_page.dart';
import 'log_in/log_in_page.dart';
import 'models/user.dart';

class LandingSemaphorePage extends StatelessWidget {
  LandingSemaphorePage({@required this.auth, @required this.db}) {
    WasteNoneUser user = auth.userListenerUpdated();
    userStreamCtrl.sink.add(user);
  }

  final AuthBase auth;
  final WNFirebaseDB db;

  StreamController<WasteNoneUser> userStreamCtrl = new StreamController();

  @override
  Widget build(BuildContext context) {
    userStreamCtrl.sink.add(auth.currentUser());
    return StreamBuilder<WasteNoneUser>(
//        stream: auth.onAuthStateChange,
//         stream: db.onDBCreateStateChange,
        stream: userStreamCtrl.stream,
        builder: (context, snapshot) {
//          WasteNoneLogger().d(snapshot.connectionState);
          if (snapshot.connectionState == ConnectionState.active) {
            WasteNoneUser user = snapshot.data;
            if (user == null) {
              return LogInPage(
                auth: auth,
                db: db,
                userStreamCtrl: userStreamCtrl,
              );
            } else
              return FridgePage(
                auth: auth,
                db: db,
                userStreamCtrl: userStreamCtrl,
              );
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
