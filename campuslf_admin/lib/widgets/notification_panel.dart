import 'package:flutter/material.dart';
import 'dart:async';

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Timer _notificationTimer;
  final List<AdminNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _generateInitialNotifications();
    _startNotificationStream();
  }

  void _generateInitialNotifications() {
    _notifications.addAll([
      AdminNotification(
        id: '1',
        title: 'New Item Reported',
        message: 'iPhone 13 Pro reported lost in Main Library',
        type: NotificationType.newItem,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        priority: Priority.high,
      ),
      AdminNotification(
        id: '2',
        title: 'Match Found',
        message: 'Potential match for blue backpack found',
        type: NotificationType.match,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        priority: Priority.medium,
      ),
      AdminNotification(
        id: '3',
        title: 'System Alert',
        message: 'High activity detected in Student Center area',
        type: NotificationType.system,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        priority: Priority.low,
      ),
    ]);
  }

  void _startNotificationStream() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _addRandomNotification();
    });
  }

  void _addRandomNotification() {
    final notifications = [
      'New wallet found in Cafeteria',
      'Student ID card reported missing',
      'Laptop charger found in Library',
      'Keys reported lost in Parking Lot',
      'Textbook found in Engineering Building',
    ];

    final types = [
      NotificationType.newItem,
      NotificationType.resolved,
      NotificationType.match,
    ];

    final priorities = [Priority.low, Priority.medium, Priority.high];

    setState(() {
      _notifications.insert(0, AdminNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Live Update',
        message: notifications[DateTime.now().second % notifications.length],
        type: types[DateTime.now().second % types.length],
        timestamp: DateTime.now(),
        priority: priorities[DateTime.now().second % priorities.length],
      ));

      // Keep only last 10 notifications
      if (_notifications.length > 10) {
        _notifications.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _notificationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Live Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _notifications.where((n) => !n.isRead).length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _markAllAsRead,
                child: const Icon(
                  Icons.done_all,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification, index);
      },
    );
  }

  Widget _buildNotificationItem(AdminNotification notification, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          setState(() {
            _notifications.remove(notification);
          });
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        child: GestureDetector(
          onTap: () => _markAsRead(notification),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.grey.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _buildPriorityIndicator(notification.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(Priority priority) {
    Color color;
    switch (priority) {
      case Priority.high:
        color = Colors.red;
        break;
      case Priority.medium:
        color = Colors.orange;
        break;
      case Priority.low:
        color = Colors.green;
        break;
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newItem:
        return Colors.blue;
      case NotificationType.match:
        return Colors.green;
      case NotificationType.resolved:
        return Colors.orange;
      case NotificationType.system:
        return Colors.purple;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newItem:
        return Icons.add_circle;
      case NotificationType.match:
        return Icons.search;
      case NotificationType.resolved:
        return Icons.check_circle;
      case NotificationType.system:
        return Icons.settings;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _markAsRead(AdminNotification notification) {
    setState(() {
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
  }
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Priority priority;
  bool isRead;

  AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.priority,
    this.isRead = false,
  });
}

enum NotificationType { newItem, match, resolved, system }
enum Priority { low, medium, high }