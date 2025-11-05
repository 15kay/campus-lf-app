import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'User Manual',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '🏠 Getting Started',
              [
                'Sign up with your WSU email or continue as guest',
                'Browse lost and found items on the home screen',
                'Use filters to find specific categories',
                'Tap on any item to view details',
              ],
            ),
            _buildSection(
              '📝 Reporting Items',
              [
                'Tap "Report" in bottom navigation',
                'Choose "Lost Item" or "Found Item"',
                'Fill in item details and description',
                'Add up to 5 photos for better identification',
                'Select campus location where item was lost/found',
                'Submit to help others find their belongings',
              ],
            ),
            _buildSection(
              '💬 Messaging System',
              [
                'Tap "Send Message" on any item to contact owner',
                'View all conversations in Messages tab',
                'Make voice/video calls directly from chat',
                'Messages are saved for future reference',
              ],
            ),
            _buildSection(
              '🔍 Search & Filters',
              [
                'Use search bar on home screen',
                'Filter by category (Electronics, Books, etc.)',
                'Filter by status (Lost or Found)',
                'Sort by date or relevance',
              ],
            ),
            _buildSection(
              '⭐ Karma System',
              [
                'Earn karma points by helping others',
                '+10 points for reporting items',
                '+5 points for resolving items',
                'Higher karma = trusted community member',
              ],
            ),
            _buildSection(
              '👤 Profile Management',
              [
                'View your karma and statistics',
                'Access quick actions (Report, Messages, etc.)',
                'Manage account settings',
                'View achievements and progress',
                'Logout when needed',
              ],
            ),
            _buildSection(
              '🔐 Safety Tips',
              [
                'Meet in public campus locations',
                'Verify item ownership before handover',
                'Report suspicious activity to campus security',
                'Use in-app messaging for communication',
              ],
            ),
            _buildSection(
              '📞 Support',
              [
                'Email: lostfound@wsu.ac.za',
                'Phone: +27 43 702 9111',
                'Office: Student Affairs, Building A',
                'Hours: Mon-Fri 8AM-4:30PM, Sat 8AM-12PM',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, color: Colors.black)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}