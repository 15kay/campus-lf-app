import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: _analytics);

  // Initialize analytics
  static Future<void> initialize() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
    
    if (kDebugMode) {
      print('Analytics initialized');
    }
  }

  // User events
  static Future<void> logUserSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  static Future<void> logUserLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  static Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // App usage events
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Item reporting events
  static Future<void> logItemReported({
    required String itemType,
    required String category,
    required String status, // 'lost' or 'found'
    required String location,
  }) async {
    await _analytics.logEvent(
      name: 'item_reported',
      parameters: {
        'item_type': itemType,
        'category': category,
        'status': status,
        'location': location,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logItemStatusUpdate({
    required String itemId,
    required String oldStatus,
    required String newStatus,
  }) async {
    await _analytics.logEvent(
      name: 'item_status_updated',
      parameters: {
        'item_id': itemId,
        'old_status': oldStatus,
        'new_status': newStatus,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logItemResolved({
    required String itemId,
    required String itemType,
    required int daysToResolve,
  }) async {
    await _analytics.logEvent(
      name: 'item_resolved',
      parameters: {
        'item_id': itemId,
        'item_type': itemType,
        'days_to_resolve': daysToResolve,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Search events
  static Future<void> logSearch({
    required String searchTerm,
    required int resultsCount,
    Map<String, dynamic>? filters,
  }) async {
    await _analytics.logSearch(
      searchTerm: searchTerm,
    );
    
    if (filters != null) {
      await _analytics.logEvent(
        name: 'search_with_filters',
        parameters: {
          'search_term': searchTerm,
          'results_count': resultsCount,
          'filters_used': filters.keys.join(','),
          ...filters,
        },
      );
    }
  }

  static Future<void> logSearchResultTap({
    required String searchTerm,
    required String itemId,
    required int position,
  }) async {
    await _analytics.logEvent(
      name: 'search_result_tapped',
      parameters: {
        'search_term': searchTerm,
        'item_id': itemId,
        'position': position,
      },
    );
  }

  // Communication events
  static Future<void> logChatStarted({
    required String chatId,
    required String itemId,
    required String itemType,
  }) async {
    await _analytics.logEvent(
      name: 'chat_started',
      parameters: {
        'chat_id': chatId,
        'item_id': itemId,
        'item_type': itemType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logMessageSent({
    required String chatId,
    required String messageType, // 'text', 'image', 'voice'
  }) async {
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {
        'chat_id': chatId,
        'message_type': messageType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logVideoCallStarted({
    required String chatId,
    required int duration, // in seconds
  }) async {
    await _analytics.logEvent(
      name: 'video_call_started',
      parameters: {
        'chat_id': chatId,
        'duration': duration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // User engagement events
  static Future<void> logProfileUpdated() async {
    await _analytics.logEvent(
      name: 'profile_updated',
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logRatingGiven({
    required String targetUserId,
    required double rating,
    required String context, // 'item_return', 'helpfulness', etc.
  }) async {
    await _analytics.logEvent(
      name: 'rating_given',
      parameters: {
        'target_user_id': targetUserId,
        'rating': rating,
        'context': context,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logQRCodeScanned({
    required String qrType, // 'item', 'user', 'other'
    required String qrData,
  }) async {
    await _analytics.logEvent(
      name: 'qr_code_scanned',
      parameters: {
        'qr_type': qrType,
        'qr_data_length': qrData.length,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<void> logQRCodeGenerated({
    required String qrType,
    required String itemId,
  }) async {
    await _analytics.logEvent(
      name: 'qr_code_generated',
      parameters: {
        'qr_type': qrType,
        'item_id': itemId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Feature usage events
  static Future<void> logFeatureUsed({
    required String featureName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {
        'feature_name': featureName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?parameters,
      },
    );
  }

  static Future<void> logOfflineDataSync({
    required int itemsSynced,
    required int syncDuration, // in milliseconds
  }) async {
    await _analytics.logEvent(
      name: 'offline_data_synced',
      parameters: {
        'items_synced': itemsSynced,
        'sync_duration_ms': syncDuration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Error tracking
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
  }) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage.length > 100 ? errorMessage.substring(0, 100) : errorMessage,
        'has_stack_trace': stackTrace != null,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // Performance tracking
  static Future<void> logPerformanceMetric({
    required String metricName,
    required int value, // in milliseconds
    Map<String, dynamic>? additionalData,
  }) async {
    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: {
        'metric_name': metricName,
        'value_ms': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?additionalData,
      },
    );
  }

  // Custom events
  static Future<void> logCustomEvent({
    required String eventName,
    Map<String, dynamic>? parameters,
  }) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...?parameters,
      },
    );
  }

  // Get analytics instance for advanced usage
  static FirebaseAnalytics get instance => _analytics;
}