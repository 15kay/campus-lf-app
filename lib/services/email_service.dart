import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmailService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Email service configuration
  static const String _emailServiceUrl = 'https://us-central1-campuslf.cloudfunctions.net/sendEmail';
  static const String _fromEmail = 'noreply@campuslf.web.app';
  static const String _fromName = 'Campus Lost & Found';

  /// Sends an email using Firebase Cloud Functions
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Prepare email data
      final emailData = {
        'to': to,
        'from': {
          'email': _fromEmail,
          'name': _fromName,
        },
        'subject': subject,
        'html': htmlBody,
        'text': textBody ?? _stripHtml(htmlBody),
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send via Firebase Cloud Function
      final response = await http.post(
        Uri.parse(_emailServiceUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(emailData),
      );

      if (response.statusCode == 200) {
        // Log successful email send
        await _analytics.logEvent(
          name: 'email_sent_success',
          parameters: {
            'recipient': to,
            'subject': subject,
            'type': metadata?['type'] ?? 'unknown',
          },
        );

        // Store email record in Firestore
        await _storeEmailRecord(emailData, 'sent');
        
        print('Email sent successfully to: $to');
        return true;
      } else {
        throw Exception('Email service returned status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending email: $e');
      
      // Log email failure
      await _analytics.logEvent(
        name: 'email_sent_failure',
        parameters: {
          'recipient': to,
          'subject': subject,
          'error': e.toString(),
          'type': metadata?['type'] ?? 'unknown',
        },
      );

      // Store failed email record
      await _storeEmailRecord({
        'to': to,
        'subject': subject,
        'error': e.toString(),
        'metadata': metadata ?? {},
      }, 'failed');

      return false;
    }
  }

  /// Sends a welcome email to new users
  static Future<bool> sendWelcomeEmail({
    required String userEmail,
    required String userName,
    required String userId,
  }) async {
    final subject = 'Welcome to Campus Lost & Found! 🎓';
    
    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #4CAF50, #45a049); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .feature-card { background: white; padding: 20px; border-radius: 10px; margin: 15px 0; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .cta-button { background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; display: inline-block; margin: 20px 0; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Welcome to Campus Lost & Found! 🎓</h1>
            <p>Hi $userName, we're excited to help you find your lost items!</p>
        </div>
        
        <div class="content">
            <p>Thank you for joining our community! Campus Lost & Found makes it easy to report lost items and find things that others have discovered on campus.</p>
            
            <div class="feature-card">
                <h3>🔍 Report Lost Items</h3>
                <p>Quickly report items you've lost with photos, descriptions, and location details.</p>
            </div>
            
            <div class="feature-card">
                <h3>📱 Smart Matching</h3>
                <p>Our AI-powered system automatically matches lost and found items and notifies you instantly.</p>
            </div>
            
            <div class="feature-card">
                <h3>💬 Direct Communication</h3>
                <p>Chat directly with people who may have found your items in a safe, moderated environment.</p>
            </div>
            
            <div style="text-align: center;">
                <a href="https://campuslf.web.app/" class="cta-button">
                    Start Using the App
                </a>
            </div>
            
            <div style="background: #e8f5e8; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h3>Quick Tips:</h3>
                <ul>
                    <li>Add detailed descriptions and photos for better matches</li>
                    <li>Check your notifications regularly for new matches</li>
                    <li>Always meet in public places when exchanging items</li>
                    <li>Mark items as resolved once you've been reunited</li>
                </ul>
            </div>
        </div>
        
        <div class="footer">
            <p>Campus Lost & Found - Reuniting you with your belongings</p>
            <p>Need help? Reply to this email or visit our support page.</p>
        </div>
    </div>
</body>
</html>
    ''';

    return await sendEmail(
      to: userEmail,
      subject: subject,
      htmlBody: htmlBody,
      metadata: {
        'type': 'welcome',
        'user_id': userId,
        'user_name': userName,
      },
    );
  }

  /// Sends a password reset email
  static Future<bool> sendPasswordResetEmail({
    required String userEmail,
    required String resetLink,
  }) async {
    final subject = 'Reset Your Campus Lost & Found Password';
    
    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #4CAF50; color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .cta-button { background: #4CAF50; color: white; padding: 15px 30px; text-decoration: none; border-radius: 25px; display: inline-block; margin: 20px 0; font-weight: bold; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        .warning { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Password Reset Request</h1>
        </div>
        
        <div class="content">
            <p>We received a request to reset your Campus Lost & Found password.</p>
            
            <div style="text-align: center;">
                <a href="$resetLink" class="cta-button">
                    Reset Your Password
                </a>
            </div>
            
            <div class="warning">
                <strong>Security Notice:</strong>
                <ul>
                    <li>This link will expire in 1 hour</li>
                    <li>If you didn't request this reset, please ignore this email</li>
                    <li>Never share this link with anyone</li>
                </ul>
            </div>
            
            <p>If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="word-break: break-all; background: #f0f0f0; padding: 10px; border-radius: 5px;">$resetLink</p>
        </div>
        
        <div class="footer">
            <p>Campus Lost & Found Security Team</p>
            <p>If you need help, contact our support team.</p>
        </div>
    </div>
</body>
</html>
    ''';

    return await sendEmail(
      to: userEmail,
      subject: subject,
      htmlBody: htmlBody,
      metadata: {
        'type': 'password_reset',
        'user_email': userEmail,
      },
    );
  }

  /// Stores email record in Firestore for tracking
  static Future<void> _storeEmailRecord(Map<String, dynamic> emailData, String status) async {
    try {
      await _firestore.collection('email_logs').add({
        ...emailData,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing email record: $e');
    }
  }

  /// Strips HTML tags from text (basic implementation)
  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// Gets email statistics for analytics
  static Future<Map<String, int>> getEmailStats() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      final query = await _firestore
          .collection('email_logs')
          .where('timestamp', isGreaterThan: startOfDay)
          .get();

      int sent = 0;
      int failed = 0;
      
      for (final doc in query.docs) {
        final status = doc.data()['status'];
        if (status == 'sent') {
          sent++;
        } else if (status == 'failed') {
          failed++;
        }
      }

      return {
        'sent_today': sent,
        'failed_today': failed,
        'total_today': sent + failed,
      };
    } catch (e) {
      print('Error getting email stats: $e');
      return {
        'sent_today': 0,
        'failed_today': 0,
        'total_today': 0,
      };
    }
  }
}