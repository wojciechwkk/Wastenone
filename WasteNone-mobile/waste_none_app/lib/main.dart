import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:waste_none_app/app/landing_page.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';
import 'package:waste_none_app/services/firebase_auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
