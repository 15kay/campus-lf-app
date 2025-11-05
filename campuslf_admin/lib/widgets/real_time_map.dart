import 'package:flutter/material.dart';
import 'dart:math';
import '../models/item.dart';

class RealTimeMap extends StatefulWidget {
  final List<Item> items;

  const RealTimeMap({super.key, required this.items});

  @override
  State<RealTimeMap> createState() => _RealTimeMapState();
}

class _RealTimeMapState extends State<RealTimeMap> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final String _selectedLocation = 'All';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
          _buildMapHeader(),
          Expanded(
            child: Stack(
              children: [
                _buildCampusMap(),
                _buildItemMarkers(),
                _buildLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapHeader() {
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
            'Live Campus Map',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Live',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampusMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CustomPaint(
        painter: CampusMapPainter(),
      ),
    );
  }

  Widget _buildItemMarkers() {
    return Stack(
      children: widget.items.map((item) {
        final position = _getItemPosition(item.location);
        return Positioned(
          left: position.dx - 12,
          top: position.dy - 12,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return GestureDetector(
                onTap: () => _showItemPopup(item),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulse effect for recent items
                    if (_isRecentItem(item))
                      Container(
                        width: 24 + (_pulseController.value * 16),
                        height: 24 + (_pulseController.value * 16),
                        decoration: BoxDecoration(
                          color: (item.isLost ? Colors.red : Colors.green)
                              .withOpacity(0.3 - (_pulseController.value * 0.3)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    // Main marker
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: item.isLost ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(item.category),
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legend',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            _buildLegendItem('Lost Items', Colors.red),
            _buildLegendItem('Found Items', Colors.green),
            _buildLegendItem('Recent (24h)', Colors.blue, isPulsing: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isPulsing = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isPulsing)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 12 + (_pulseController.value * 4),
                      height: 12 + (_pulseController.value * 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3 - (_pulseController.value * 0.3)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Offset _getItemPosition(String location) {
    final locationMap = {
      'Main Library': const Offset(120, 80),
      'Student Center': const Offset(200, 120),
      'Engineering Building': const Offset(80, 160),
      'Science Building': const Offset(250, 100),
      'Administration': const Offset(160, 60),
      'Main Cafeteria': const Offset(180, 140),
      'Parking Lot A': const Offset(60, 200),
      'Sports Complex': const Offset(280, 180),
      'Residence Hall': const Offset(100, 220),
      'Main Gate': const Offset(40, 120),
    };

    final basePosition = locationMap[location] ?? const Offset(150, 150);
    final random = Random(location.hashCode);
    final randomOffset = Offset(
      (random.nextDouble() - 0.5) * 30,
      (random.nextDouble() - 0.5) * 30,
    );

    return basePosition + randomOffset;
  }

  IconData _getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics:
        return Icons.phone_android;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.books:
        return Icons.book;
      case ItemCategory.accessories:
        return Icons.watch;
      case ItemCategory.keys:
        return Icons.key;
      case ItemCategory.bags:
        return Icons.backpack;
      case ItemCategory.documents:
        return Icons.description;
      case ItemCategory.sports:
        return Icons.sports_basketball;
      case ItemCategory.personal:
        return Icons.person;
      case ItemCategory.academic:
        return Icons.school;
      case ItemCategory.other:
        return Icons.help_outline;
    }
  }

  bool _isRecentItem(Item item) {
    return DateTime.now().difference(item.dateTime).inHours < 24;
  }

  void _showItemPopup(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(item.category),
              color: item.isLost ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Status', item.isLost ? 'Lost' : 'Found'),
            _buildInfoRow('Location', item.location),
            _buildInfoRow('Category', Item.getCategoryName(item.category)),
            _buildInfoRow('Contact', item.contactInfo),
            _buildInfoRow('Reported', _formatDateTime(item.dateTime)),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle item action
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: item.isLost ? Colors.red : Colors.green,
            ),
            child: Text(
              item.isLost ? 'Mark Found' : 'Contact Reporter',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
}

class CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw campus buildings
    final buildings = [
      const Rect.fromLTWH(100, 60, 80, 60),   // Library
      const Rect.fromLTWH(180, 100, 60, 50),  // Student Center
      const Rect.fromLTWH(60, 140, 70, 60),   // Engineering
      const Rect.fromLTWH(230, 80, 60, 50),   // Science
      const Rect.fromLTWH(140, 40, 50, 40),   // Administration
      const Rect.fromLTWH(160, 120, 60, 40),  // Cafeteria
      const Rect.fromLTWH(40, 180, 40, 60),   // Parking
      const Rect.fromLTWH(260, 160, 50, 50),  // Sports
    ];

    // Fill buildings
    paint.style = PaintingStyle.fill;
    paint.color = Colors.grey.shade200;
    for (final building in buildings) {
      canvas.drawRect(building, paint);
    }

    // Draw building outlines
    paint.style = PaintingStyle.stroke;
    paint.color = Colors.grey.shade400;
    for (final building in buildings) {
      canvas.drawRect(building, paint);
    }

    // Draw paths
    paint.color = Colors.grey.shade300;
    paint.strokeWidth = 4;
    
    // Main horizontal path
    canvas.drawLine(
      const Offset(20, 120),
      Offset(size.width - 20, 120),
      paint,
    );
    
    // Vertical paths
    canvas.drawLine(
      const Offset(120, 20),
      const Offset(120, 200),
      paint,
    );
    
    canvas.drawLine(
      const Offset(200, 20),
      const Offset(200, 200),
      paint,
    );

    // Add building labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final buildingLabels = {
      'Library': const Offset(130, 85),
      'Student\nCenter': const Offset(200, 120),
      'Engineering': const Offset(85, 165),
      'Science': const Offset(250, 100),
      'Admin': const Offset(160, 55),
    };

    buildingLabels.forEach((label, position) {
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, position);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}