import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'notification_service.dart';
import 'email_service.dart';
import 'firebase_service.dart';
import '../models.dart';
import 'dart:convert';

class MatchNotificationHandler {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize the match notification handler
  static Future<void> initialize() async {
    print('MatchNotificationHandler initialized');
    // Any initialization logic can go here
  }
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Handles the complete notification flow when a match is found
  static Future<void> handleNewMatch({
    required String matchId,
    required Report lostItem,
    required Report foundItem,
    required UserProfile lostItemOwner,
    required UserProfile foundItemOwner,
  }) async {
    try {
      // Send notifications to both users
      await Future.wait([
        _notifyUser(
          user: lostItemOwner,
          matchedUser: foundItemOwner,
          userItem: lostItem,
          matchedItem: foundItem,
          matchId: matchId,
          matchType: 'found',
        ),
        _notifyUser(
          user: foundItemOwner,
          matchedUser: lostItemOwner,
          userItem: foundItem,
          matchedItem: lostItem,
          matchId: matchId,
          matchType: 'lost',
        ),
      ]);

      // Log analytics event
      await _analytics.logEvent(
        name: 'match_notifications_sent',
        parameters: {
          'match_id': matchId,
          'lost_item_id': lostItem.reportId,
        'found_item_id': foundItem.reportId,
        'lost_item_owner': lostItemOwner.uid,
         'found_item_owner': foundItemOwner.uid,
        },
      );

      print('Match notifications sent successfully for match: $matchId');
    } catch (e) {
      print('Error sending match notifications: $e');
      
      // Log error to analytics
      await _analytics.logEvent(
        name: 'match_notification_error',
        parameters: {
          'match_id': matchId,
          'error': e.toString(),
        },
      );
    }
  }

  /// Sends both push and email notifications to a user about a new match
  static Future<void> _notifyUser({
    required UserProfile user,
    required UserProfile matchedUser,
    required Report userItem,
    required Report matchedItem,
    required String matchId,
    required String matchType,
  }) async {
    // Send push notification
    await _sendPushNotification(
      user: user,
      matchedUser: matchedUser,
      userItem: userItem,
      matchedItem: matchedItem,
      matchId: matchId,
      matchType: matchType,
    );

    // Send email notification
    await _sendEmailNotification(
      user: user,
      matchedUser: matchedUser,
      userItem: userItem,
      matchedItem: matchedItem,
      matchId: matchId,
      matchType: matchType,
    );

    // Update user's notification preferences if needed
    await _updateNotificationHistory(user.uid, matchId, matchType);
  }

  /// Sends WhatsApp-style push notification
  static Future<void> _sendPushNotification({
    required UserProfile user,
    required UserProfile matchedUser,
    required Report userItem,
    required Report matchedItem,
    required String matchId,
    required String matchType,
  }) async {
    await NotificationService.sendItemMatchNotification(
       userId: user.uid,
       itemName: userItem.itemName,
       matchType: matchType,
       matchId: matchId,
       matchedUserName: matchedUser.name,
       itemImageUrl: null, // Report model doesn't have imageUrls field
     );
  }

