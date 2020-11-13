import 'dart:collection';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:waste_none_app/app/utils/cryptography_util.dart';

/*
  String dbKey;
  String fuid;
  String fridge_no;
  String product_puid;
  int qty;
  String validDate;
  String comment;
 */
class FridgeItem implements Comparable {
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

  asEncodedString(String usersEncodingPassword) {
    return encryptAESCryptoJS(jsonEncode(this), usersEncodingPassword);
  }

  bool isEmpty() {
    return fridge_no == null || product_puid == null;
  }

  @override
  int compareTo(other) {
    DateTime thisDate = new DateFormat("yyyy-MM-dd").parse(this.validDate);
    DateTime otherDate = new DateFormat("yyyy-MM-dd").parse(other.validDate);
    // print(
    //     '${this.validDate}: ${thisDate.month}-${thisDate.day} compare to ${other.validDate}: ${otherDate.month}-${otherDate.day}');
    return thisDate.compareTo(otherDate);
  }

  DateTime getValidDateAsDate() {
    return new DateFormat("yyyy-MM-dd").parse(this.validDate);
  }
}
