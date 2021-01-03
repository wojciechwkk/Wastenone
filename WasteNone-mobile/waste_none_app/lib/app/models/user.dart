import 'dart:collection';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:waste_none_app/app/utils/cryptography_util.dart';

import 'fridge.dart';

class WasteNoneUser {
  WasteNoneUser(this.uid, this.displayName);

  String uid;
  String dbRef;
  String displayName;
  List<dynamic> _fridgeIDs;
  // int fridgesCount;

  WasteNoneUser.fromSnapshot(DataSnapshot snapshot)
      : dbRef = snapshot.key,
        uid = snapshot.value["uid"],
        displayName = snapshot.value["displayName"],
        _fridgeIDs = snapshot.value["fridgeIDs"] != null ? snapshot.value["fridgeIDs"] : List<dynamic>()
  // ,
  // fridgesCount = snapshot.value["fridgesAdded"]
  ;

  WasteNoneUser.fromMap(String key, LinkedHashMap<dynamic, dynamic> valueMap)
      : dbRef = key,
        uid = valueMap["uid"],
        displayName = valueMap["displayName"],
        _fridgeIDs = valueMap["fridgeIDs"] != null ? valueMap["fridgeIDs"] : List<dynamic>()
  // ,
  // fridgesCount = valueMap["fridgesAdded"]
  ;

  Map<String, dynamic> get map {
    return {
      "dbRef": "dbRef",
      "uid": uid,
      "displayName": displayName,
      "fridgeIDs": _fridgeIDs,
      // "fridgesAdded": fridgesCount,
    };
  }

  toJson() {
    return {
      "uid": uid,
      "dbRef": dbRef,
      "displayName": displayName,
      "fridgeIDs": _fridgeIDs,
      // "fridgesAdded": fridgesCount,
    };
  }

  addFridgeID(String fridgeID) {
    if (_fridgeIDs == null) {
      _fridgeIDs = List<dynamic>();
      _fridgeIDs.add(fridgeID);
      // fridgesCount = 1;
    } else {
      var newFridgeIDs = new List<dynamic>(_fridgeIDs.length + 1);
      int fridgeArrayIndex = 0;
      _fridgeIDs.forEach((fridgeId) {
        newFridgeIDs[fridgeArrayIndex++] = fridgeId;
      });
      newFridgeIDs[fridgeArrayIndex] = fridgeID;
      newFridgeIDs.sort();
      _fridgeIDs = newFridgeIDs;
      // fridgesCount++;
    }
  }

  removeFridgeID(String fridgeID) {
    var newFridgeList = List<dynamic>();
    _fridgeIDs.forEach((element) {
      if (element != fridgeID) newFridgeList.add(element);
    });
    newFridgeList.sort();
    _fridgeIDs = newFridgeList;
  }

  List<dynamic> getFridgeIDs() {
    return _fridgeIDs;
  }

  void sortFridgeList() {
    _fridgeIDs.sort();
  }

  isAnonymous() {
    return this.displayName == 'anonymous';
  }

  asEncodedString(String usersEncodingPassword) {
    return encryptAESCryptoJS(jsonEncode(this), usersEncodingPassword);
  }
}
