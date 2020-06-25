import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:waste_none_app/app/landing_page.dart';
import 'package:waste_none_app/services/firebase_auth.dart';
import 'package:waste_none_app/services/firebase_database.dart';

void main() {
  runApp(WasteNoneApp());
}

class WasteNoneApp extends StatelessWidget {
  final storage = new FlutterSecureStorage();

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

  storeSecrets() async {
    await storage.write(key: "twitterKey", value: "lqkhcIN7gru1zWBEHfv07JrMw");
    await storage.write(
        key: "twitterSecret",
        value: "d5DDRkgE7oa10EZpH0kOfkMIl3l972QpP9sQ1N0FgUGifJCKNQ");
    await storage.write(key: "githubKey", value: "896604686094f376acb8");
    await storage.write(
        key: "githubSecret", value: "b73ad19b4ce6fe31a81c1ef090806882dce66323");
  }
}
