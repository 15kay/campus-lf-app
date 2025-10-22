import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';

class RatingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _ratingsCollection = 'ratings';
  static const String _userReputationCollection = 'user_reputation';
  static const String _feedbackCollection = 'feedback';

  // Rating types
  static const String ratingTypeHelpfulness = 'helpfulness';
  static const String ratingTypeReliability = 'reliability';
  static const String ratingTypeCommunication = 'communication';
  static const String ratingTypeOverall = 'overall';

  // Submit a rating
  static Future<bool> submitRating({
    required String ratedUserId,
    required String raterUserId,
    required String itemId,
    required double rating,
    required String ratingType,
    String? comment,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate rating
      if (rating < 1.0 || rating > 5.0) {
        throw ArgumentError('Rating must be between 1.0 and 5.0');
      }

      if (ratedUserId == raterUserId) {
        throw ArgumentError('Users cannot rate themselves');
      }

      // Check if user has already rated this interaction
      final existingRating = await _firestore
          .collection(_ratingsCollection)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .where('raterUserId', isEqualTo: raterUserId)
          .where('itemId', isEqualTo: itemId)
          .where('ratingType', isEqualTo: ratingType)
          .get();

      if (existingRating.docs.isNotEmpty) {
        // Update existing rating
        await existingRating.docs.first.reference.update({
          'rating': rating,
          'comment': comment,
          'updatedAt': FieldValue.serverTimestamp(),
          'additionalData': additionalData,
        });
      } else {
        // Create new rating
        await _firestore.collection(_ratingsCollection).add({
          'ratedUserId': ratedUserId,
          'raterUserId': raterUserId,
          'itemId': itemId,
          'rating': rating,
          'ratingType': ratingType,
          'comment': comment,
          'additionalData': additionalData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update user reputation
      await _updateUserReputation(ratedUserId);

      // Log analytics
      await AnalyticsService.logRatingGiven(
        targetUserId: ratedUserId,
        rating: rating,
        context: ratingType,
      );

      if (kDebugMode) {
        print('Rating submitted successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting rating: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'rating_submission_error',
        errorMessage: e.toString(),
      );
      
      return false;
    }
  }

  // Get user ratings
  static Future<List<UserRating>> getUserRatings(String userId, {String? ratingType}) async {
    try {
      Query query = _firestore
          .collection(_ratingsCollection)
          .where('ratedUserId', isEqualTo: userId);

      if (ratingType != null) {
        query = query.where('ratingType', isEqualTo: ratingType);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserRating.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user ratings: $e');
      }
      return [];
    }
  }

  // Get user reputation
  static Future<UserReputation?> getUserReputation(String userId) async {
    try {
      final doc = await _firestore
          .collection(_userReputationCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserReputation.fromMap(data, userId);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user reputation: $e');
      }
      return null;
    }
  }

  // Update user reputation
  static Future<void> _updateUserReputation(String userId) async {
    try {
      // Get all ratings for this user
      final ratingsSnapshot = await _firestore
          .collection(_ratingsCollection)
          .where('ratedUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate reputation metrics
      final ratings = ratingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['rating'] as double;
      }).toList();

      final ratingsByType = <String, List<double>>{};
      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final type = data['ratingType'] as String;
        final rating = data['rating'] as double;
        
        ratingsByType.putIfAbsent(type, () => []).add(rating);
      }

      // Calculate overall metrics
      final totalRatings = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalRatings;
      
      // Calculate rating distribution
      final ratingDistribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = ratings.where((r) => r.round() == i).length;
      }

      // Calculate type-specific averages
      final typeAverages = <String, double>{};
      for (final entry in ratingsByType.entries) {
        typeAverages[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }

      // Calculate reputation score (weighted average with additional factors)
      double reputationScore = averageRating;
      
      // Boost for high number of ratings
      if (totalRatings >= 10) {
        reputationScore += 0.1;
      } else if (totalRatings >= 5) {
        reputationScore += 0.05;
      }

      // Boost for consistency (low standard deviation)
      final variance = ratings.map((r) => (r - averageRating) * (r - averageRating)).reduce((a, b) => a + b) / totalRatings;
      final standardDeviation = variance.sqrt();
      if (standardDeviation < 0.5) {
        reputationScore += 0.1;
      }

      // Cap at 5.0
      reputationScore = reputationScore.clamp(1.0, 5.0);

      // Determine reputation level
      String reputationLevel;
      if (reputationScore >= 4.5) {
        reputationLevel = 'Excellent';
      } else if (reputationScore >= 4.0) {
        reputationLevel = 'Very Good';
      } else if (reputationScore >= 3.5) {
        reputationLevel = 'Good';
      } else if (reputationScore >= 3.0) {
        reputationLevel = 'Fair';
      } else {
        reputationLevel = 'Needs Improvement';
      }

      // Update reputation document
      await _firestore
          .collection(_userReputationCollection)
          .doc(userId)
          .set({
        'userId': userId,
        'totalRatings': totalRatings,
        'averageRating': averageRating,
        'reputationScore': reputationScore,
        'reputationLevel': reputationLevel,
        'ratingDistribution': ratingDistribution,
        'typeAverages': typeAverages,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('User reputation updated: $userId - Score: $reputationScore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user reputation: $e');
      }
    }
  }

  // Submit general feedback
  static Future<bool> submitFeedback({
    required String userId,
    required String feedbackType,
    required String message,
    String? itemId,
    String? targetUserId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection(_feedbackCollection).add({
        'userId': userId,
        'feedbackType': feedbackType,
        'message': message,
        'itemId': itemId,
        'targetUserId': targetUserId,
        'additionalData': additionalData,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'feedback_submitted',
        parameters: {
          'feedback_type': feedbackType,
          'has_target_user': targetUserId != null,
          'has_item': itemId != null,
        },
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting feedback: $e');
      }
      return false;
    }
  }

  // Get leaderboard
  static Future<List<UserReputation>> getLeaderboard({
    int limit = 10,
    String? ratingType,
  }) async {
    try {
      Query query = _firestore
          .collection(_userReputationCollection)
          .where('totalRatings', isGreaterThanOrEqualTo: 3) // Minimum ratings required
          .orderBy('reputationScore', descending: true);

      if (ratingType != null) {
        query = query.where('typeAverages.$ratingType', isGreaterThan: 0);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserReputation.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting leaderboard: $e');
      }
      return [];
    }
  }

  // Check if user can rate another user for specific item
  static Future<bool> canUserRate({
    required String raterUserId,
    required String ratedUserId,
    required String itemId,
    required String ratingType,
  }) async {
    try {
      if (raterUserId == ratedUserId) return false;

      final existingRating = await _firestore
          .collection(_ratingsCollection)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .where('raterUserId', isEqualTo: raterUserId)
          .where('itemId', isEqualTo: itemId)
          .where('ratingType', isEqualTo: ratingType)
          .get();

      return existingRating.docs.isEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user can rate: $e');
      }
      return false;
    }
  }

  // Get rating statistics
  static Future<RatingStatistics> getRatingStatistics(String userId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection(_ratingsCollection)
          .where('ratedUserId', isEqualTo: userId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        return RatingStatistics.empty();
      }

      final ratings = ratingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['rating'] as double;
      }).toList();

      final totalRatings = ratings.length;
      final averageRating = ratings.reduce((a, b) => a + b) / totalRatings;
      
      // Calculate percentiles
      ratings.sort();
      final median = totalRatings % 2 == 0
          ? (ratings[totalRatings ~/ 2 - 1] + ratings[totalRatings ~/ 2]) / 2
          : ratings[totalRatings ~/ 2];

      // Rating distribution
      final distribution = <int, int>{};
      for (int i = 1; i <= 5; i++) {
        distribution[i] = ratings.where((r) => r.round() == i).length;
      }

      // Recent ratings trend (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final recentRatings = ratingsSnapshot.docs.where((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        return createdAt != null && createdAt.toDate().isAfter(thirtyDaysAgo);
      }).map((doc) {
        final data = doc.data();
        return data['rating'] as double;
      }).toList();

      final recentAverage = recentRatings.isNotEmpty
          ? recentRatings.reduce((a, b) => a + b) / recentRatings.length
          : 0.0;

      return RatingStatistics(
        totalRatings: totalRatings,
        averageRating: averageRating,
        medianRating: median,
        ratingDistribution: distribution,
        recentRatingsCount: recentRatings.length,
        recentAverageRating: recentAverage,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting rating statistics: $e');
      }
      return RatingStatistics.empty();
    }
  }

  // Delete rating (admin function)
  static Future<bool> deleteRating(String ratingId) async {
    try {
      await _firestore.collection(_ratingsCollection).doc(ratingId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting rating: $e');
      }
      return false;
    }
  }

  // Report inappropriate rating
  static Future<bool> reportRating({
    required String ratingId,
    required String reporterUserId,
    required String reason,
    String? additionalInfo,
  }) async {
    try {
      await _firestore.collection('rating_reports').add({
        'ratingId': ratingId,
        'reporterUserId': reporterUserId,
        'reason': reason,
        'additionalInfo': additionalInfo,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting rating: $e');
      }
      return false;
    }
  }
}

