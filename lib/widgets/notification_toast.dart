import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class NotificationToast extends StatefulWidget {
  final String title;
  final String message;
  final String? imageUrl;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showCloseButton;
  final bool enableHapticFeedback;

  const NotificationToast({
    Key? key,
    required this.title,
    required this.message,
    this.imageUrl,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration = const Duration(seconds: 4),
    this.onTap,
    this.onDismiss,
    this.showCloseButton = true,
    this.enableHapticFeedback = true,
  }) : super(key: key);

  @override
  State<NotificationToast> createState() => _NotificationToastState();

  /// Show a WhatsApp-style notification toast
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? imageUrl,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
    bool showCloseButton = true,
    bool enableHapticFeedback = true,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotificationToast(
            title: title,
            message: message,
            imageUrl: imageUrl,
            icon: icon,
            backgroundColor: backgroundColor,
            textColor: textColor,
            duration: duration,
            onTap: () {
              overlayEntry.remove();
              onTap?.call();
            },
            onDismiss: () {
              overlayEntry.remove();
              onDismiss?.call();
            },
            showCloseButton: showCloseButton,
            enableHapticFeedback: enableHapticFeedback,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Timer(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
        onDismiss?.call();
      }
    });
  }

  /// Show a match notification toast
  static void showMatchNotification(
    BuildContext context, {
    required String itemName,
    required String matchedUserName,
    String? itemImageUrl,
    VoidCallback? onTap,
  }) {
    if (context.mounted) {
      show(
        context,
        title: 'New Match Found! 🎉',
        message: 'Someone found your $itemName. Tap to chat with $matchedUserName.',
        imageUrl: itemImageUrl,
        icon: Icons.celebration,
        backgroundColor: const Color(0xFF4CAF50),
        textColor: Colors.white,
        duration: const Duration(seconds: 6),
        onTap: onTap,
        enableHapticFeedback: true,
      );
    }
  }

  /// Show a message notification toast
  static void showMessageNotification(
    BuildContext context, {
    required String senderName,
    required String message,
    String? senderImageUrl,
    VoidCallback? onTap,
  }) {
    if (context.mounted) {
      show(
        context,
        title: senderName,
        message: message,
        imageUrl: senderImageUrl,
        icon: Icons.message,
        backgroundColor: const Color(0xFF2196F3),
        textColor: Colors.white,
        duration: const Duration(seconds: 4),
        onTap: onTap,
        enableHapticFeedback: true,
      );
    }
  }
}

class _NotificationToastState extends State<NotificationToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Trigger haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanUpdate: (details) {
                // Allow swipe up to dismiss
                if (details.delta.dy < -5) {
                  _dismiss();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? const Color(0xFF323232),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Leading icon or image
                          _buildLeadingWidget(),
                          const SizedBox(width: 12),
                          
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: widget.textColor ?? Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: (widget.textColor ?? Colors.white).withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Close button
                          if (widget.showCloseButton)
                            GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: widget.textColor ?? Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingWidget() {
    if (widget.imageUrl != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.imageUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconWidget();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildIconWidget();
            },
          ),
        ),
      );
    }
    
    return _buildIconWidget();
  }

  Widget _buildIconWidget() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        widget.icon ?? Icons.notifications,
        color: widget.textColor ?? Colors.white,
        size: 24,
      ),
    );
  }
}

/// Notification manager for handling multiple notifications
class NotificationManager {
  static final List<OverlayEntry> _activeNotifications = [];
  static const int maxNotifications = 3;

  static void showNotification(
    BuildContext context, {
    required String title,
    required String message,
    String? imageUrl,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    // Remove oldest notification if we have too many
    if (_activeNotifications.length >= maxNotifications) {
      final oldest = _activeNotifications.removeAt(0);
      oldest.remove();
    }

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10 + (_activeNotifications.length * 80),
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotificationToast(
            title: title,
            message: message,
            imageUrl: imageUrl,
            icon: icon,
            backgroundColor: backgroundColor,
            textColor: textColor,
            duration: duration,
            onTap: () {
              _removeNotification(overlayEntry);
              onTap?.call();
            },
            onDismiss: () {
              _removeNotification(overlayEntry);
              onDismiss?.call();
            },
          ),
        ),
      ),
    );

    _activeNotifications.add(overlayEntry);
    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Timer(duration, () {
      _removeNotification(overlayEntry);
      onDismiss?.call();
    });
  }

  static void _removeNotification(OverlayEntry entry) {
    if (_activeNotifications.contains(entry) && entry.mounted) {
      _activeNotifications.remove(entry);
      entry.remove();
    }
  }

  static void clearAllNotifications() {
    for (final entry in _activeNotifications) {
      if (entry.mounted) {
        entry.remove();
      }
    }
    _activeNotifications.clear();
  }
}