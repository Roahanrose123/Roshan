import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

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

  factory GoogleUser.fromGoogleUserData(Map<String, dynamic> userData) {
    return GoogleUser(
      id: userData['id'] ?? userData['sub'] ?? '',
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      photoUrl: userData['picture'],
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

  // Google OAuth for Desktop using OAuth 2.0 flow
  Future<GoogleUser?> signInWithGoogleDesktop() async {
    try {
      if (kDebugMode) print('🔐 Starting Google Desktop OAuth...');
      
      // Google OAuth 2.0 configuration - Working OAuth client ID  
      const String clientId = '804059036502-aikvfenplv2hm7uvlpsbq0iml60udg0a.apps.googleusercontent.com';
      const String redirectUri = 'http://localhost:8081/auth/callback';
      const String scope = 'openid email profile';
      
      // Build authorization URL
      final String authUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
          '?client_id=$clientId'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&scope=${Uri.encodeComponent(scope)}'
          '&response_type=code'
          '&access_type=offline'
          '&prompt=consent';

      if (kDebugMode) print('🌐 Opening browser for Google OAuth...');
      
      // Launch browser
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch browser for Google authentication');
      }

      // Start local server to receive callback
      final authCode = await _startLocalServer();
      
      if (authCode == null) {
        throw Exception('Google authentication was cancelled by user');
      }

      if (kDebugMode) print('✅ Received authorization code, exchanging for tokens...');

      // Exchange authorization code for tokens
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': '', // For desktop apps, client secret is typically empty
          'code': authCode,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Token exchange failed: ${tokenResponse.body}');
      }

      final tokenData = json.decode(tokenResponse.body);
      final accessToken = tokenData['access_token'];

      if (kDebugMode) print('🔑 Got access token, fetching user profile...');

      // Get user profile information
      final userResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get Google user profile: ${userResponse.body}');
      }

      final userData = json.decode(userResponse.body);
      _currentUser = GoogleUser.fromGoogleUserData(userData);
      _authController.add(_currentUser);

      if (kDebugMode) print('🎉 Google OAuth successful for user: ${_currentUser!.email}');
      return _currentUser;

    } catch (e) {
      if (kDebugMode) print('❌ Google Desktop OAuth error: $e');
      rethrow;
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

  // Firebase Google Sign-In for Mobile
  Future<GoogleUser?> signInWithGoogleMobile() async {
    if (_isDesktop || kIsWeb) return null;

    try {
      if (kDebugMode) print('🔐 Starting Firebase Mobile OAuth...');
      
      // For mobile, use GoogleSignIn package
      if (kDebugMode) print('📱 Using GoogleSignIn for mobile...');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
        
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          if (kDebugMode) print('ℹ️  Google sign-in cancelled by user');
          return null; // User cancelled
        }

        if (kDebugMode) print('✅ Google Sign-In successful, getting authentication...');
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        if (kDebugMode) print('🔑 Creating Firebase credential...');
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        if (kDebugMode) print('🔥 Signing in with Firebase...');
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        if (userCredential.user != null) {
          _currentUser = GoogleUser.fromFirebaseUser(userCredential.user!);
          if (kDebugMode) print('🎉 Firebase Google OAuth successful for user: ${_currentUser!.email}');
          return _currentUser;
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Google OAuth error: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      rethrow;
    }
  }

  // Main sign-in method that chooses the right implementation
  Future<GoogleUser?> signInWithGoogle() async {
    if (kIsWeb) {
      // For web, use Firebase popup (works better with web OAuth client)
      return await signInWithGoogleWeb();
    } else if (_isDesktop) {
      // Use desktop OAuth flow for desktop only
      return await signInWithGoogleDesktop();
    } else {
      return await signInWithGoogleMobile();
    }
  }

  // Helper method to start local server for OAuth callback
  Future<String?> _startLocalServer() async {
    final completer = Completer<String?>();
    
    try {
      final server = await HttpServer.bind('localhost', 8081);
      if (kDebugMode) print('🌐 Local callback server started on http://localhost:8081');
      
      server.listen((request) async {
        if (request.uri.path == '/auth/callback') {
          final code = request.uri.queryParameters['code'];
          final error = request.uri.queryParameters['error'];
          
          // Send response to browser
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('''
              <!DOCTYPE html>
              <html>
                <head>
                  <title>Google Authentication</title>
                  <style>
                    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
                    .success { color: #4CAF50; }
                    .error { color: #f44336; }
                    .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 400px; margin: 0 auto; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    ${error == null ? '''
                      <h1 class="success">✅ Authentication Successful!</h1>
                      <p>You have successfully signed in with your Google account.</p>
                      <p><strong>You can now close this window and return to TODO-APP.</strong></p>
                    ''' : '''
                      <h1 class="error">❌ Authentication Failed</h1>
                      <p>There was an error signing in with Google: $error</p>
                      <p>Please try again.</p>
                    '''}
                  </div>
                  <script>
                    setTimeout(() => window.close(), 3000);
                  </script>
                </body>
              </html>
            ''')
            ..close();
          
          await server.close();
          completer.complete(error == null ? code : null);
        }
      });
      
      // Timeout after 5 minutes
      Timer(const Duration(minutes: 5), () async {
        if (!completer.isCompleted) {
          await server.close();
          completer.complete(null);
          if (kDebugMode) print('⏰ OAuth callback timeout after 5 minutes');
        }
      });
      
    } catch (e) {
      if (kDebugMode) print('❌ Local server error: $e');
      completer.complete(null);
    }
    
    return completer.future;
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