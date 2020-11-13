import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:waste_none_app/app/models/fridge.dart';
import 'package:waste_none_app/app/models/fridge_item.dart';
import 'package:waste_none_app/app/models/product.dart';
import 'package:waste_none_app/app/models/user.dart';
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
      debugPrint('notification payload: $payload');
    }
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute<void>(
    //       builder: (context) => LandingSemaphorePage(
    //             auth: WNFirebaseAuth(),
    //             db: WNFirebaseDB(),
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
        0, 'Added new product to your fridge: $fridgeName', product.name, platformChannelSpecifics,
        payload: fridgeItem.fuid);
  }

  Future<void> addExpiryNotification(WasteNoneUser user, Product product, FridgeItem fridgeItem) async {
    DateTime expiryDate = fridgeItem.getValidDateAsDate();

    double _notifyAtForWidget = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_HRS, user.uid), 8);
    double _notifyDaysBefore = Settings.getValue(getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_DAYS, user.uid), 2);
    int notifDayOfTheMonth = expiryDate.day - _notifyDaysBefore.toInt();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month,
    //     notifDayOfTheMonth, _notifyAtForWidget.toInt());
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, now.hour, now.minute + 1);
    List<PendingNotificationRequest> existingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();

    bool foundNotificationOnThisDate = false;
    for (PendingNotificationRequest pendingNotification in existingNotifications) {
      if (pendingNotification.id == _presentDateAsInt(expiryDate)) {
        await flutterLocalNotificationsPlugin.cancel(pendingNotification.id);
        String newNotificationBody = '''
${pendingNotification.body} 
${product.name}''';
        int payload = int.parse(pendingNotification.payload);
        scheduleExpiryNotification(newNotificationBody, expiryDate, scheduledDate, (++payload).toString());
        foundNotificationOnThisDate = true;
      }
    }
    if (!foundNotificationOnThisDate) {
      if (scheduledDate.compareTo(now) < 1) {
        // add scheduledDate to the first scheduled notif
      } else {
        scheduleExpiryNotification(product.name, expiryDate, scheduledDate, '1');
      }
    }
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
    print('scheduled notification: $productsName expires on $validDate, notification will show: $notificationTime');
    String title = int.parse(payload) > 1 ? 'Items' : 'Item';
    title += ' about to get expired on ${validDate.year}-${validDate.month}-${validDate.day}';
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
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  int _presentDateAsInt(DateTime notificationDate) {
    return notificationDate.year * 10000 + notificationDate.month * 100 + notificationDate.day;
  }

  void clearNotifications() {
    print('clear notifications');
    flutterLocalNotificationsPlugin.cancelAll();
  }

  void printNotifications() async {
    print('print notifications');
    List<PendingNotificationRequest> existingNotifications =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    for (PendingNotificationRequest pendingNotification in existingNotifications) {
      print('${pendingNotification.id}-${pendingNotification.body}');
    }
    print('end print notifications');
  }
}
