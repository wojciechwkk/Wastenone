import 'package:firebase_database/firebase_database.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';

class WNFirebaseDB {
  var _firebaseDB = FirebaseDatabase.instance;

  void getAllProducts() {
    print("get all products");
    Query _todoQuery = _firebaseDB.reference().child("products");
  }

  Future<bool> isInProductsWNDB(String eanCode) async {
    print("check if product with EAN: ${eanCode} is in the WNDB");
    Product product = await getProductByEanCode(eanCode);
    return product != null;
  }

  Future<Product> getProductByEanCode(String eanCode) async {
    print("get product by EAN: $eanCode");
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("products")
        .orderByChild('eanCode')
        .equalTo(eanCode)
        .once();
    if (snapshot != null && snapshot.value != null) {
      var productMap = Map<String, dynamic>.from(snapshot.value);
      return Product.fromMap(productMap.values.elementAt(0));
    }
    return null;
  }

  Future<Product> getProductByPUID(String puid) async {
    print("get product by PUID: ${puid}");
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("products")
        .orderByChild('puid')
        .equalTo(puid)
        .once();
    if (snapshot != null && snapshot.value != null) {
      var productMap = Map<String, dynamic>.from(snapshot.value);
//    print("getProductWNDB: ${productMap.values.elementAt(0).runtimeType}");
      return Product.fromMap(productMap.values.elementAt(0));
    }
    return null;
  }

  Future<DataSnapshot> getProductsSnapshot(String eanCode) async {
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("products")
        .orderByChild('eanCode')
        .equalTo(eanCode)
        .once();
    return snapshot;
  }

  void addToProductsWNDB(Product product) {
    print("add product: ${product.name}");
    _firebaseDB.reference().child("products").push().set(product?.toJson());
  }

  void addToFridge(FridgeItem fridgeItem) {
    print("add item to fridge: ${fridgeItem.fridge_no}");
    _firebaseDB
        .reference()
        .child("fridges/${fridgeItem.fridge_no}")
        .push()
        .set(fridgeItem.toJson());
  }

  void removeFridge(String fridgeNo) async {
    print("remove fridge: $fridgeNo");
    _firebaseDB.reference().child("fridges/$fridgeNo").remove();
  }

  Future<List<FridgeItem>> getFridgeContent(String fridgeNo) async {
    print("get fridge content for: $fridgeNo");
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("fridges/$fridgeNo")
        .orderByChild('validDate')
        .once();
    if (snapshot != null && snapshot.value != null) {
      var fridgeItemsMap = Map<String, dynamic>.from(snapshot.value);
      return fridgeItemsMap.values
          .map((value) => FridgeItem.fromMap(value))
          .toList();
    }
    return null;
  }
}
