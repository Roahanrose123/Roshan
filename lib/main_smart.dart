import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'todo_service.dart';
import 'todo_item.dart';
import 'config.dart';
import 'smart_auth_service.dart';

// Conditional Firebase imports
import 'package:firebase_core/firebase_core.dart'
    if (dart.library.io) 'package:flutter/services.dart';
import 'firebase_options.dart'
    if (dart.library.io) 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for supported platforms (mobile and web)
  try {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization failed: $e');
    }
  }
  
  // Initialize smart auth service
  await SmartAuthService().initialize();
  
  runApp(const TodoApp());
}

// --- Main Application Widget ---
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const SmartAuthWrapper(),
    );
  }
}

// --- Smart Auth Wrapper ---
class SmartAuthWrapper extends StatefulWidget {
  const SmartAuthWrapper({super.key});

  @override
  State<SmartAuthWrapper> createState() => _SmartAuthWrapperState();
}

class _SmartAuthWrapperState extends State<SmartAuthWrapper> {
  final SmartAuthService _authService = SmartAuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthStatus>(
      stream: _authService.authStatusStream,
      initialData: _authService.authStatus,
      builder: (context, snapshot) {
        final AuthStatus status = snapshot.data ?? AuthStatus.unauthenticated;
        
        switch (status) {
          case AuthStatus.loading:
            return const LoadingScreen();
          case AuthStatus.authenticated:
            return const TodoListScreen();
          case AuthStatus.unauthenticated:
            return const WelcomeScreen();
        }
      },
    );
  }
}

// --- Welcome/Choice Screen ---
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final SmartAuthService _authService = SmartAuthService();

  @override
  Widget build(BuildContext context) {
    final bool isOnline = _authService.isOnline;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to TODO-APP'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Icon(
                isOnline ? Icons.network_wifi : Icons.wifi_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Icon(
                Icons.check_circle_outline,
                size: 120,
                color: Colors.teal,
              ),
              const SizedBox(height: 30),
              Text(
                'TODO-APP',
                style: GoogleFonts.pacifico(
                  fontSize: 42,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Smart Todo Management',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // Status indicator
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.blue[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOnline ? Colors.blue[200]! : Colors.orange[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      color: isOnline ? Colors.blue : Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOnline 
                        ? 'Internet Connected - Choose authentication method'
                        : 'No Internet - Will use offline mode automatically',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isOnline ? Colors.blue[700] : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              if (isOnline) ...[
                // Online authentication options
                const Text(
                  'Sign in with:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                
                // Google Sign-In
                SizedBox(
                  width: 300,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => _signInWithGoogle(),
                    icon: const Icon(Icons.login, size: 24),
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Microsoft Sign-In
                SizedBox(
                  width: 300,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => _signInWithMicrosoft(),
                    icon: const Icon(Icons.business, size: 24),
                    label: const Text('Continue with Microsoft', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                const Text('or', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
              ],
              
              // Offline/Skip authentication
              SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => _authService.skipAuthentication(),
                  icon: Icon(
                    isOnline ? Icons.offline_bolt : Icons.person,
                    size: 24,
                  ),
                  label: Text(
                    isOnline ? 'Continue Offline' : 'Continue as Guest',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Platform and feature info
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '📱 Multi-Platform Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Works on Mobile (Android/iOS) and Desktop (Windows/Linux/Mac)\n'
                      '• Online: Firebase authentication with cloud sync\n'
                      '• Offline: Local storage, works without internet\n'
                      '• Smart switching: Auto-detects connectivity',
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
    );
  }

  Future<void> _signInWithGoogle() async {
    final success = await _authService.signInWithGoogle();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed. Please try again.')),
      );
    }
  }

  Future<void> _signInWithMicrosoft() async {
    final success = await _authService.signInWithMicrosoft();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microsoft sign-in failed. Please try again.')),
      );
    }
  }
}

// --- Loading Screen ---
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 20),
            Text(
              'Initializing TODO-APP...',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.teal[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Checking connectivity and authentication',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Main Todo Screen ---
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todoItems = [];
  final TodoService _todoService = TodoService();
  final SmartAuthService _authService = SmartAuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _todoService.loadTodos();
    setState(() {
      _todoItems.clear();
      _todoItems.addAll(todos);
      _isLoading = false;
    });
  }

  Future<void> _saveTodos() async {
    await _todoService.saveTodos(_todoItems);
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
                          const Icon(Icons.calendar_today, color: Colors.teal),
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

  @override
  Widget build(BuildContext context) {
    List<TodoItem> activeTasks = _todoItems.where((t) => !t.isCompleted).toList();
    List<TodoItem> completedTasks = _todoItems.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConfig.appName,
          style: GoogleFonts.pacifico(fontSize: 28),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _authService.isOnline ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _authService.isOnline ? 'ON' : 'OFF',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // User info and logout
          if (_authService.currentUser != null) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (String value) {
                if (value == 'logout') {
                  _authService.signOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _authService.currentUser!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _authService.getStatusInfo(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTodos,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildTaskList('📝 Active Tasks', activeTasks, Colors.blue),
                  const SizedBox(height: 20),
                  _buildTaskList('✅ Completed Tasks', completedTasks, Colors.green),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTaskList(String title, List<TodoItem> tasks, Color accentColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
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
                separatorBuilder: (context, index) => const SizedBox(height: 8),
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
      elevation: 1,
      color: isOverdue ? Colors.red[50] : null,
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
        ),
        title: Text(
          item.task,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 16,
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              isOverdue ? Icons.warning : Icons.schedule,
              size: 14,
              color: isOverdue ? Colors.red : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(item.dueDate),
              style: TextStyle(
                color: isOverdue ? Colors.red : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (isOverdue)
              const Text(
                ' • OVERDUE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _showTaskDialog(item: item, index: index),
              tooltip: 'Edit task',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteItem(index),
              tooltip: 'Delete task',
            ),
          ],
        ),
      ),
    );
  }
}