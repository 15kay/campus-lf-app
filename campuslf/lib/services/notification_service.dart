import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  void showItemMatch(Item lostItem, Item foundItem) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '🎯 Potential Match Found!',
      body: 'Found item "${foundItem.title}" matches your lost "${lostItem.title}"',
      type: NotificationType.match,
      timestamp: DateTime.now(),
      data: {'lostItem': lostItem, 'foundItem': foundItem},
    );
    _addNotification(notification);
  }

  void showNewMessage(String senderName, String message) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '💬 New Message',
      body: '$senderName: $message',
      type: NotificationType.message,
      timestamp: DateTime.now(),
      data: {'sender': senderName},
    );
    _addNotification(notification);
  }

  void showItemResolved(Item item) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '✅ Item Resolved!',
      body: 'Your ${item.isLost ? "lost" : "found"} item "${item.title}" has been resolved',
      type: NotificationType.resolved,
      timestamp: DateTime.now(),
      data: {'item': item},
    );
    _addNotification(notification);
  }

  void _addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    unreadCount.value++;
    HapticFeedback.lightImpact();
  }

  List<AppNotification> getNotifications() => _notifications;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      unreadCount.value = _notifications.where((n) => !n.isRead).length;
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
    unreadCount.value = 0;
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });
}

enum NotificationType { match, message, resolved, general }