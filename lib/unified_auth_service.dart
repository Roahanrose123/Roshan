import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';


class UnifiedUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider; // 'google', 'microsoft', 'firebase'

  UnifiedUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  factory UnifiedUser.fromFirebaseUser(User firebaseUser) {
    return UnifiedUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      provider: 'firebase',
    );
  }

  factory UnifiedUser.fromDesktopAuth(String email, String name, String provider) {
    return UnifiedUser(
      id: email.hashCode.toString(), // Simple ID generation
      email: email,
      name: name,
      photoUrl: null,
      provider: provider,
    );
  }
}

class UnifiedAuthService {
  static final UnifiedAuthService _instance = UnifiedAuthService._internal();
  factory UnifiedAuthService() => _instance;
  UnifiedAuthService._internal();

  FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;
  StreamController<UnifiedUser?>? _desktopAuthController;

  FirebaseAuth? get firebaseAuth {
    if (_isFirebaseAvailable && _firebaseAuth == null) {
      _firebaseAuth = FirebaseAuth.instance;
    }
    return _firebaseAuth;
  }

  GoogleSignIn? get googleSignIn {
    if (_isFirebaseAvailable && _googleSignIn == null) {
      _googleSignIn = GoogleSignIn();
    }
    return _googleSignIn;
  }

  UnifiedUser? _currentUser;
  UnifiedUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Check if we're on a desktop platform
  bool get _isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS
  );

  // Check if Firebase is available (not on desktop)
  bool get _isFirebaseAvailable => !_isDesktop;

  Stream<UnifiedUser?> get authStateChanges {
    if (_isFirebaseAvailable && firebaseAuth != null) {
      return firebaseAuth!.authStateChanges().map((user) {
        if (user != null) {
          _currentUser = UnifiedUser.fromFirebaseUser(user);
          return _currentUser;
        } else {
          _currentUser = null;
          return null;
        }
      });
    } else {
      // For desktop, use a stream controller
      _desktopAuthController ??= StreamController<UnifiedUser?>.broadcast();
      
      // Start with current user if exists
      if (_currentUser != null) {
        // Add current user to stream immediately
        Future.microtask(() => _desktopAuthController?.add(_currentUser));
      }
      
      return _desktopAuthController!.stream.asBroadcastStream();
    }
  }

  // Desktop auth methods
  void signInWithDesktopAuth(String email, String name, String provider) {
    _currentUser = UnifiedUser.fromDesktopAuth(email, name, provider);
    _desktopAuthController?.add(_currentUser);
  }

  Future<UnifiedUser?> signInWithGoogle() async {
    try {
      if (_isDesktop) {
        // Desktop auth is handled by the UI layer
        throw Exception('Desktop auth should be handled by UI');
      } else {
        // Mobile/Web Firebase flow
        if (googleSignIn == null || firebaseAuth == null) {
          throw Exception('Firebase/Google Sign-In not available');
        }
        
        final GoogleSignInAccount? googleUser = await googleSignIn!.signIn();
        if (googleUser == null) {
          return null; // User cancelled
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await firebaseAuth!.signInWithCredential(credential);
        if (userCredential.user != null) {
          _currentUser = UnifiedUser.fromFirebaseUser(userCredential.user!);
          return _currentUser;
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In error: $e');
      }
      rethrow;
    }
  }

  Future<UnifiedUser?> signInWithMicrosoft() async {
    try {
      if (_isDesktop) {
        // Desktop auth is handled by the UI layer
        throw Exception('Desktop auth should be handled by UI');
      } else {
        // For mobile/web, you'd need to implement Microsoft auth via Firebase
        // This would require additional setup in Firebase console
        throw UnimplementedError('Microsoft Sign-In not implemented for mobile/web yet. Please implement Azure AD integration with Firebase.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Microsoft Sign-In error: $e');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (_isFirebaseAvailable) {
        await firebaseAuth?.signOut();
        await googleSignIn?.signOut();
      }
      
      _currentUser = null;
      _desktopAuthController?.add(null);
    } catch (e) {
      if (kDebugMode) {
        print('Sign-Out error: $e');
      }
    }
  }
}