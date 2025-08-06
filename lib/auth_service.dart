import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final AadOAuth oauth;

  AuthService(this.oauth);

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      if (kDebugMode) {
        print("Google Sign-In Error: $e");
      }
      rethrow;
    }
  }

  // Microsoft Sign-In
  Future<UserCredential?> signInWithMicrosoft() async {
    try {
      await oauth.login();
      final String? accessToken = await oauth.getAccessToken();
      if (accessToken != null) {
        final AuthCredential credential = OAuthProvider("microsoft.com").credential(
          accessToken: accessToken,
        );
        return await _auth.signInWithCredential(credential);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print("Microsoft Sign-In Error: $e");
      }
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    try {
      await oauth.logout();
    } catch (e) {
      if (kDebugMode) {
        print("Microsoft Sign-Out Error: $e");
      }
    }
  }
}
