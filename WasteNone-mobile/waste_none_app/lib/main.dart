import 'package:flutter/material.dart';
import 'package:waste_none_app/app/log_in/log_in_page.dart';

void main() {
  runApp(WasteNoneApp());
}

class WasteNoneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteNone',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: LogInPage(
      ),
    );
  }
}
