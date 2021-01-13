import 'dart:collection';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:waste_none_app/app/utils/cryptography_util.dart';

import 'fridge.dart';

class ShareFridgeInvite {
  ShareFridgeInvite(this.senderUID, this.receiverUID, this.fridgeID);

  String inviteDBRef;
  String senderUID;
  String receiverUID;
  String fridgeID;

  ShareFridgeInvite.fromSnapshot(DataSnapshot snapshot)
      : inviteDBRef = snapshot.key,
        senderUID = snapshot.value["senderUID"],
        receiverUID = snapshot.value["receiverUID"],
        fridgeID = snapshot.value["fridgeID"];

  ShareFridgeInvite.fromMap(String key, LinkedHashMap<dynamic, dynamic> valueMap)
      : inviteDBRef = key,
        senderUID = valueMap["senderUID"],
        receiverUID = valueMap["receiverUID"],
        fridgeID = valueMap["fridgeID"];

  Map<String, dynamic> get map {
    return {
      "inviteDBRef": inviteDBRef,
      "senderUID": senderUID,
      "receiverUID": receiverUID,
      "fridgeID": fridgeID,
    };
  }

  toJson() {
    return {
      "inviteDBRef": inviteDBRef,
      "senderUID": senderUID,
      "receiverUID": receiverUID,
      "fridgeID": fridgeID,
    };
  }
}
