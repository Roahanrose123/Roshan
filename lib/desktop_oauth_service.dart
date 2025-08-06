import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class GoogleUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  GoogleUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  factory GoogleUser.fromMap(Map<String, dynamic> map) {
    return GoogleUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['picture'],
    );
  }
}

class MicrosoftUser {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;

  MicrosoftUser({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  factory MicrosoftUser.fromMap(Map<String, dynamic> map) {
    return MicrosoftUser(
      id: map['id'] ?? '',
      email: map['mail'] ?? map['userPrincipalName'] ?? '',
      name: map['displayName'] ?? '',
      photoUrl: null, // Microsoft Graph API would need separate call for photo
    );
  }
}

class DesktopOAuthService {
  // Using a public client ID that works for testing (Google's own demo client)
  // In production, you would create your own OAuth 2.0 Client ID in Google Cloud Console
  static const String _googleClientId = '407408718192.apps.googleusercontent.com';
  static const String _googleAuthUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const String _googleTokenUrl = 'https://oauth2.googleapis.com/token';
  static const String _googleUserInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';
  
  static const String _microsoftClientId = '56fe33c3-6a96-4dde-948b-1bcf1aa17364';
  static const String _microsoftAuthUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const String _microsoftTokenUrl = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  static const String _microsoftUserInfoUrl = 'https://graph.microsoft.com/v1.0/me';
  
  HttpServer? _redirectServer;
  String? _accessToken;
  GoogleUser? _currentGoogleUser;
  MicrosoftUser? _currentMicrosoftUser;

  GoogleUser? get currentGoogleUser => _currentGoogleUser;
  MicrosoftUser? get currentMicrosoftUser => _currentMicrosoftUser;
  bool get isSignedIn => _currentGoogleUser != null || _currentMicrosoftUser != null;
  
  String get currentUserEmail {
    return _currentGoogleUser?.email ?? _currentMicrosoftUser?.email ?? 'Unknown';
  }
  
  String get currentUserName {
    return _currentGoogleUser?.name ?? _currentMicrosoftUser?.name ?? 'Unknown User';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<GoogleUser?> signInWithGoogle() async {
    try {
      // Generate PKCE parameters
      final codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateRandomString(32);

      // Start local HTTP server for redirect
      _redirectServer = await HttpServer.bind('localhost', 0);
      final redirectUri = 'http://localhost:${_redirectServer!.port}/auth';

      // Build authorization URL
      final authUrl = Uri.parse(_googleAuthUrl).replace(queryParameters: {
        'client_id': _googleClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      });

      if (kDebugMode) {
        print('Authorization URL: $authUrl');
      }

      // Launch browser
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl);
      } else {
        throw Exception('Could not launch browser');
      }

      // Listen for redirect
      final completer = Completer<String?>();
      late StreamSubscription subscription;
      
      subscription = _redirectServer!.listen((HttpRequest request) async {
        final uri = request.uri;
        
        // Send response to browser
        request.response.headers.set('content-type', 'text/html');
        request.response.write('''
          <html>
            <head><title>Authentication Success</title></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
              <h2>✅ Authentication Successful!</h2>
              <p>You can now close this window and return to the application.</p>
              <script>setTimeout(() => window.close(), 2000);</script>
            </body>
          </html>
        ''');
        await request.response.close();

        // Process the authorization code
        if (uri.queryParameters.containsKey('code')) {
          final receivedState = uri.queryParameters['state'];
          if (receivedState != state) {
            completer.complete(null);
            return;
          }
          completer.complete(uri.queryParameters['code']);
        } else if (uri.queryParameters.containsKey('error')) {
          completer.complete(null);
        }
        
        subscription.cancel();
        _redirectServer?.close();
      });

      // Wait for authorization code
      final authCode = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          subscription.cancel();
          _redirectServer?.close();
          return null;
        },
      );

      if (authCode == null) {
        throw Exception('Authorization failed or cancelled');
      }

      // Exchange authorization code for access token
      final tokenResponse = await http.post(
        Uri.parse(_googleTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _googleClientId,
          'code': authCode,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Token exchange failed: ${tokenResponse.body}');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      _accessToken = tokenData['access_token'];

      if (_accessToken == null) {
        throw Exception('No access token received');
      }

      // Get user info
      final userResponse = await http.get(
        Uri.parse(_googleUserInfoUrl),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get user info: ${userResponse.body}');
      }

      final userData = jsonDecode(userResponse.body);
      _currentGoogleUser = GoogleUser.fromMap(userData);
      _currentMicrosoftUser = null; // Clear Microsoft user

      if (kDebugMode) {
        print('Google Sign-In successful: ${_currentGoogleUser!.email}');
      }

      return _currentGoogleUser;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In error: $e');
      }
      _redirectServer?.close();
      rethrow;
    }
  }

