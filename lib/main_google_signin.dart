import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple OAuth Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _status = 'Ready to test OAuth';
  bool _isLoading = false;
  GoogleSignInAccount? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth Client Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client ID: 804059036502-aikvfenplv2hm7uvlpsbq0iml60udg0a.apps.googleusercontent.com',
                         style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 10),
                    Text('Status: $_status'),
                    if (_user != null) ...[
                      const SizedBox(height: 10),
                      Text('Signed in as: ${_user!.displayName}'),
                      Text('Email: ${_user!.email}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _testDirectGoogleSignIn,
                child: const Text('Test Direct Google Sign-In'),
              ),
              const SizedBox(height: 10),
              if (kIsWeb)
                const Text('Running on Web - Testing your OAuth client'),
              if (!kIsWeb)
                const Text('Running on Desktop - Testing your OAuth client'),
            ],
            const SizedBox(height: 20),
            if (_user != null)
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
          ],
        ),
      ),
    );
  }

  // Test direct Google Sign-In without Firebase
  Future<void> _testDirectGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing direct Google Sign-In...';
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? '804059036502-aikvfenplv2hm7uvlpsbq0iml60udg0a.apps.googleusercontent.com' : null,
        scopes: ['email', 'profile'],
      );

      print('🔍 Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _status = 'User cancelled sign-in');
        return;
      }

      setState(() {
        _user = googleUser;
        _status = 'Success! Signed in as ${googleUser.displayName}';
      });
      print('✅ Google Sign-In successful: ${googleUser.email}');

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      print('❌ Google Sign-In error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await GoogleSignIn().signOut();
    setState(() {
      _user = null;
      _status = 'Signed out';
    });
  }
}