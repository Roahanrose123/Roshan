import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional imports - only load Firebase on supported platforms
import 'package:firebase_auth/firebase_auth.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'package:aad_oauth/aad_oauth.dart'
    if (dart.library.io) 'package:flutter/services.dart';

class UnifiedAuthService {
  static bool get isFirebaseSupported => kIsWeb || !_isDesktop;
  static bool get _isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || 
                                           defaultTargetPlatform == TargetPlatform.windows ||
                                           defaultTargetPlatform == TargetPlatform.macOS);

  // Simulated auth for desktop platforms
  static String? _currentUser;
  static final List<VoidCallback> _authStateListeners = [];
  
  // Firebase instances (only for web/mobile)
  static final FirebaseAuth? _auth = isFirebaseSupported ? FirebaseAuth.instance : null;
  static final GoogleSignIn? _googleSignIn = isFirebaseSupported ? GoogleSignIn() : null;
  
  // Current user getter
  static String? get currentUser {
    if (isFirebaseSupported && _auth?.currentUser != null) {
      return _auth!.currentUser!.email;
    }
    return _currentUser;
  }
  
  // Auth state stream
  static Stream<String?> authStateChanges() {
    if (isFirebaseSupported) {
      return _auth!.authStateChanges().map((user) => user?.email);
    } else {
      // For desktop, create a simple stream
      return Stream.periodic(const Duration(seconds: 1), (_) => _currentUser).distinct();
    }
  }
  
  // Google Sign-In
  static Future<bool> signInWithGoogle() async {
    try {
      if (isFirebaseSupported) {
        // Web/Mobile Firebase authentication
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return false;
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth!.signInWithCredential(credential);
        return true;
      } else {
        // Desktop simulation
        _currentUser = 'desktop.user@gmail.com';
        _notifyAuthStateListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      return false;
    }
  }
  
  // Microsoft Sign-In
  static Future<bool> signInWithMicrosoft() async {
    try {
      if (isFirebaseSupported) {
        // This would require additional setup for web
        // For now, simulate success
        _currentUser = 'desktop.user@microsoft.com';
        _notifyAuthStateListeners();
        return true;
      } else {
        // Desktop simulation
        _currentUser = 'desktop.user@microsoft.com';
        _notifyAuthStateListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Microsoft Sign-In Error: $e');
      }
      return false;
    }
  }
  
  // Sign Out
  static Future<void> signOut() async {
    if (isFirebaseSupported) {
      await _auth!.signOut();
      await _googleSignIn?.signOut();
    } else {
      _currentUser = null;
      _notifyAuthStateListeners();
    }
  }
  
  // Add auth state listener
  static void addAuthStateListener(VoidCallback listener) {
    _authStateListeners.add(listener);
  }
  
  // Remove auth state listener
  static void removeAuthStateListener(VoidCallback listener) {
    _authStateListeners.remove(listener);
  }
  
  // Notify listeners (for desktop)
  static void _notifyAuthStateListeners() {
    for (var listener in _authStateListeners) {
      listener();
    }
  }
  
  // Initialize (call this in main)
  static Future<void> initialize() async {
    if (isFirebaseSupported) {
      // Firebase initialization handled in main
    } else {
      // Desktop initialization if needed
    }
  }
}