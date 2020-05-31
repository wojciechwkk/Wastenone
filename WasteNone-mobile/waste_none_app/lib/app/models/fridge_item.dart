import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';

class FridgeItem {
  FridgeItem();

  String dbKey;
  String fuid;
  String fridge_no;
  String product_puid;
  int qty;
  String validDate;
  String comment;

  FridgeItem.fromSnapshot(DataSnapshot snapshot)
      : dbKey = snapshot.key,
        fuid = snapshot.value["fuid"],
        fridge_no = snapshot.value["fridge_no"],
        product_puid = snapshot.value["product_puid"],
        qty = snapshot.value["qty"],
        validDate = snapshot.value["validDate"],
        comment = snapshot.value["comment"];

  FridgeItem.fromMap(String key, LinkedHashMap<dynamic, dynamic> valueMap)
      : dbKey = key,
        fuid = valueMap["fuid"],
        fridge_no = valueMap["fridge_no"],
        product_puid = valueMap["product_puid"],
        qty = valueMap["qty"],
        validDate = valueMap["validDate"],
        comment = valueMap["comment"];

  Map<String, dynamic> get map {
    return {
      "dbKey": dbKey,
      "fuid": fuid,
      "fridge_no": fridge_no,
      "product_puid": product_puid,
      "qty": qty,
      "validDate": validDate,
      "comment": comment,
    };
  }

  toJson() {
    return {
      "fridge_no": fridge_no,
      "product_puid": product_puid,
      "qty": qty,
      "validDate": validDate,
      "comment": comment,
    };
  }

  bool isEmpty() {
    return fridge_no == null || product_puid == null;
  }
}