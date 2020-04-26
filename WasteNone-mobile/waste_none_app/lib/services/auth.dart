
import 'package:flutter/foundation.dart';

class User{
  User({@required this.uid});
  final String uid;
}

abstract class AuthBase {
  Stream<User> get onAuthStateChange;
  Future<User> currentUser();
  Future<User> logInAnonymously();
  Future<User> logInWihGoogle();
  Future<void> logOut();

}