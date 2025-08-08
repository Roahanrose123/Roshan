import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'todo_service.dart';
import 'todo_item.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'google_auth_service.dart';
import 'env_config.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter binding initialized');
    
    // Initialize environment configuration
    try {
      await EnvConfig.initialize();
      print('✅ Environment configuration loaded');
    } catch (envError) {
      print('⚠️ Warning: Environment configuration failed to load: $envError');
      print('📋 Continuing with fallback values...');
    }
    
    // Initialize Firebase only on supported platforms
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux ||
                    defaultTargetPlatform == TargetPlatform.windows ||
                    defaultTargetPlatform == TargetPlatform.macOS)) {
      print('🖥️  Running on desktop platform - Firebase initialization skipped');
    } else {
      print('📱 Initializing Firebase for mobile/web platform...');
      print('🔧 Platform: ${defaultTargetPlatform.name}');
      print('🌐 isWeb: $kIsWeb');
      
      try {
        // Check if Firebase is already initialized
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print('✅ Firebase initialized successfully');
        } else {
          print('✅ Firebase already initialized');
        }
      } catch (firebaseError) {
        print('❌ Firebase initialization failed: $firebaseError');
        throw Exception('Firebase initialization failed: $firebaseError');
      }
    }
    
    print('🚀 Starting TodoApp...');
    runApp(const TodoApp());
    print('✅ TodoApp started');
  } catch (e, stackTrace) {
    print('❌ Error in main(): $e');
    print('📋 Stack trace: $stackTrace');
    // Still try to run the app even if there's an error
    runApp(ErrorApp(error: e.toString()));
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO-APP Error',
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please check your internet connection and Firebase configuration.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[50],
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔧 Building AuthWrapper...');
    
    try {
      final authService = GoogleAuthService();
      print('✅ GoogleAuthService created');
      
      return StreamBuilder<GoogleUser?>(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          print('🔍 AuthWrapper state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('❌ AuthWrapper error: ${snapshot.error}');
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ AuthWrapper waiting...');
            return const LoadingScreen();
          }
          
          if (snapshot.hasError) {
            return ErrorScreen(error: snapshot.error.toString());
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            print('✅ User authenticated, showing TODO app for: ${snapshot.data!.email} (${snapshot.data!.provider})');
            return TodoListScreen(user: snapshot.data!);
          } else {
            print('❌ No user data, showing login screen');
            return const GoogleLoginScreen();
          }
        },
      );
    } catch (e) {
      print('❌ Error creating AuthWrapper: $e');
      return ErrorScreen(error: 'AuthWrapper initialization failed: $e');
    }
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to restart the app
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TodoApp()),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading TODO-APP...',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key});

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final GoogleAuthService _authService = GoogleAuthService();
  final TodoService _todoService = TodoService();
  bool _isLoadingGoogle = false;
  bool _isLoadingMicrosoft = false;
  bool _hasReturnedUsers = false;
  bool _isCheckingUsers = true;

  @override
  void initState() {
    super.initState();
    _checkForReturnedUsers();
  }

  Future<void> _checkForReturnedUsers() async {
    // Check if there are any users who have previously visited
    // by checking SharedPreferences for any visited keys or todo data
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Look for any user visit keys or todo data keys
      final hasVisitedKeys = keys.any((key) => key.contains('_visited'));
      final hasTodoKeys = keys.any((key) => key.startsWith('todos_'));
      
      // If we have either visited keys or todo data, show "Welcome back!"
      final hasReturnedUsers = hasVisitedKeys || hasTodoKeys;
      
      if (kDebugMode) {
        print('🔍 Checking for returned users...');
        print('📋 Found visited keys: $hasVisitedKeys');
        print('📝 Found todo keys: $hasTodoKeys');
        print('🔄 Has returned users: $hasReturnedUsers');
        print('🗂️ All keys: ${keys.where((k) => k.contains('todo') || k.contains('visited')).toList()}');
      }
      
      if (mounted) {
        setState(() {
          _hasReturnedUsers = hasReturnedUsers;
          _isCheckingUsers = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking returned users: $e');
      }
      if (mounted) {
        setState(() {
          _hasReturnedUsers = false;
          _isCheckingUsers = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo and Title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.assignment_turned_in,
                      size: 80,
                      color: Colors.blue,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'TODO-APP',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    isDesktop ? 'Desktop Edition' : 'Mobile Edition',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Dynamic welcome message
                  if (_isCheckingUsers)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        Text(
                          _hasReturnedUsers ? 'Welcome back!' : 'Welcome!',
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          _hasReturnedUsers 
                            ? 'Sign in to continue where you left off'
                            : 'Sign in with your account to get started',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingGoogle || _isLoadingMicrosoft ? null : _signInWithGoogle,
                      icon: _isLoadingGoogle 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.login,
                                size: 24,
                                color: Colors.white,
                              );
                            },
                          ),
                      label: Text(
                        _isLoadingGoogle ? 'Signing in with Google...' : 'Continue with Google',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Demo mode button for testing
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _signInDemo,
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: Text(
                        'Try Demo Mode',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[400]!, width: 2),
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mobile test mode button (for testing mobile auth without emulator)
                  if (!isDesktop)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _testMobileAuth,
                        icon: const Icon(Icons.phone_android, size: 24),
                        label: Text(
                          'Test Mobile Google Auth',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue[400]!, width: 2),
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Microsoft Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoadingGoogle || _isLoadingMicrosoft) ? null : _signInWithMicrosoft,
                      icon: _isLoadingMicrosoft 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.business, size: 24, color: Colors.white),
                      label: Text(
                        _isLoadingMicrosoft ? 'Signing in with Microsoft...' : 'Continue with Microsoft',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0078D4), // Microsoft blue
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF0078D4).withOpacity(0.3),
                      ),
                    ),
                  ),
                  
                  
                  const SizedBox(height: 40),
                  
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isDesktop ? Icons.computer : Icons.phone_android,
                              size: 20,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isDesktop ? 'Desktop OAuth Authentication' : 'Firebase Authentication',
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isDesktop 
                            ? '• Secure browser-based OAuth authentication\n'
                              '• Real Google & Microsoft account support\n'
                              '• Automatic token management\n'
                              '• Production-ready implementation'
                            : '• Firebase & Microsoft authentication\n'
                              '• Secure cloud authentication\n'
                              '• Real account verification\n'
                              '• Cross-platform compatibility',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy note
                  Text(
                    'Your privacy is protected. We only access your basic profile information.',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInDemo() async {
    try {
      // Create a demo user for testing
      final demoUser = GoogleUser(
        id: 'demo_user_123',
        email: 'demo@todoapp.com',
        name: 'Demo User',
        photoUrl: null,
        provider: 'demo',
      );
      
      // Navigate directly to TodoListScreen with demo user
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TodoListScreen(user: demoUser),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Demo mode failed: $e');
      }
    }
  }

  Future<void> _testMobileAuth() async {
    setState(() => _isLoadingGoogle = true);
    try {
      if (kDebugMode) print('🧪 Testing mobile Google authentication...');
      
      // Test mobile authentication directly
      final user = await _authService.signInWithGoogleMobile();
      if (user != null && kDebugMode) {
        print('✅ Mobile Google sign-in test successful: ${user.email}');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Google Sign-In setup required')) {
          _showInfoMessage('Mobile authentication would work on a real device with proper setup. Error: ${errorMessage.replaceAll('Exception: ', '')}');
        } else {
          _showErrorMessage('Mobile auth test failed: $errorMessage');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null && kDebugMode) {
        print('✅ Google sign-in successful: ${user.email}');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Check if it's the setup required message
        if (errorMessage.contains('Google Sign-In setup required')) {
          _showInfoMessage(errorMessage.replaceAll('Exception: ', ''));
        } else if (errorMessage.contains('network_error')) {
          _showErrorMessage('Network error. Please check your internet connection.');
        } else if (errorMessage.contains('sign_in_canceled')) {
          _showErrorMessage('Sign-in was cancelled.');
        } else if (errorMessage.contains('sign_in_failed')) {
          _showErrorMessage('Google Sign-in failed. Please try again.');
        } else {
          _showErrorMessage('Google Sign-in failed: $errorMessage');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _signInWithMicrosoft() async {
    setState(() => _isLoadingMicrosoft = true);
    try {
      final user = await _authService.signInWithMicrosoft();
      if (user != null && kDebugMode) {
        print('✅ Microsoft sign-in successful: ${user.email}');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Check if it's the mobile development message
        if (errorMessage.contains('Microsoft Sign-In on mobile is currently in development')) {
          _showInfoMessage(errorMessage.replaceAll('Exception: ', ''));
        } else {
          _showErrorMessage('Microsoft Sign-in failed: $errorMessage');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingMicrosoft = false);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

}

class TodoListScreen extends StatefulWidget {
  final GoogleUser user;
  
  const TodoListScreen({super.key, required this.user});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> with TickerProviderStateMixin {
  final List<TodoItem> _todoItems = [];
  final TodoService _todoService = TodoService();
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = true;
  Map<String, int> _userStats = {};
  bool _isNewUser = false;
  
  // Live clock and calendar
  DateTime _currentTime = DateTime.now();
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Get current UTC time and convert to Kolkata timezone (UTC+5:30)
          final utcNow = DateTime.now().toUtc();
          _currentTime = utcNow.add(const Duration(hours: 5, minutes: 30));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final todos = await _todoService.loadTodos(
      userEmail: widget.user.email,
      provider: widget.user.provider,
    );
    final stats = await _todoService.getUserStats(
      userEmail: widget.user.email,
      provider: widget.user.provider,
    );
    final isNew = await _todoService.isNewUser(
      userEmail: widget.user.email,
      provider: widget.user.provider,
    );
    setState(() {
      _todoItems.clear();
      _todoItems.addAll(todos);
      _userStats = stats;
      _isNewUser = isNew;
      _isLoading = false;
    });
  }

  Future<void> _saveTodos() async {
    await _todoService.saveTodos(
      _todoItems,
      userEmail: widget.user.email,
      provider: widget.user.provider,
    );
    // Update stats after saving
    final stats = await _todoService.getUserStats(
      userEmail: widget.user.email,
      provider: widget.user.provider,
    );
    setState(() {
      _userStats = stats;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
    });
    _saveTodos();
  }

  void _showTaskDialog({TodoItem? item, int? index}) {
    final TextEditingController textController = TextEditingController(text: item?.task);
    DateTime selectedDate = item?.dueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(item == null ? 'Add Task' : 'Update Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      labelText: 'Task Description',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null && context.mounted) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Due: ${DateFormat.yMMMd().add_jm().format(selectedDate)}",
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(Icons.edit, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      Navigator.of(context).pop();
                      
                      setState(() {
                        if (index != null) {
                          _todoItems[index].task = textController.text.trim();
                          _todoItems[index].dueDate = selectedDate;
                        } else {
                          _todoItems.add(
                            TodoItem(
                              task: textController.text.trim(),
                              dueDate: selectedDate,
                            ),
                          );
                        }
                      });
                      _saveTodos();
                    }
                  },
                  child: Text(item == null ? 'Add Task' : 'Update Task'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    final hour = _currentTime.hour;
    String greeting;
    String emoji;
    
    if ((hour >= 0 && hour < 5) || (hour >= 5 && hour < 12)) {
      // Early morning (12 AM - 5 AM) and morning (5 AM - 12 PM)
      greeting = 'Good Morning';
      emoji = '🌅';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else if (hour >= 17 && hour < 22) {
      greeting = 'Good Evening';
      emoji = '🌙';
    } else {
      // Late night (10 PM - 12 AM)
      greeting = 'Good Night';
      emoji = '🌙';
    }
    
    final providerName = widget.user.provider == 'google' ? 'Google' : 'Microsoft';
    final providerColor = widget.user.provider == 'google' ? Colors.blue : const Color(0xFF0078D4);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              providerColor.withOpacity(0.1),
              providerColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isNewUser 
                          ? 'Welcome, ${widget.user.name.split(' ').first}!'
                          : '$greeting, ${widget.user.name.split(' ').first}!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isNewUser 
                          ? 'Thanks for joining TODO-APP! Let\'s get started with your first task.'
                          : 'Welcome back! Let\'s see what you need to accomplish today.',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: _isNewUser ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Signed in with $providerName',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: providerColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.user.email,
                              style: TextStyle(
                                fontSize: 10,
                                color: providerColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Live clock and calendar section
            Row(
              children: [
                // Live clock
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: providerColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, color: providerColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Live Time',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: providerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('hh:mm:ss a').format(_currentTime),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          DateFormat('EEEE').format(_currentTime),
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Live calendar/date
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: providerColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today, color: providerColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Today',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: providerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('dd MMM').format(_currentTime),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          DateFormat('yyyy').format(_currentTime),
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final providerColor = widget.user.provider == 'google' ? Colors.blue : const Color(0xFF0078D4);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Total Tasks',
                '${_userStats['total'] ?? 0}',
                Icons.assignment,
                Colors.grey[600]!,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Active',
                '${_userStats['active'] ?? 0}',
                Icons.pending_actions,
                providerColor,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Completed',
                '${_userStats['completed'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Overdue',
                '${_userStats['overdue'] ?? 0}',
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<TodoItem> activeTasks = _todoItems.where((t) => !t.isCompleted).toList();
    List<TodoItem> completedTasks = _todoItems.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.blue),
            onPressed: () async {
              await _authService.signOut();
            },
            tooltip: 'Sign Out',
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in, size: 28),
            const SizedBox(width: 12),
            Text(
              AppConfig.appName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: widget.user.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.user.photoUrl!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.person, color: Colors.blue, size: 20);
                        },
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.blue, size: 20),
            ),
            onSelected: (String value) async {
              if (value == 'logout') {
                await _authService.signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.user.provider == 'google' ? 'Google Account' : 'Microsoft Account',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.user.provider == 'google' ? Colors.blue[800] : const Color(0xFF0078D4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 12),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodos,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 20),
                  _buildStatsSection(),
                  const SizedBox(height: 20),
                  _buildTaskList('📝 Active Tasks', activeTasks, Colors.blue),
                  const SizedBox(height: 20),
                  _buildTaskList('✅ Completed Tasks', completedTasks, Colors.green),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTaskList(String title, List<TodoItem> tasks, Color accentColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    title.contains('Active') ? 'No active tasks! 🎉' : 'No completed tasks yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = tasks[index];
                  final originalIndex = _todoItems.indexOf(item);
                  return _buildTaskCard(item, originalIndex);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TodoItem item, int index) {
    final bool isOverdue = item.dueDate.isBefore(DateTime.now()) && !item.isCompleted;
    
    return Card(
      elevation: 2,
      color: isOverdue ? Colors.red[50] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (bool? value) {
            setState(() {
              item.isCompleted = value!;
            });
            _saveTodos();
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          item.task,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 16,
            color: item.isCompleted ? Colors.grey : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(
                isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                size: 16,
                color: isOverdue ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat.yMMMd().add_jm().format(item.dueDate),
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              if (isOverdue) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
              onPressed: () => _showTaskDialog(item: item, index: index),
              tooltip: 'Edit task',
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
              onPressed: () => _deleteItem(index),
              tooltip: 'Delete task',
            ),
          ],
        ),
      ),
    );
  }
}