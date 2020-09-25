import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../services/base_classes.dart';

class WNFlutterStorageUtil {
  static Future<String> readEncryptionPassword(String uuid) async {
    String encryptionPassword =
        await FlutterSecureStorage().read(key: '$uuid-pass');
    return encryptionPassword;
  }

  static Future<String> createEncryptionPassword(String usersUid) async {
    String existingPassword = await readEncryptionPassword(usersUid);
    if (existingPassword == null) {
      var uuidFactory = Uuid();
      String encryptionPassword = uuidFactory.v1();
      FlutterSecureStorage()
          .write(key: '$usersUid-pass', value: encryptionPassword);
      return encryptionPassword;
    }
  }

  static initStoreGithubKey() {
    FlutterSecureStorage()
        .write(key: "githubKey", value: "896604686094f376acb8");
  }

  static initStoreGithubSecret() {
    FlutterSecureStorage().write(
        key: "githubSecret", value: "b73ad19b4ce6fe31a81c1ef090806882dce66323");
  }

  static initStoreTwitterKey() {
    FlutterSecureStorage()
        .write(key: "twitterKey", value: "lqkhcIN7gru1zWBEHfv07JrMw");
  }

  static initStoreTwitterSecret() {
    FlutterSecureStorage().write(
        key: "twitterSecret",
        value: "d5DDRkgE7oa10EZpH0kOfkMIl3l972QpP9sQ1N0FgUGifJCKNQ");
  }
}
