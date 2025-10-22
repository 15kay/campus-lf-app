import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import '../services/firebase_service.dart';
import 'item_details_page.dart';
import 'chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Report> _userReports = [];
  Map<String, List<Report>> _matchesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserReportsAndMatches();
  }

  Future<void> _loadUserReportsAndMatches() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get user's reports
      final userReportsStream = FirebaseService.getUserReportsStream(currentUser.uid);
      userReportsStream.listen((reports) async {
        setState(() {
          _userReports = reports.where((r) => r.status != 'Resolved' && r.status != 'Returned').toList();
        });

        // Find matches for each report
        final Map<String, List<Report>> newMatchesMap = {};
        for (final report in _userReports) {
          try {
            final matches = await FirebaseService.findPotentialMatches(report);
            if (matches.isNotEmpty) {
              newMatchesMap[report.reportId] = matches;
            }
          } catch (e) {
            print('Error finding matches for ${report.itemName}: $e');
          }
        }

        setState(() {
          _matchesMap = newMatchesMap;
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading matches: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potential Matches'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_matchesMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No potential matches found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you when potential matches are found for your items.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchesMap.length,
      itemBuilder: (context, index) {
        final reportId = _matchesMap.keys.elementAt(index);
        final userReport = _userReports.firstWhere((r) => r.reportId == reportId);
        final matches = _matchesMap[reportId]!;

        return _buildMatchSection(userReport, matches);
      },
    );
  }

  Widget _buildMatchSection(Report userReport, List<Report> matches) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User's report header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: userReport.imageBytes != null 
                      ? null 
                      : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE0C200)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: userReport.imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          userReport.imageBytes!,
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                      )
                    : Icon(
                        userReport.status == 'Lost' ? Icons.search : Icons.check_circle, 
                        color: Colors.black87,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your ${userReport.status} Item',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userReport.itemName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${userReport.category} • ${userReport.location}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Potential Matches (${matches.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ...matches.map((match) => _buildMatchItem(userReport, match)),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchItem(Report userReport, Report match) {
    final matchScore = FirebaseService.calculateMatchScore(userReport, match);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: match.imageBytes != null 
                    ? null 
                    : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE0C200)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: match.imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        match.imageBytes!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                      ),
                    )
                  : Icon(
                      match.status == 'Lost' ? Icons.search : Icons.check_circle, 
                      color: Colors.black87,
                      size: 20,
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
                            match.itemName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${matchScore}% match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${match.status} • ${match.category} • ${match.location}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (match.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        match.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewDetails(match),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactOwner(match),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewDetails(Report report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsPage(report: report),
      ),
    );
  }

  void _contactOwner(Report report) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to contact the owner')),
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
        'lastMessage': 'Chat started about potential match: ${report.itemName}',
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
}