
import 'package:flutter/foundation.dart';

class User{
  User({@required this.uid});
  final String uid;
}

abstract class AuthBase {
  Stream<User> get onAuthStateChange;
  Future<User> currentUser();
  Future<String> getCurrentUsersDisplayName();
  Future<User> createUser(String email, String password, String displayName );
  Future<User> logInAnonymously();
  Future<User> logInWithEmailAndPassword(String email, String password);
  Future<User> logInWihGoogle();
  Future<void> logOut();

}