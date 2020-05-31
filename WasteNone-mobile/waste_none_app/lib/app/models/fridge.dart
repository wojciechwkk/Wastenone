import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class Fridge {
  Fridge(@required this.fridgeID, @required this.fridgeNo);

  String dbKey;
  String fridgeID;
  int fridgeNo;
  String displayName;
  String otherUsers;

  Fridge.fromSnapshot(DataSnapshot snapshot)
      : dbKey = snapshot.key,
        fridgeID = snapshot.value["fridgeID"],
        fridgeNo = snapshot.value["fridgeNo"],
        displayName = snapshot.value["displayName"],
        otherUsers = snapshot.value["otherUsers"];

  Fridge.fromMap(String key, LinkedHashMap<dynamic, dynamic> valueMap)
      : dbKey = key,
        fridgeID = valueMap["fridgeID"],
        fridgeNo = valueMap["fridgeNo"],
        displayName = valueMap["displayName"],
        otherUsers = valueMap["otherUsers"];

  Map<String, dynamic> get map {
    return {
      "dbKey": dbKey,
      "fridgeID": fridgeID,
      "fridgeNo": fridgeNo,
      "displayName": displayName,
      "otherUsers": otherUsers,
    };
  }

  toJson() {
    return {
      "dbKey": dbKey,
      "fridgeID": fridgeID,
      "fridgeNo": fridgeNo,
      "displayName": displayName,
      "otherUsers": otherUsers,
    };
  }
}
