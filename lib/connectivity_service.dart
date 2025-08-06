import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  // Getters
  bool get isOnline => _isOnline;
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  // Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      await _updateConnectivityStatus();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          _handleConnectivityChange(results);
        },
        onError: (error) {
          if (kDebugMode) {
            print('Connectivity stream error: $error');
          }
          // Default to online if we can't monitor connectivity
          _isOnline = true;
          _connectivityController.add(_isOnline);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize connectivity service: $e');
      }
      // Default to online if initialization fails
      _isOnline = true;
      _connectivityController.add(_isOnline);
    }
  }
  
  // Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final bool wasOnline = _isOnline;
    
    // Check if any connection type indicates online status
    _isOnline = results.any((result) => 
      result != ConnectivityResult.none
    );
    
    // Only notify if status changed
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      if (kDebugMode) {
        print('Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
      }
    }
  }
  
  // Update connectivity status
  Future<void> _updateConnectivityStatus() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check connectivity: $e');
      }
      // Assume online if we can't determine connectivity (e.g., NetworkManager not available)
      _isOnline = true;
      _connectivityController.add(_isOnline);
    }
  }
  
  // Test internet connectivity (ping-like test)
  Future<bool> testInternetConnection() async {
    try {
      // This is a simple test - in production you might want to ping a specific server
      await _updateConnectivityStatus();
      return _isOnline;
    } catch (e) {
      if (kDebugMode) {
        print('Internet connection test failed: $e');
      }
      return false;
    }
  }
  
  // Dispose
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}