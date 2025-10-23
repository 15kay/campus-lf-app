import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'analytics_service.dart';
import 'rating_service.dart';

class SocialService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // User Profile Management
  static Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();
      
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  static Future<bool> createUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? bio,
    String? department,
    String? year,
    String? phoneNumber,
    List<String>? interests,
  }) async {
    try {
      final profile = UserProfile(
        userId: userId,
        displayName: displayName,
        email: email,
        bio: bio ?? '',
        department: department ?? '',
        year: year ?? '',
        phoneNumber: phoneNumber ?? '',
        interests: interests ?? [],
        joinDate: DateTime.now(),
        lastActive: DateTime.now(),
        isVerified: false,
        verificationBadges: [],
        socialLinks: {},
        privacySettings: UserPrivacySettings.defaultSettings(),
        statistics: UserStatistics.empty(),
      );

      await _firestore.collection('user_profiles').doc(userId).set(profile.toMap());

      // Log analytics
      await AnalyticsService.logUserSignUp('profile_creation');
      await AnalyticsService.setUserId(userId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user profile: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'profile_creation_error',
        errorMessage: e.toString(),
      );
      
      return false;
    }
  }

  static Future<bool> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? department,
    String? year,
    String? phoneNumber,
    List<String>? interests,
    Map<String, String>? socialLinks,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastActive': FieldValue.serverTimestamp(),
      };

      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (department != null) updates['department'] = department;
      if (year != null) updates['year'] = year;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (interests != null) updates['interests'] = interests;
      if (socialLinks != null) updates['socialLinks'] = socialLinks;

      await _firestore.collection('user_profiles').doc(userId).update(updates);

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'profile_updated',
        parameters: {
          'user_id': userId,
          'fields_updated': updates.keys.toList(),
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      return false;
    }
  }

  static Future<String?> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('profile_pictures/$userId.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile with new picture URL
      await _firestore.collection('user_profiles').doc(userId).update({
        'profilePictureUrl': downloadUrl,
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'profile_picture_uploaded',
        parameters: {'user_id': userId},
      );

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile picture: $e');
      }
      return null;
    }
  }

  // User Verification System
  static Future<bool> requestVerification({
    required String userId,
    required VerificationType type,
    Map<String, dynamic>? verificationData,
  }) async {
    try {
      final request = VerificationRequest(
        userId: userId,
        type: type,
        status: VerificationStatus.pending,
        requestDate: DateTime.now(),
        data: verificationData ?? {},
      );

      await _firestore.collection('verification_requests').add(request.toMap());

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'verification_requested',
        parameters: {
          'user_id': userId,
          'verification_type': type.toString(),
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting verification: $e');
      }
      return false;
    }
  }

  static Future<List<VerificationBadge>> getUserVerificationBadges(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.verificationBadges ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting verification badges: $e');
      }
      return [];
    }
  }

  // Community Features
  static Future<List<UserProfile>> getCommunityLeaderboard({
    LeaderboardType type = LeaderboardType.reputation,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection('user_profiles');

      switch (type) {
        case LeaderboardType.reputation:
          query = query.orderBy('statistics.reputationScore', descending: true);
          break;
        case LeaderboardType.helpfulReports:
          query = query.orderBy('statistics.successfulReports', descending: true);
          break;
        case LeaderboardType.itemsFound:
          query = query.orderBy('statistics.itemsFound', descending: true);
          break;
        case LeaderboardType.itemsReturned:
          query = query.orderBy('statistics.itemsReturned', descending: true);
          break;
      }

      final snapshot = await query.limit(limit).get();
      
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting community leaderboard: $e');
      }
      return [];
    }
  }

  static Future<List<UserProfile>> searchUsers({
    String? query,
    String? department,
    String? year,
    List<String>? interests,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('user_profiles');

      if (department != null && department.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('department', isEqualTo: department);
      }

      if (year != null && year.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('year', isEqualTo: year);
      }

      if (interests != null && interests.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('interests', arrayContainsAny: interests);
      }

      final snapshot = await firestoreQuery.limit(limit).get();
      
      List<UserProfile> users = snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by query if provided
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        users = users.where((user) =>
          user.displayName.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery) ||
          user.bio.toLowerCase().contains(lowerQuery)
        ).toList();
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        print('Error searching users: $e');
      }
      return [];
    }
  }

  // Social Sharing
  static Future<bool> shareReport({
    required String reportId,
    required String reportTitle,
    required SharePlatform platform,
  }) async {
    try {
      final shareUrl = 'https://campuslf.app/report/$reportId';
      final shareText = 'Check out this lost item report: $reportTitle';

      String url;
      switch (platform) {
        case SharePlatform.whatsapp:
          url = 'https://wa.me/?text=${Uri.encodeComponent('$shareText $shareUrl')}';
          break;
        case SharePlatform.telegram:
          url = 'https://t.me/share/url?url=${Uri.encodeComponent(shareUrl)}&text=${Uri.encodeComponent(shareText)}';
          break;
        case SharePlatform.twitter:
          url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent('$shareText $shareUrl')}';
          break;
        case SharePlatform.facebook:
          url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}';
          break;
        case SharePlatform.email:
          url = 'mailto:?subject=${Uri.encodeComponent('Lost Item: $reportTitle')}&body=${Uri.encodeComponent('$shareText\n\n$shareUrl')}';
          break;
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Log analytics
        await AnalyticsService.logFeatureUsed(
          featureName: 'report_shared',
          parameters: {
            'report_id': reportId,
            'platform': platform.toString(),
          },
        );
        
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing report: $e');
      }
      return false;
    }
  }

  // User Statistics
  static Future<bool> updateUserStatistics({
    required String userId,
    int? reportsSubmitted,
    int? successfulReports,
    int? itemsFound,
    int? itemsReturned,
    int? helpfulRatings,
    double? averageRating,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (reportsSubmitted != null) {
        updates['statistics.reportsSubmitted'] = FieldValue.increment(reportsSubmitted);
      }
      if (successfulReports != null) {
        updates['statistics.successfulReports'] = FieldValue.increment(successfulReports);
      }
      if (itemsFound != null) {
        updates['statistics.itemsFound'] = FieldValue.increment(itemsFound);
      }
      if (itemsReturned != null) {
        updates['statistics.itemsReturned'] = FieldValue.increment(itemsReturned);
      }
      if (helpfulRatings != null) {
        updates['statistics.helpfulRatings'] = FieldValue.increment(helpfulRatings);
      }
      if (averageRating != null) {
        updates['statistics.averageRating'] = averageRating;
      }

      // Calculate reputation score
      final reputation = await RatingService.getUserReputation(userId);
      if (reputation != null) {
        updates['statistics.reputationScore'] = reputation.reputationScore;
      }

      updates['lastActive'] = FieldValue.serverTimestamp();

      await _firestore.collection('user_profiles').doc(userId).update(updates);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user statistics: $e');
      }
      return false;
    }
  }

  // Privacy Settings
  static Future<bool> updatePrivacySettings({
    required String userId,
    required UserPrivacySettings settings,
  }) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'privacySettings': settings.toMap(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'privacy_settings_updated',
        parameters: {'user_id': userId},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating privacy settings: $e');
      }
      return false;
    }
  }

  // User Activity
  static Future<List<UserActivity>> getUserActivity({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserActivity.fromMap(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user activity: $e');
      }
      return [];
    }
  }

  static Future<bool> logUserActivity({
    required String userId,
    required ActivityType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final activity = UserActivity(
        userId: userId,
        type: type,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore.collection('user_activities').add(activity.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error logging user activity: $e');
      }
      return false;
    }
  }

  // User Connections
  static Future<bool> followUser({
    required String followerId,
    required String followeeId,
  }) async {
    try {
      // Add to follower's following list
      await _firestore.collection('user_connections').doc(followerId).set({
        'following': FieldValue.arrayUnion([followeeId]),
      }, SetOptions(merge: true));

      // Add to followee's followers list
      await _firestore.collection('user_connections').doc(followeeId).set({
        'followers': FieldValue.arrayUnion([followerId]),
      }, SetOptions(merge: true));

      // Log activity
      await logUserActivity(
        userId: followerId,
        type: ActivityType.followUser,
        description: 'Started following a user',
        metadata: {'followee_id': followeeId},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error following user: $e');
      }
      return false;
    }
  }

  static Future<bool> unfollowUser({
    required String followerId,
    required String followeeId,
  }) async {
    try {
      // Remove from follower's following list
      await _firestore.collection('user_connections').doc(followerId).update({
        'following': FieldValue.arrayRemove([followeeId]),
      });

      // Remove from followee's followers list
      await _firestore.collection('user_connections').doc(followeeId).update({
        'followers': FieldValue.arrayRemove([followerId]),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unfollowing user: $e');
      }
      return false;
    }
  }

  static Future<UserConnections?> getUserConnections(String userId) async {
    try {
      final doc = await _firestore.collection('user_connections').doc(userId).get();
      
      if (doc.exists) {
        return UserConnections.fromMap(doc.data()!);
      }
      return UserConnections.empty();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user connections: $e');
      }
      return null;
    }
  }
}

