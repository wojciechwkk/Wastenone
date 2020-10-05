import 'package:async/async.dart';
import 'package:day_night_time_picker/day_night_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';
import 'package:waste_none_app/common_widgets/loading_indicator.dart';
import 'package:waste_none_app/services/base_classes.dart';
import 'package:waste_none_app/services/firebase_database.dart';
import 'package:waste_none_app/app/utils/storage_util.dart';

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
  TimeOfDay _notificationTime = TimeOfDay(hour: 9, minute: 0);
  bool _notificationTimeChanged = false;
  bool _is24hrsFormat = false;
  bool _timeFormatChanged = false;

  _setInitTimeFormat() {
    return this._memoizer.runOnce(() async {
      _is24hrsFormat = await isUsersTimeFormat24hs(user, context);
      _notificationTime = await getNotificationTime(user);
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
            body: Container(
              child: Column(
                children: [
                  Text(
                    '',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, top: 20.0),
                    child: Row(
                      children: [
                        Text(
                          'Time format:  ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        FlatButton(
                          onPressed: () {
                            _setTimeFormat(TimeFormatEnum.ampm);
                          },
                          child: Text('am/pm'),
                        ),
                        Text(' or '),
                        FlatButton(
                          onPressed: () {
                            _setTimeFormat(TimeFormatEnum.a24h);
                          },
                          child: Text('24-hour'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 30.0, top: 20.0),
                    child: Row(
                      children: [
                        Text(
                          'Notification time:  ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16.0),
                        ),
                        Text(_formatTime(_notificationTime.hour)),
                        FlatButton(
                          onPressed: () {
                            Navigator.of(context).push(showPicker(
                                context: context,
                                value: _notificationTime,
                                onChange: _onNotificationTimeChanged,
                                is24HrFormat: _is24hrsFormat,
                                sunAsset: Image(
                                  image: AssetImage(
                                    "packages/day_night_time_picker/assets/sun.png",
                                  ),
                                )));
                          },
                          child: Text(
                            'Set',
                            // style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              // ),
            ),
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton.extended(
                    onPressed: _cancel,
                    label: Text("Cancel"),
                    icon: Icon(Icons.cancel),
                    heroTag: null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton.extended(
                    onPressed: _apply,
                    label: Text("Save"),
                    icon: Icon(Icons.check_circle),
                    heroTag: null,
                  ),
                ),
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        } else {
          return LoadingIndicator();
        }
      },
    );
  }

  void _setTimeFormat(TimeFormatEnum timeFormatEnum) {
    _timeFormatChanged = true;
    setState(() {
      _is24hrsFormat = timeFormatEnum == TimeFormatEnum.a24h;
    });
  }

  void _onNotificationTimeChanged(TimeOfDay newTime) {
    _notificationTimeChanged = true;
    setState(() {
      _notificationTime = newTime;
    });
  }

  String _formatTime(int hour) {
    if (_is24hrsFormat)
      return '${hour.toString()}:00';
    else {
      return hour < 12 ? '${hour}AM' : '${hour % 12}PM';
    }
  }

  _cancel() {
    _timeFormatChanged = false;
    _notificationTimeChanged = false;
    Navigator.pop(context);
  }

  _apply() {
    if (_timeFormatChanged) {
      var timeFormat =
          _is24hrsFormat ? TimeFormatEnum.a24h : TimeFormatEnum.ampm;
      storeUsersTimeFormat(user, timeFormat);
    }
    if (_notificationTimeChanged) {
      storeUsersPushNotificationTime(user, _notificationTime.hour.toString());
    }
    Navigator.pop(context);
  }
}
