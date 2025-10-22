import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Configure Firebase messaging
    await _configureFCM();
    
    // Set up message handlers
    _setupMessageHandlers();
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
    
    await Permission.notification.request();
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // High priority channel for match notifications
      const AndroidNotificationChannel matchChannel = AndroidNotificationChannel(
        'match_notifications',
        'Match Notifications',
        description: 'Notifications for new matches found',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
        showBadge: true,
        playSound: true,
      );

      // Message channel for chat notifications
      const AndroidNotificationChannel messageChannel = AndroidNotificationChannel(
        'message_notifications',
        'Message Notifications',
        description: 'Notifications for new messages',
        importance: Importance.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
        showBadge: true,
        playSound: true,
      );

      // General channel for other notifications
      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        'general_notifications',
        'General Notifications',
        description: 'General app notifications',
        importance: Importance.defaultImportance,
        enableVibration: false,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(matchChannel);
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(messageChannel);
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);
    }
  }

  static Future<void> _configureFCM() async {
    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Log analytics event
    await _analytics.logEvent(
      name: 'fcm_token_generated',
      parameters: {'token_length': token?.length ?? 0},
    );
  }

  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification
    await _showLocalNotification(
      title: message.notification?.title ?? 'Campus Lost & Found',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
    
    // Log analytics
    await _analytics.logEvent(
      name: 'notification_received_foreground',
      parameters: {
        'message_id': message.messageId ?? '',
        'notification_type': message.data['type'] ?? 'unknown',
      },
    );
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Received background message: ${message.messageId}');
    
    // Log analytics
    await _analytics.logEvent(
      name: 'notification_received_background',
      parameters: {
        'message_id': message.messageId ?? '',
        'notification_type': message.data['type'] ?? 'unknown',
      },
    );
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');
    
    // Log analytics
    await _analytics.logEvent(
      name: 'notification_tapped',
      parameters: {
        'message_id': message.messageId ?? '',
        'notification_type': message.data['type'] ?? 'unknown',
      },
    );
    
    // Handle navigation based on notification type
    _handleNotificationNavigation(message.data);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    
    // Parse payload and handle navigation
    if (response.payload != null) {
      try {
        final Map<String, dynamic> payload = jsonDecode(response.payload!);
        _handleNotificationNavigation(payload);
      } catch (e) {
        // Fallback for old payload format
        _handleLocalNotificationNavigation(response.payload!);
      }
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'campus_lf_channel',
      'Campus Lost & Found',
      channelDescription: 'Notifications for Campus Lost & Found app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Public methods for sending notifications
  static Future<void> sendNewMessageNotification({
    required String recipientId,
    required String senderName,
    required String itemName,
  }) async {
    await _showLocalNotification(
      title: 'New Message from $senderName',
      body: 'About: $itemName',
      payload: 'chat:$recipientId',
    );
    
    await _analytics.logEvent(
      name: 'notification_sent_new_message',
      parameters: {
        'recipient_id': recipientId,
        'sender_name': senderName,
      },
    );
  }

  static Future<void> sendItemMatchNotification({
    required String userId,
    required String itemName,
    required String matchType,
    required String matchId,
    String? matchedUserName,
    String? itemImageUrl,
  }) async {
    // Create WhatsApp-style match notification
    await _showMatchNotification(
      title: 'New Match Found! 🎉',
      body: 'Tap to see who you matched with',
      itemName: itemName,
      matchType: matchType,
      matchId: matchId,
      matchedUserName: matchedUserName,
      itemImageUrl: itemImageUrl,
    );
    
    // Trigger haptic feedback
    if (Platform.isIOS || Platform.isAndroid) {
      HapticFeedback.mediumImpact();
    }
    
    await _analytics.logEvent(
      name: 'notification_sent_item_match',
      parameters: {
        'user_id': userId,
        'item_name': itemName,
        'match_type': matchType,
        'match_id': matchId,
      },
    );
  }

  static Future<void> _showMatchNotification({
    required String title,
    required String body,
    required String itemName,
    required String matchType,
    required String matchId,
    String? matchedUserName,
    String? itemImageUrl,
  }) async {
    // Create rich notification with custom styling
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'match_notifications',
      'Match Notifications',
      channelDescription: 'Notifications for new matches found',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      enableLights: true,
      ledColor: const Color(0xFF4CAF50),
      color: const Color(0xFF4CAF50),
      colorized: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Someone ${matchType == 'found' ? 'found' : 'lost'} your $itemName. ${matchedUserName != null ? 'Matched with $matchedUserName.' : ''} Tap to view details and start chatting!',
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: 'Campus Lost & Found',
        htmlFormatSummaryText: true,
      ),
      actions: [
        const AndroidNotificationAction(
          'view_match',
          'View Match',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_visibility'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
          cancelNotification: true,
        ),
      ],
      category: AndroidNotificationCategory.social,
      visibility: NotificationVisibility.public,
      ticker: 'New match found for $itemName',
      autoCancel: true,
      ongoing: false,
      silent: false,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
      categoryIdentifier: 'MATCH_CATEGORY',
      threadIdentifier: 'match_notifications',
      subtitle: 'Campus Lost & Found',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create payload with match details
    final Map<String, dynamic> payload = {
      'type': 'match',
      'match_id': matchId,
      'item_name': itemName,
      'match_type': matchType,
      'matched_user_name': matchedUserName,
      'item_image_url': itemImageUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _localNotifications.show(
      matchId.hashCode, // Use match ID hash as notification ID
      title,
      body,
      details,
      payload: jsonEncode(payload),
    );
  }

  static Future<void> sendStatusUpdateNotification({
    required String userId,
    required String itemName,
    required String newStatus,
  }) async {
    await _showLocalNotification(
      title: 'Item Status Updated',
      body: 'Your $itemName is now marked as $newStatus',
      payload: 'reports:$userId',
    );
    
    await _analytics.logEvent(
      name: 'notification_sent_status_update',
      parameters: {
        'user_id': userId,
        'item_name': itemName,
        'new_status': newStatus,
      },
    );
  }



  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    await _analytics.logEvent(
      name: 'notification_topic_subscribed',
      parameters: {'topic': topic},
    );
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    await _analytics.logEvent(
      name: 'notification_topic_unsubscribed',
      parameters: {'topic': topic},
    );
  }

  // Custom notification tap handler
  static Function(Map<String, dynamic>)? _customNotificationTapHandler;

  static void setNotificationTapHandler(Function(Map<String, dynamic>) handler) {
    _customNotificationTapHandler = handler;
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (_customNotificationTapHandler != null) {
      _customNotificationTapHandler!(data);
    } else {
      // Default navigation handling
      print('No custom notification handler set. Data: $data');
    }
  }

  static void _handleLocalNotificationNavigation(String payload) {
    // Handle legacy payload format
    if (_customNotificationTapHandler != null) {
      _customNotificationTapHandler!({'payload': payload});
    } else {
      print('No custom notification handler set. Payload: $payload');
    }
  }
}