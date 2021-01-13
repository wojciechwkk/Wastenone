import 'dart:collection';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:waste_none_app/app/utils/cryptography_util.dart';

/*
  String dbKey;
  String fuid;
  String fridge_id;
  String product_ean;
  int qty;
  String validDate;
  String comment;
 */
class FridgeItem implements Comparable {
  FridgeItem();

  String dbKey;
  String fuid;
  String fridge_id;
  String product_ean;
  int qty;
  String validDate;
  String comment;

  FridgeItem.fromSnapshot(DataSnapshot snapshot)
      : dbKey = snapshot.key,
        fuid = snapshot.value["fuid"],
        fridge_id = snapshot.value["fridge_no"],
        product_ean = snapshot.value["product_ean"],
        qty = snapshot.value["qty"],
        validDate = snapshot.value["validDate"],
        comment = snapshot.value["comment"];

  FridgeItem.fromMap(String key, LinkedHashMap<dynamic, dynamic> valueMap)
      : dbKey = key,
        fuid = valueMap["fuid"],
        fridge_id = valueMap["fridge_no"],
        product_ean = valueMap["product_ean"],
        qty = valueMap["qty"],
        validDate = valueMap["validDate"],
        comment = valueMap["comment"];

  Map<String, dynamic> get map {
    return {
      "dbKey": dbKey,
      "fuid": fuid,
      "fridge_no": fridge_id,
      "product_ean": product_ean,
      "qty": qty,
      "validDate": validDate,
      "comment": comment,
    };
  }

  toJson() {
    return {
      "fridge_no": fridge_id,
      "product_ean": product_ean,
      "qty": qty,
      "validDate": validDate,
      "comment": comment,
    };
  }

  asEncodedString(String usersEncodingPassword) {
    return encryptAESCryptoJS(jsonEncode(this), usersEncodingPassword);
  }

  bool isEmpty() {
    return fridge_id == null || product_ean == null;
  }

  @override
  int compareTo(other) {
    DateTime thisDate = new DateFormat("yyyy-MM-dd").parse(this.validDate);
    DateTime otherDate = new DateFormat("yyyy-MM-dd").parse(other.validDate);
    // WasteNoneLogger().d(
    //     '${this.validDate}: ${thisDate.month}-${thisDate.day} compare to ${other.validDate}: ${otherDate.month}-${otherDate.day}');
    return thisDate.compareTo(otherDate);
  }

  DateTime getValidDateAsDate() {
    return new DateFormat("yyyy-MM-dd").parse(this.validDate);
  }

  @override
  bool operator ==(Object other) {
    return other is FridgeItem && this.product_ean == other.product_ean && this.validDate == other.validDate;
  }

  @override
  int get hashCode => this.product_ean.hashCode + this.validDate.hashCode;
}
