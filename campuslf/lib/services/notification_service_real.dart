import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class NotificationServiceReal {
  static final NotificationServiceReal _instance = NotificationServiceReal._internal();
  factory NotificationServiceReal() => _instance;
  NotificationServiceReal._internal();

  final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  Future<void> initialize() async {
    // Simulate periodic notifications for demo
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _sendRandomNotification();
    });
  }

  Future<void> sendItemMatchNotification(Item item) async {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Potential Match Found!',
      'body': 'Someone reported a ${item.isLost ? 'found' : 'lost'} ${item.title}',
      'type': 'match',
      'itemId': item.id,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _storeNotification(notification);
    _notificationController.add(notification);
  }

  Future<void> sendMessageNotification(String senderName, String message) async {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'New Message from $senderName',
      'body': message.length > 50 ? '${message.substring(0, 50)}...' : message,
      'type': 'message',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _storeNotification(notification);
    _notificationController.add(notification);
  }

  Future<void> sendItemStatusNotification(String itemTitle, String status) async {
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'Item Status Update',
      'body': 'Your $itemTitle has been marked as $status',
      'type': 'status',
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await _storeNotification(notification);
    _notificationController.add(notification);
  }

  Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    
    return notificationsJson.map((json) {
      final parts = json.split('|');
      return {
        'id': parts[0],
        'title': parts[1],
        'body': parts[2],
        'type': parts[3],
        'timestamp': parts[4],
        'isRead': parts.length > 5 ? parts[5] == 'true' : false,
      };
    }).toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getStoredNotifications();
    
    final updatedNotifications = notifications.map((notification) {
      if (notification['id'] == notificationId) {
        notification['isRead'] = true;
      }
      return notification;
    }).toList();
    
    final notificationsJson = updatedNotifications.map((notification) =>
      '${notification['id']}|${notification['title']}|${notification['body']}|${notification['type']}|${notification['timestamp']}|${notification['isRead']}'
    ).toList();
    
    await prefs.setStringList('notifications', notificationsJson);
  }

  Future<void> _storeNotification(Map<String, dynamic> notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList('notifications') ?? [];
    
    final notificationString = '${notification['id']}|${notification['title']}|${notification['body']}|${notification['type']}|${notification['timestamp']}|false';
    notifications.insert(0, notificationString);
    
    // Keep only last 50 notifications
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    
    await prefs.setStringList('notifications', notifications);
  }

  void _sendRandomNotification() {
    final notifications = [
      {
        'title': 'New Item Reported',
        'body': 'Someone found a phone near the library',
        'type': 'item',
      },
      {
        'title': 'Potential Match',
        'body': 'Your lost keys might have been found',
        'type': 'match',
      },
      {
        'title': 'Reminder',
        'body': 'Check for updates on your reported items',
        'type': 'reminder',
      },
    ];
    
    final randomNotification = notifications[DateTime.now().millisecond % notifications.length];
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': randomNotification['title']!,
      'body': randomNotification['body']!,
      'type': randomNotification['type']!,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _storeNotification(notification);
    _notificationController.add(notification);
  }

  void dispose() {
    _notificationController.close();
  }
}