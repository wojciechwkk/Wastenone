import 'package:flutter/material.dart';
import 'package:waste_none_app/app/landing_page.dart';
import 'package:waste_none_app/services/firebase_auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';

void main() {
  runApp(WasteNoneApp());
}

class WasteNoneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
}
