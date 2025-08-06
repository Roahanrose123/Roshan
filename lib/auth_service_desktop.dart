import 'dart:async';
import 'package:flutter/foundation.dart';

enum AuthStatus { authenticated, unauthenticated, loading }

class DesktopAuthService {
  static final DesktopAuthService _instance = DesktopAuthService._internal();
  factory DesktopAuthService() => _instance;
  DesktopAuthService._internal();

  // State management
  String? _currentUser;
  AuthStatus _authStatus = AuthStatus.unauthenticated;
  bool _isOnline = true; // Default to online for desktop
  
  final StreamController<AuthStatus> _authStatusController = StreamController<AuthStatus>.broadcast();
  final StreamController<String> _userController = StreamController<String>.broadcast();
  
  // Getters
  bool get isOnline => _isOnline;
  AuthStatus get authStatus => _authStatus;
  String? get currentUser => _currentUser;
  
  // Streams
  Stream<AuthStatus> get authStatusStream => _authStatusController.stream;
  Stream<String> get userStream => _userController.stream;
  
  // Initialize the service
  Future<void> initialize() async {
    // For desktop, we assume online by default to avoid NetworkManager issues
    _isOnline = true;
    
    // Set initial auth status
    _updateAuthStatus();
  }
  
  // Update authentication status
  void _updateAuthStatus() {
    final AuthStatus newStatus = _currentUser != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    
    if (_authStatus != newStatus) {
      _authStatus = newStatus;
      _authStatusController.add(_authStatus);
    }
    
    if (_currentUser != null) {
      _userController.add(_currentUser!);
    }
  }
  
  // Sign in with Google (simulated for desktop)
  Future<bool> signInWithGoogle() async {
    try {
      _authStatus = AuthStatus.loading;
      _authStatusController.add(_authStatus);
      
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (isOnline) {
        _currentUser = 'desktop.google.user@gmail.com';
      } else {
        _currentUser = 'offline.google.user@gmail.com';
      }
      
      _updateAuthStatus();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      _updateAuthStatus();
      return false;
    }
  }
  
  // Sign in with Microsoft (simulated for desktop)
  Future<bool> signInWithMicrosoft() async {
    try {
      _authStatus = AuthStatus.loading;
      _authStatusController.add(_authStatus);
      
      // Simulate authentication delay
      await Future.delayed(const Duration(seconds: 1));
      
      if (isOnline) {
        _currentUser = 'desktop.microsoft.user@outlook.com';
      } else {
        _currentUser = 'offline.microsoft.user@outlook.com';
      }
      
      _updateAuthStatus();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Microsoft Sign-In Error: $e');
      }
      _updateAuthStatus();
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
    _updateAuthStatus();
  }
  
  // Skip authentication (go to offline mode)
  void skipAuthentication() {
    _currentUser = isOnline ? 'guest.user.online' : 'guest.user.offline';
    _updateAuthStatus();
  }
  
  // Get status info for UI
  String getStatusInfo() {
    if (isOnline) {
      return 'Desktop Mode - Online';
    } else {
      return 'Desktop Mode - Offline';
    }
  }
  
  // Dispose
  void dispose() {
    _authStatusController.close();
    _userController.close();
  }
}