  Future<MicrosoftUser?> signInWithMicrosoft() async {
    try {
      // Generate PKCE parameters
      final codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final state = _generateRandomString(32);

      // Start local HTTP server for redirect
      _redirectServer = await HttpServer.bind('localhost', 0);
      final redirectUri = 'http://localhost:${_redirectServer!.port}/auth';

      // Build authorization URL
      final authUrl = Uri.parse(_microsoftAuthUrl).replace(queryParameters: {
        'client_id': _microsoftClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile User.Read',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      });

      if (kDebugMode) {
        print('Microsoft Authorization URL: $authUrl');
      }

      // Launch browser
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl);
      } else {
        throw Exception('Could not launch browser');
      }

      // Listen for redirect
      final completer = Completer<String?>();
      late StreamSubscription subscription;
      
      subscription = _redirectServer!.listen((HttpRequest request) async {
        final uri = request.uri;
        
        // Send response to browser
        request.response.headers.set('content-type', 'text/html');
        request.response.write('''
          <html>
            <head><title>Microsoft Authentication Success</title></head>
            <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
              <h2>✅ Microsoft Authentication Successful!</h2>
              <p>You can now close this window and return to the application.</p>
              <script>setTimeout(() => window.close(), 2000);</script>
            </body>
          </html>
        ''');
        await request.response.close();

        // Process the authorization code
        if (uri.queryParameters.containsKey('code')) {
          final receivedState = uri.queryParameters['state'];
          if (receivedState != state) {
            completer.complete(null);
            return;
          }
          completer.complete(uri.queryParameters['code']);
        } else if (uri.queryParameters.containsKey('error')) {
          completer.complete(null);
        }
        
        subscription.cancel();
        _redirectServer?.close();
      });

      // Wait for authorization code
      final authCode = await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          subscription.cancel();
          _redirectServer?.close();
          return null;
        },
      );

      if (authCode == null) {
        throw Exception('Microsoft authorization failed or cancelled');
      }

      // Exchange authorization code for access token
      final tokenResponse = await http.post(
        Uri.parse(_microsoftTokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _microsoftClientId,
          'code': authCode,
          'code_verifier': codeVerifier,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Microsoft token exchange failed: ${tokenResponse.body}');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      _accessToken = tokenData['access_token'];

      if (_accessToken == null) {
        throw Exception('No Microsoft access token received');
      }

      // Get user info
      final userResponse = await http.get(
        Uri.parse(_microsoftUserInfoUrl),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get Microsoft user info: ${userResponse.body}');
      }

      final userData = jsonDecode(userResponse.body);
      _currentMicrosoftUser = MicrosoftUser.fromMap(userData);
      _currentGoogleUser = null; // Clear Google user

      if (kDebugMode) {
        print('Microsoft Sign-In successful: ${_currentMicrosoftUser!.email}');
      }

      return _currentMicrosoftUser;
    } catch (e) {
      if (kDebugMode) {
        print('Microsoft Sign-In error: $e');
      }
      _redirectServer?.close();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _accessToken = null;
    _currentGoogleUser = null;
    _currentMicrosoftUser = null;
    _redirectServer?.close();
  }
}