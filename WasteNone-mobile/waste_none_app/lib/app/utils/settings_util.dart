import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';

enum TimeFormatEnum { ampm, a24h }

Future<bool> isUsersTimeFormat24hs(
    WasteNoneUser user, BuildContext context) async {
  String timeFormatStored = await getUsersStoredTimeFormat(user);
  if (timeFormatStored != null)
    return timeFormatStored == TimeFormatEnum.a24h.toString();
  else
    return MediaQuery.of(context).alwaysUse24HourFormat;
}

Future<TimeOfDay> getNotificationTime(WasteNoneUser user) async {
  String notificationTime = await getUsersPushNotificationTime(user);
  int hour = notificationTime != null ? int.parse(notificationTime) : 9;
  return TimeOfDay(hour: hour, minute: 0);
}
