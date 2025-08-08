import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'env_config.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String provider;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.provider,
  });

  factory AuthUser.fromFirebaseUser(User firebaseUser) {
    return AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      provider: 'google',
    );
  }

  factory AuthUser.fromGoogleUserData(Map<String, dynamic> userData) {
    return AuthUser(
      id: userData['id'] ?? userData['sub'] ?? '',
      email: userData['email'] ?? '',
      name: userData['name'] ?? '',
      photoUrl: userData['picture'],
      provider: 'google',
    );
  }

  factory AuthUser.fromMicrosoftUserData(Map<String, dynamic> userData) {
    return AuthUser(
      id: userData['id'] ?? userData['sub'] ?? '',
      email: userData['mail'] ?? userData['userPrincipalName'] ?? userData['email'] ?? '',
      name: userData['displayName'] ?? userData['name'] ?? '',
      photoUrl: null, // Microsoft Graph API requires separate call for photo
      provider: 'microsoft',
    );
  }
}

// Keep GoogleUser as alias for backwards compatibility
typedef GoogleUser = AuthUser;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if we're on desktop
  bool get _isDesktop => !kIsWeb && (
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.macOS
  );

  // Current user
  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Stream controllers
  final StreamController<AuthUser?> _authController = StreamController<AuthUser?>.broadcast();
  
  Stream<AuthUser?> get authStateChanges {
    if (kIsWeb) {
      // Web - use Firebase
      return FirebaseAuth.instance.authStateChanges().map((user) {
        if (user != null) {
          _currentUser = AuthUser.fromFirebaseUser(user);
          return _currentUser;
        } else {
          _currentUser = null;
          return null;
        }
      });
    } else if (_isDesktop) {
      // Desktop - use custom OAuth implementation (unchanged)
      if (kDebugMode) {
        print('🔍 Desktop authStateChanges requested, current user: ${_currentUser?.email}');
      }
      // Always emit current state when stream is accessed
      Future.microtask(() {
        if (kDebugMode) {
          print('🔄 Emitting current auth state: ${_currentUser?.email}');
        }
        _authController.add(_currentUser);
      });
      return _authController.stream;
    } else {
      // Mobile - use custom stream only (simplified)
      if (kDebugMode) {
        print('📱 Mobile authStateChanges requested, current user: ${_currentUser?.email}');
      }
      
      // Always emit current state for mobile
      Future.microtask(() {
        if (kDebugMode) {
          print('🔄 Emitting current mobile auth state: ${_currentUser?.email}');
        }
        _authController.add(_currentUser);
      });
      
      return _authController.stream;
    }
  }

  // Main sign-in methods
  Future<AuthUser?> signInWithGoogle() async {
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

  Future<AuthUser?> signInWithMicrosoft() async {
    if (kIsWeb) {
      throw UnimplementedError('Microsoft web authentication not implemented yet');
    } else if (_isDesktop) {
      // Use desktop OAuth flow for Microsoft (unchanged)
      return await signInWithMicrosoftDesktop();
    } else {
      // Mobile only: Use aad_oauth for Microsoft authentication
      return await signInWithMicrosoftMobile();
    }
  }

  // Web-specific Google Sign-In using Firebase
  Future<AuthUser?> signInWithGoogleWeb() async {
    try {
      if (kDebugMode) print('🌐 Starting Firebase Web OAuth...');
      
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      if (userCredential.user != null) {
        _currentUser = AuthUser.fromFirebaseUser(userCredential.user!);
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

  // Desktop OAuth implementation - real browser-based OAuth like web
  Future<AuthUser?> signInWithGoogleDesktop() async {
    try {
      if (kDebugMode) print('🔐 Starting Google Desktop OAuth...');
      
      // Use your desktop application client ID from environment
      final String clientId = EnvConfig.googleClientIdDesktop.isNotEmpty 
          ? EnvConfig.googleClientIdDesktop 
          : 'YOUR_GOOGLE_CLIENT_ID_DESKTOP'; // fallback - replace with actual value
      const String redirectUri = 'http://localhost:8081/auth/callback';
      const String scope = 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile openid';
      
      // Build authorization URL with proper formatting
      final Map<String, String> queryParams = {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope': scope,
        'response_type': 'code',
        'access_type': 'offline',
        'prompt': 'consent',
        'state': 'desktop_oauth_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      final String authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', queryParams).toString();

      if (kDebugMode) {
        print('🌐 Opening browser for Google OAuth...');
        print('🔗 Auth URL: $authUrl');
      }
      
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

      // Exchange authorization code for tokens with client secret
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': EnvConfig.googleClientSecret.isNotEmpty 
              ? EnvConfig.googleClientSecret 
              : 'YOUR_GOOGLE_CLIENT_SECRET', // fallback - replace with actual value
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
      _currentUser = AuthUser.fromGoogleUserData(userData);
      
      if (kDebugMode) {
        print('🎉 Google OAuth successful for user: ${_currentUser!.email}');
        print('📤 Adding user to auth stream controller');
      }
      
      _authController.add(_currentUser);
      return _currentUser;

    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Desktop OAuth error: $e');
        if (e.toString().contains('XMLHttpRequest error')) {
          print('💡 Tip: This might be a CORS issue. Make sure redirect URI is configured in Google Cloud Console.');
        }
      }
      
      // Provide user-friendly error messages
      if (e.toString().contains('invalid_request')) {
        throw Exception('OAuth configuration error. Please check Google Cloud Console settings.');
      } else if (e.toString().contains('access_denied')) {
        throw Exception('Access denied. Please try again and grant permissions.');
      } else if (e.toString().contains('Network')) {
        throw Exception('Network error. Please check your internet connection.');
      }
      
      rethrow;
    }
  }

  // Microsoft Desktop OAuth implementation with PKCE
  Future<AuthUser?> signInWithMicrosoftDesktop() async {
    try {
      if (kDebugMode) print('🔐 Starting Microsoft Desktop OAuth with PKCE...');
      
      // Microsoft OAuth configuration from environment
      final String clientId = EnvConfig.microsoftClientId.isNotEmpty 
          ? EnvConfig.microsoftClientId 
          : 'YOUR_MICROSOFT_CLIENT_ID'; // fallback - replace with actual value
      const String redirectUri = 'http://localhost:8086/auth/callback';
      const String scope = 'openid profile email User.Read';
      
      // Generate PKCE parameters for Microsoft (keeping PKCE for extra security)
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      
      if (kDebugMode) print('🔒 Generated PKCE challenge for Microsoft authentication');
      
      // Build Microsoft authorization URL with PKCE
      final String authUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize'
          '?client_id=$clientId'
          '&response_type=code'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&scope=${Uri.encodeComponent(scope)}'
          '&response_mode=query'
          '&code_challenge=$codeChallenge'
          '&code_challenge_method=S256'
          '&prompt=consent';

      if (kDebugMode) print('🌐 Opening browser for Microsoft OAuth...');
      
      // Launch browser
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch browser for Microsoft authentication');
      }

      // Start local server to receive callback
      final authCode = await _startMicrosoftLocalServer();
      
      if (authCode == null) {
        throw Exception('Microsoft authentication was cancelled by user');
      }

      if (kDebugMode) print('✅ Received Microsoft authorization code, exchanging for tokens with PKCE...');

      // Exchange authorization code for tokens using PKCE
      final tokenResponse = await http.post(
        Uri.parse('https://login.microsoftonline.com/common/oauth2/v2.0/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'code': authCode,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'scope': scope,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Microsoft token exchange failed: ${tokenResponse.body}');
      }

      final tokenData = json.decode(tokenResponse.body);
      final accessToken = tokenData['access_token'];

      if (kDebugMode) print('🔑 Got Microsoft access token, fetching user profile...');

      // Get user profile information from Microsoft Graph
      final userResponse = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get Microsoft user profile: ${userResponse.body}');
      }

      final userData = json.decode(userResponse.body);
      _currentUser = AuthUser.fromMicrosoftUserData(userData);
      
      if (kDebugMode) {
        print('🎉 Microsoft OAuth successful for user: ${_currentUser!.email}');
        print('📤 Adding Microsoft user to auth stream controller');
      }
      
      _authController.add(_currentUser);
      return _currentUser;

    } catch (e) {
      if (kDebugMode) print('❌ Microsoft Desktop OAuth error: $e');
      rethrow;
    }
  }

  // Mobile OAuth - Enhanced with better error handling
  Future<AuthUser?> signInWithGoogleMobile() async {
    try {
      if (kDebugMode) print('📱 Starting Mobile Google Sign-In...');
      
      // Use GoogleSignIn with proper configuration
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
        // Add client ID for better compatibility from environment
        clientId: kIsWeb ? null : (EnvConfig.googleClientIdMobile.isNotEmpty 
            ? EnvConfig.googleClientIdMobile 
            : 'YOUR_GOOGLE_CLIENT_ID_MOBILE'), // fallback - replace with actual value
      );
      
      // Clear any previous sign-in state
      try {
        await googleSignIn.signOut();
        if (kDebugMode) print('🧹 Cleared previous sign-in state');
      } catch (e) {
        if (kDebugMode) print('⚠️  Could not clear previous state: $e');
      }
      
      if (kDebugMode) print('🔐 Attempting Google sign-in...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        if (kDebugMode) print('ℹ️  Google sign-in cancelled by user');
        return null;
      }

      if (kDebugMode) print('✅ Google sign-in successful, creating AuthUser...');
      
      // Create AuthUser directly
      _currentUser = AuthUser(
        id: googleUser.id,
        email: googleUser.email,
        name: googleUser.displayName ?? 'User',
        photoUrl: googleUser.photoUrl,
        provider: 'google',
      );
      
      if (kDebugMode) print('🎉 Mobile Google authentication successful for user: ${_currentUser!.email}');
      
      // Emit auth state change
      _authController.add(_currentUser);
      return _currentUser;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Mobile Google Sign-In error: $e');
        print('Error type: ${e.runtimeType}');
      }
      
      // Show helpful error messages based on error type
      if (e.toString().contains('DEVELOPER_ERROR') || e.toString().contains('10')) {
        throw Exception(
          'Google Sign-In Setup Required!\n\n'
          'This app requires Google Sign-In configuration in Google Cloud Console.\n'
          'The developer needs to add the app\'s SHA-1 fingerprint.\n\n'
          'For now, you can try the demo mode or contact support.'
        );
      } else if (e.toString().contains('network_error')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Sign-in was cancelled.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Google Sign-in failed. Please try again.');
      } else {
        throw Exception('Authentication failed: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  // Microsoft Mobile OAuth - Simplified using URL launcher
  Future<AuthUser?> signInWithMicrosoftMobile() async {
    try {
      if (kDebugMode) print('📱 Starting Microsoft Mobile Sign-In...');
      
      // For now, show a user-friendly message that Microsoft auth on mobile requires setup
      // In production, you'd implement proper deep linking or WebView
      throw Exception(
        'Microsoft Sign-In on mobile is currently in development.\n\n'
        'Please use Google Sign-In on mobile, or use Microsoft Sign-In on desktop.\n\n'
        'Both accounts will sync your data across devices!'
      );
      
    } catch (e) {
      if (kDebugMode) print('❌ Microsoft Mobile Sign-In: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (kDebugMode) print('🔓 Signing out...');
      
      if (kIsWeb) {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } else if (!_isDesktop) {
        // Mobile sign out
        await GoogleSignIn().signOut();
      }
      
      _currentUser = null;
      _authController.add(null);
      
      if (kDebugMode) print('✅ Sign out successful');
    } catch (e) {
      if (kDebugMode) print('❌ Sign-out error: $e');
    }
  }

  // Helper method to start Microsoft local server for OAuth callback
  Future<String?> _startMicrosoftLocalServer() async {
    final completer = Completer<String?>();
    
    try {
      final server = await HttpServer.bind('localhost', 8086);
      if (kDebugMode) print('🌐 Microsoft callback server started on http://localhost:8086');
      
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
                  <title>Microsoft Authentication</title>
                  <style>
                    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
                    .success { color: #4CAF50; }
                    .error { color: #f44336; }
                    .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 400px; margin: 0 auto; }
                    .microsoft { color: #0078d4; }
                  </style>
                </head>
                <body>
                  <div class="container">
                    ${error == null ? '''
                      <h1 class="success">✅ Microsoft Authentication Successful!</h1>
                      <p>You have successfully signed in with your <span class="microsoft">Microsoft account</span>.</p>
                      <p><strong>You can now close this window and return to TODO-APP.</strong></p>
                    ''' : '''
                      <h1 class="error">❌ Authentication Failed</h1>
                      <p>There was an error signing in with Microsoft: $error</p>
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
          if (kDebugMode) print('⏰ Microsoft OAuth callback timeout after 5 minutes');
        }
      });
      
    } catch (e) {
      if (kDebugMode) print('❌ Microsoft local server error: $e');
      completer.complete(null);
    }
    
    return completer.future;
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
          final errorDescription = request.uri.queryParameters['error_description'];
          
          if (kDebugMode) {
            print('🔍 Google OAuth callback received:');
            print('  - Code: ${code != null ? "✅ Present" : "❌ Missing"}');
            print('  - Error: ${error ?? "None"}');
            print('  - Description: ${errorDescription ?? "None"}');
            print('  - Full query: ${request.uri.query}');
          }
          
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

  // PKCE helper methods for secure desktop OAuth
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(128, (i) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  void dispose() {
    _authController.close();
  }
}

// Backwards compatibility alias
typedef GoogleAuthService = AuthService;