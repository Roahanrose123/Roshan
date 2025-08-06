import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for web
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const WebTestApp());
}

class WebTestApp extends StatelessWidget {
  const WebTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Web OAuth Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebTestScreen(),
    );
  }
}

class WebTestScreen extends StatefulWidget {
  const WebTestScreen({super.key});

  @override
  State<WebTestScreen> createState() => _WebTestScreenState();
}

class _WebTestScreenState extends State<WebTestScreen> {
  String _status = 'Ready to test Firebase Web OAuth';
  bool _isLoading = false;
  User? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Web OAuth Test'),
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
                    Text('Using Firebase Web Authentication'),
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
                onPressed: _testFirebaseWebAuth,
                child: const Text('Test Firebase Web Auth'),
              ),
              const SizedBox(height: 10),
              const Text('This uses Firebase popup authentication (no redirect URIs needed)'),
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

  // Test Firebase Web Authentication (popup based)
  Future<void> _testFirebaseWebAuth() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase Web authentication...';
    });

    try {
      print('🔍 Starting Firebase Web Auth with popup...');
      
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      
      if (userCredential.user != null) {
        setState(() {
          _user = userCredential.user;
          _status = 'Success! Signed in with Firebase: ${userCredential.user!.displayName}';
        });
        print('✅ Firebase Web Auth successful: ${userCredential.user!.email}');
      } else {
        setState(() => _status = 'No user returned from Firebase');
      }

    } catch (e) {
      setState(() {
        _status = 'Firebase Web Auth Error: $e';
      });
      print('❌ Firebase Web Auth error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _user = null;
      _status = 'Signed out from Firebase';
    });
  }
}