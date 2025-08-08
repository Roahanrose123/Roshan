#!/usr/bin/env dart

// Quick OAuth URL tester to check the exact issue
import 'dart:io';

void main() async {
  final client = HttpClient();
  
  // Your current OAuth URL parameters
  final clientId = '804059036502-ccsjaad5i8hf83m4igugtsc8qogmqtkc.apps.googleusercontent.com';
  final redirectUri = 'http://127.0.0.1:8081/auth/callback';
  final scope = 'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile openid';
  final state = 'test_${DateTime.now().millisecondsSinceEpoch}';
  
  final testUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'scope': scope,
    'response_type': 'code',
    'access_type': 'offline',
    'prompt': 'consent',
    'state': state,
  });
  
  print('🔗 Testing OAuth URL:');
  print('$testUrl\n');
  
  print('📋 Checking individual parameters:');
  print('✓ Client ID: ${clientId.length} characters');
  print('✓ Redirect URI: $redirectUri');
  print('✓ Scope: $scope');
  print('✓ State: $state');
  
  print('\n💡 Common fixes to try in Google Cloud Console:');
  print('1. Add both redirect URIs:');
  print('   - http://127.0.0.1:8081/auth/callback');
  print('   - http://localhost:8081/auth/callback');
  print('\n2. Check OAuth consent screen is configured');
  print('3. Ensure app is published or you\'re added as test user');
  print('4. Verify OAuth 2.0 Client ID is for "Desktop application" type');
  
  client.close();
}