import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';

class Product {
  Product();

  // String puid;
  String eanCode;
  String name;
  String brand;
  String owner;
  String picLink =
      "https://image.shutterstock.com/z/stock-vector-avocado-green-flat-icon-on-white-background-434253583.jpg";
  String ingredients;
  String type;
  String size;

  Product.fromSnapshot(DataSnapshot snapshot)
      : eanCode = snapshot.value["eanCode"],
        name = snapshot.value["name"],
        brand = snapshot.value["brand"],
        owner = snapshot.value["owner"],
        picLink = snapshot.value["picLink"],
        ingredients = snapshot.value["ingredients"],
        type = snapshot.value["type"],
        size = snapshot.value["size"];

  Product.fromLinkedHashMap(LinkedHashMap<dynamic, dynamic> valueMap)
      : eanCode = valueMap["eanCode"],
        name = valueMap["name"],
        brand = valueMap["brand"],
        owner = valueMap["owner"],
        picLink = valueMap["picLink"],
        ingredients = valueMap["ingredients"],
        type = valueMap["type"],
        size = valueMap["size"];

  Product.fromMap(Map<String, dynamic> valueMap)
      : eanCode = valueMap["eanCode"],
        name = valueMap["name"],
        brand = valueMap["brand"],
        owner = valueMap["owner"],
        picLink = valueMap["picLink"],
        ingredients = valueMap["ingredients"],
        type = valueMap["type"],
        size = valueMap["size"];

  Map<String, dynamic> get map {
    return {
      "eanCode": eanCode,
      "name": name,
      "brand": brand,
      "owner": owner,
      "picLink": picLink,
      "ingredients": ingredients,
      "type": type,
      "size": size,
    };
  }

  toJson() {
    return {
      "eanCode": eanCode,
      "name": name,
      "brand": brand,
      "owner": owner,
      "picLink": picLink,
      "ingredients": ingredients,
      "type": type,
      "size": size,
    };
  }
}