// Data models
class UserRating {
  final String id;
  final String ratedUserId;
  final String raterUserId;
  final String itemId;
  final double rating;
  final String ratingType;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? additionalData;

  UserRating({
    required this.id,
    required this.ratedUserId,
    required this.raterUserId,
    required this.itemId,
    required this.rating,
    required this.ratingType,
    this.comment,
    this.createdAt,
    this.updatedAt,
    this.additionalData,
  });

  factory UserRating.fromMap(Map<String, dynamic> map, String id) {
    return UserRating(
      id: id,
      ratedUserId: map['ratedUserId'] ?? '',
      raterUserId: map['raterUserId'] ?? '',
      itemId: map['itemId'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      ratingType: map['ratingType'] ?? '',
      comment: map['comment'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      additionalData: map['additionalData'],
    );
  }
}

class UserReputation {
  final String userId;
  final int totalRatings;
  final double averageRating;
  final double reputationScore;
  final String reputationLevel;
  final Map<int, int> ratingDistribution;
  final Map<String, double> typeAverages;
  final DateTime? lastUpdated;

  UserReputation({
    required this.userId,
    required this.totalRatings,
    required this.averageRating,
    required this.reputationScore,
    required this.reputationLevel,
    required this.ratingDistribution,
    required this.typeAverages,
    this.lastUpdated,
  });

  factory UserReputation.fromMap(Map<String, dynamic> map, String userId) {
    return UserReputation(
      userId: userId,
      totalRatings: map['totalRatings'] ?? 0,
      averageRating: map['averageRating']?.toDouble() ?? 0.0,
      reputationScore: map['reputationScore']?.toDouble() ?? 0.0,
      reputationLevel: map['reputationLevel'] ?? 'Unrated',
      ratingDistribution: Map<int, int>.from(map['ratingDistribution'] ?? {}),
      typeAverages: Map<String, double>.from(map['typeAverages'] ?? {}),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

class RatingStatistics {
  final int totalRatings;
  final double averageRating;
  final double medianRating;
  final Map<int, int> ratingDistribution;
  final int recentRatingsCount;
  final double recentAverageRating;

  RatingStatistics({
    required this.totalRatings,
    required this.averageRating,
    required this.medianRating,
    required this.ratingDistribution,
    required this.recentRatingsCount,
    required this.recentAverageRating,
  });

  factory RatingStatistics.empty() {
    return RatingStatistics(
      totalRatings: 0,
      averageRating: 0.0,
      medianRating: 0.0,
      ratingDistribution: {},
      recentRatingsCount: 0,
      recentAverageRating: 0.0,
    );
  }
}