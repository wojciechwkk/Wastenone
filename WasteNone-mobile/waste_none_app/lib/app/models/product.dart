import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';

class Product {
  Product();

  String puid;
  String name;
  String brand;
  String owner;
  String picLink =
      "https://image.shutterstock.com/z/stock-vector-avocado-green-flat-icon-on-white-background-434253583.jpg";
  String ingredients;
  String eanCode;
  String type;
  String size;

  Product.fromSnapshot(DataSnapshot snapshot)
      : puid = snapshot.value["puid"],
        name = snapshot.value["name"],
        brand = snapshot.value["brand"],
        owner = snapshot.value["owner"],
        picLink = snapshot.value["picLink"],
        ingredients = snapshot.value["ingredients"],
        eanCode = snapshot.value["eanCode"],
        type = snapshot.value["type"],
        size = snapshot.value["size"];

  Product.fromMap(LinkedHashMap<dynamic, dynamic> valueMap)
      : puid = valueMap["puid"],
        name = valueMap["name"],
        brand = valueMap["brand"],
        owner = valueMap["owner"],
        picLink = valueMap["picLink"],
        ingredients = valueMap["ingredients"],
        eanCode = valueMap["eanCode"],
        type = valueMap["type"],
        size = valueMap["size"];

  Map<String, dynamic> get map {
    return {
      "puid": puid,
      "name": name,
      "brand": brand,
      "owner": owner,
      "picLink": picLink,
      "ingredients": ingredients,
      "eanCode": eanCode,
      "type": type,
      "size": size,
    };
  }

  toJson() {
    return {
      "puid": puid,
      "name": name,
      "brand": brand,
      "owner": owner,
      "picLink": picLink,
      "ingredients": ingredients,
      "eanCode": eanCode,
      "type": type,
      "size": size,
    };
  }
}
