import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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
      // Handle navigation based on payload
      _handleLocalNotificationNavigation(response.payload!);
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
    
    const NotificationDetails details = NotificationDetails(
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
  }) async {
    await _showLocalNotification(
      title: 'Potential Match Found!',
      body: 'Someone may have ${matchType == 'found' ? 'found' : 'lost'} your $itemName',
      payload: 'matches:$userId',
    );
    
    await _analytics.logEvent(
      name: 'notification_sent_item_match',
      parameters: {
        'user_id': userId,
        'item_name': itemName,
        'match_type': matchType,
      },
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

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // This will be implemented with navigation logic
    String type = data['type'] ?? '';
    String targetId = data['target_id'] ?? '';
    
    print('Handling notification navigation: $type -> $targetId');
    // TODO: Implement navigation logic based on notification type
  }

  static void _handleLocalNotificationNavigation(String payload) {
    print('Handling local notification navigation: $payload');
    // TODO: Implement navigation logic based on payload
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
}