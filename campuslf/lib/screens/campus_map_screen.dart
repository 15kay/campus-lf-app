import 'package:flutter/material.dart';
import '../models/item.dart';

class CampusMapScreen extends StatefulWidget {
  final List<Item> items;

  const CampusMapScreen({super.key, required this.items});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Lost', 'Found', 'Electronics', 'Personal', 'Academic'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Campus Map',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildMap()),
          _buildLocationStats(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Campus map background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(
              painter: CampusMapPainter(),
            ),
          ),
          // Item markers
          ..._buildItemMarkers(),
          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemMarkers() {
    final filteredItems = _getFilteredItems();
    final markers = <Widget>[];

    for (int i = 0; i < filteredItems.length; i++) {
      final item = filteredItems[i];
      final position = _getItemPosition(item.location, i);
      
      markers.add(
        Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onTap: () => _showItemPopup(item),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.isLost ? Colors.red : Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Item.getCategoryIcon(item.category),
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Offset _getItemPosition(String location, int index) {
    // Map locations to approximate positions on campus
    final locationMap = {
      'Library': const Offset(150, 100),
      'Student Center': const Offset(200, 150),
      'Engineering Building': const Offset(100, 200),
      'Science Building': const Offset(250, 120),
      'Administration': const Offset(180, 80),
      'Cafeteria': const Offset(220, 180),
      'Parking Lot A': const Offset(80, 250),
      'Sports Complex': const Offset(280, 200),
      'Residence Hall': const Offset(120, 300),
      'Main Gate': const Offset(50, 150),
    };

    // Add some randomness to avoid overlapping markers
    final basePosition = locationMap[location] ?? const Offset(150, 150);
    final randomOffset = Offset(
      (index % 3 - 1) * 15.0,
      ((index ~/ 3) % 3 - 1) * 15.0,
    );

    return basePosition + randomOffset;
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Lost', style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text('Found', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStats() {
    final locationCounts = <String, int>{};
    for (final item in widget.items) {
      locationCounts[item.location] = (locationCounts[item.location] ?? 0) + 1;
    }

    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hotspots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedLocations.take(5).length,
              itemBuilder: (context, index) {
                final entry = sortedLocations[index];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    '${entry.key} (${entry.value})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Item> _getFilteredItems() {
    if (_selectedFilter == 'All') return widget.items;
    if (_selectedFilter == 'Lost') return widget.items.where((item) => item.isLost).toList();
    if (_selectedFilter == 'Found') return widget.items.where((item) => !item.isLost).toList();
    
    // Filter by category
    final categoryMap = {
      'Electronics': ItemCategory.electronics,
      'Personal': ItemCategory.personal,
      'Academic': ItemCategory.academic,
    };
    
    final category = categoryMap[_selectedFilter];
    if (category != null) {
      return widget.items.where((item) => item.category == category).toList();
    }
    
    return widget.items;
  }

  void _showItemPopup(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${item.isLost ? "Lost" : "Found"}'),
            Text('Location: ${item.location}'),
            Text('Category: ${Item.getCategoryName(item.category)}'),
            const SizedBox(height: 8),
            Text(item.description),
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
              // Navigate to item details
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }
}

class CampusMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw campus buildings as rectangles
    final buildings = [
      const Rect.fromLTWH(120, 80, 80, 60),   // Library
      const Rect.fromLTWH(180, 130, 60, 50),  // Student Center
      const Rect.fromLTWH(80, 180, 70, 60),   // Engineering
      const Rect.fromLTWH(230, 100, 60, 50),  // Science
      const Rect.fromLTWH(160, 60, 50, 40),   // Administration
    ];

    for (final building in buildings) {
      canvas.drawRect(building, paint);
    }

    // Draw paths
    paint.color = Colors.grey.shade400;
    paint.strokeWidth = 3;
    
    // Main path
    canvas.drawLine(
      const Offset(50, 150),
      const Offset(300, 150),
      paint,
    );
    
    // Cross paths
    canvas.drawLine(
      const Offset(150, 50),
      const Offset(150, 250),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}