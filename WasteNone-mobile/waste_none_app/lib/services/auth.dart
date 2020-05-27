import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class WasteNoneUser {
  WasteNoneUser({@required this.uid, @required this.displayName});
  final String uid;
  final String displayName;
}

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
