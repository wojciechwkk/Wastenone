import 'package:waste_none_app/app/models/user.dart';

abstract class AuthBase {
  Stream<WasteNoneUser> get onAuthStateChange;
  Future<WasteNoneUser> currentUser();
  Future<WasteNoneUser> createUser(
      String email, String password, String displayName);
  Future<WasteNoneUser> logInAnonymously();
  Future<WasteNoneUser> logInWithEmailAndPassword(
      String email, String password);
  Future<WasteNoneUser> logInWihGoogle();
  Future<WasteNoneUser> logInWihTwitter();
  Future<WasteNoneUser> logInWihGithub();
  Future<void> logOut();
}
