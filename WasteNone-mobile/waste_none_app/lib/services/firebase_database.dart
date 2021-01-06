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
    DataSnapshot snapshot = await _firebaseDB.reference().child("user").orderByChild('uid').equalTo(user.uid).once();
    if (snapshot != null && snapshot.value != null) {
      var productMap = Map<String, dynamic>.from(snapshot.value);
      return productMap.values.elementAt(0) != null;
    }
    return false;
  }

  Future createUser(WasteNoneUser user) async {
    print("db: creating user in wastenone db: ${user.displayName}");

    DatabaseReference dbNewUserRef = _firebaseDB
        .reference()
        .child("user") //user/${user.uid}
        .push();

    user.dbRef = dbNewUserRef.key;
    await dbNewUserRef.set(user.toJson());
  }
  // Future createUserEncrypted(WasteNoneUser user, String encodedUserData) async {
  //   print("db: creating user in wastenone db: ${user.displayName} - encrypted");
  //
  //   DatabaseReference dbNewUserRef = _firebaseDB
  //       .reference()
  //       .child("user") //user/${user.uid}
  //       .push();
  //
  //   user.dbRef = dbNewUserRef.key;
  //   await dbNewUserRef.set({"uid": user.uid, "userData": encodedUserData});
  // }

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
    print('db: updating user ${user.toJson()}');
    if (user.dbRef != null) {
      DatabaseReference dbUserRef = _firebaseDB.reference().child("user").child(user.dbRef);
      await dbUserRef.set(user.toJson());
    }
  }
  // updateUserEncrypted(WasteNoneUser user, String encodedUserData) async {
  //   print('db: updating user ${user.toJson()}');
  //   if (user.dbRef != null) {
  //     DatabaseReference dbUserRef = _firebaseDB.reference().child("user").child(user.dbRef);
  //     await dbUserRef.set({"uid": user.uid, "userData": encodedUserData});
  //   }
  // }

  deleteUser(WasteNoneUser user) async {
    print('db: deleting user ${user?.toJson()}');
    if (user != null) {
      user?.getFridgeIDs()?.forEach((fridgeId) => deleteFridge(fridgeId));
      if (user.dbRef != null) {
        _firebaseDB.reference().child("user").child('${user.dbRef}').remove();
      }
    }
  }
  // deleteUserEncrypted(WasteNoneUser user) async {
  //   print('db: deleting user ${user?.toJson()}');
  //   if (user != null) {
  //     user?.getFridgeIDs()?.forEach((fridgeId) => deleteFridge(fridgeId));
  //     if (user.dbRef != null) {
  //       _firebaseDB.reference().child("user").child('${user.dbRef}').remove();
  //     }
  //   }
  // }

  /*
   returns:
   - dbKey
   - userData encrypted with user pass phrase
   */
  // Future<Map<dynamic, dynamic>> getUserData(String uid) async {
  Future<WasteNoneUser> getUserData(String uid) async {
    print('db: fetching user $uid');
    DataSnapshot snapshot = await _firebaseDB.reference().child("user").orderByChild('uid').equalTo(uid).once();

    if (snapshot != null && snapshot.value != null) {
      var usersMap = Map<String, dynamic>.from(snapshot.value);
      WasteNoneUser fullUser = WasteNoneUser.fromMap(usersMap.keys.elementAt(0), usersMap.values.elementAt(0));
      return fullUser;
      // String dbKey = usersMap.keys.elementAt(0);
      // Map<dynamic, dynamic> values = usersMap.values.elementAt(0);
      // values["dbKey"] = dbKey;
      // return values;
    }
    return null;
  }

  Future<List<Fridge>> getUsersFridges(WasteNoneUser user) async {
    print("db: getting users fridges: ${user.displayName}, uid: ${user.uid}");
    DataSnapshot snapshot = await _firebaseDB.reference().child("fridge").orderByKey().startAt(user.uid).once();

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
    print("db: getting all products");
    Query _todoQuery = _firebaseDB.reference().child("products");
  }

  Future<bool> isInProductsWNDB(String eanCode) async {
    print("db: checking if product with EAN: ${eanCode} is in the WNDB");
    Product product = await getProductByEanCode(eanCode);
    return product != null;
  }

  Future<Product> getProductByEanCode(String eanCode) async {
    // print("get product by EAN: $eanCode");
    DataSnapshot snapshot =
        await _firebaseDB.reference().child("product").orderByChild('eanCode').equalTo(eanCode).once();
    if (snapshot != null && snapshot.value != null) {
      var productMap = Map<String, dynamic>.from(snapshot.value);
      return Product.fromLinkedHashMap(productMap.values.elementAt(0));
    }
    return null;
  }

  Future<Product> getProductByPUID(String puid) async {
    // print("get product by PUID: ${puid}");
    DataSnapshot snapshot = await _firebaseDB.reference().child("product").orderByChild('puid').equalTo(puid).once();
    if (snapshot != null && snapshot.value != null) {
      var productMap = Map<String, dynamic>.from(snapshot.value);
//    print("getProductWNDB: ${productMap.values.elementAt(0).runtimeType}");
      return Product.fromLinkedHashMap(productMap.values.elementAt(0));
    }
    return null;
  }

  void addProduct(Product product) {
    print("db: adding product: ${product.name}");
    _firebaseDB.reference().child("product").push().set(product?.toJson());
  }

  Future<DataSnapshot> getProductsSnapshot(String eanCode) async {
    DataSnapshot snapshot =
        await _firebaseDB.reference().child("product").orderByChild('eanCode').equalTo(eanCode).once();
    return snapshot;
  }

