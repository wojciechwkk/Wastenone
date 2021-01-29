import 'dart:collection';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';

class Fridge extends Comparable {
  Fridge(@required this.fridgeID, @required this.fridgeNo);

  String dbKey;
  String fridgeID;
  int fridgeNo;
  String displayName;
  String otherUsers;
  List<dynamic> sharedToIDs;

  Fridge.fromSnapshot(DataSnapshot snapshot)
      : dbKey = snapshot.key,
        fridgeID = snapshot.value["fridgeID"],
        fridgeNo = snapshot.value["fridgeNo"],
        displayName = snapshot.value["displayName"],
        otherUsers = snapshot.value["otherUsers"],
        sharedToIDs = snapshot.value["sharedToIDs"] != null ? snapshot.value["sharedToIDs"] : List<dynamic>();

  Fridge.fromMap(String key, LinkedHashMap<dynamic, dynamic> valueMap)
      : dbKey = key,
        fridgeID = valueMap["fridgeID"],
        fridgeNo = valueMap["fridgeNo"],
        displayName = valueMap["displayName"],
        otherUsers = valueMap["otherUsers"],
        sharedToIDs = valueMap["sharedToIDs"] != null ? valueMap["sharedToIDs"] : List<dynamic>();

  Map<String, dynamic> get map {
    return {
      "dbKey": dbKey,
      "fridgeID": fridgeID,
      "fridgeNo": fridgeNo,
      "displayName": displayName,
      "otherUsers": otherUsers,
      "sharedToIDs": sharedToIDs,
    };
  }

  toJson() {
    return {
      "dbKey": dbKey,
      "fridgeID": fridgeID,
      "fridgeNo": fridgeNo,
      "displayName": displayName,
      "otherUsers": otherUsers,
      "sharedToIDs": sharedToIDs,
    };
  }

  @override
  int compareTo(other) {
    if (this.displayName != null && other.displayName != null)
      return this.displayName.compareTo(other.displayName);
    else if (this.displayName != null && other.displayName == null)
      return -1;
    else if (this.displayName == null && other.displayName != null)
      return 1;
    else
      return this.fridgeNo.compareTo(other.fridgeNo);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is Fridge && this.fridgeID == other.fridgeID);
  }

  @override
  int get hashCode => fridgeID.hashCode;

  addSharedTo(String userUID) {
    if (sharedToIDs == null) {
      sharedToIDs = List<dynamic>();
      sharedToIDs.add(userUID);
    } else {
      var _newUserUID = new List<dynamic>(sharedToIDs.length + 1);
      int fridgeArrayIndex = 0;
      sharedToIDs.forEach((oldUsersUID) {
        _newUserUID[fridgeArrayIndex++] = oldUsersUID;
      });
      _newUserUID[fridgeArrayIndex] = userUID;
      sharedToIDs = _newUserUID;
    }
  }

  removeSharedTo(String userUID) {
    var newSharedToList = List<dynamic>();
    sharedToIDs.forEach((e) => print(e));
    sharedToIDs.forEach((sharedToUser) {
      if (sharedToUser != userUID) newSharedToList.add(sharedToUser);
    });
    sharedToIDs = newSharedToList;
  }

  List<dynamic> getSharedToIDs() {
    return sharedToIDs != null ? sharedToIDs : new List<dynamic>();
  }

  removeAllSharing() {
    sharedToIDs = new List<dynamic>();
  }
}
