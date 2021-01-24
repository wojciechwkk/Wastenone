import 'dart:io';
import 'dart:math';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/services/flutter_notification.dart';
import 'package:waste_none_app/services/local_nosql_cache.dart';

import 'models/product.dart';

class SettingsWindow extends StatefulWidget {
  SettingsWindow({@required this.auth, @required this.db, @required this.user});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;

  @override
  _SettingsWindowState createState() => _SettingsWindowState(auth: this.auth, db: this.db, user: this.user);
}

class _SettingsWindowState extends State<SettingsWindow> {
  _SettingsWindowState({@required this.auth, @required this.db, @required this.user});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;

  String TIME_FORMAT_KEY;
  String IS_12H_KEY;
  String EXPIRE_NOTIFY_DAYS_KEY;
  String EXPIRE_NOTIFY_HRS_KEY;
  String EXPIRE_NOTIFY_MIN_KEY;
  String METRIC_SYSTEM_KEY;

  bool _is24hrsFormat;
  String _ampmForWidget;
  double _notifyDaysBefore;
  double _notifyAtForWidget;
  double _notifyAtMinForWidget;
  double _maxNotifyTimeScale;
  bool _isSystemMetric;
  String _metricSystem;

  final AsyncMemoizer _memoizer = AsyncMemoizer();
  _setInitTimeFormat() {
    return this._memoizer.runOnce(() async {
      _setSettingsKeys();
      _is24hrsFormat = Settings.getValue(this.TIME_FORMAT_KEY, MediaQuery.of(context).alwaysUse24HourFormat);
      _maxNotifyTimeScale = _is24hrsFormat ? 23.0 : 11.0;
      _ampmForWidget = Settings.getValue(this.IS_12H_KEY, false) ? 'pm' : 'am';
      _isSystemMetric = true; //TODO default based on devices country
      _metricSystem = Settings.getValue(this.METRIC_SYSTEM_KEY, true) ? 'metric' : 'imperial';
      _notifyDaysBefore = Settings.getValue(this.EXPIRE_NOTIFY_DAYS_KEY, 2);
      double notifAt = Settings.getValue(this.EXPIRE_NOTIFY_HRS_KEY, 8);
      _notifyAtForWidget = _is24hrsFormat ? notifAt : notifAt % 12;
      _notifyAtMinForWidget = Settings.getValue(this.EXPIRE_NOTIFY_MIN_KEY, 0);
      // print('w: $_notifyAtForWidget max: $_maxNotifyTimeScale ampm: $_ampmForWidget');
    });
  }

