import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class Product {
  Product();

  String puid;
  String name;
  String brand;
  String owner;
  String picLink =
      "https://image.shutterstock.com/z/stock-vector-avocado-green-flat-icon-on-white-background-434253583.jpg";
  String description;
  String eanCode;
  String type;

  Product.fromSnapshot(DataSnapshot snapshot)
      : puid = snapshot.value["puid"],
        name = snapshot.value["name"],
        brand = snapshot.value["brand"],
        owner = snapshot.value["owner"],
        picLink = snapshot.value["picLink"],
        description = snapshot.value["description"],
        eanCode = snapshot.value["eanCode"],
        type = snapshot.value["type"];

  Product.fromMap(LinkedHashMap<dynamic, dynamic> valueMap)
      : puid = valueMap["puid"],
        name = valueMap["name"],
        brand = valueMap["brand"],
        owner = valueMap["owner"],
        picLink = valueMap["picLink"],
        description = valueMap["description"],
        eanCode = valueMap["eanCode"],
        type = valueMap["type"];

  Map<String, dynamic> get map {
    return {
      "puid": puid,
      "name": name,
      "brand": brand,
      "owner": owner,
      "picLink": picLink,
      "description": description,
      "eanCode": eanCode,
      "type": type,
    };
  }

  toJson() {
    return {
      "puid": puid,
      "name": name,
      "brand": brand,
      "owner": owner,
      "picLink": picLink,
      "description": description,
      "eanCode": eanCode,
      "type": type,
    };
  }
}
