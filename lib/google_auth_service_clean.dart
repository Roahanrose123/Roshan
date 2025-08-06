import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class GoogleUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider;

  GoogleUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  factory GoogleUser.fromFirebaseUser(User firebaseUser) {
    return GoogleUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      provider: 'google',
    );
  }
}

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  // Check if we're on desktop
  bool get _isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS
  );

  // Current user
  GoogleUser? _currentUser;
  GoogleUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Stream controllers
  final StreamController<GoogleUser?> _authController = StreamController<GoogleUser?>.broadcast();
  
  Stream<GoogleUser?> get authStateChanges {
    if (kIsWeb || !_isDesktop) {
      // Web and Mobile - use Firebase
      return FirebaseAuth.instance.authStateChanges().map((user) {
        if (user != null) {
          _currentUser = GoogleUser.fromFirebaseUser(user);
          return _currentUser;
        } else {
          _currentUser = null;
          return null;
        }
      });
    } else {
      // Desktop only - use custom OAuth implementation
      Future.microtask(() => _authController.add(_currentUser));
      return _authController.stream;
    }
  }

  // Main sign-in method that chooses the right implementation
  Future<GoogleUser?> signInWithGoogle() async {
    if (kIsWeb) {
      // For web, use Firebase popup
      return await signInWithGoogleWeb();
    } else if (_isDesktop) {
      // Use desktop OAuth flow for desktop only
      return await signInWithGoogleDesktop();
    } else {
      return await signInWithGoogleMobile();
    }
  }

  // Web-specific Google Sign-In using Firebase
  Future<GoogleUser?> signInWithGoogleWeb() async {
    try {
      if (kDebugMode) print('🌐 Starting Firebase Web OAuth...');
      
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      if (userCredential.user != null) {
        _currentUser = GoogleUser.fromFirebaseUser(userCredential.user!);
        _authController.add(_currentUser);
        if (kDebugMode) print('🎉 Firebase web OAuth successful for user: ${_currentUser!.email}');
        return _currentUser;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Web OAuth error: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  // Desktop OAuth placeholder (not needed for web)
  Future<GoogleUser?> signInWithGoogleDesktop() async {
    throw UnimplementedError('Desktop OAuth not implemented in this version');
  }

  // Mobile OAuth 
  Future<GoogleUser?> signInWithGoogleMobile() async {
    try {
      if (kDebugMode) print('📱 Starting Mobile OAuth...');
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) print('ℹ️  Google sign-in cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user != null) {
        _currentUser = GoogleUser.fromFirebaseUser(userCredential.user!);
        if (kDebugMode) print('🎉 Mobile OAuth successful for user: ${_currentUser!.email}');
        return _currentUser;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mobile OAuth error: $e');
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (kDebugMode) print('🔓 Signing out...');
      
      if (kIsWeb || !_isDesktop) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      }
      
      _currentUser = null;
      _authController.add(null);
      
      if (kDebugMode) print('✅ Sign out successful');
    } catch (e) {
      if (kDebugMode) print('❌ Sign-out error: $e');
    }
  }

  void dispose() {
    _authController.close();
  }
}