  void _setSettingsKeys() {
    TIME_FORMAT_KEY = getSettingsKey(SettingsKeysEnum.TIME_FORMAT, user.uid);
    IS_12H_KEY = getSettingsKey(SettingsKeysEnum.AM_PM, user.uid);
    EXPIRE_NOTIFY_DAYS_KEY = getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_DAYS, user.uid);
    EXPIRE_NOTIFY_HRS_KEY = getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_HRS, user.uid);
    EXPIRE_NOTIFY_MIN_KEY = getSettingsKey(SettingsKeysEnum.NOTIFY_EXPIRY_MIN, user.uid);
    METRIC_SYSTEM_KEY = getSettingsKey(SettingsKeysEnum.UNIT_SYSTEM, user.uid);
  }

  _changeTimeFormat(bool is24hrs) {
    setState(() {
      _is24hrsFormat = is24hrs;
      if (is24hrs) {
        _maxNotifyTimeScale = 23.0;
        if (_ampmForWidget == 'pm') {
          // print('_notifyAtForWidget $_notifyAtForWidget');
          _notifyAtForWidget += 12.0;
          // print('_notifyAtForWidget $_notifyAtForWidget');
        }
      } else {
        _maxNotifyTimeScale = 11.0;
        _ampmForWidget = _notifyAtForWidget ~/ 12 == 0 ? 'am' : 'pm';
        // print('_notifyAtForWidget $_notifyAtForWidget');
        _notifyAtForWidget %= 12;
        // print('_notifyAtForWidget $_notifyAtForWidget');
      }
    });
    Settings.setValue(this.IS_12H_KEY, _ampmForWidget == 'pm');
  }

  _changeUnitsSystem(bool isSystemMetric) {
    setState(() {
      _isSystemMetric = isSystemMetric;
    });
    Settings.setValue(this.METRIC_SYSTEM_KEY, _isSystemMetric);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: this._setInitTimeFormat(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
              appBar: AppBar(title: Text('Settings'), actions: <Widget>[]),
              body: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: <Widget>[
                      ExpandableSettingsTile(
                        subtitle: 'expand for options',
                        title: 'Expiry notifications',
                        children: [
                          SliderSettingsTile(
                            title: 'notify days before:',
                            settingKey: this.EXPIRE_NOTIFY_DAYS_KEY,
                            defaultValue: 2,
                            min: 1,
                            max: 9,
                            step: 1,
                            leading: Icon(Icons.calendar_today_outlined),
                            onChange: (value) {
                              // debugWasteNoneLogger().d('expiry-notify-days: $value');
                              setState(() {
                                _notifyDaysBefore = value;
                              });
                            },
                            subtitle: '${_notifyDaysBefore.toInt()} days',
                          ),
                          Visibility(
                            visible: !_is24hrsFormat,
                            child: SwitchSettingsTile(
                              settingKey: this.IS_12H_KEY,
                              title: 'AM / PM',
                              disabledLabel: 'am',
                              enabledLabel: 'pm',
                              presetValue: _ampmForWidget == 'pm',
                              onChange: (value) {
                                setState(() {
                                  _ampmForWidget = value == true ? 'pm' : 'am';
                                });
                              },
                            ),
                          ),
                          NotifyTimeSliderSettingsTile(
                            title: 'notify at:',
                            settingKey: this.EXPIRE_NOTIFY_HRS_KEY,
                            defaultValue: 8.0,
                            min: 0.0,
                            max: _maxNotifyTimeScale,
                            step: 1,
                            leading: Icon(Icons.timer),
                            presetValue: _notifyAtForWidget,
                            onChange: (value) {
                              setState(() {
                                _notifyAtForWidget = value;
                              });
                            },
                            subtitle: '${_formatTime(_notifyAtForWidget.toInt())}',
                          ),
                          NotifyTimeSliderSettingsTile(
                            title: 'minutes:',
                            settingKey: this.EXPIRE_NOTIFY_MIN_KEY,
                            defaultValue: 0.0,
                            min: 0.0,
                            max: 59.0,
                            step: 1,
                            leading: Icon(Icons.access_time_sharp),
                            presetValue: _notifyAtMinForWidget,
                            onChange: (value) {
                              setState(() {
                                _notifyAtMinForWidget = value;
                              });
                            },
                            subtitle: _notifyAtMinForWidget.toInt().toString(),
                          ),
                        ],
                      ),
                      SwitchSettingsTile(
                        settingKey: this.TIME_FORMAT_KEY,
                        title: 'Time format',
                        enabledLabel: '24-hour',
                        disabledLabel: 'AM / PM',
                        leading: Icon(Icons.accessibility_new_rounded),
                        onChange: (value) {
                          _changeTimeFormat(value);
                        },
                      ),
                      SwitchSettingsTile(
                        settingKey: this.METRIC_SYSTEM_KEY,
                        title: 'Units',
                        enabledLabel: 'Metric',
                        disabledLabel: 'Imperial',
                        leading: Icon(Icons.architecture),
                        onChange: (value) {
                          _changeUnitsSystem(value);
                        },
                      ),
                      // SimpleSettingsTile(
                      //   title: 'Logger().d notifications',
                      //   subtitle: '',
                      //   onTap: _Logger().dNotifications,
                      // ),
                      SimpleSettingsTile(
                        title: 'Clear notifications',
                        subtitle: '',
                        onTap: _clearNotifications,
                      ),
                      // SimpleSettingsTile(
                      //   title: 'Logger().d cached prods',
                      //   subtitle: '',
                      //   onTap: _Logger().dCachedProducts,
                      // ),
                      SimpleSettingsTile(
                        title: 'Clear cached products',
                        subtitle: '',
                        onTap: _clearCachedProducts,
                      ),
                      SimpleSettingsTile(
                        title: 'Send console log',
                        subtitle: '',
                        onTap: _sendConsolLog,
                      ),
                    ],
                  ),
                ),
              ));
        } else {
          return LoadingIndicator();
        }
      },
    );
  }

  void _clearNotifications() {
    WasteNoneLogger().d('clear notifications');
    FlutterNotification().clearNotifications();
  }

  void _printNotifications() async {
    WasteNoneLogger().d('print notifications');
    FlutterNotification().printNotifications();
  }

  String _formatTime(int hour) {
    if (_is24hrsFormat)
      return '${hour.toString()}:00';
    else {
      return '$hour$_ampmForWidget';
    }
  }

  _printCachedProducts() async {
    List<Product> storedInCache = await getAllCachedProducts();
    WasteNoneLogger().d('Cached ${storedInCache.length} products: ');
    storedInCache.forEach((e) => WasteNoneLogger().d(e.toJson()));
  }

  _clearCachedProducts() async {
    clearCachedProducts();
    WasteNoneLogger().d('cache cleared');
  }

  _sendConsolLog() async {
    WasteNoneLogger()
        .d('                                        ----------------------------                                  ');
    db.storeLogger(user, WasteNoneLogger().getFullLog());
    WasteNoneLogger()
        .d('                                        ----------------------------                                  ');
  }
}

class WasteNoneLogger extends Logger {
  static WasteNoneLogger instance;
  static StringBuffer logBuffer;

  static final WasteNoneLogger _wasteNoneLogger = WasteNoneLogger._internal();

  factory WasteNoneLogger() {
    return _wasteNoneLogger;
  }

  WasteNoneLogger._internal() {
    logBuffer = StringBuffer();
  }

  void d(dynamic message, [dynamic error, StackTrace stackTrace]) {
    logBuffer?.write(' | $message | ');
    // print('Logger size: ${logBuffer.length}');
    // super.d(message);
    print(message);
  }

  String getFullLog() {
    print('logger returned: ${logBuffer != null}');
    return logBuffer?.toString();
  }

  clear() {
    logBuffer?.clear();
    print('logger cleaned: ${logBuffer != null}');
  }
}
