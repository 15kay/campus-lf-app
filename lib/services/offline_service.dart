import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_service.dart';

class OfflineService {
  static const String _reportsBoxName = 'reports_cache';
  static const String _chatsBoxName = 'chats_cache';
  static const String _usersBoxName = 'users_cache';
  static const String _pendingActionsBoxName = 'pending_actions';
  static const String _settingsBoxName = 'app_settings';
  static const String _searchHistoryBoxName = 'search_history';

  static Box<Map>? _reportsBox;
  static Box<Map>? _chatsBox;
  static Box<Map>? _usersBox;
  static Box<Map>? _pendingActionsBox;
  static Box<dynamic>? _settingsBox;
  static Box<String>? _searchHistoryBox;

  static bool _isInitialized = false;
  static bool _isOnline = true;
  static final Connectivity _connectivity = Connectivity();

  // Initialize offline service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      
      // Open boxes
      _reportsBox = await Hive.openBox<Map>(_reportsBoxName);
      _chatsBox = await Hive.openBox<Map>(_chatsBoxName);
      _usersBox = await Hive.openBox<Map>(_usersBoxName);
      _pendingActionsBox = await Hive.openBox<Map>(_pendingActionsBoxName);
      _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
      _searchHistoryBox = await Hive.openBox<String>(_searchHistoryBoxName);

      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
      
      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;

      _isInitialized = true;
      
      if (kDebugMode) {
        print('Offline service initialized. Online: $_isOnline');
      }