  /// Sends email notification about the match
  static Future<void> _sendEmailNotification({
    required UserProfile user,
    required UserProfile matchedUser,
    required Report userItem,
    required Report matchedItem,
    required String matchId,
    required String matchType,
  }) async {
    final String subject = 'New Match Found! 🎉 - Campus Lost & Found';
    
    final String emailBody = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .match-card { background: white; padding: 20px; border-radius: 10px; margin: 20px 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .item-details { display: flex; align-items: center; margin: 15px 0; }
        .item-image { width: 80px; height: 80px; border-radius: 10px; margin-right: 15px; object-fit: cover; }
        .cta-button { background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; display: inline-block; margin: 20px 0; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        .emoji { font-size: 24px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><span class="emoji">🎉</span> Great News, ${user.name}!</h1>
            <p>We found a match for your ${matchType == 'found' ? 'lost' : 'found'} item!</p>
        </div>
        
        <div class="content">
            <div class="match-card">
                <h2>Match Details</h2>
                
                <div class="item-details">
                    <div>
                        <h3>Your Item: ${userItem.itemName}</h3>
                        <p><strong>Category:</strong> ${userItem.category}</p>
                        <p><strong>Location:</strong> ${userItem.location}</p>
                        <p><strong>Date:</strong> ${userItem.date.toLocal().toString().split(' ')[0]}</p>
                    </div>
                </div>
                
                <hr style="margin: 20px 0; border: 1px solid #eee;">
                
                <div class="item-details">
                    <div>
                        <h3>Matched Item: ${matchedItem.itemName}</h3>
                         <p><strong>Reported by:</strong> ${matchedUser.name}</p>
                        <p><strong>Category:</strong> ${matchedItem.category}</p>
                        <p><strong>Location:</strong> ${matchedItem.location}</p>
                        <p><strong>Date:</strong> ${matchedItem.date.toLocal().toString().split(' ')[0]}</p>
                    </div>
                </div>
            </div>
            
            <div style="text-align: center;">
                <a href="https://campuslf.web.app/matches/$matchId" class="cta-button">
                    View Match Details & Start Chat
                </a>
            </div>
            
            <div style="background: #e8f5e8; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h3>Next Steps:</h3>
                <ol>
                    <li>Click the button above to view full match details</li>
                    <li>Start a conversation with ${matchedUser.name}</li>
                    <li>Arrange a safe meeting to exchange the item</li>
                    <li>Mark the item as resolved once returned</li>
                </ol>
            </div>
            
            <p><strong>Safety Reminder:</strong> Always meet in a public, well-lit area on campus. Consider bringing a friend and let someone know about your meeting.</p>
        </div>
        
        <div class="footer">
            <p>Campus Lost & Found - Reuniting you with your belongings</p>
            <p>If you have any questions, reply to this email or contact our support team.</p>
        </div>
    </div>
</body>
</html>
    ''';

    await EmailService.sendEmail(
      to: user.email,
      subject: subject,
      htmlBody: emailBody,
      metadata: {
        'type': 'match_notification',
        'match_id': matchId,
        'user_id': user.uid,
         'matched_user_id': matchedUser.uid,
      },
    );
  }

  /// Updates the user's notification history
  static Future<void> _updateNotificationHistory(String userId, String matchId, String matchType) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).collection('notifications').add({
        'type': 'match',
        'match_id': matchId,
        'match_type': matchType,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'title': 'New Match Found!',
        'body': 'Tap to see who you matched with',
      });
    } catch (e) {
      print('Error updating notification history: $e');
    }
  }

  /// Checks if a potential match should trigger notifications
  static Future<bool> shouldNotifyForMatch({
    required Report item1,
    required Report item2,
    required UserProfile user1,
    required UserProfile user2,
  }) async {
    try {
      // Check if users have notification preferences enabled
      final user1Prefs = await _getUserNotificationPreferences(user1.uid);
      final user2Prefs = await _getUserNotificationPreferences(user2.uid);

      // Check if this match was already notified
      final existingMatch = await _checkExistingMatch(item1.reportId, item2.reportId);

      return user1Prefs['match_notifications'] == true &&
             user2Prefs['match_notifications'] == true &&
             !existingMatch;
    } catch (e) {
      print('Error checking notification eligibility: $e');
      return true; // Default to sending notifications
    }
  }

  /// Gets user notification preferences
  static Future<Map<String, dynamic>> _getUserNotificationPreferences(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();
      final data = doc.data();
      return data?['notification_preferences'] ?? {
        'match_notifications': true,
        'message_notifications': true,
        'email_notifications': true,
      };
    } catch (e) {
      print('Error getting notification preferences: $e');
      return {
        'match_notifications': true,
        'message_notifications': true,
        'email_notifications': true,
      };
    }
  }

  /// Checks if a match between two items already exists
  static Future<bool> _checkExistingMatch(String item1Id, String item2Id) async {
    try {
      final query = await _firestore
          .collection('matches')
          .where('report_ids', arrayContainsAny: [item1Id, item2Id])
          .get();

      for (final doc in query.docs) {
        final itemIds = List<String>.from(doc.data()['report_ids'] ?? []);
        if (itemIds.contains(item1Id) && itemIds.contains(item2Id)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking existing match: $e');
      return false;
    }
  }

  /// Manually trigger a test notification (for development/testing)
  static Future<void> sendTestMatchNotification(String userId) async {
    try {
      final user = await _firestore.collection('user_profiles').doc(userId).get();
      if (!user.exists) return;

      await NotificationService.sendItemMatchNotification(
        userId: userId,
        itemName: 'Test iPhone',
        matchType: 'found',
        matchId: 'test_match_${DateTime.now().millisecondsSinceEpoch}',
        matchedUserName: 'Test User',
      );

      await _analytics.logEvent(
        name: 'test_match_notification_sent',
        parameters: {'user_id': userId},
      );
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Handles a new report by checking for potential matches and sending notifications
  static Future<void> handleNewReport(Report newReport) async {
    try {
      // Get potential matches for the new report
      final potentialMatches = await FirebaseService.findPotentialMatches(newReport);
      
      if (potentialMatches.isEmpty) return;
      
      // Get the report owner
      final reportOwner = await FirebaseService.getUserProfile(newReport.uid);
      if (reportOwner == null) return;
      
      // Process each potential match
      for (final match in potentialMatches) {
        final matchOwner = await FirebaseService.getUserProfile(match.uid);
        if (matchOwner == null) continue;
        
        // Check if we should notify for this match
        final shouldNotify = await shouldNotifyForMatch(
          item1: newReport,
          item2: match,
          user1: reportOwner,
          user2: matchOwner,
        );
        
        if (shouldNotify) {
          // Create match in Firebase
          final lostItem = newReport.type == 'Lost' ? newReport : match;
          final foundItem = newReport.type == 'Found' ? newReport : match;
          final lostOwner = newReport.type == 'Lost' ? reportOwner : matchOwner;
          final foundOwner = newReport.type == 'Found' ? reportOwner : matchOwner;
          
          final matchId = await FirebaseService.createMatch(
            lostItemId: lostItem.reportId,
            foundItemId: foundItem.reportId,
            lostItemOwnerId: lostOwner.uid,
            foundItemOwnerId: foundOwner.uid,
            matchScore: 0.85, // This should come from the matching algorithm
          );
          
          // Handle the match notification
          await handleNewMatch(
            matchId: matchId,
            lostItem: lostItem,
            foundItem: foundItem,
            lostItemOwner: lostOwner,
            foundItemOwner: foundOwner,
          );
        }
      }
    } catch (e) {
      print('Error handling new report: $e');
    }
  }
}