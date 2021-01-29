import 'package:date_util/date_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logger/logger.dart';
import 'package:waste_none_app/app/fridge_page.dart';
import 'package:waste_none_app/app/models/fridge.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/settings_window.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';

import 'base_classes.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class FlutterNotification implements NotificationBase {
  static final FlutterNotification _instance = FlutterNotification._internal();

  factory FlutterNotification() {
    return _instance;
  }
  FlutterNotification._internal();

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('wastenone_icon');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(onDidReceiveLocalNotification: null);
    final MacOSInitializationSettings initializationSettingsMacOS = MacOSInitializationSettings();
    final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS, macOS: initializationSettingsMacOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: selectNotification);
  }

  Future selectNotification(String payload) async {
    if (payload != null) {
      //debugWasteNoneLogger().d('notification payload: $payload');
    }
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute<void>(
    //       builder: (context) => FridgePage(
    //
    //           )),
    // );
  }

  showItemAddedNotification(Fridge fridge, Product product, FridgeItem fridgeItem) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        '0', 'item_add', 'channel user for for notifications  on item adding',
        importance: Importance.max, priority: Priority.high, showWhen: false);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    String fridgeName = fridge.displayName != null ? fridge.displayName : fridge.fridgeNo.toString();
    await flutterLocalNotificationsPlugin.show(
        0, 'Added new product to your fridge "$fridgeName"', product.name, platformChannelSpecifics,
        payload: fridgeItem.fuid);
  }

  Future<void> addExpiryNotification(WasteNoneUser user, Product product, FridgeItem fridgeItem) async {
    DateTime itemExpiryDate = fridgeItem.getValidDateAsDate();
    DateTime notifyAtDate = _calcScheduledDate(user, itemExpiryDate);
    List<PendingNotificationRequest> existingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    bool foundNotificationOnThisDate = false;
    for (PendingNotificationRequest pendingNotification in existingNotifications) {
      if (pendingNotification.id == _presentDateAsInt(itemExpiryDate)) {
        await flutterLocalNotificationsPlugin.cancel(pendingNotification.id);
        String newNotificationBody = '''
${pendingNotification.body} 
${product.name}''';
        int payload = int.parse(pendingNotification.payload);
        scheduleExpiryNotification(newNotificationBody, itemExpiryDate, notifyAtDate, (++payload).toString());
        foundNotificationOnThisDate = true;
      }
    }
    if (!foundNotificationOnThisDate) {
      if (notifyBeforeNow(notifyAtDate)) {
        // add scheduledDate to the first scheduled notif
      } else {
        scheduleExpiryNotification(product.name, itemExpiryDate, notifyAtDate, '1');
      }
    }
  }

  bool notifyBeforeNow(DateTime notifyAtDate) => notifyAtDate.compareTo(tz.TZDateTime.now(tz.local)) < 1;

  DateTime _calcScheduledDate(WasteNoneUser user, DateTime itemExpiryDate) {
    double _notifyDaysBefore = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_DAYS, user.uid), 2);
    int notifyDayOfTheMonth = itemExpiryDate.day > _notifyDaysBefore.toInt()
        ? itemExpiryDate.day - _notifyDaysBefore.toInt()
        : DateUtil().daysInMonth(_prevMonth(itemExpiryDate.month), itemExpiryDate.year) -
            (_notifyDaysBefore.toInt() - itemExpiryDate.day);

    int notifyMonth =
        itemExpiryDate.day > _notifyDaysBefore.toInt() ? itemExpiryDate.month : _prevMonth(itemExpiryDate.month);
    double _notifyAtForWidget = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_HRS, user.uid), 8);
    double _notifyAtMinForWidget = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_MIN, user.uid), 0);

    print('schedule notif on mm:$notifyMonth dd:$notifyDayOfTheMonth at $_notifyAtForWidget');
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // tz.TZDateTime scheduledDate =
    // tz.TZDateTime(tz.local, now.year, notifyMonth, notifyDayOfTheMonth, _notifyAtForWidget.toInt(),_notifyAtMinForWidget.toInt());
    // debug +1 minute:
    return tz.TZDateTime(tz.local, now.year, notifyMonth, notifyDayOfTheMonth, _notifyAtForWidget.toInt(),
        _notifyAtMinForWidget.toInt());
  }

  _prevMonth(int month) {
    return month > 1 ? month - 1 : 12;
  }

  Future<void> removeNotification(Product product, FridgeItem fridgeItem) async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, now.hour, now.minute + 1);
    List<PendingNotificationRequest> existingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    for (PendingNotificationRequest pendingNotification in existingNotifications) {
      if (pendingNotification.id == _presentDateAsInt(fridgeItem.getValidDateAsDate())) {
        if (!pendingNotification.body.contains("\n")) {
          await flutterLocalNotificationsPlugin.cancel(pendingNotification.id);
        } else {
          String newNotificationBody = pendingNotification.body.replaceFirst("\n${product.name}", "");
          await flutterLocalNotificationsPlugin.cancel(pendingNotification.id);
          int payload = int.parse(pendingNotification.payload);
          scheduleExpiryNotification(
              newNotificationBody, fridgeItem.getValidDateAsDate(), scheduledDate, (--payload).toString());
        }
      }
    }
  }

  Future<void> scheduleExpiryNotification(
      String productsName, DateTime validDate, tz.TZDateTime notificationTime, String payload) async {
    Logger()
        .d('scheduled notification: $productsName expires on $validDate, notification will show: $notificationTime');
    String title = int.parse(payload) > 1 ? 'Items' : 'Item';
    title += ' about to expire ${validDate.year}-${validDate.month}-${validDate.day}';
    await flutterLocalNotificationsPlugin.zonedSchedule(
      _presentDateAsInt(validDate),
      title,
      productsName,
      notificationTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          '1',
          'item_expire',
          'channel used for notifying on expiry',
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  int _presentDateAsInt(DateTime notificationDate) {
    return notificationDate.year * 10000 + notificationDate.month * 100 + notificationDate.day;
  }

  void clearNotifications() {
    WasteNoneLogger().d('clear notifications');
    flutterLocalNotificationsPlugin.cancelAll();
  }

  void printNotifications() async {
    WasteNoneLogger().d('print notifications');
    List<PendingNotificationRequest> existingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (PendingNotificationRequest pendingNotification in existingNotifications) {
      WasteNoneLogger().d('${pendingNotification.id}-${pendingNotification.body}');
    }
    WasteNoneLogger().d('end print notifications');
  }
}