// Data Models
class UserProfile {
  final String userId;
  final String displayName;
  final String email;
  final String bio;
  final String department;
  final String year;
  final String phoneNumber;
  final String? profilePictureUrl;
  final List<String> interests;
  final DateTime joinDate;
  final DateTime lastActive;
  final bool isVerified;
  final List<VerificationBadge> verificationBadges;
  final Map<String, String> socialLinks;
  final UserPrivacySettings privacySettings;
  final UserStatistics statistics;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.department,
    required this.year,
    required this.phoneNumber,
    this.profilePictureUrl,
    required this.interests,
    required this.joinDate,
    required this.lastActive,
    required this.isVerified,
    required this.verificationBadges,
    required this.socialLinks,
    required this.privacySettings,
    required this.statistics,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'department': department,
      'year': year,
      'phoneNumber': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'interests': interests,
      'joinDate': joinDate.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'isVerified': isVerified,
      'verificationBadges': verificationBadges.map((badge) => badge.toMap()).toList(),
      'socialLinks': socialLinks,
      'privacySettings': privacySettings.toMap(),
      'statistics': statistics.toMap(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      bio: map['bio'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      profilePictureUrl: map['profilePictureUrl'],
      interests: List<String>.from(map['interests'] ?? []),
      joinDate: DateTime.parse(map['joinDate'] ?? DateTime.now().toIso8601String()),
      lastActive: DateTime.parse(map['lastActive'] ?? DateTime.now().toIso8601String()),
      isVerified: map['isVerified'] ?? false,
      verificationBadges: (map['verificationBadges'] as List<dynamic>?)
          ?.map((badge) => VerificationBadge.fromMap(badge))
          .toList() ?? [],
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      privacySettings: UserPrivacySettings.fromMap(map['privacySettings'] ?? {}),
      statistics: UserStatistics.fromMap(map['statistics'] ?? {}),
    );
  }
}

