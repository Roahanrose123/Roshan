import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'google_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (!kIsWeb) {
      print('🖥️  Running on desktop - skipping Firebase');
    } else {
      print('🌐 Initializing Firebase for web...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    }
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DebugScreen(),
    );
  }
}

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = false;
  String _status = 'Ready to test authentication';
  String _error = '';

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = !kIsWeb;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Authentication - ${isDesktop ? 'Desktop' : 'Web'}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform: ${isDesktop ? 'Desktop' : 'Web'}',
                      style: GoogleFonts.mono(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'kIsWeb: $kIsWeb',
                      style: GoogleFonts.mono(),
                    ),
                    Text(
                      'Platform: ${defaultTargetPlatform}',
                      style: GoogleFonts.mono(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: GoogleFonts.lato(),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_error',
                        style: GoogleFonts.lato(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton.icon(
                onPressed: _testGoogleSignIn,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Google Sign-In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _showDebugInfo,
              child: const Text('Show Debug Info'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting Google Sign-In test...';
      _error = '';
    });

    try {
      print('🔍 Starting debug Google Sign-In...');
      setState(() => _status = 'Calling GoogleAuthService.signInWithGoogle()...');
      
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        setState(() {
          _status = 'SUCCESS! Signed in as: ${user.name} (${user.email})';
        });
        print('✅ Debug sign-in successful: ${user.email}');
      } else {
        setState(() {
          _status = 'Sign-in returned null (user cancelled?)';
        });
        print('ℹ️  Debug sign-in returned null');
      }
    } catch (e) {
      setState(() {
        _status = 'Sign-in failed';
        _error = e.toString();
      });
      print('❌ Debug sign-in error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDebugInfo() {
    final bool isDesktop = !kIsWeb;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Platform: ${isDesktop ? 'Desktop' : 'Web'}'),
              Text('kIsWeb: $kIsWeb'),
              Text('defaultTargetPlatform: $defaultTargetPlatform'),
              const SizedBox(height: 10),
              const Text('Authentication Service:'),
              Text('Service type: ${_authService.runtimeType}'),
              Text('Is signed in: ${_authService.isSignedIn}'),
              Text('Current user: ${_authService.currentUser?.email ?? 'null'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}