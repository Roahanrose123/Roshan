import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class SimpleUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider;

  SimpleUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  factory SimpleUser.fromFirebaseUser(User firebaseUser) {
    return SimpleUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      provider: 'firebase',
    );
  }

  factory SimpleUser.fromDesktop(String email, String name, String provider) {
    return SimpleUser(
      id: email.hashCode.toString(),
      email: email,
      name: name,
      photoUrl: null,
      provider: provider,
    );
  }
}

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  // Check if we're on desktop
  bool get _isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS
  );

  // Current user
  SimpleUser? _currentUser;
  SimpleUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Stream controllers
  final StreamController<SimpleUser?> _authController = StreamController<SimpleUser?>.broadcast();
  
  Stream<SimpleUser?> get authStateChanges {
    if (!_isDesktop) {
      // Mobile/Web - use Firebase
      return FirebaseAuth.instance.authStateChanges().map((user) {
        if (user != null) {
          _currentUser = SimpleUser.fromFirebaseUser(user);
          return _currentUser;
        } else {
          _currentUser = null;
          return null;
        }
      });
    } else {
      // Desktop - use simple stream controller with initial value
      // Add current user asynchronously to avoid blocking
      Future.microtask(() => _authController.add(_currentUser));
      return _authController.stream;
    }
  }

  // Desktop sign in
  void signInWithDesktop(String email, String name, String provider) {
    _currentUser = SimpleUser.fromDesktop(email, name, provider);
    _authController.add(_currentUser);
  }

  // Firebase sign in methods
  Future<SimpleUser?> signInWithGoogle() async {
    if (_isDesktop) {
      // Should not be called for desktop
      return null;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        _currentUser = SimpleUser.fromFirebaseUser(userCredential.user!);
        return _currentUser;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!_isDesktop) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }
      
      _currentUser = null;
      _authController.add(null);
    } catch (e) {
      if (kDebugMode) {
        print('Sign-Out error: $e');
      }
    }
  }

  void dispose() {
    _authController.close();
  }
}