import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config.dart';

void main() {
  runApp(const DebugTodoApp());
}

class DebugTodoApp extends StatelessWidget {
  const DebugTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const DebugLoginScreen(),
    );
  }
}

class DebugLoginScreen extends StatelessWidget {
  const DebugLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug - TODO-APP'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Debug Mode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This screen should be visible if the app is working',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Button works!')),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Test Button'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugTodoScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Go to Todo Screen'),
            ),
          ],
        ),
      ),
    );
  }
}

class DebugTodoScreen extends StatefulWidget {
  const DebugTodoScreen({super.key});

  @override
  State<DebugTodoScreen> createState() => _DebugTodoScreenState();
}

class _DebugTodoScreenState extends State<DebugTodoScreen> {
  final List<String> _todos = ['Sample Todo 1', 'Sample Todo 2'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Todo List'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(_todos[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _todos.removeAt(index);
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _todos.add('New Todo ${_todos.length + 1}');
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}