import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'connectivity_service.dart';

// Conditional imports - only load Firebase on supported platforms
import 'package:firebase_auth/firebase_auth.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'package:aad_oauth/aad_oauth.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'package:aad_oauth/model/config.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'config.dart';

enum AuthMode { online, offline, auto }
enum AuthStatus { authenticated, unauthenticated, loading }

class SmartAuthService {
  static final SmartAuthService _instance = SmartAuthService._internal();
  factory SmartAuthService() => _instance;
  SmartAuthService._internal();

  // Services
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Firebase instances (only for web/mobile)
  static final bool _isFirebaseSupported = kIsWeb || !(defaultTargetPlatform == TargetPlatform.linux || 
                                                     defaultTargetPlatform == TargetPlatform.windows ||
                                                     defaultTargetPlatform == TargetPlatform.macOS);
  
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  AadOAuth? _microsoftOAuth;
  
  // State management
  AuthMode _currentMode = AuthMode.auto;
  String? _offlineUser;
  String? _authenticatedUser;
  AuthStatus _authStatus = AuthStatus.unauthenticated;
  
  final StreamController<AuthStatus> _authStatusController = StreamController<AuthStatus>.broadcast();
  final StreamController<String> _userController = StreamController<String>.broadcast();
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _firebaseAuthSubscription;
  
  // Getters
  AuthMode get currentMode => _currentMode;
  bool get isOnline => _connectivityService.isOnline;
  bool get isOfflineMode => _currentMode == AuthMode.offline || (!isOnline && _currentMode == AuthMode.auto);
  AuthStatus get authStatus => _authStatus;
  String? get currentUser => isOfflineMode ? _offlineUser : _authenticatedUser;
  
  // Streams
  Stream<AuthStatus> get authStatusStream => _authStatusController.stream;
  Stream<String> get userStream => _userController.stream;
  
  // Initialize the service
  Future<void> initialize() async {
    await _connectivityService.initialize();
    
    // Initialize Firebase if supported and online
    if (_isFirebaseSupported) {
      _auth = FirebaseAuth.instance;
      _googleSignIn = GoogleSignIn();
      
      // Microsoft OAuth setup
      _microsoftOAuth = AadOAuth(Config(
        tenant: AppConfig.microsoftTenant,
        clientId: AppConfig.microsoftClientId,
        scope: AppConfig.microsoftScope,
        redirectUri: AppConfig.microsoftRedirectUri,
        navigatorKey: GlobalKey<NavigatorState>(),
      ));
      
      // Listen to Firebase auth changes
      _firebaseAuthSubscription = _auth!.authStateChanges().listen((User? user) {
        if (!isOfflineMode) {
          _authenticatedUser = user?.email;
          _updateAuthStatus();
        }
      });
    }
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((bool isOnline) {
      _handleConnectivityChange(isOnline);
    });
    
    // Set initial auth status
    _updateAuthStatus();
  }
  
  // Handle connectivity changes
  void _handleConnectivityChange(bool isOnline) {
    if (_currentMode == AuthMode.auto) {
      if (!isOnline && _authenticatedUser != null) {
        // Switch to offline mode but keep user session
        _offlineUser = _authenticatedUser;
      } else if (isOnline && _offlineUser != null) {
        // Back online - try to restore Firebase session
        _tryRestoreOnlineSession();
      }
      _updateAuthStatus();
    }
  }
  
  // Try to restore online session when connectivity returns
  Future<void> _tryRestoreOnlineSession() async {
    if (_isFirebaseSupported && _auth?.currentUser != null) {
      _authenticatedUser = _auth!.currentUser!.email;
      _offlineUser = null;
    }
  }
  
  // Update authentication status
  void _updateAuthStatus() {
    final String? user = currentUser;
    final AuthStatus newStatus = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    
    if (_authStatus != newStatus) {
      _authStatus = newStatus;
      _authStatusController.add(_authStatus);
    }
    
    if (user != null) {
      _userController.add(user);
    }
  }
  
  // Set authentication mode
  void setAuthMode(AuthMode mode) {
    _currentMode = mode;
    _updateAuthStatus();
  }
  
  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _authStatus = AuthStatus.loading;
      _authStatusController.add(_authStatus);
      
      if (isOfflineMode) {
        // Offline simulation
        _offlineUser = 'offline.user@gmail.com';
        _updateAuthStatus();
        return true;
      }
      
      if (_isFirebaseSupported && _googleSignIn != null) {
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
        if (googleUser == null) return false;
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        await _auth!.signInWithCredential(credential);
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      _updateAuthStatus();
      return false;
    }
  }
  
  // Sign in with Microsoft
  Future<bool> signInWithMicrosoft() async {
    try {
      _authStatus = AuthStatus.loading;
      _authStatusController.add(_authStatus);
      
      if (isOfflineMode) {
        // Offline simulation
        _offlineUser = 'offline.user@outlook.com';
        _updateAuthStatus();
        return true;
      }
      
      if (_isFirebaseSupported && _microsoftOAuth != null) {
        await _microsoftOAuth!.login();
        final String? accessToken = await _microsoftOAuth!.getAccessToken();
        
        if (accessToken != null) {
          final AuthCredential credential = OAuthProvider("microsoft.com").credential(
            accessToken: accessToken,
            idToken: accessToken,
          );
          await _auth!.signInWithCredential(credential);
          return true;
        }
      }
      
      return false;
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
    try {
      if (_isFirebaseSupported && !isOfflineMode) {
        await _auth?.signOut();
        await _googleSignIn?.signOut();
        await _microsoftOAuth?.logout();
      }
      
      _authenticatedUser = null;
      _offlineUser = null;
      _updateAuthStatus();
    } catch (e) {
      if (kDebugMode) {
        print('Sign-Out Error: $e');
      }
    }
  }
  
  // Skip authentication (go to offline mode)
  void skipAuthentication() {
    _offlineUser = 'guest.user';
    _updateAuthStatus();
  }
  
  // Get status info for UI
  String getStatusInfo() {
    if (isOfflineMode) {
      return isOnline ? 'Offline Mode' : 'No Internet - Offline Mode';
    } else {
      return 'Online Mode - Firebase Auth';
    }
  }
  
  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _firebaseAuthSubscription?.cancel();
    _authStatusController.close();
    _userController.close();
    _connectivityService.dispose();
  }
}