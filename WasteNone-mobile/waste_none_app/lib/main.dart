import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:waste_none_app/app/landing_page.dart';
import 'package:waste_none_app/services/firebase_auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';

void main() {
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
    WNFlutterStorageUtil.initStoreGithubKey();
    WNFlutterStorageUtil.initStoreGithubSecret();
    WNFlutterStorageUtil.initStoreTwitterKey();
    WNFlutterStorageUtil.initStoreTwitterSecret();
  }
}
