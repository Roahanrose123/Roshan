import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'todo_item.dart';

class TodoService {
  static const String _todosKeyPrefix = 'todos_';
  
  // Generate user-specific key based on email and provider
  String _getUserKey(String userEmail, String provider) {
    final userKey = '${userEmail}_${provider}'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return '${_todosKeyPrefix}$userKey';
  }

  Future<List<TodoItem>> loadTodos({String? userEmail, String? provider}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String todosKey;
      
      if (userEmail != null && provider != null) {
        todosKey = _getUserKey(userEmail, provider);
        if (kDebugMode) {
          print('📖 Loading todos for user: $userEmail ($provider) with key: $todosKey');
        }
      } else {
        todosKey = '${_todosKeyPrefix}default';
        if (kDebugMode) {
          print('📖 Loading default todos');
        }
      }
      
      final todosJson = prefs.getStringList(todosKey) ?? [];
      
      final todos = todosJson.map((todoJson) {
        final Map<String, dynamic> todoMap = json.decode(todoJson);
        return TodoItem.fromJson(todoMap);
      }).toList();
      
      if (kDebugMode) {
        print('✅ Loaded ${todos.length} todos for user: $userEmail');
      }
      
      return todos;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading todos: $e');
      }
      return [];
    }
  }

  Future<void> saveTodos(List<TodoItem> todos, {String? userEmail, String? provider}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String todosKey;
      
      if (userEmail != null && provider != null) {
        todosKey = _getUserKey(userEmail, provider);
        if (kDebugMode) {
          print('💾 Saving ${todos.length} todos for user: $userEmail ($provider) with key: $todosKey');
        }
      } else {
        todosKey = '${_todosKeyPrefix}default';
        if (kDebugMode) {
          print('💾 Saving ${todos.length} default todos');
        }
      }
      
      final todosJson = todos.map((todo) {
        return json.encode(todo.toJson());
      }).toList();
      
      await prefs.setStringList(todosKey, todosJson);
      if (kDebugMode) {
        print('✅ Successfully saved ${todos.length} todos for user: $userEmail');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving todos: $e');
      }
    }
  }

  // Get statistics for user's todos
  Future<Map<String, int>> getUserStats({String? userEmail, String? provider}) async {
    final todos = await loadTodos(userEmail: userEmail, provider: provider);
    final completed = todos.where((t) => t.isCompleted).length;
    final active = todos.where((t) => !t.isCompleted).length;
    final overdue = todos.where((t) => !t.isCompleted && t.dueDate.isBefore(DateTime.now())).length;
    
    return {
      'total': todos.length,
      'completed': completed,
      'active': active,
      'overdue': overdue,
    };
  }

  // Check if user is new (first time login) or returning
  Future<bool> isNewUser({String? userEmail, String? provider}) async {
    if (userEmail == null || provider == null) return true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserKey(userEmail, provider);
      final userVisitKey = '${userKey}_visited';
      
      final hasVisited = prefs.getBool(userVisitKey) ?? false;
      
      if (!hasVisited) {
        // Mark user as visited
        await prefs.setBool(userVisitKey, true);
        if (kDebugMode) {
          print('🆕 New user detected: $userEmail ($provider)');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('🔄 Returning user: $userEmail ($provider)');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking user status: $e');
      }
      return true; // Default to new user if error
    }
  }
}