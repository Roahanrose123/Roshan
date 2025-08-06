import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimpleDesktopAuth extends StatefulWidget {
  final Function(String email, String name, String provider) onSignIn;
  
  const SimpleDesktopAuth({super.key, required this.onSignIn});

  @override
  State<SimpleDesktopAuth> createState() => _SimpleDesktopAuthState();
}

class _SimpleDesktopAuthState extends State<SimpleDesktopAuth> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In to TODO-APP'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Icon(
                    Icons.assignment,
                    size: 100,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'TODO-APP',
                    style: GoogleFonts.pacifico(
                      fontSize: 36,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Desktop Edition - Quick Sign In',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  
                  const Text(
                    'Enter your details to continue:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 30),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.teal)
                  else ...[
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'yourname@gmail.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Your Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Google Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _signIn('google'),
                        icon: const Icon(Icons.login, size: 24),
                        label: const Text(
                          'Continue with Google Account',
                          style: TextStyle(fontSize: 16)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Microsoft Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _signIn('microsoft'),
                        icon: const Icon(Icons.business, size: 24),
                        label: const Text(
                          'Continue with Microsoft Account',
                          style: TextStyle(fontSize: 16)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    // Guest Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _signIn('guest'),
                        icon: const Icon(Icons.person, size: 24),
                        label: const Text(
                          'Continue as Guest',
                          style: TextStyle(fontSize: 16)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '💻 Desktop Quick Sign-In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Enter your real email and name\n'
                          '• Choose your preferred provider\n'
                          '• All data saved locally on this computer\n'
                          '• No complex OAuth setup required',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn(String provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate authentication delay
    await Future.delayed(const Duration(seconds: 1));
    
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    
    widget.onSignIn(email, name, provider);
    
    setState(() => _isLoading = false);
  }
}