class UserPrivacySettings {
  final bool showEmail;
  final bool showPhoneNumber;
  final bool showDepartment;
  final bool showYear;
  final bool allowDirectMessages;
  final bool showActivity;
  final bool showStatistics;

  UserPrivacySettings({
    required this.showEmail,
    required this.showPhoneNumber,
    required this.showDepartment,
    required this.showYear,
    required this.allowDirectMessages,
    required this.showActivity,
    required this.showStatistics,
  });

  factory UserPrivacySettings.defaultSettings() {
    return UserPrivacySettings(
      showEmail: false,
      showPhoneNumber: false,
      showDepartment: true,
      showYear: true,
      allowDirectMessages: true,
      showActivity: true,
      showStatistics: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showEmail': showEmail,
      'showPhoneNumber': showPhoneNumber,
      'showDepartment': showDepartment,
      'showYear': showYear,
      'allowDirectMessages': allowDirectMessages,
      'showActivity': showActivity,
      'showStatistics': showStatistics,
    };
  }

  factory UserPrivacySettings.fromMap(Map<String, dynamic> map) {
    return UserPrivacySettings(
      showEmail: map['showEmail'] ?? false,
      showPhoneNumber: map['showPhoneNumber'] ?? false,
      showDepartment: map['showDepartment'] ?? true,
      showYear: map['showYear'] ?? true,
      allowDirectMessages: map['allowDirectMessages'] ?? true,
      showActivity: map['showActivity'] ?? true,
      showStatistics: map['showStatistics'] ?? true,
    );
  }
}

