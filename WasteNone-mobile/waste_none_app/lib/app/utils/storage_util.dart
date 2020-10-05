import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:waste_none_app/app/models/user.dart';
import 'package:waste_none_app/app/utils/settings_util.dart';

Future<String> readEncryptionPassword(String uuid) async {
  String encryptionPassword =
      await FlutterSecureStorage().read(key: '$uuid-pass');
  return encryptionPassword;
}

Future<String> createEncryptionPassword(String usersUid) async {
  String existingPassword = await readEncryptionPassword(usersUid);
  if (existingPassword == null) {
    var uuidFactory = Uuid();
    String encryptionPassword = uuidFactory.v1();
    FlutterSecureStorage()
        .write(key: '$usersUid-pass', value: encryptionPassword);
    return encryptionPassword;
  }
  return existingPassword;
}

initStoreGithubKey() {
  FlutterSecureStorage().write(key: "githubKey", value: "896604686094f376acb8");
}

initStoreGithubSecret() {
  FlutterSecureStorage().write(
      key: "githubSecret", value: "b73ad19b4ce6fe31a81c1ef090806882dce66323");
}

initStoreTwitterKey() {
  FlutterSecureStorage()
      .write(key: "twitterKey", value: "lqkhcIN7gru1zWBEHfv07JrMw");
}

initStoreTwitterSecret() {
  FlutterSecureStorage().write(
      key: "twitterSecret",
      value: "d5DDRkgE7oa10EZpH0kOfkMIl3l972QpP9sQ1N0FgUGifJCKNQ");
}

const _TIME_FORMAT_KEY = "timeFormat";

storeUsersTimeFormat(WasteNoneUser user, TimeFormatEnum timeFormatEnum) {
  FlutterSecureStorage().write(
      key: user.uid + _TIME_FORMAT_KEY, value: timeFormatEnum.toString());
}

Future<String> getUsersStoredTimeFormat(WasteNoneUser user) async {
  return await FlutterSecureStorage().read(key: user.uid + _TIME_FORMAT_KEY);
}

const _NOTIFICATION_TIME_KEY = "notificationTime";

storeUsersPushNotificationTime(WasteNoneUser user, String hour) {
  FlutterSecureStorage()
      .write(key: user.uid + _NOTIFICATION_TIME_KEY, value: hour);
}

Future<String> getUsersPushNotificationTime(WasteNoneUser user) async {
  return await FlutterSecureStorage()
      .read(key: user.uid + _NOTIFICATION_TIME_KEY);
}
