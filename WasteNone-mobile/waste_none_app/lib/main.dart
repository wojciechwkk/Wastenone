import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:waste_none_app/app/landing_page.dart';
import 'package:waste_none_app/services/secure_storage.dart';
import 'package:waste_none_app/services/firebase_auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:waste_none_app/services/flutter_notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Settings.init();
  FlutterNotification().init();
  runApp(WasteNoneApp());
}

class WasteNoneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    storeSecrets();

    return MaterialApp(
      title: 'WasteNone',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: LandingSemaphorePage(
        auth: WNFirebaseAuth(),
        db: WNFirebaseDB(),
      ),
    );
  }

  storeSecrets() {
    initStoreGithubKey();
    initStoreGithubSecret();
    initStoreTwitterKey();
    initStoreTwitterSecret();
  }
}
