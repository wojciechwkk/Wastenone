import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:waste_none_app/app/models/fridge.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/services/base_classes.dart';

class WNFirebaseDB implements DBBase {
  final _firebaseDB = FirebaseDatabase.instance;
// --------------------------------------- user --------------------------------

  Future<bool> userExists(WasteNoneUser user) async {
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

  Future createUser(WasteNoneUser user, String encodedUserData) async {
    print('create db user: ${user?.toJson()}');

    print("create user in wastenone db: ${user.displayName}");

    DatabaseReference dbNewUserRef = _firebaseDB
        .reference()
        .child("user") //user/${user.uid}
        .push();

    user.dbRef = dbNewUserRef.key;
    await dbNewUserRef.set({"uid": user.uid, "userData": encodedUserData});
  }

  /*
   * returns default fridge ID
   */
  Future<String> createDefaultFridge(String uuid) async {
    String defaultFridge = "$uuid-1";
    Fridge fridge = Fridge(defaultFridge, 1);
    await this.addFridge(fridge);
    return fridge.fridgeID;
  }

  updateUser(WasteNoneUser user, String encodedUserData) async {
    print('update user ${user.toJson()}');
    DatabaseReference dbUserRef =
        _firebaseDB.reference().child("user").child(user.dbRef);
    await dbUserRef.set({"uid": user.uid, "userData": encodedUserData});
  }

  deleteUser(WasteNoneUser user) async {
    print('delete user ${user?.toJson()}');
    if (user != null) {
      user?.getFridgeIDs()?.forEach((fridgeId) => deleteFridge(fridgeId));
      _firebaseDB.reference().child("user").child('${user.dbRef}').remove();
    }
  }

  Future<String> getUserData(String uid) async {
    print('fetch user $uid');
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("user")
        .orderByChild('uid')
        .equalTo(uid)
        .once();

    if (snapshot != null && snapshot.value != null) {
      var usersMap = Map<String, dynamic>.from(snapshot.value);
      String dbKey = usersMap.keys.elementAt(0);
      Map<dynamic, dynamic> values = usersMap.values.elementAt(0);
      String uid = values["uid"];
      return values["userData"];
      // Map<dynamic, dynamic> userData = values["userData"];
      // print('data: ${uid}, $userData');
      // WasteNoneUser fullUser = WasteNoneUser.fromMap(dbKey, userData);
      // return fullUser;

    }
    return null;
  }

  Future<List<Fridge>> getUsersFridges(WasteNoneUser user) async {
    print("get users fridges: ${user.displayName}");
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("fridge")
        .orderByKey()
        .startAt(user.uid)
        .once();

    if (snapshot != null && snapshot.value != null) {
      var fridgeMap = Map<String, dynamic>.from(snapshot.value);

      var fridgeResult = List<Fridge>();
      for (var fridgeKey in fridgeMap.keys) {
        var fridge = Map<String, dynamic>.from(fridgeMap[fridgeKey]);
        for (var subFridgeKey in fridge.keys) {
          fridgeResult.add(Fridge.fromMap(subFridgeKey, fridge[subFridgeKey]));
        }
      }
//      fridgeResult.sort();
      return fridgeResult;
    }
    return null;
  }

// --------------------------------------- /user -------------------------------
// --------------------------------------- product -----------------------------

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

  void addProduct(Product product) {
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

// --------------------------------------- /product ----------------------------
// --------------------------------------- fridge ------------------------------

  Future<void> addFridge(Fridge fridge) async {
    print("add fridge: ${fridge.fridgeID}");
    await _firebaseDB
        .reference()
        .child("fridge/${fridge.fridgeID}")
        .push()
        .set(fridge.toJson());
  }

  Future<void> updateFridge(Fridge fridge) async {
    await _firebaseDB
        .reference()
        .child("fridge/${fridge.fridgeID}/")
        .child(fridge.dbKey)
        .set(fridge.toJson());
  }

  @deprecated
  addToFridge(FridgeItem fridgeItem, String uid) async {
    print("add item to fridge: ${fridgeItem.fridge_no}");
    _firebaseDB
        .reference()
        .child("fridge-contents/${fridgeItem.fridge_no}")
        .push()
        .set(fridgeItem.toJson());
  }

  addToFridgeEncrypted(String encryptedFridgeItem, String fridgeNo) async {
    print("add encrypted item to fridge: $fridgeNo");
    _firebaseDB
        .reference()
        .child("fridge-contents/$fridgeNo")
        .push()
        .set(encryptedFridgeItem);
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

  @deprecated
  Future<List<FridgeItem>> getFridgeContent(String fridgeID, String uid) async {
    print("get fridge content for: $fridgeID");
    DataSnapshot snapshot = await _firebaseDB
        .reference()
        .child("fridge-contents/$fridgeID")
        .orderByChild('validDate')
        .once();
    if (snapshot != null && snapshot.value != null) {
      var fridgeItemsMap = Map<String, dynamic>.from(snapshot.value);
      var fridgeItemsResult = List<FridgeItem>();
      for (var fridgeItemKey in fridgeItemsMap.keys) {
        fridgeItemsResult.add(
            FridgeItem.fromMap(fridgeItemKey, fridgeItemsMap[fridgeItemKey]));
      }
      return fridgeItemsResult;
    }
    return null;
  }

  @deprecated
  updateFridgeItem(FridgeItem fridgeItem) async {
    await _firebaseDB
        .reference()
        .child("fridge-contents/${fridgeItem.fridge_no}/")
        .child(fridgeItem.dbKey)
        .set(fridgeItem.toJson());
  }

  updateEncryptedFridgeItem(
      String fridgeNo, String itemKey, String encryptedFridgeItem) async {
    await _firebaseDB
        .reference()
        .child("fridge-contents/$fridgeNo/")
        .child(itemKey)
        .set(encryptedFridgeItem);
  }

  @deprecated
  deleteFridgeItem(FridgeItem fridgeItem) async {
    print('delete fridge item ${fridgeItem?.toJson()}');
    if (fridgeItem != null) {
      await _firebaseDB
          .reference()
          .child("fridge-contents/${fridgeItem.fridge_no}/")
          .child(fridgeItem.dbKey)
          .remove();
    }
  }

  deleteEncryptedFridgeItem(String fridgeNo, String itemKey) async {
    await _firebaseDB
        .reference()
        .child("fridge-contents/$fridgeNo/")
        .child(itemKey)
        .remove();
  }

  Future<Map<String, String>> getFridgeEncryptedContent(
      String fridgeID, String uid) async {
    print("get encrypted fridge content for: $fridgeID");
    DataSnapshot snapshot =
        await _firebaseDB.reference().child("fridge-contents/$fridgeID").once();

    if (snapshot != null && snapshot.value != null) {
      var fridgeItemsMap = Map<String, dynamic>.from(snapshot.value);

      var fridgeItemsResult = new Map<String, String>();
      for (String fridgeItemKey in fridgeItemsMap.keys) {
        String encryptedFridgeItem = fridgeItemsMap[fridgeItemKey];
        fridgeItemsResult[fridgeItemKey] = encryptedFridgeItem;
      }
      return fridgeItemsResult;
    }
    print('get encrypted fridge got null');
    return null;
  }

  void removeFridge(String fridgeNo) async {
    print("remove fridge: $fridgeNo");
    _firebaseDB.reference().child("fridge-contents/$fridgeNo").remove();
  }

  emptyFridge(String fridgeId) {
    print('empty fridge $fridgeId');
    _firebaseDB.reference().child("fridge-contents/$fridgeId").remove();
  }

  deleteFridge(String fridgeId) {
    print('delete fridge $fridgeId');
    emptyFridge(fridgeId);
    _firebaseDB.reference().child("fridge/$fridgeId").remove();
  }

// --------------------------------------- /fridge -----------------------------
}
