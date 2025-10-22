import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'chat_page.dart';

class ItemDetailsPage extends StatelessWidget {
  final Report report;

  const ItemDetailsPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(report.itemName),
        backgroundColor: cs.surface,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(report.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.status,
                            style: TextStyle(
                              color: _getStatusColor(report.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTypeColor(report.type).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            report.type,
                            style: TextStyle(
                              color: _getTypeColor(report.type),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      report.itemName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Report ID: ${report.reportId}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Details Section
            _buildDetailSection(
              context,
              'Description',
              report.description,
              Icons.description_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailSection(
              context,
              'Location',
              report.location,
              Icons.location_on_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailSection(
              context,
              'Date Reported',
              _formatDate(report.date),
              Icons.calendar_today_outlined,
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailSection(
              context,
              'Reporter ID',
              report.uid,
              Icons.contact_phone_outlined,
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactReporter(context),
                    icon: const Icon(Icons.message),
                    label: const Text('Contact Reporter'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share functionality coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, String content, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'found':
        return const Color(0xFF10B981); // Green
      case 'lost':
        return const Color(0xFFEF4444); // Red
      case 'resolved':
        return const Color(0xFF6366F1); // Blue
      case 'pending':
        return const Color(0xFFF59E0B); // Amber
      case 'cancelled':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lost':
        return const Color(0xFFEF4444); // Red
      case 'found':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF6366F1); // Blue
    }
  }

  void _contactReporter(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to contact the reporter')),
        );
        return;
      }

      if (report.uid == currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot contact yourself')),
        );
        return;
      }

      // Get the other user's information
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(report.uid)
          .get();
      
      if (!otherUserDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      final otherUserData = otherUserDoc.data()!;
      final otherUserName = otherUserData['name'] ?? 'Unknown User';

      // Create conversation object
      final sortedUids = [currentUser.uid, report.uid]..sort();
      final conversationId = '${sortedUids[0]}_${sortedUids[1]}';
      
      final conversation = Conversation(
        id: conversationId,
        participants: [currentUser.uid, report.uid],
        messages: [],
        lastActivity: DateTime.now(),
      );

      // Create chat entry so both users can see the conversation in their chat list
      final chatId = conversationId;
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, report.uid],
        'lastMessage': 'Chat started about: ${report.itemName}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'conversationId': conversationId,
        'unreadCount_${currentUser.uid}': 0,
        'unreadCount_${report.uid}': 1,
      }, SetOptions(merge: true));

      // Navigate to chat page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(conversation: conversation),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}