import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized for web');
  }
  
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Google Auth Test',
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
  String _status = 'Ready to test';
  bool _isLoading = false;
  User? _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
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
                    Text('Platform: ${kIsWeb ? 'Web' : 'Desktop'}'),
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
                onPressed: _testMethod1,
                child: const Text('Test Method 1: Firebase Only'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _testMethod2,
                child: const Text('Test Method 2: GoogleSignIn + Firebase'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _testMethod3,
                child: const Text('Test Method 3: Simple GoogleSignIn'),
              ),
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

  // Method 1: Direct Firebase Auth
  Future<void> _testMethod1() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase Auth directly...';
    });

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      if (kIsWeb) {
        // For web, use popup
        final UserCredential result = await FirebaseAuth.instance.signInWithPopup(googleProvider);
        _handleAuthResult(result.user, 'Method 1 (Firebase popup)');
      } else {
        // For mobile, use redirect
        await FirebaseAuth.instance.signInWithProvider(googleProvider);
      }
    } catch (e) {
      setState(() {
        _status = 'Method 1 failed: $e';
      });
      print('❌ Method 1 error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method 2: GoogleSignIn + Firebase
  Future<void> _testMethod2() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing GoogleSignIn + Firebase...';
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      print('🔍 Calling googleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _status = 'Method 2: User cancelled');
        return;
      }

      print('✅ Got GoogleSignInAccount: ${googleUser.email}');
      setState(() => _status = 'Got Google account, getting Firebase credential...');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('✅ Got GoogleSignInAuthentication');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔥 Signing in with Firebase...');
      final UserCredential result = await FirebaseAuth.instance.signInWithCredential(credential);
      _handleAuthResult(result.user, 'Method 2 (GoogleSignIn + Firebase)');

    } catch (e) {
      setState(() {
        _status = 'Method 2 failed: $e';
      });
      print('❌ Method 2 error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method 3: Simple GoogleSignIn only
  Future<void> _testMethod3() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing simple GoogleSignIn...';
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      print('🔍 Simple GoogleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() => _status = 'Method 3: User cancelled');
        return;
      }

      setState(() {
        _status = 'Method 3 SUCCESS: ${googleUser.displayName} (${googleUser.email})';
      });
      print('✅ Simple GoogleSignIn successful: ${googleUser.email}');

    } catch (e) {
      setState(() {
        _status = 'Method 3 failed: $e';
      });
      print('❌ Method 3 error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleAuthResult(User? user, String method) {
    if (user != null) {
      setState(() {
        _user = user;
        _status = '$method SUCCESS: ${user.displayName} (${user.email})';
      });
      print('✅ $method successful: ${user.email}');
    } else {
      setState(() {
        _status = '$method: No user returned';
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      _user = null;
      _status = 'Signed out';
    });
  }
}