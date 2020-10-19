import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';

class SettingsWindow extends StatefulWidget {
  SettingsWindow({@required this.auth, @required this.db, @required this.user});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;

  @override
  _SettingsWindowState createState() =>
      _SettingsWindowState(auth: this.auth, db: this.db, user: this.user);
}

class _SettingsWindowState extends State<SettingsWindow> {
  _SettingsWindowState(
      {@required this.auth, @required this.db, @required this.user});

  final AuthBase auth;
  final WNFirebaseDB db;
  final WasteNoneUser user;

  final AsyncMemoizer _memoizer = AsyncMemoizer();

  String TIME_FORMAT_KEY;
  String AM_PM_KEY;
  String EXPIRE_NOTIFY_DAYS_KEY;
  String EXPIRE_NOTIFY_HRS_KEY;

  bool _is24hrsFormat;
  String _ampmForWidget;
  double _notifyDaysBefore;
  double _notifyAtForWidget;
  double _maxNotifyTimeScale;

  _setInitTimeFormat() {
    return this._memoizer.runOnce(() async {
      _setSettingsKeys();

      _is24hrsFormat = Settings.getValue(
          this.TIME_FORMAT_KEY, MediaQuery.of(context).alwaysUse24HourFormat);
      _maxNotifyTimeScale = _is24hrsFormat ? 23.0 : 11.0;
      _notifyAtForWidget = Settings.getValue(this.EXPIRE_NOTIFY_HRS_KEY, 8);
      _notifyDaysBefore = Settings.getValue(this.EXPIRE_NOTIFY_DAYS_KEY, 2);
      _ampmForWidget = Settings.getValue(this.AM_PM_KEY, false) ? 'pm' : 'am';
      // Settings.clearCache();
    });
  }

  void _setSettingsKeys() {
    TIME_FORMAT_KEY = '${user.uid}-24hrs-format';
    AM_PM_KEY = '${user.uid}-am-pm';
    EXPIRE_NOTIFY_DAYS_KEY = '${user.uid}-expiry-notify-days';
    EXPIRE_NOTIFY_HRS_KEY = '${user.uid}-expiry-notify-hours';
  }

  _changeTimeFormat(bool is24hrs) {
    setState(() {
      _is24hrsFormat = is24hrs;
      if (is24hrs) {
        _maxNotifyTimeScale = 23.0;
        if (_ampmForWidget == 'pm') {
          _notifyAtForWidget += 12.0;
        }
      } else {
        _maxNotifyTimeScale = 11.0;
        _ampmForWidget = _notifyAtForWidget ~/ 12 == 0 ? 'am' : 'pm';
        _notifyAtForWidget %= 12;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: this._setInitTimeFormat(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
              appBar: AppBar(title: Text('Settings'), actions: <Widget>[]),
              body: Center(
                child: Column(
                  children: <Widget>[
                    ExpandableSettingsTile(
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
                            debugPrint('expiry-notify-days: $value');
                            setState(() {
                              _notifyDaysBefore = value;
                            });
                          },
                          subtitle: '${_notifyDaysBefore.toInt()} days',
                        ),
                        Visibility(
                          visible: !_is24hrsFormat,
                          child: SwitchSettingsTile(
                            settingKey: this.AM_PM_KEY,
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
                          leading: Icon(Icons.access_time_sharp),
                          presetValue: _notifyAtForWidget,
                          onChange: (value) {
                            setState(() {
                              _notifyAtForWidget = value;
                            });
                          },
                          subtitle:
                              '${_formatTime(_notifyAtForWidget.toInt())}',
                        ),
                      ],
                    ),
                    SwitchSettingsTile(
                      settingKey: this.TIME_FORMAT_KEY,
                      title: 'Time format',
                      enabledLabel: '24-hour',
                      disabledLabel: 'AM/PM',
                      leading: Icon(Icons.accessibility_new_rounded),
                      onChange: (value) {
                        _changeTimeFormat(value);
                      },
                    ),
                  ],
                ),
              ));
        } else {
          return LoadingIndicator();
        }
      },
    );
  }

  String _formatTime(int hour) {
    if (_is24hrsFormat)
      return '${hour.toString()}:00';
    else {
      return '$hour$_ampmForWidget';
    }
  }
}
