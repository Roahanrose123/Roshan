import 'package:flutter/foundation.dart';
import 'dart:async';

class DemoUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider;

  DemoUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });
}

class DemoAuthService {
  static final DemoAuthService _instance = DemoAuthService._internal();
  factory DemoAuthService() => _instance;
  DemoAuthService._internal();

  // Current user
  DemoUser? _currentUser;
  DemoUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Stream controllers
  final StreamController<DemoUser?> _authController = StreamController<DemoUser?>.broadcast();
  
  Stream<DemoUser?> get authStateChanges {
    Future.microtask(() => _authController.add(_currentUser));
    return _authController.stream;
  }

  // Demo sign-in that works without OAuth setup
  Future<DemoUser?> signInWithGoogle() async {
    try {
      if (kDebugMode) print('🔐 Starting Demo Google Sign-In...');
      
      // Simulate loading
      await Future.delayed(const Duration(seconds: 1));
      
      // Create demo user with real-looking data
      _currentUser = DemoUser(
        id: 'demo_user_123',
        email: 'demo.user@gmail.com',
        name: 'Demo User',
        photoUrl: 'https://ui-avatars.com/api/?name=Demo+User&background=4285f4&color=fff&size=128',
        provider: 'google_demo',
      );
      
      _authController.add(_currentUser);
      
      if (kDebugMode) print('✅ Demo Google sign-in successful: ${_currentUser!.email}');
      return _currentUser;

    } catch (e) {
      if (kDebugMode) print('❌ Demo sign-in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (kDebugMode) print('🔓 Demo signing out...');
      
      _currentUser = null;
      _authController.add(null);
      
      if (kDebugMode) print('✅ Demo sign out successful');
    } catch (e) {
      if (kDebugMode) print('❌ Demo sign-out error: $e');
    }
  }

  void dispose() {
    _authController.close();
  }
}