import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'todo_service.dart';
import 'todo_item.dart';
import 'config.dart';
import 'firebase_options.dart';
import 'simple_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on supported platforms
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.macOS)) {
    if (kDebugMode) {
      print('Running on desktop platform - Firebase initialization skipped');
    }
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(const TodoApp());
}

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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = SimpleAuthService();
    
    return StreamBuilder<SimpleUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return TodoListScreen(user: snapshot.data!);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

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
              'Loading TODO-APP...',
              style: GoogleFonts.lato(
                fontSize: 18,
                color: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final SimpleAuthService _authService = SimpleAuthService();
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
    final bool isDesktop = !kIsWeb && (
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS
    );

    if (isDesktop) {
      return _buildDesktopLogin();
    } else {
      return _buildMobileLogin();
    }
  }

  Widget _buildDesktopLogin() {
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
                    'Desktop Edition',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  
                  if (_isLoading)
                    const CircularProgressIndicator(color: Colors.teal)
                  else ...[
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Your Email Address',
                        hintText: 'hariroshan803@gmail.com',
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
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Full Name',
                        hintText: 'Hari Roshan',
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
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _signInDesktop('google'),
                        icon: const Icon(Icons.login, size: 24),
                        label: const Text(
                          'Sign In with Google Account',
                          style: TextStyle(fontSize: 16)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => _signInDesktop('microsoft'),
                        icon: const Icon(Icons.business, size: 24),
                        label: const Text(
                          'Sign In with Microsoft Account',
                          style: TextStyle(fontSize: 16)
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '💻 Desktop Authentication',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Enter your real Gmail or Microsoft email\n'
                          '• Your actual name will appear in the app\n'
                          '• All data saved locally on this computer\n'
                          '• Simple, secure desktop authentication',
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

  Widget _buildMobileLogin() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to TODO-APP'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment,
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
            const SizedBox(height: 40),
            
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.teal)
            else
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInDesktop(String provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 1));
    
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    
    _authService.signInWithDesktop(email, name, provider);
    
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class TodoListScreen extends StatefulWidget {
  final SimpleUser user;
  
  const TodoListScreen({super.key, required this.user});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todoItems = [];
  final TodoService _todoService = TodoService();
  final SimpleAuthService _authService = SimpleAuthService();
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
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await _authService.signOut();
          },
          tooltip: 'Sign Out',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment, size: 24),
            const SizedBox(width: 8),
            Text(
              AppConfig.appName,
              style: GoogleFonts.pacifico(fontSize: 28),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.user.email,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Signed in via ${widget.user.provider.toUpperCase()}',
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
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
      elevation: 8,
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
                    color: accentColor.withValues(alpha: 0.1),
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
      elevation: 3,
      color: isOverdue ? Colors.red[50] : Colors.white,
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