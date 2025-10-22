import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'analytics_service.dart';

class SecurityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Item Verification
  static Future<String> generateVerificationCode({
    required String itemId,
    required String ownerId,
  }) async {
    try {
      // Generate a unique 6-digit verification code
      final random = Random.secure();
      final code = (100000 + random.nextInt(900000)).toString();
      
      // Hash the code for storage
      final hashedCode = _hashString('$code$itemId$ownerId');
      
      final verification = ItemVerification(
        itemId: itemId,
        ownerId: ownerId,
        verificationCode: hashedCode,
        generatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        isUsed: false,
        attempts: 0,
      );

      await _firestore.collection('item_verifications').add(verification.toMap());

      // Log analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'verification_code_generated',
        parameters: {
          'item_id': itemId,
          'owner_id': ownerId,
        },
      );

      return code; // Return the plain code to show to user
    } catch (e) {
      if (kDebugMode) {
        print('Error generating verification code: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'verification_code_generation_error',
        errorMessage: e.toString(),
      );
      
      throw Exception('Failed to generate verification code');
    }
  }

  static Future<VerificationResult> verifyItemOwnership({
    required String itemId,
    required String claimantId,
    required String verificationCode,
  }) async {
    try {
      // Find verification record
      final snapshot = await _firestore
          .collection('item_verifications')
          .where('itemId', isEqualTo: itemId)
          .where('isUsed', isEqualTo: false)
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return VerificationResult(
          success: false,
          message: 'No active verification code found for this item',
        );
      }

      final doc = snapshot.docs.first;
      final verification = ItemVerification.fromMap(doc.data());

      // Check if expired
      if (verification.expiresAt.isBefore(DateTime.now())) {
        return VerificationResult(
          success: false,
          message: 'Verification code has expired',
        );
      }

      // Check attempt limit
      if (verification.attempts >= 3) {
        return VerificationResult(
          success: false,
          message: 'Maximum verification attempts exceeded',
        );
      }

      // Verify the code
      final hashedInput = _hashString('$verificationCode$itemId${verification.ownerId}');
      
      if (hashedInput != verification.verificationCode) {
        // Increment attempts
        await doc.reference.update({
          'attempts': FieldValue.increment(1),
        });

        // Log failed attempt
        await _logSecurityEvent(
          type: SecurityEventType.verificationFailed,
          userId: claimantId,
          details: {
            'item_id': itemId,
            'attempts': verification.attempts + 1,
          },
        );

        return VerificationResult(
          success: false,
          message: 'Invalid verification code',
        );
      }

      // Mark as used
      await doc.reference.update({
        'isUsed': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': claimantId,
      });

      // Log successful verification
      await _logSecurityEvent(
        type: SecurityEventType.verificationSuccess,
        userId: claimantId,
        details: {
          'item_id': itemId,
          'owner_id': verification.ownerId,
        },
      );

      return VerificationResult(
        success: true,
        message: 'Item ownership verified successfully',
        ownerId: verification.ownerId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying item ownership: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'item_verification_error',
        errorMessage: e.toString(),
      );
      
      return VerificationResult(
        success: false,
        message: 'Verification failed due to technical error',
      );
    }
  }

  // Fraud Detection
  static Future<FraudAssessment> assessUserBehavior({
    required String userId,
    required String action,
    Map<String, dynamic>? context,
  }) async {
    try {
      final riskScore = await _calculateRiskScore(userId, action, context);
      final riskLevel = _determineRiskLevel(riskScore);
      
      final assessment = FraudAssessment(
        userId: userId,
        action: action,
        riskScore: riskScore,
        riskLevel: riskLevel,
        timestamp: DateTime.now(),
        context: context ?? {},
        flags: await _getFraudFlags(userId, action, context),
      );

      // Store assessment
      await _firestore.collection('fraud_assessments').add(assessment.toMap());

      // Log high-risk activities
      if (riskLevel == RiskLevel.high) {
        await _logSecurityEvent(
          type: SecurityEventType.highRiskActivity,
          userId: userId,
          details: {
            'action': action,
            'risk_score': riskScore,
            'flags': assessment.flags,
          },
        );
      }

      return assessment;
    } catch (e) {
      if (kDebugMode) {
        print('Error assessing user behavior: $e');
      }
      
      return FraudAssessment(
        userId: userId,
        action: action,
        riskScore: 0.0,
        riskLevel: RiskLevel.low,
        timestamp: DateTime.now(),
        context: context ?? {},
        flags: [],
      );
    }
  }

  static Future<bool> reportSuspiciousActivity({
    required String reporterId,
    required String suspiciousUserId,
    required SuspiciousActivityType type,
    required String description,
    String? evidenceUrl,
  }) async {
    try {
      final report = SuspiciousActivityReport(
        reporterId: reporterId,
        suspiciousUserId: suspiciousUserId,
        type: type,
        description: description,
        evidenceUrl: evidenceUrl,
        reportedAt: DateTime.now(),
        status: ReportStatus.pending,
      );

      await _firestore.collection('suspicious_activity_reports').add(report.toMap());

      // Log security event
      await _logSecurityEvent(
        type: SecurityEventType.suspiciousActivityReported,
        userId: reporterId,
        details: {
          'suspicious_user_id': suspiciousUserId,
          'activity_type': type.toString(),
          'description': description,
        },
      );

      // Auto-flag user if multiple reports
      await _checkForAutoFlag(suspiciousUserId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting suspicious activity: $e');
      }
      return false;
    }
  }

  // User Verification and Trust Score
  static Future<double> calculateTrustScore(String userId) async {
    try {
      double trustScore = 50.0; // Base score

      // Get user statistics
      final userDoc = await _firestore.collection('user_profiles').doc(userId).get();
      if (!userDoc.exists) return trustScore;

      final userData = userDoc.data()!;
      final stats = userData['statistics'] as Map<String, dynamic>? ?? {};

      // Account age factor (max 20 points)
      final joinDate = DateTime.parse(userData['joinDate'] ?? DateTime.now().toIso8601String());
      final accountAge = DateTime.now().difference(joinDate).inDays;
      trustScore += (accountAge / 365 * 20).clamp(0, 20);

      // Successful reports factor (max 15 points)
      final successfulReports = stats['successfulReports'] ?? 0;
      trustScore += (successfulReports * 2).clamp(0, 15);

      // Items returned factor (max 15 points)
      final itemsReturned = stats['itemsReturned'] ?? 0;
      trustScore += (itemsReturned * 3).clamp(0, 15);

      // Average rating factor (max 10 points)
      final averageRating = (stats['averageRating'] ?? 0.0).toDouble();
      if (averageRating > 0) {
        trustScore += (averageRating - 3) * 5; // 3 is neutral, above adds points
      }

      // Verification badges factor (max 10 points)
      final verificationBadges = userData['verificationBadges'] as List<dynamic>? ?? [];
      trustScore += verificationBadges.length * 5;

      // Negative factors
      // Check for fraud flags
      final fraudFlags = await _getUserFraudFlags(userId);
      trustScore -= fraudFlags.length * 10;

      // Check for suspicious activity reports
      final suspiciousReports = await _getSuspiciousActivityReports(userId);
      trustScore -= suspiciousReports.length * 5;

      // Clamp between 0 and 100
      trustScore = trustScore.clamp(0, 100);

      // Update user profile with trust score
      await _firestore.collection('user_profiles').doc(userId).update({
        'trustScore': trustScore,
        'trustScoreUpdatedAt': FieldValue.serverTimestamp(),
      });

      return trustScore;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating trust score: $e');
      }
      return 50.0; // Return neutral score on error
    }
  }

  // Security Monitoring
  static Future<bool> monitorUserSession({
    required String userId,
    required String sessionId,
    required String ipAddress,
    required String userAgent,
    required String location,
  }) async {
    try {
      final session = UserSession(
        userId: userId,
        sessionId: sessionId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        location: location,
        startTime: DateTime.now(),
        isActive: true,
        riskFlags: [],
      );

      // Check for suspicious patterns
      final riskFlags = await _analyzeSessionRisk(userId, ipAddress, location);
      session.riskFlags.addAll(riskFlags);

      await _firestore.collection('user_sessions').doc(sessionId).set(session.toMap());

      // Log high-risk sessions
      if (riskFlags.isNotEmpty) {
        await _logSecurityEvent(
          type: SecurityEventType.suspiciousSession,
          userId: userId,
          details: {
            'session_id': sessionId,
            'ip_address': ipAddress,
            'location': location,
            'risk_flags': riskFlags,
          },
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error monitoring user session: $e');
      }
      return false;
    }
  }

  static Future<List<SecurityAlert>> getSecurityAlerts({
    String? userId,
    SecurityEventType? type,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('security_events');

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SecurityAlert.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting security alerts: $e');
      }
      return [];
    }
  }

  // Data Protection
  static Future<bool> encryptSensitiveData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // In a real implementation, use proper encryption
      final encryptedData = <String, dynamic>{};
      
      for (final entry in data.entries) {
        if (_isSensitiveField(entry.key)) {
          encryptedData[entry.key] = _encryptString(entry.value.toString());
        } else {
          encryptedData[entry.key] = entry.value;
        }
      }

      await _firestore.collection('encrypted_user_data').doc(userId).set(encryptedData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error encrypting sensitive data: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>?> decryptSensitiveData(String userId) async {
    try {
      final doc = await _firestore.collection('encrypted_user_data').doc(userId).get();
      
      if (!doc.exists) return null;

      final encryptedData = doc.data()!;
      final decryptedData = <String, dynamic>{};

      for (final entry in encryptedData.entries) {
        if (_isSensitiveField(entry.key)) {
          decryptedData[entry.key] = _decryptString(entry.value.toString());
        } else {
          decryptedData[entry.key] = entry.value;
        }
      }

      return decryptedData;
    } catch (e) {
      if (kDebugMode) {
        print('Error decrypting sensitive data: $e');
      }
      return null;
    }
  }

  // Private helper methods
  static String _hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<double> _calculateRiskScore(
    String userId,
    String action,
    Map<String, dynamic>? context,
  ) async {
    double riskScore = 0.0;

    // Check user history
    final userTrustScore = await calculateTrustScore(userId);
    riskScore += (100 - userTrustScore) / 100 * 30; // Max 30 points

    // Check action frequency
    final recentActions = await _getRecentUserActions(userId, action);
    if (recentActions > 10) riskScore += 20; // Suspicious frequency

    // Check time patterns
    final hour = DateTime.now().hour;
    if (hour < 6 || hour > 22) riskScore += 10; // Unusual hours

    // Check location consistency (if available)
    if (context?['location'] != null) {
      final locationConsistency = await _checkLocationConsistency(userId, context!['location']);
      if (!locationConsistency) riskScore += 15;
    }

    return riskScore.clamp(0, 100);
  }

  static RiskLevel _determineRiskLevel(double riskScore) {
    if (riskScore >= 70) return RiskLevel.high;
    if (riskScore >= 40) return RiskLevel.medium;
    return RiskLevel.low;
  }

  static Future<List<String>> _getFraudFlags(
    String userId,
    String action,
    Map<String, dynamic>? context,
  ) async {
    final flags = <String>[];

    // Check for rapid successive actions
    final recentActions = await _getRecentUserActions(userId, action);
    if (recentActions > 5) flags.add('rapid_actions');

    // Check for unusual patterns
    if (context?['unusual_pattern'] == true) flags.add('unusual_pattern');

    // Check for multiple device usage
    final deviceCount = await _getRecentDeviceCount(userId);
    if (deviceCount > 3) flags.add('multiple_devices');

    return flags;
  }

  static Future<void> _logSecurityEvent({
    required SecurityEventType type,
    required String userId,
    required Map<String, dynamic> details,
  }) async {
    try {
      final event = SecurityEvent(
        type: type,
        userId: userId,
        timestamp: DateTime.now(),
        details: details,
      );

      await _firestore.collection('security_events').add(event.toMap());

      // Also log to analytics
      await AnalyticsService.logFeatureUsed(
        featureName: 'security_event',
        parameters: {
          'event_type': type.toString(),
          'user_id': userId,
          ...details,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error logging security event: $e');
      }
    }
  }

  static Future<void> _checkForAutoFlag(String userId) async {
    try {
      final recentReports = await _firestore
          .collection('suspicious_activity_reports')
          .where('suspiciousUserId', isEqualTo: userId)
          .where('reportedAt', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
          .get();

      if (recentReports.docs.length >= 3) {
        // Auto-flag user for review
        await _firestore.collection('user_flags').doc(userId).set({
          'flagged': true,
          'reason': 'Multiple suspicious activity reports',
          'flaggedAt': FieldValue.serverTimestamp(),
          'reportCount': recentReports.docs.length,
        });

        await _logSecurityEvent(
          type: SecurityEventType.userAutoFlagged,
          userId: userId,
          details: {
            'report_count': recentReports.docs.length,
            'reason': 'Multiple suspicious activity reports',
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for auto flag: $e');
      }
    }
  }

  static Future<List<String>> _getUserFraudFlags(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('fraud_assessments')
          .where('userId', isEqualTo: userId)
          .where('riskLevel', isEqualTo: RiskLevel.high.toString())
          .limit(10)
          .get();

      return snapshot.docs
          .expand((doc) => List<String>.from(doc.data()['flags'] ?? []))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<SuspiciousActivityReport>> _getSuspiciousActivityReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('suspicious_activity_reports')
          .where('suspiciousUserId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => SuspiciousActivityReport.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> _analyzeSessionRisk(
    String userId,
    String ipAddress,
    String location,
  ) async {
    final riskFlags = <String>[];

    // Check for unusual location
    final userSessions = await _firestore
        .collection('user_sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(10)
        .get();

    final recentLocations = userSessions.docs
        .map((doc) => doc.data()['location'] as String)
        .toSet();

    if (recentLocations.isNotEmpty && !recentLocations.contains(location)) {
      riskFlags.add('unusual_location');
    }

    // Check for multiple simultaneous sessions
    final activeSessions = await _firestore
        .collection('user_sessions')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (activeSessions.docs.length > 2) {
      riskFlags.add('multiple_active_sessions');
    }

    return riskFlags;
  }

  static Future<int> _getRecentUserActions(String userId, String action) async {
    try {
      final snapshot = await _firestore
          .collection('user_activities')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: action)
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 1)))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  static Future<bool> _checkLocationConsistency(String userId, String location) async {
    try {
      final recentSessions = await _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(5)
          .get();

      final recentLocations = recentSessions.docs
          .map((doc) => doc.data()['location'] as String)
          .toList();

      return recentLocations.contains(location);
    } catch (e) {
      return true; // Assume consistent on error
    }
  }

  static Future<int> _getRecentDeviceCount(String userId) async {
    try {
      final recentSessions = await _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThan: DateTime.now().subtract(const Duration(days: 1)))
          .get();

      final devices = recentSessions.docs
          .map((doc) => doc.data()['userAgent'] as String)
          .toSet();

      return devices.length;
    } catch (e) {
      return 1;
    }
  }

  static bool _isSensitiveField(String fieldName) {
    const sensitiveFields = [
      'phoneNumber',
      'email',
      'address',
      'socialSecurityNumber',
      'creditCardNumber',
    ];
    return sensitiveFields.contains(fieldName);
  }

  static String _encryptString(String input) {
    // Simple base64 encoding for demo - use proper encryption in production
    return base64Encode(utf8.encode(input));
  }

  static String _decryptString(String encrypted) {
    // Simple base64 decoding for demo - use proper decryption in production
    return utf8.decode(base64Decode(encrypted));
  }
}

// Data Models
class ItemVerification {
  final String itemId;
  final String ownerId;
  final String verificationCode;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final bool isUsed;
  final int attempts;

  ItemVerification({
    required this.itemId,
    required this.ownerId,
    required this.verificationCode,
    required this.generatedAt,
    required this.expiresAt,
    required this.isUsed,
    required this.attempts,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'ownerId': ownerId,
      'verificationCode': verificationCode,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isUsed': isUsed,
      'attempts': attempts,
    };
  }

  factory ItemVerification.fromMap(Map<String, dynamic> map) {
    return ItemVerification(
      itemId: map['itemId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      verificationCode: map['verificationCode'] ?? '',
      generatedAt: DateTime.parse(map['generatedAt']),
      expiresAt: DateTime.parse(map['expiresAt']),
      isUsed: map['isUsed'] ?? false,
      attempts: map['attempts'] ?? 0,
    );
  }
}

class VerificationResult {
  final bool success;
  final String message;
  final String? ownerId;

  VerificationResult({
    required this.success,
    required this.message,
    this.ownerId,
  });
}

class FraudAssessment {
  final String userId;
  final String action;
  final double riskScore;
  final RiskLevel riskLevel;
  final DateTime timestamp;
  final Map<String, dynamic> context;
  final List<String> flags;

  FraudAssessment({
    required this.userId,
    required this.action,
    required this.riskScore,
    required this.riskLevel,
    required this.timestamp,
    required this.context,
    required this.flags,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      'riskScore': riskScore,
      'riskLevel': riskLevel.toString(),
      'timestamp': timestamp.toIso8601String(),
      'context': context,
      'flags': flags,
    };
  }
}

class SuspiciousActivityReport {
  final String reporterId;
  final String suspiciousUserId;
  final SuspiciousActivityType type;
  final String description;
  final String? evidenceUrl;
  final DateTime reportedAt;
  final ReportStatus status;

  SuspiciousActivityReport({
    required this.reporterId,
    required this.suspiciousUserId,
    required this.type,
    required this.description,
    this.evidenceUrl,
    required this.reportedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'suspiciousUserId': suspiciousUserId,
      'type': type.toString(),
      'description': description,
      'evidenceUrl': evidenceUrl,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory SuspiciousActivityReport.fromMap(Map<String, dynamic> map) {
    return SuspiciousActivityReport(
      reporterId: map['reporterId'] ?? '',
      suspiciousUserId: map['suspiciousUserId'] ?? '',
      type: SuspiciousActivityType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SuspiciousActivityType.other,
      ),
      description: map['description'] ?? '',
      evidenceUrl: map['evidenceUrl'],
      reportedAt: DateTime.parse(map['reportedAt']),
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ReportStatus.pending,
      ),
    );
  }
}

class UserSession {
  final String userId;
  final String sessionId;
  final String ipAddress;
  final String userAgent;
  final String location;
  final DateTime startTime;
  final bool isActive;
  final List<String> riskFlags;

  UserSession({
    required this.userId,
    required this.sessionId,
    required this.ipAddress,
    required this.userAgent,
    required this.location,
    required this.startTime,
    required this.isActive,
    required this.riskFlags,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'location': location,
      'startTime': startTime.toIso8601String(),
      'isActive': isActive,
      'riskFlags': riskFlags,
    };
  }
}

class SecurityEvent {
  final SecurityEventType type;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  SecurityEvent({
    required this.type,
    required this.userId,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}

class SecurityAlert {
  final SecurityEventType type;
  final String userId;
  final DateTime timestamp;
  final String message;
  final AlertSeverity severity;

  SecurityAlert({
    required this.type,
    required this.userId,
    required this.timestamp,
    required this.message,
    required this.severity,
  });

  factory SecurityAlert.fromMap(Map<String, dynamic> map) {
    return SecurityAlert(
      type: SecurityEventType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SecurityEventType.other,
      ),
      userId: map['userId'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      message: map['message'] ?? '',
      severity: AlertSeverity.values.firstWhere(
        (e) => e.toString() == map['severity'],
        orElse: () => AlertSeverity.low,
      ),
    );
  }
}

// Enums
enum RiskLevel { low, medium, high }

enum SuspiciousActivityType {
  fakeReports,
  spamming,
  harassment,
  fraudulentClaims,
  multipleAccounts,
  other,
}

enum ReportStatus { pending, investigating, resolved, dismissed }

enum SecurityEventType {
  verificationSuccess,
  verificationFailed,
  highRiskActivity,
  suspiciousActivityReported,
  suspiciousSession,
  userAutoFlagged,
  dataEncrypted,
  unauthorizedAccess,
  other,
}

enum AlertSeverity { low, medium, high, critical }