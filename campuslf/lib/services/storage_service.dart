import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _itemsKey = 'stored_items';
  static const String _userDataKey = 'user_data';
  static const String _settingsKey = 'app_settings';

  Future<void> saveItems(List<Item> items) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = items.map((item) => item.toJson()).toList();
    await prefs.setString(_itemsKey, jsonEncode(itemsJson));
  }

  Future<List<Item>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsString = prefs.getString(_itemsKey);
    
    if (itemsString == null) return [];
    
    final itemsJson = jsonDecode(itemsString) as List;
    return itemsJson.map((json) => Item.fromJson(json)).toList();
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  Future<Map<String, dynamic>> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      
      if (userDataString == null) {
        return {
          'name': 'Campus User',
          'email': 'user@wsu.ac.za',
          'karma': 0,
          'joinDate': DateTime.now().toIso8601String(),
        };
      }
      
      return jsonDecode(userDataString);
    } catch (e) {
      return {
        'name': 'Campus User',
        'email': 'user@wsu.ac.za',
        'karma': 0,
        'joinDate': DateTime.now().toIso8601String(),
      };
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_settingsKey);
    
    if (settingsString == null) return AppSettings();
    
    return AppSettings.fromJson(jsonDecode(settingsString));
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

class AppSettings {
  bool notificationsEnabled;
  bool darkModeEnabled;
  String language;
  double searchRadius;
  bool locationEnabled;

  AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.language = 'en',
    this.searchRadius = 5.0,
    this.locationEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'darkModeEnabled': darkModeEnabled,
    'language': language,
    'searchRadius': searchRadius,
    'locationEnabled': locationEnabled,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    notificationsEnabled: json['notificationsEnabled'] ?? true,
    darkModeEnabled: json['darkModeEnabled'] ?? false,
    language: json['language'] ?? 'en',
    searchRadius: json['searchRadius'] ?? 5.0,
    locationEnabled: json['locationEnabled'] ?? true,
  );
}