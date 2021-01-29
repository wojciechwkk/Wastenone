import 'package:waste_none_app/app/models/user.dart';

abstract class AuthBase {
  // Stream<WasteNoneUser> get onAuthStateChange;
  WasteNoneUser currentUser();
  WasteNoneUser userListenerUpdated();
  Future<WasteNoneUser> createUser(String email, String password, String displayName);
  Future<WasteNoneUser> logInAnonymously();
  Future<WasteNoneUser> logInWithEmailAndPassword(String email, String password);
  Future<WasteNoneUser> logInWihGoogle();
  Future<void> logOut();
}

abstract class DBBase {
  // to be "implemented" interface implemented haha
}

abstract class NotificationBase {
  // to be "implemented" too haha
}
