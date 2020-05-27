import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'auth.dart';

class WNFirebaseAuth implements AuthBase {
  var _firebaseAuth = FirebaseAuth.instance;

  WasteNoneUser _userFromFirebase(FirebaseUser user) {
    return (user == null)
        ? null
        : new WasteNoneUser(uid: user.uid, displayName: user.displayName);
  }

  @override
  Stream<WasteNoneUser> get onAuthStateChange {
    return _firebaseAuth.onAuthStateChanged.map(_userFromFirebase);
  }

  @override
  Future<WasteNoneUser> currentUser() async {
    final user = await _firebaseAuth.currentUser();
    return _userFromFirebase(user);
  }

  @override
  Future<WasteNoneUser> logInAnonymously() async {
    final authResult = await _firebaseAuth.signInAnonymously();
    return _userFromFirebase(authResult.user);
  }

  @override
  Future<WasteNoneUser> createUser(
      String email, String password, String displayName) async {
    final authResult = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    print('created, about to update displayNamee');
    UserUpdateInfo userUpdateInfo = UserUpdateInfo();
    userUpdateInfo.displayName = displayName;
    authResult.user.updateProfile(userUpdateInfo);
    return _userFromFirebase((authResult.user));
  }

  @override
  Future<void> logOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await twitterLogin.logOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<WasteNoneUser> logInWithEmailAndPassword(
      String email, String password) async {
    final authResult = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return _userFromFirebase((authResult.user));
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
        final authResult = await _firebaseAuth.signInWithCredential(
            GoogleAuthProvider.getCredential(
                idToken: googleAuth.idToken,
                accessToken: googleAuth.accessToken));
        return _userFromFirebase(authResult.user);
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
//  ------------------------------ Twitter -------------------------------------
  var twitterLogin = new TwitterLogin(
    consumerKey: 'lqkhcIN7gru1zWBEHfv07JrMw',
    consumerSecret: 'd5DDRkgE7oa10EZpH0kOfkMIl3l972QpP9sQ1N0FgUGifJCKNQ',
  );

  @override
  Future<WasteNoneUser> logInWihTwitter() async {
    final TwitterLoginResult result = await twitterLogin.authorize();
    switch (result.status) {
      case TwitterLoginStatus.loggedIn:
        var session = result.session;
        final authResult = await _firebaseAuth.signInWithCredential(
            TwitterAuthProvider.getCredential(
                authToken: session.token, authTokenSecret: session.secret));
        return (_userFromFirebase(authResult.user));
        break;
      case TwitterLoginStatus.cancelledByUser:
        //_showCancelMessage();
        break;
      case TwitterLoginStatus.error:
        //_showErrorMessage(result.error);
        break;
    }
    return null;
  }

//  ------------------------------ Twitter -------------------------------------
//  ------------------------------ Github  -------------------------------------
  String githubLoginKey = '896604686094f376acb8';
  String githubLoginSecret = 'b73ad19b4ce6fe31a81c1ef090806882dce66323';

  @override
  Future<WasteNoneUser> logInWihGithub() async {
    _logInToGithub();

//    Auth auth = Auth(githubLoginKey, githubLoginSecret);
//    GithubOauth oauth = GithubOauth(auth);
//    GitHub
//    print(oauth);
//    oauth.getToken(username, password)
//    oauth.login(username,password).then((result){
//      if(result.data == null){
//        // 1. this means your clientId or clientSecret is error
//        // 2. this means your username or password is error
//        // 3. detail information please see result.code and result.message
//      } else {
//        setState((){
//          this.user = result.data;
//        });
//      }
//    });
//
//    final authResult = await _firebaseAuth.signInWithCredential(
//        GithubAuthProvider.getCredential(token: githubToken));
    return null;
  }

  void _logInToGithub() async {
    const String url = "https://github.com/login/oauth/authorize" +
        "?client_id=" +
        "896604686094f376acb8" +
        "&scope=public_repo%20read:user%20user:email";

    print('calling $url');
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
      );
    } else {
      print("CANNOT LAUNCH THIS URL!");
    }
  }
}
//  ------------------------------ Github  -------------------------------------
