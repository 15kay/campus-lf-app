import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models.dart';
import 'dart:convert';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Collection references
  static CollectionReference get _reportsCollection => _firestore.collection('reports');
  static CollectionReference get _usersCollection => _firestore.collection('users');
  static CollectionReference get _matchesCollection => _firestore.collection('matches');
  static CollectionReference get _notificationsCollection => _firestore.collection('notifications');

  // Reports CRUD operations
  static Future<String> addReport(Report report) async {
    try {
      debugPrint('DEBUG: Adding report for user ${report.uid}: ${report.itemName}');
      final docRef = await _reportsCollection.add(report.toJson());
      debugPrint('DEBUG: Report added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('DEBUG: Failed to add report: $e');
      throw Exception('Failed to add report: $e');
    }
  }

  static Future<void> updateReport(Report report) async {
    try {
      await _reportsCollection.doc(report.reportId).update(report.toJson());
    } catch (e) {
      throw Exception('Failed to update report: $e');
    }
  }

  static Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Get all reports as a stream for real-time updates
  static Stream<List<Report>> getAllReportsStream() {
    return _reportsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      debugPrint('DEBUG: Received ${snapshot.docs.length} reports from Firestore');
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['reportId'] = doc.id; // Use Firestore document ID
        final report = Report.fromJson(data);
        debugPrint('DEBUG: Report - ID: ${report.reportId}, User: ${report.uid}, Item: ${report.itemName}');
        return report;
      }).toList();
      debugPrint('DEBUG: Total reports processed: ${reports.length}');
      return reports;
    });
  }

  // Get reports by user ID
  static Stream<List<Report>> getUserReportsStream(String uid) {
    debugPrint('DEBUG: Getting reports for user: $uid');
    return _reportsCollection
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      debugPrint('DEBUG: User reports query returned ${snapshot.docs.length} documents');
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['reportId'] = doc.id;
        final report = Report.fromJson(data);
        debugPrint('DEBUG: User report - ID: ${report.reportId}, Item: ${report.itemName}, UID: ${report.uid}');
        return report;
      }).toList();
      
      // Sort manually by timestamp (descending)
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      debugPrint('DEBUG: Total user reports processed: ${reports.length}');
      return reports;
    });
  }

  // Search reports
  static Future<List<Report>> searchReports(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation - for production, consider using Algolia or similar
      final snapshot = await _reportsCollection.get();
      final allReports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['reportId'] = doc.id;
        return Report.fromJson(data);
      }).toList();

      // Filter locally (not ideal for large datasets)
      return allReports.where((report) {
        final searchTerm = query.toLowerCase();
        return report.itemName.toLowerCase().contains(searchTerm) ||
               report.description.toLowerCase().contains(searchTerm) ||
               report.location.toLowerCase().contains(searchTerm) ||
               report.category.toLowerCase().contains(searchTerm);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search reports: $e');
    }
  }

  // User profile operations
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _usersCollection.doc(user.uid).set(profile.toJson());
      }
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  static Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Messages operations are handled directly in chat_page.dart using conversation subcollections

  // Get current user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is authenticated
  static bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Admin functionality
  static Future<bool> isUserAdmin(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setUserAdminStatus(String uid, bool isAdmin) async {
    try {
      await _usersCollection.doc(uid).update({'isAdmin': isAdmin});
    } catch (e) {
      throw Exception('Failed to update admin status: $e');
    }
  }

  // Get all users for admin dashboard
  static Stream<List<UserProfile>> getAllUsersStream() {
    return _usersCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return UserProfile.fromJson(data);
      }).toList();
    });
  }

  // Get reports statistics for admin dashboard
  static Future<Map<String, int>> getReportsStatistics() async {
    try {
      final snapshot = await _reportsCollection.get();
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Report.fromJson(data);
      }).toList();

      final stats = <String, int>{
        'total': reports.length,
        'lost': reports.where((r) => r.type == 'Lost').length,
        'found': reports.where((r) => r.type == 'Found').length,
        'resolved': reports.where((r) => r.status == 'Resolved').length,
        'pending': reports.where((r) => r.status == 'Pending').length,
      };

      // Category breakdown
      final categories = <String, int>{};
      for (final report in reports) {
        categories[report.category] = (categories[report.category] ?? 0) + 1;
      }
      stats.addAll(categories);

      return stats;
    } catch (e) {
      throw Exception('Failed to get statistics: $e');
    }
  }

  // Admin report management
  static Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _reportsCollection.doc(reportId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // Resolve report with additional metadata
  static Future<void> resolveReport(String reportId, String resolverUid, String status, {String? notes}) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'status': status, // 'Resolved' or 'Returned'
        'resolvedBy': resolverUid,
        'resolvedAt': DateTime.now().toIso8601String(),
        'resolutionNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to resolve report: $e');
    }
  }

  // Get resolved reports for statistics
  static Future<List<Report>> getResolvedReports() async {
    try {
      final snapshot = await _reportsCollection
          .where('status', whereIn: ['Resolved', 'Returned'])
          .orderBy('resolvedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['reportId'] = doc.id;
        return Report.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get resolved reports: $e');
    }
  }

  static Future<void> deleteReportAsAdmin(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Item matching functionality
  static Future<List<Report>> findPotentialMatches(Report report) async {
    try {
      final snapshot = await _reportsCollection.get();
      final allReports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['reportId'] = doc.id;
        return Report.fromJson(data);
      }).toList();

      // Find reports with opposite status (Lost <-> Found) and similar characteristics
      final oppositeStatus = report.status == 'Lost' ? 'Found' : 'Lost';
      
      final potentialMatches = allReports.where((otherReport) {
        // Skip same report and same user
        if (otherReport.reportId == report.reportId || otherReport.uid == report.uid) {
          return false;
        }
        
        // Must have opposite status
        if (otherReport.status != oppositeStatus) {
          return false;
        }
        
        // Skip resolved/returned items
        if (otherReport.status == 'Resolved' || otherReport.status == 'Returned') {
          return false;
        }
        
        // Calculate match score based on various factors
        int matchScore = 0;
        
        // Category match (high weight)
        if (otherReport.category.toLowerCase() == report.category.toLowerCase()) {
          matchScore += 40;
        }
        
        // Item name similarity (high weight)
        if (_calculateStringSimilarity(otherReport.itemName.toLowerCase(), report.itemName.toLowerCase()) > 0.6) {
          matchScore += 30;
        }
        
        // Location proximity (medium weight)
        if (_calculateStringSimilarity(otherReport.location.toLowerCase(), report.location.toLowerCase()) > 0.5) {
          matchScore += 20;
        }
        
        // Description similarity (low weight)
        if (_calculateStringSimilarity(otherReport.description.toLowerCase(), report.description.toLowerCase()) > 0.4) {
          matchScore += 10;
        }
        
        // Date proximity (within 7 days gets bonus points)
        final daysDifference = (otherReport.date.difference(report.date)).inDays.abs();
        if (daysDifference <= 7) {
          matchScore += 15 - (daysDifference * 2); // More recent = higher score
        }
        
        // Return true if match score is above threshold
        return matchScore >= 50; // Minimum 50% match required
      }).toList();

      // Sort by match score (descending)
      potentialMatches.sort((a, b) {
        final scoreA = calculateMatchScore(a, report);
        final scoreB = calculateMatchScore(b, report);
        return scoreB.compareTo(scoreA);
      });

      return potentialMatches.take(5).toList(); // Return top 5 matches
    } catch (e) {
      throw Exception('Failed to find potential matches: $e');
    }
  }

  // Helper method to calculate string similarity using Levenshtein distance
  static double _calculateStringSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    final int maxLength = s1.length > s2.length ? s1.length : s2.length;
    final int distance = _levenshteinDistance(s1, s2);
    return 1.0 - (distance / maxLength);
  }

  // Levenshtein distance algorithm
  static int _levenshteinDistance(String s1, String s2) {
    final int m = s1.length;
    final int n = s2.length;
    
    if (m == 0) return n;
    if (n == 0) return m;
    
    final List<List<int>> dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,      // deletion
          dp[i][j - 1] + 1,      // insertion
          dp[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return dp[m][n];
  }

  // Helper method to calculate overall match score
  static int calculateMatchScore(Report report1, Report report2) {
    int score = 0;
    
    if (report1.category.toLowerCase() == report2.category.toLowerCase()) {
      score += 40;
    }
    
    if (_calculateStringSimilarity(report1.itemName.toLowerCase(), report2.itemName.toLowerCase()) > 0.6) {
      score += 30;
    }
    
    if (_calculateStringSimilarity(report1.location.toLowerCase(), report2.location.toLowerCase()) > 0.5) {
      score += 20;
    }
    
    if (_calculateStringSimilarity(report1.description.toLowerCase(), report2.description.toLowerCase()) > 0.4) {
      score += 10;
    }
    
    final daysDifference = (report1.date.difference(report2.date)).inDays.abs();
    if (daysDifference <= 7) {
      score += 15 - (daysDifference * 2);
    }
    
    return score;
  }

  // Authentication methods
  static Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // FCM Token Management
  static Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> saveFCMToken(String userId) async {
    try {
      final token = await getFCMToken();
      if (token != null) {
        await _usersCollection.doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  static Future<void> removeFCMToken(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  // Match Management
  static Future<String> createMatch({
    required String lostItemId,
    required String foundItemId,
    required String lostItemOwnerId,
    required String foundItemOwnerId,
    required double matchScore,
  }) async {
    try {
      final matchData = {
        'lost_item_id': lostItemId,
        'found_item_id': foundItemId,
        'lost_item_owner_id': lostItemOwnerId,
        'found_item_owner_id': foundItemOwnerId,
        'match_score': matchScore,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'item_ids': [lostItemId, foundItemId],
        'user_ids': [lostItemOwnerId, foundItemOwnerId],
      };

      final docRef = await _matchesCollection.add(matchData);
      debugPrint('Match created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating match: $e');
      throw Exception('Failed to create match: $e');
    }
  }

  static Future<void> updateMatchStatus(String matchId, String status) async {
    try {
      await _matchesCollection.doc(matchId).update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update match status: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getUserMatchesStream(String userId) {
    return _matchesCollection
        .where('user_ids', arrayContains: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Push Notification Management
  static Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data() as Map<String, dynamic>;
      final fcmToken = userData['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('No FCM token found for user: $userId');
        return;
      }

      // Create notification payload
      final notificationData = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'icon': 'ic_launcher',
          'sound': 'default',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'data': {
          ...data,
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': data['type'] == 'match' ? 'match_notifications' : 'general_notifications',
            'color': '#4CAF50',
            'icon': 'ic_launcher',
            'sound': 'notification_sound',
            'vibrate_timings': ['0', '500', '200', '500'],
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'alert': {
                'title': title,
                'body': body,
              },
              'badge': 1,
              'sound': 'notification_sound.aiff',
              'category': data['type'] == 'match' ? 'MATCH_CATEGORY' : 'GENERAL_CATEGORY',
            },
          },
        },
      };

      // Store notification in Firestore for tracking
      await _notificationsCollection.add({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'fcm_token': fcmToken,
        'status': 'sent',
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Push notification queued for user: $userId');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
      
      // Store failed notification
      await _notificationsCollection.add({
        'user_id': userId,
        'title': title,
        'body': body,
        'data': data,
        'status': 'failed',
        'error': e.toString(),
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // Notification History
  static Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _notificationsCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'read': true,
        'read_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Notification Preferences
  static Future<void> updateNotificationPreferences(String userId, Map<String, bool> preferences) async {
    try {
      await _usersCollection.doc(userId).update({
        'notification_preferences': preferences,
        'preferences_updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update notification preferences: $e');
    }
  }

  static Future<Map<String, bool>> getNotificationPreferences(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final prefs = data['notification_preferences'] as Map<String, dynamic>?;
        return {
          'match_notifications': prefs?['match_notifications'] ?? true,
          'message_notifications': prefs?['message_notifications'] ?? true,
          'email_notifications': prefs?['email_notifications'] ?? true,
          'push_notifications': prefs?['push_notifications'] ?? true,
        };
      }
      return {
        'match_notifications': true,
        'message_notifications': true,
        'email_notifications': true,
        'push_notifications': true,
      };
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return {
        'match_notifications': true,
        'message_notifications': true,
        'email_notifications': true,
        'push_notifications': true,
      };
    }
  }

  // Initialize Firestore settings (call this once in main.dart)
  static Future<void> initialize() async {
    // Enable offline persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}