import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'todo_service.dart';
import 'todo_item.dart';
import 'config.dart';
import 'desktop_oauth_service.dart';

// --- Desktop Login Screen ---
class DesktopLoginScreen extends StatefulWidget {
  final Function(String) onSignIn;
  
  const DesktopLoginScreen({super.key, required this.onSignIn});

  @override
  State<DesktopLoginScreen> createState() => _DesktopLoginScreenState();
}

class _DesktopLoginScreenState extends State<DesktopLoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to TODO-APP'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
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
              const SizedBox(height: 10),
              const Text(
                'Desktop Edition',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'Choose your sign-in method:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.teal)
              else ...[
                // Google Sign-In (Simulated for desktop)
                SizedBox(
                  width: 300,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.login, size: 24),
                    label: const Text(
                      'Sign in with Google (Demo)',
                      style: TextStyle(fontSize: 16)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Microsoft Sign-In (Simulated for desktop)
                SizedBox(
                  width: 300,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithMicrosoft,
                    icon: const Icon(Icons.business, size: 24),
                    label: const Text(
                      'Sign in with Microsoft (Demo)',
                      style: TextStyle(fontSize: 16)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Guest Sign-In
                SizedBox(
                  width: 300,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _signInAsGuest,
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
              
              // Desktop features info
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
                      '💻 Desktop Features',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Native ${defaultTargetPlatform.name.toUpperCase()} application\n'
                      '• Local storage - all data saved on this computer\n'
                      '• Works offline - no internet required\n'
                      '• Demo authentication for testing',
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
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    widget.onSignIn('demo.google.user@gmail.com');
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithMicrosoft() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate loading
    widget.onSignIn('demo.microsoft.user@outlook.com');
    setState(() => _isLoading = false);
  }

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
    widget.onSignIn('Guest User');
    setState(() => _isLoading = false);
  }
}

// --- Desktop Todo List Screen ---
class DesktopTodoListScreen extends StatefulWidget {
  final String currentUser;
  final VoidCallback onSignOut;
  
  const DesktopTodoListScreen({
    super.key, 
    required this.currentUser,
    required this.onSignOut,
  });

  @override
  State<DesktopTodoListScreen> createState() => _DesktopTodoListScreenState();
}

class _DesktopTodoListScreenState extends State<DesktopTodoListScreen> {
  final List<TodoItem> _todoItems = [];
  final TodoService _todoService = TodoService();
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

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/backgroundimage.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onSignOut,
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
          backgroundColor: Colors.teal.withValues(alpha: 0.9),
          foregroundColor: Colors.white,
          actions: [
            // User info and logout
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (String value) async {
                if (value == 'logout') {
                  widget.onSignOut();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentUser,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Desktop Mode',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
        body: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
          ),
          child: _isLoading
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
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showTaskDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTaskList(String title, List<TodoItem> tasks, Color accentColor) {
    return Card(
      elevation: 8,
      color: Colors.white.withValues(alpha: 0.95),
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
      color: isOverdue ? Colors.red[50] : Colors.white.withValues(alpha: 0.9),
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