import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_github_api/flutter_github_api.dart';
import 'package:waste_none_app/app/models/fridge.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/services/auth.dart';

class WNFirebaseDB {
  var _firebaseDB = FirebaseDatabase.instance;

  createUser(WasteNoneUser user) async {
    if (await _userExists(user))
      return;
    else {
      String defaultFridge = "${user.uid}-1";
      Fridge fridge = Fridge(defaultFridge, 1);
//      user.fridgeIDList.add(defaultFridge);
      print("create user in wastenone db: ${user.displayName}");

      DatabaseReference dbNewUserRef = _firebaseDB
          .reference()
          .child("user") //user/${user.uid}
          .push();
      print('dbRef: ${dbNewUserRef.key}');
      user.dbRef = dbNewUserRef.key;
      await dbNewUserRef.set(user?.toJson());
      this.addFridge(user, fridge);
    }
  }

  updateUser(WasteNoneUser user) async {
    print('update user ${user.toJson()}');
    DatabaseReference dbUserRef =
        _firebaseDB.reference().child("user").child(user.dbRef);
    dbUserRef.set(user.toJson());
  }

  deleteUser(WasteNoneUser user) async {
    print('delete user ${user?.toJson()}');
    if (user != null) {
      DataSnapshot snapshot = await _firebaseDB
          .reference()
          .child("user")
          .orderByChild('uid')
          .equalTo(user.uid)
          .once();

      if (snapshot != null && snapshot.value != null) {
        var usersMap = Map<String, dynamic>.from(snapshot.value);
        WasteNoneUser fullUser = WasteNoneUser.fromMap(
            usersMap.keys.elementAt(0), usersMap.values.elementAt(0));
        fullUser
            ?.getFridgeIDs()
            ?.forEach((fridgeId) => deleteFridgeWhileDeletingUser(fridgeId));
        _firebaseDB
            .reference()
            .child("user")
            .child('${fullUser.dbRef}')
            .remove();
      }
    }
  }

  Future<WasteNoneUser> getUserData(String uid) async {
    print('fetch user $uid');
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("user")
        .orderByChild('uid')
        .equalTo(uid)
        .once();

    if (snapshot != null && snapshot.value != null) {
      var usersMap = Map<String, dynamic>.from(snapshot.value);
      WasteNoneUser fullUser = WasteNoneUser.fromMap(
          usersMap.keys.elementAt(0), usersMap.values.elementAt(0));
      return fullUser;
    }
    return null;
  }

  deleteFridge(WasteNoneUser user, String fridgeId) {
//    var fridgeId = '${user.uid}-${fridgeNo}';
    print('delete fridge $fridgeId');
    emptyFridge(fridgeId);
    _firebaseDB.reference().child("fridge/$fridgeId").remove();
    user.removeFridgeID(fridgeId);
    this.updateUser(user);
  }

  deleteFridgeWhileDeletingUser(String fridgeId) {
    print('delete fridge $fridgeId');
    emptyFridge(fridgeId);
    _firebaseDB.reference().child("fridge/$fridgeId").remove();
  }

  emptyFridge(String fridgeId) {
    print('empty fridge $fridgeId');
    _firebaseDB.reference().child("fridge-contents/$fridgeId").remove();
  }

  Future<bool> _userExists(WasteNoneUser user) async {
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("user")
        .orderByChild('uid')
        .equalTo(user.uid)
        .once();
    if (snapshot != null && snapshot.value != null) {
      var productMap = Map<String, dynamic>.from(snapshot.value);
      return productMap.values.elementAt(0) != null;
    }
    return false;
  }

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
        .child("product")
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
        .child("product")
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

  void addToProductsWNDB(Product product) {
    print("add product: ${product.name}");
    _firebaseDB.reference().child("product").push().set(product?.toJson());
  }

  Future<DataSnapshot> getProductsSnapshot(String eanCode) async {
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("product")
        .orderByChild('eanCode')
        .equalTo(eanCode)
        .once();
    return snapshot;
  }

  updateFridgeItemQty(FridgeItem fridgeItem) async {
    await _firebaseDB
        .reference()
        .child("fridge-contents/${fridgeItem.fridge_no}/")
        .child(fridgeItem.dbKey)
        .set(fridgeItem.toJson());
  }

  updateFridgeItemDate(String puid, String date) {}

  Future<void> addFridge(WasteNoneUser user, Fridge fridge) async {
    print("add fridge: ${fridge.fridgeID}");
    await _firebaseDB
        .reference()
        .child("fridge/${fridge.fridgeID}")
        .push()
        .set(fridge.toJson());
//    if (user.fridgeIDs == null) user.fridgeIDs = List<String>();
    user.addFridgeID(fridge.fridgeID);
    await updateUser(user);
  }

  Future<void> updateFridge(Fridge fridge) async {
    await _firebaseDB
        .reference()
        .child("fridge/${fridge.fridgeID}/")
        .child(fridge.dbKey)
        .set(fridge.toJson());
  }

  addToFridge(FridgeItem fridgeItem) {
    print("add item to fridge: ${fridgeItem.fridge_no}");
    _firebaseDB
        .reference()
        .child("fridge-contents/${fridgeItem.fridge_no}")
        .push()
        .set(fridgeItem.toJson());
  }

  Future<Fridge> getFridge(String fridgeID) async {
    print("get fridge: $fridgeID");
    DataSnapshot snapshot =
        await _firebaseDB.reference().child("fridge/$fridgeID").once();
    if (snapshot != null && snapshot.value != null) {
      var fridgeMap = Map<String, dynamic>.from(snapshot.value);
      var fridgeResult = List<Fridge>();
      for (var fridgeKey in fridgeMap.keys) {
        fridgeResult.add(Fridge.fromMap(fridgeKey, fridgeMap[fridgeKey]));
      }
      return fridgeResult[0];
    }
    return null;
  }

  Future<List<FridgeItem>> getFridgeContent(String fridgeID) async {
    print("get fridge content for: $fridgeID");
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("fridge-contents/$fridgeID")
        .orderByChild('validDate')
        .once();
    if (snapshot != null && snapshot.value != null) {
      var fridgeItemsMap = Map<String, dynamic>.from(snapshot.value);
//      return fridgeItemsMap.values
//          .map((value) => FridgeItem.fromMap(value))
//          .toList();
      var fridgeItemsResult = List<FridgeItem>();
      for (var fridgeItemKey in fridgeItemsMap.keys) {
        fridgeItemsResult.add(
            FridgeItem.fromMap(fridgeItemKey, fridgeItemsMap[fridgeItemKey]));
      }
      return fridgeItemsResult;
    }
    return null;
  }

  void removeFridge(String fridgeNo) async {
    print("remove fridge: $fridgeNo");
    _firebaseDB.reference().child("fridge-contents/$fridgeNo").remove();
  }
}