class UserStatistics {
  final int reportsSubmitted;
  final int successfulReports;
  final int itemsFound;
  final int itemsReturned;
  final int helpfulRatings;
  final double averageRating;
  final double reputationScore;

  UserStatistics({
    required this.reportsSubmitted,
    required this.successfulReports,
    required this.itemsFound,
    required this.itemsReturned,
    required this.helpfulRatings,
    required this.averageRating,
    required this.reputationScore,
  });

  factory UserStatistics.empty() {
    return UserStatistics(
      reportsSubmitted: 0,
      successfulReports: 0,
      itemsFound: 0,
      itemsReturned: 0,
      helpfulRatings: 0,
      averageRating: 0.0,
      reputationScore: 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportsSubmitted': reportsSubmitted,
      'successfulReports': successfulReports,
      'itemsFound': itemsFound,
      'itemsReturned': itemsReturned,
      'helpfulRatings': helpfulRatings,
      'averageRating': averageRating,
      'reputationScore': reputationScore,
    };
  }

  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      reportsSubmitted: map['reportsSubmitted'] ?? 0,
      successfulReports: map['successfulReports'] ?? 0,
      itemsFound: map['itemsFound'] ?? 0,
      itemsReturned: map['itemsReturned'] ?? 0,
      helpfulRatings: map['helpfulRatings'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      reputationScore: (map['reputationScore'] ?? 0.0).toDouble(),
    );
  }
}

class VerificationBadge {
  final VerificationType type;
  final DateTime verifiedDate;
  final String verifiedBy;

  VerificationBadge({
    required this.type,
    required this.verifiedDate,
    required this.verifiedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'verifiedDate': verifiedDate.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  factory VerificationBadge.fromMap(Map<String, dynamic> map) {
    return VerificationBadge(
      type: VerificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => VerificationType.student,
      ),
      verifiedDate: DateTime.parse(map['verifiedDate']),
      verifiedBy: map['verifiedBy'] ?? '',
    );
  }
}

class VerificationRequest {
  final String userId;
  final VerificationType type;
  final VerificationStatus status;
  final DateTime requestDate;
  final Map<String, dynamic> data;

  VerificationRequest({
    required this.userId,
    required this.type,
    required this.status,
    required this.requestDate,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString(),
      'status': status.toString(),
      'requestDate': requestDate.toIso8601String(),
      'data': data,
    };
  }
}

class UserActivity {
  final String userId;
  final ActivityType type;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserActivity({
    required this.userId,
    required this.type,
    required this.description,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString(),
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    return UserActivity(
      userId: map['userId'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ActivityType.other,
      ),
      description: map['description'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

class UserConnections {
  final List<String> followers;
  final List<String> following;

  UserConnections({
    required this.followers,
    required this.following,
  });

  factory UserConnections.empty() {
    return UserConnections(
      followers: [],
      following: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followers': followers,
      'following': following,
    };
  }

  factory UserConnections.fromMap(Map<String, dynamic> map) {
    return UserConnections(
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }
}

// Enums
enum VerificationType {
  student,
  faculty,
  staff,
  trustedUser,
  campusAmbassador,
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
}

enum LeaderboardType {
  reputation,
  helpfulReports,
  itemsFound,
  itemsReturned,
}

enum SharePlatform {
  whatsapp,
  telegram,
  twitter,
  facebook,
  email,
}

enum ActivityType {
  reportSubmitted,
  itemFound,
  itemReturned,
  ratingGiven,
  ratingReceived,
  followUser,
  profileUpdated,
  verificationRequested,
  badgeEarned,
  other,
}