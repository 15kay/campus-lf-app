import 'package:flutter/material.dart';
import '../models/item.dart';

class StatsCards extends StatelessWidget {
  final List<Item> items;

  const StatsCards({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final totalItems = items.length;
    final lostItems = items.where((item) => item.isLost).length;
    final foundItems = items.where((item) => !item.isLost).length;
    final todayItems = items.where((item) => 
      DateTime.now().difference(item.dateTime).inDays == 0
    ).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Items',
            totalItems.toString(),
            Icons.inventory,
            Colors.blue,
            '+12% from last week',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Lost Items',
            lostItems.toString(),
            Icons.search,
            Colors.red,
            '${lostItems > 0 ? ((lostItems/totalItems)*100).round() : 0}% of total',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Found Items',
            foundItems.toString(),
            Icons.check_circle,
            Colors.green,
            '${foundItems > 0 ? ((foundItems/totalItems)*100).round() : 0}% of total',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Today\'s Reports',
            todayItems.toString(),
            Icons.today,
            Colors.orange,
            'New reports today',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}