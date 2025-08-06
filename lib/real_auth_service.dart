import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class RealUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider;

  RealUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  factory RealUser.fromFirebaseUser(User firebaseUser) {
    return RealUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      provider: 'google',
    );
  }

  factory RealUser.fromGoogleUser(Map<String, dynamic> userData) {
    return RealUser(
      id: userData['id'] ?? userData['sub'] ?? '',
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      photoUrl: userData['picture'],
      provider: 'google',
    );
  }

  factory RealUser.fromMicrosoftUser(Map<String, dynamic> userData) {
    return RealUser(
      id: userData['id'] ?? userData['oid'] ?? '',
      email: userData['mail'] ?? userData['userPrincipalName'] ?? '',
      name: userData['displayName'] ?? '',
      photoUrl: null, // Microsoft Graph API photo would require additional call
      provider: 'microsoft',
    );
  }
}

class RealAuthService {
  static final RealAuthService _instance = RealAuthService._internal();
  factory RealAuthService() => _instance;
  RealAuthService._internal();

  // Check if we're on desktop
  bool get _isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS
  );

  // Current user
  RealUser? _currentUser;
  RealUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Stream controllers
  final StreamController<RealUser?> _authController = StreamController<RealUser?>.broadcast();
  
  // Azure AD OAuth configuration
  late final AadOAuth _aadOAuth;

  Stream<RealUser?> get authStateChanges {
    if (!_isDesktop) {
      // Mobile/Web - use Firebase
      return FirebaseAuth.instance.authStateChanges().map((user) {
        if (user != null) {
          _currentUser = RealUser.fromFirebaseUser(user);
          return _currentUser;
        } else {
          _currentUser = null;
          return null;
        }
      });
    } else {
      // Desktop - use custom OAuth implementations
      Future.microtask(() => _authController.add(_currentUser));
      return _authController.stream;
    }
  }

  void _initMicrosoftOAuth() {
    final Config config = Config(
      tenant: 'common', // Use 'common' for multi-tenant or your specific tenant ID
      clientId: '56fe33c3-6a96-4dde-948b-1bcf1aa17364', // Your Azure AD app client ID
      scope: 'openid profile email User.Read',
      redirectUri: 'msal56fe33c3-6a96-4dde-948b-1bcf1aa17364://auth',
      navigatorKey: GlobalKey<NavigatorState>(),
    );
    
    _aadOAuth = AadOAuth(config);
  }

  // Google OAuth for Desktop using OAuth 2.0 flow
  Future<RealUser?> signInWithGoogleDesktop() async {
    try {
      if (kDebugMode) print('Starting Google Desktop OAuth...');
      
      // Google OAuth 2.0 endpoints - you need to replace this with your actual Google Client ID
      const String clientId = '979447508831-qo76h1jvjq1g4pn3uqpq2s9qa1h9q8r7.apps.googleusercontent.com';
      const String redirectUri = 'http://localhost:8080/auth/callback';
      const String scope = 'openid email profile';
      
      // Build authorization URL
      final String authUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
          '?client_id=$clientId'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&scope=${Uri.encodeComponent(scope)}'
          '&response_type=code'
          '&access_type=offline'
          '&prompt=consent';

      if (kDebugMode) print('Opening browser for Google OAuth...');
      
      // Launch browser
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch browser for authentication');
      }

      // Start local server to receive callback
      final authCode = await _startLocalServer();
      
      if (authCode == null) {
        throw Exception('Authorization cancelled by user');
      }

      if (kDebugMode) print('Received authorization code, exchanging for tokens...');

      // Exchange authorization code for tokens
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': '', // For desktop apps, client secret might be empty
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

      if (kDebugMode) print('Got access token, fetching user info...');

      // Get user info
      final userResponse = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get user info: ${userResponse.body}');
      }

      final userData = json.decode(userResponse.body);
      _currentUser = RealUser.fromGoogleUser(userData);
      _authController.add(_currentUser);

      if (kDebugMode) print('Google OAuth successful for user: ${_currentUser!.email}');
      return _currentUser;

    } catch (e) {
      if (kDebugMode) print('Google Desktop OAuth error: $e');
      rethrow;
    }
  }

  // Microsoft OAuth for Desktop
  Future<RealUser?> signInWithMicrosoftDesktop() async {
    try {
      if (kDebugMode) print('Starting Microsoft Desktop OAuth...');
      
      _initMicrosoftOAuth();
      
      // Perform OAuth login
      final result = await _aadOAuth.login();
      
      if (result == null) {
        throw Exception('Microsoft OAuth failed - no result returned');
      }

      if (kDebugMode) print('Microsoft OAuth successful, getting user info...');

      // Handle OAuth result properly
      String? accessToken;
      result.fold(
        (failure) => throw Exception('Microsoft OAuth failed: ${failure.toString()}'),
        (token) => accessToken = token.accessToken,
      );

      if (accessToken == null) {
        throw Exception('Failed to get access token from Microsoft OAuth');
      }

      // Get user information from Microsoft Graph
      final userResponse = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get Microsoft user info: ${userResponse.body}');
      }

      final userData = json.decode(userResponse.body);
      _currentUser = RealUser.fromMicrosoftUser(userData);
      _authController.add(_currentUser);

      if (kDebugMode) print('Microsoft OAuth successful for user: ${_currentUser!.email}');
      return _currentUser;

    } catch (e) {
      if (kDebugMode) print('Microsoft Desktop OAuth error: $e');
      rethrow;
    }
  }

  // Firebase Google Sign-In for Mobile/Web
  Future<RealUser?> signInWithGoogleMobile() async {
    if (_isDesktop) return null;

    try {
      if (kDebugMode) print('Starting Firebase Google OAuth...');
      
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
        _currentUser = RealUser.fromFirebaseUser(userCredential.user!);
        if (kDebugMode) print('Firebase Google OAuth successful for user: ${_currentUser!.email}');
        return _currentUser;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Firebase Google OAuth error: $e');
      rethrow;
    }
  }

  // Main sign-in methods that choose the right implementation
  Future<RealUser?> signInWithGoogle() async {
    if (_isDesktop) {
      return await signInWithGoogleDesktop();
    } else {
      return await signInWithGoogleMobile();
    }
  }

  Future<RealUser?> signInWithMicrosoft() async {
    if (_isDesktop) {
      return await signInWithMicrosoftDesktop();
    } else {
      throw UnimplementedError('Microsoft Sign-In for mobile/web requires Firebase configuration');
    }
  }

  // Helper method to start local server for OAuth callback
  Future<String?> _startLocalServer() async {
    final completer = Completer<String?>();
    
    try {
      final server = await HttpServer.bind('localhost', 8080);
      if (kDebugMode) print('Local server started on http://localhost:8080');
      
      server.listen((request) {
        if (request.uri.path == '/auth/callback') {
          final code = request.uri.queryParameters['code'];
          
          // Send response to browser
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write('''
              <!DOCTYPE html>
              <html>
                <head><title>Authentication Complete</title></head>
                <body>
                  <h1>✅ Authentication Successful!</h1>
                  <p>You can now close this window and return to the TODO-APP.</p>
                  <script>window.close();</script>
                </body>
              </html>
            ''')
            ..close();
          
          server.close();
          completer.complete(code);
        }
      });
      
      // Timeout after 5 minutes
      Timer(const Duration(minutes: 5), () {
        if (!completer.isCompleted) {
          server.close();
          completer.complete(null);
        }
      });
      
    } catch (e) {
      if (kDebugMode) print('Local server error: $e');
      completer.complete(null);
    }
    
    return completer.future;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!_isDesktop) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } else {
        // For desktop, we need to clear any stored tokens
        await _aadOAuth.logout();
      }
      
      _currentUser = null;
      _authController.add(null);
      
      if (kDebugMode) print('Sign out successful');
    } catch (e) {
      if (kDebugMode) print('Sign-Out error: $e');
    }
  }

  void dispose() {
    _authController.close();
  }
}