
import 'package:flutter/foundation.dart';

class WasteNoneUser{
  WasteNoneUser({@required this.uid});
  final String uid;
}

abstract class AuthBase {
  Stream<WasteNoneUser> get onAuthStateChange;
  Future<WasteNoneUser> currentUser();
  Future<String> getCurrentUsersDisplayName();
  Future<WasteNoneUser> createUser(String email, String password, String displayName );
  Future<WasteNoneUser> logInAnonymously();
  Future<WasteNoneUser> logInWithEmailAndPassword(String email, String password);
  Future<WasteNoneUser> logInWihGoogle();
  Future<WasteNoneUser> logInWihTwitter();
  Future<WasteNoneUser> logInWihGithub();
  Future<void> logOut();

}