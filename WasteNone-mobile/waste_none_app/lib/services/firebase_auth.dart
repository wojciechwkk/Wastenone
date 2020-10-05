import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:waste_none_app/app/models/user.dart';

import 'base_classes.dart';

class WNFirebaseAuth implements AuthBase {
  var _firebaseAuth = FirebaseAuth.instance;

  WasteNoneUser _userFromFirebase(User user) {
    return (user == null)
        ? null
        : new WasteNoneUser(user.uid, user.displayName);
  }

  // @override
  // Stream<WasteNoneUser> get onAuthStateChange {
  //   return _firebaseAuth.onAuthStateChanged.map(_userFromFirebase);
  // }

  @override
  WasteNoneUser currentUser() {
    final user = _firebaseAuth.currentUser;
    return _userFromFirebase(user);
  }

  @override
  Future<WasteNoneUser> logInAnonymously() async {
    final userCredential = await _firebaseAuth.signInAnonymously();
    await userCredential.user.updateProfile(displayName: 'anonymous');
    await userCredential.user.reload();
    User user = _firebaseAuth.currentUser;
    return _userFromFirebase(user);
  }

  @override
  Future<WasteNoneUser> createUser(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      if (userCredential != null) {
        if (displayName != null) {
          print('fb.setting display text $displayName');
          await userCredential.user.updateProfile(displayName: displayName);
        }
        print(
            'fb.created user ${_userFromFirebase((userCredential.user)).toJson()}');
        return _userFromFirebase((userCredential.user));
      } else
        return null;
    } on PlatformException catch (exception) {
      switch (exception.code) {
        case 'ERROR_EMAIL_ALREADY_IN_USE':
          print('error email already in use');
          break;
        default:
          break;
      }
    }
    return null;
  }

  @override
  Future<void> logOut() async {
    User user = _firebaseAuth.currentUser;
    print('user: $user');
    if (user?.displayName == 'anonymous')
      user.delete();
    else {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await _firebaseAuth.signOut();
    }
  }

  @override
  Future<WasteNoneUser> logInWithEmailAndPassword(
      String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return _userFromFirebase((userCredential.user));
  }

//  ------------------------------ Google --------------------------------------
  @override
  Future<WasteNoneUser> logInWihGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleAccount = await googleSignIn.signIn();
    if (googleAccount != null) {
      GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;
      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final userCredential = await _firebaseAuth.signInWithCredential(
            GoogleAuthProvider.credential(
                idToken: googleAuth.idToken,
                accessToken: googleAuth.accessToken));
        return _userFromFirebase(userCredential.user);
      } else {
        throw PlatformException(
          code: 'ERROR_MISSING_GOOGLE_AUTH_TOEKN',
          message: 'Missing google Auth Token',
        );
      }
    } else {
      throw PlatformException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
  }

//  ------------------------------ Google --------------------------------------
}
