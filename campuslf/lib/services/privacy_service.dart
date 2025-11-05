import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class PrivacyService {
  static final PrivacyService _instance = PrivacyService._internal();
  factory PrivacyService() => _instance;
  PrivacyService._internal();

  // Export all user data
  Future<String> exportUserData() async {
    final userData = await StorageService().loadUserData();
    final items = await StorageService().loadItems();
    final settings = await StorageService().loadSettings();
    
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'userData': userData,
      'items': items.map((item) => item.toJson()).toList(),
      'settings': settings.toJson(),
    };
    
    return jsonEncode(exportData);
  }

  // Save exported data to file
  Future<File> saveDataToFile() async {
    final data = await exportUserData();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/wsu_lostfound_data_export.json');
    return await file.writeAsString(data);
  }

  // Delete all user data
  Future<void> deleteAllUserData() async {
    await StorageService().clearAllData();
    await AuthService.logout();
  }

  // Get data summary for access request
  Future<Map<String, dynamic>> getDataSummary() async {
    try {
      final userData = await StorageService().loadUserData();
      final items = await StorageService().loadItems();
      
      return {
        'personalInfo': {
          'name': userData['name'] ?? 'Campus User',
          'email': userData['email'] ?? 'user@wsu.ac.za',
          'joinDate': userData['joinDate'] ?? DateTime.now().toIso8601String(),
          'karma': userData['karma'] ?? 0,
        },
        'itemsReported': items.length,
        'dataCategories': [
          'Personal Information',
          'Item Reports',
          'App Settings',
          'Privacy Preferences',
        ],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'personalInfo': {
          'name': 'Campus User',
          'email': 'user@wsu.ac.za',
          'joinDate': DateTime.now().toIso8601String(),
          'karma': 0,
        },
        'itemsReported': 0,
        'dataCategories': [
          'Personal Information',
          'Item Reports',
          'App Settings',
          'Privacy Preferences',
        ],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }

  // Anonymize user data (for research purposes)
  Future<void> anonymizeData() async {
    final userData = await StorageService().loadUserData();
    
    userData['name'] = 'Anonymous User';
    userData['email'] = 'anonymous@wsu.ac.za';
    
    await StorageService().saveUserData(userData);
  }

  // Submit privacy request
  Future<bool> submitPrivacyRequest(String requestType, String details) async {
    // In a real app, this would send to a server
    // For now, we'll simulate success
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  // Check consent status
  Future<Map<String, bool>> getConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'dataCollection': prefs.getBool('consent_dataCollection') ?? true,
      'analytics': prefs.getBool('consent_analytics') ?? true,
      'communications': prefs.getBool('consent_communications') ?? true,
      'research': prefs.getBool('consent_research') ?? false,
    };
  }

  // Update consent
  Future<void> updateConsent(String consentType, bool granted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent_$consentType', granted);
    
    // Apply consent changes immediately
    switch (consentType) {
      case 'dataCollection':
        if (!granted) {
          // Stop data collection
          await _stopDataCollection();
        }
        break;
      case 'analytics':
        if (!granted) {
          // Disable analytics
          await _disableAnalytics();
        }
        break;
      case 'communications':
        if (!granted) {
          // Disable notifications
          await _disableNotifications();
        }
        break;
      case 'research':
        if (!granted) {
          // Remove from research data
          await _removeFromResearch();
        }
        break;
    }
  }

  Future<void> _stopDataCollection() async {
    // Implementation for stopping data collection
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('data_collection_stopped', true);
  }

  Future<void> _disableAnalytics() async {
    // Implementation for disabling analytics
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_disabled', true);
  }

  Future<void> _disableNotifications() async {
    // Implementation for disabling notifications
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_disabled', true);
  }

  Future<void> _removeFromResearch() async {
    // Implementation for removing from research
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('research_excluded', true);
  }

  // Check if specific consent is granted
  Future<bool> hasConsent(String consentType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('consent_$consentType') ?? false;
  }

  // Get privacy settings summary
  Future<Map<String, dynamic>> getPrivacySettings() async {
    final consent = await getConsentStatus();
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'consent': consent,
      'dataCollectionStopped': prefs.getBool('data_collection_stopped') ?? false,
      'analyticsDisabled': prefs.getBool('analytics_disabled') ?? false,
      'notificationsDisabled': prefs.getBool('notifications_disabled') ?? false,
      'researchExcluded': prefs.getBool('research_excluded') ?? false,
    };
  }
}