      // Sync pending actions if online
      if (_isOnline) {
        await _syncPendingActions();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing offline service: $e');
      }
    }
  }

  // Connectivity change handler
  static void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && results.any((result) => result != ConnectivityResult.none);
    
    if (kDebugMode) {
      print('Connectivity changed. Online: $_isOnline');
    }

    // If we just came online, sync pending actions
    if (!wasOnline && _isOnline) {
      await _syncPendingActions();
    }
  }

  // Check if device is online
  static bool get isOnline => _isOnline;

  // Cache reports
  static Future<void> cacheReports(List<Map<String, dynamic>> reports) async {
    if (_reportsBox == null) return;

    try {
      for (final report in reports) {
        final id = report['id'] as String?;
        if (id != null) {
          await _reportsBox!.put(id, report);
        }
      }
      
      // Update last sync timestamp
      await _settingsBox?.put('last_reports_sync', DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Cached ${reports.length} reports');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching reports: $e');
      }
    }
  }

  // Get cached reports
  static List<Map<String, dynamic>> getCachedReports({
    String? category,
    String? status,
    String? searchTerm,
  }) {
    if (_reportsBox == null) return [];

    try {
      List<Map<String, dynamic>> reports = _reportsBox!.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      // Apply filters
      if (category != null && category.isNotEmpty) {
        reports = reports.where((r) => r['category'] == category).toList();
      }
      
      if (status != null && status.isNotEmpty) {
        reports = reports.where((r) => r['status'] == status).toList();
      }
      
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final term = searchTerm.toLowerCase();
        reports = reports.where((r) {
          final title = (r['title'] as String? ?? '').toLowerCase();
          final description = (r['description'] as String? ?? '').toLowerCase();
          return title.contains(term) || description.contains(term);
        }).toList();
      }

      // Sort by timestamp (newest first)
      reports.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return reports;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached reports: $e');
      }
      return [];
    }
  }

  // Cache single report
  static Future<void> cacheReport(Map<String, dynamic> report) async {
    if (_reportsBox == null) return;

    try {
      final id = report['id'] as String?;
      if (id != null) {
        await _reportsBox!.put(id, report);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching report: $e');
      }
    }
  }

  // Get cached report by ID
  static Map<String, dynamic>? getCachedReport(String id) {
    if (_reportsBox == null) return null;

    try {
      final report = _reportsBox!.get(id);
      return report != null ? Map<String, dynamic>.from(report) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached report: $e');
      }
      return null;
    }
  }

  // Cache chats
  static Future<void> cacheChats(List<Map<String, dynamic>> chats) async {
    if (_chatsBox == null) return;

    try {
      for (final chat in chats) {
        final id = chat['id'] as String?;
        if (id != null) {
          await _chatsBox!.put(id, chat);
        }
      }
      
      await _settingsBox?.put('last_chats_sync', DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Cached ${chats.length} chats');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error caching chats: $e');
      }
    }
  }

  // Get cached chats
  static List<Map<String, dynamic>> getCachedChats() {
    if (_chatsBox == null) return [];

    try {
      return _chatsBox!.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached chats: $e');
      }
      return [];
    }
  }

  // Cache user data
  static Future<void> cacheUser(String userId, Map<String, dynamic> userData) async {
    if (_usersBox == null) return;

    try {
      await _usersBox!.put(userId, userData);
    } catch (e) {
      if (kDebugMode) {
        print('Error caching user: $e');
      }
    }
  }

  // Get cached user
  static Map<String, dynamic>? getCachedUser(String userId) {
    if (_usersBox == null) return null;

    try {
      final user = _usersBox!.get(userId);
      return user != null ? Map<String, dynamic>.from(user) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cached user: $e');
      }
      return null;
    }
  }

  // Add pending action
  static Future<void> addPendingAction({
    required String type,
    required Map<String, dynamic> data,
    int? priority,
  }) async {
    if (_pendingActionsBox == null) return;

    try {
      final action = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'data': data,
        'priority': priority ?? 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0,
      };

      await _pendingActionsBox!.put(action['id'], action);
      
      if (kDebugMode) {
        print('Added pending action: $type');
      }

      // Try to sync immediately if online
      if (_isOnline) {
        await _syncPendingActions();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding pending action: $e');
      }
    }
  }

  // Sync pending actions
  static Future<void> _syncPendingActions() async {
    if (_pendingActionsBox == null || !_isOnline) return;

    try {
      final actions = _pendingActionsBox!.values.toList();
      if (actions.isEmpty) return;

      final startTime = DateTime.now().millisecondsSinceEpoch;
      int syncedCount = 0;

      // Sort by priority and timestamp
      actions.sort((a, b) {
        final aPriority = a['priority'] as int? ?? 1;
        final bPriority = b['priority'] as int? ?? 1;
        if (aPriority != bPriority) {
          return bPriority.compareTo(aPriority); // Higher priority first
        }
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return aTime.compareTo(bTime); // Older first
      });

      for (final action in actions) {
        try {
          final success = await _executePendingAction(action);
          if (success) {
            await _pendingActionsBox!.delete(action['id']);
            syncedCount++;
          } else {
            // Increment retry count
            final retryCount = (action['retryCount'] as int? ?? 0) + 1;
            if (retryCount >= 3) {
              // Remove after 3 failed attempts
              await _pendingActionsBox!.delete(action['id']);
            } else {
              action['retryCount'] = retryCount;
              await _pendingActionsBox!.put(action['id'], action);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error executing pending action: $e');
          }
        }
      }

      final syncDuration = DateTime.now().millisecondsSinceEpoch - startTime;
      
      // Log analytics
      await AnalyticsService.logOfflineDataSync(
        itemsSynced: syncedCount,
        syncDuration: syncDuration,
      );

      if (kDebugMode) {
        print('Synced $syncedCount pending actions in ${syncDuration}ms');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing pending actions: $e');
      }
    }
  }

  // Execute a pending action
  static Future<bool> _executePendingAction(Map action) async {
    try {
      final type = action['type'] as String;
      final data = action['data'] as Map<String, dynamic>;

      switch (type) {
        case 'create_report':
          // Execute create report action
          return await _executeCreateReport(data);
        case 'update_report':
          // Execute update report action
          return await _executeUpdateReport(data);
        case 'send_message':
          // Execute send message action
          return await _executeSendMessage(data);
        case 'update_profile':
          // Execute update profile action
          return await _executeUpdateProfile(data);
        default:
          if (kDebugMode) {
            print('Unknown pending action type: $type');
          }
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error executing pending action: $e');
      }
      return false;
    }
  }

  // Execute create report
  static Future<bool> _executeCreateReport(Map<String, dynamic> data) async {
    try {
      // This would integrate with your Firebase service
      // For now, just simulate success
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Execute update report
  static Future<bool> _executeUpdateReport(Map<String, dynamic> data) async {
    try {
      // This would integrate with your Firebase service
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Execute send message
  static Future<bool> _executeSendMessage(Map<String, dynamic> data) async {
    try {
      // This would integrate with your Firebase service
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Execute update profile
  static Future<bool> _executeUpdateProfile(Map<String, dynamic> data) async {
    try {
      // This would integrate with your Firebase service
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Search history management
  static Future<void> addSearchTerm(String term) async {
    if (_searchHistoryBox == null || term.trim().isEmpty) return;

    try {
      final trimmedTerm = term.trim().toLowerCase();
      
      // Remove if already exists
      final existingKeys = _searchHistoryBox!.keys.where(
        (key) => _searchHistoryBox!.get(key) == trimmedTerm
      ).toList();
      
      for (final key in existingKeys) {
        await _searchHistoryBox!.delete(key);
      }

      // Add to beginning
      await _searchHistoryBox!.put(
        DateTime.now().millisecondsSinceEpoch.toString(),
        trimmedTerm,
      );

      // Keep only last 50 searches
      if (_searchHistoryBox!.length > 50) {
        final keys = _searchHistoryBox!.keys.toList()..sort();
        for (int i = 0; i < _searchHistoryBox!.length - 50; i++) {
          await _searchHistoryBox!.delete(keys[i]);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding search term: $e');
      }
    }
  }

  // Get search history
  static List<String> getSearchHistory({int limit = 10}) {
    if (_searchHistoryBox == null) return [];

    try {
      final entries = _searchHistoryBox!.toMap().entries.toList();
      entries.sort((a, b) => b.key.compareTo(a.key)); // Most recent first
      
      return entries
          .take(limit)
          .map((e) => e.value)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting search history: $e');
      }
      return [];
    }
  }

  // Clear search history
  static Future<void> clearSearchHistory() async {
    if (_searchHistoryBox == null) return;

    try {
      await _searchHistoryBox!.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing search history: $e');
      }
    }
  }

  // Get cache statistics
  static Map<String, dynamic> getCacheStatistics() {
    return {
      'reports_count': _reportsBox?.length ?? 0,
      'chats_count': _chatsBox?.length ?? 0,
      'users_count': _usersBox?.length ?? 0,
      'pending_actions_count': _pendingActionsBox?.length ?? 0,
      'search_history_count': _searchHistoryBox?.length ?? 0,
      'last_reports_sync': _settingsBox?.get('last_reports_sync'),
      'last_chats_sync': _settingsBox?.get('last_chats_sync'),
      'is_online': _isOnline,
    };
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    try {
      await _reportsBox?.clear();
      await _chatsBox?.clear();
      await _usersBox?.clear();
      await _pendingActionsBox?.clear();
      await _settingsBox?.clear();
      await _searchHistoryBox?.clear();
      
      if (kDebugMode) {
        print('All cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cache: $e');
      }
    }
  }

  // Force sync
  static Future<void> forceSync() async {
    if (_isOnline) {
      await _syncPendingActions();
    }
  }

  // Dispose
  static Future<void> dispose() async {
    try {
      await _reportsBox?.close();
      await _chatsBox?.close();
      await _usersBox?.close();
      await _pendingActionsBox?.close();
      await _settingsBox?.close();
      await _searchHistoryBox?.close();
      
      _isInitialized = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing offline service: $e');
      }
    }
  }
}