// --------------------------------------- /product ----------------------------
// --------------------------------------- fridge ------------------------------

  Future<void> addFridge(Fridge fridge) async {
    print("db: adding fridge: ${fridge.fridgeID}");

    DatabaseReference dbNewFridgeRef = _firebaseDB
        .reference()
        .child("fridge/${fridge.fridgeID}") //user/${user.uid}
        .push();

    fridge.dbKey = dbNewFridgeRef.key;
    await dbNewFridgeRef.set({"fridgeID": fridge.fridgeID, "fridgeNo": fridge.fridgeNo});
  }

  Future<void> updateFridge(Fridge fridge) async {
    print('db: updating fridge id: ${fridge.fridgeID}, dbkey ${fridge.dbKey}');
    await _firebaseDB.reference().child("fridge/${fridge.fridgeID}/").child(fridge.dbKey).set(fridge.toJson());
  }

  addToFridge(FridgeItem fridgeItem, String uid) async {
    print("db: adding item to fridge: ${fridgeItem.fridge_id}");
    _firebaseDB.reference().child("fridge-contents/${fridgeItem.fridge_id}").push().set(fridgeItem.toJson());
  }

  // @deprecated
  // Future<String> addToFridgeEncrypted(String encryptedFridgeItem, String fridgeNo) async {
  //   print("add encrypted item to fridge: $fridgeNo");
  //   DatabaseReference dbRef = _firebaseDB.reference().child("fridge-contents/$fridgeNo").push();
  //   dbRef.set(encryptedFridgeItem);
  //   return dbRef.key;
  // }

  Future<Fridge> getFridge(String fridgeID) async {
    // print("get fridge: $fridgeID");
    DataSnapshot snapshot = await _firebaseDB.reference().child("fridge/$fridgeID").once();
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

  Future<List<FridgeItem>> getFridgeContent(String fridgeID, String uid) async {
    print("db: getting fridge content for: $fridgeID");
    DataSnapshot snapshot =
        await _firebaseDB.reference().child("fridge-contents/$fridgeID").orderByChild('validDate').once();
    if (snapshot != null && snapshot.value != null) {
      var fridgeItemsMap = Map<String, dynamic>.from(snapshot.value);
      var fridgeItemsResult = List<FridgeItem>();
      for (var fridgeItemKey in fridgeItemsMap.keys) {
        fridgeItemsResult.add(FridgeItem.fromMap(fridgeItemKey, fridgeItemsMap[fridgeItemKey]));
      }
      fridgeItemsResult.sort();
      return fridgeItemsResult;
    }
    return new List<FridgeItem>();
  }

  updateFridgeItem(FridgeItem fridgeItem) async {
    await _firebaseDB
        .reference()
        .child("fridge-contents/${fridgeItem.fridge_id}/")
        .child(fridgeItem.dbKey)
        .set(fridgeItem.toJson());
  }

  // @deprecated
  // updateEncryptedFridgeItem(String fridgeNo, String itemKey, String encryptedFridgeItem) async {
  //   await _firebaseDB.reference().child("fridge-contents/$fridgeNo/").child(itemKey).set(encryptedFridgeItem);
  // }

  deleteFridgeItem(FridgeItem fridgeItem) async {
    print('db: deleting fridge item ${fridgeItem?.toJson()}');
    if (fridgeItem != null) {
      await _firebaseDB.reference().child("fridge-contents/${fridgeItem.fridge_id}/").child(fridgeItem.dbKey).remove();
    }
  }

  // @deprecated
  // deleteEncryptedFridgeItem(String fridgeNo, String itemKey) async {
  //   await _firebaseDB.reference().child("fridge-contents/$fridgeNo/").child(itemKey).remove();
  // }

  // @deprecated
  // Future<Map<String, String>> getFridgeEncryptedContent(String fridgeID, String uid) async {
  //   print("db: getting encrypted fridge content for: $fridgeID");
  //   DataSnapshot snapshot = await _firebaseDB.reference().child("fridge-contents/$fridgeID").once();
  //
  //   if (snapshot != null && snapshot.value != null) {
  //     var fridgeItemsMap = Map<String, dynamic>.from(snapshot.value);
  //
  //     var fridgeItemsResult = new Map<String, String>();
  //     for (String fridgeItemKey in fridgeItemsMap.keys) {
  //       String encryptedFridgeItem = fridgeItemsMap[fridgeItemKey];
  //       fridgeItemsResult[fridgeItemKey] = encryptedFridgeItem;
  //     }
  //     return fridgeItemsResult;
  //   }
  //   // print('get encrypted fridge got null');
  //   return null;
  // }

  void removeFridge(String fridgeNo) async {
    print("db: removing fridge: $fridgeNo");
    _firebaseDB.reference().child("fridge-contents/$fridgeNo").remove();
  }

  emptyFridge(String fridgeId) {
    print('db: emptying fridge $fridgeId');
    _firebaseDB.reference().child("fridge-contents/$fridgeId").remove();
  }

  deleteFridge(String fridgeId) {
    print('db: deleting fridge $fridgeId');
    emptyFridge(fridgeId);
    _firebaseDB.reference().child("fridge/$fridgeId").remove();
  }

// --------------------------------------- /fridge -----------------------------
}
