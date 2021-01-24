import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/services/secure_storage.dart';

enum TimeFormatEnum { ampm, a24h }
enum SystemOfUnits { metric, imperial }
enum SettingsKeysEnum { TIME_FORMAT, AM_PM, NOTIFY_EXPIRY_DAYS, NOTIFY_EXPIRY_HRS, NOTIFY_EXPIRY_MIN, UNIT_SYSTEM }

String getSettingsKey(SettingsKeysEnum settingsKeyEnum, String userUid) {
  switch (settingsKeyEnum) {
    case SettingsKeysEnum.TIME_FORMAT:
      return '$userUid-24hrs-format';
      break;
    case SettingsKeysEnum.AM_PM:
      return '$userUid-am-pm';
      break;
    case SettingsKeysEnum.NOTIFY_EXPIRY_DAYS:
      return '$userUid-expiry-notify-days';
      break;
    case SettingsKeysEnum.NOTIFY_EXPIRY_HRS:
      return '$userUid-expiry-notify-hours';
      break;
    case SettingsKeysEnum.NOTIFY_EXPIRY_MIN:
      return '$userUid-expiry-notify-minutes';
      break;
    case SettingsKeysEnum.UNIT_SYSTEM:
      return '$userUid-unit-system';
      break;
    default:
      return '';
  }
}

Future<String> getLocalCachePath() async {
  Directory dir = await getApplicationDocumentsDirectory();
  await dir.create(recursive: true);
  String dbPath = join(dir.path, 'localCache.db');
  return dbPath;
}

Future<TimeOfDay> getNotificationTime(WasteNoneUser user) async {
  String notificationTime = await getUsersPushNotificationTime(user);
  int hour = notificationTime != null ? int.parse(notificationTime) : 9;
  return TimeOfDay(hour: hour, minute: 0);
}
