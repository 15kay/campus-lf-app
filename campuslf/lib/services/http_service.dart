import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../models/user.dart';

// Stub HTTP response class since http package is not available
class _HttpResponse {
  final int statusCode;
  final String body;
  _HttpResponse(this.statusCode, this.body);
}

// Stub HTTP client since this service is unused
class _Http {
  Future<_HttpResponse> post(Uri uri, {Map<String, String>? headers, String? body}) async {
    throw UnimplementedError('HTTP service not implemented - use Firebase instead');
  }
  Future<_HttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    throw UnimplementedError('HTTP service not implemented - use Firebase instead');
  }
  Future<_HttpResponse> put(Uri uri, {Map<String, String>? headers, String? body}) async {
    throw UnimplementedError('HTTP service not implemented - use Firebase instead');
  }
  Future<_HttpResponse> delete(Uri uri, {Map<String, String>? headers}) async {
    throw UnimplementedError('HTTP service not implemented - use Firebase instead');
  }
}

final _http = _Http();

class HttpService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  static Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  static Map<String, String> _getHeaders([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Auth methods
  static Future<String?> register({
    required String email,
    required String password,
    required String name,
    String? studentId,
    String? phone,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'studentId': studentId,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Network error: Please check your connection';
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveToken(data['token']);
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Login failed';
      }
    } catch (e) {
      return 'Network error: Please check your connection';
    }
  }

  static Future<User?> getCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await _http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          isAdmin: data['isAdmin'] ?? false,
        );
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }

  static Future<void> logout() async {
    await _clearToken();
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  static Future<String?> updateUser({String? name, String? phone}) async {
    try {
      final token = await _getToken();
      if (token == null) return 'Not authenticated';

      final response = await _http.put(
        Uri.parse('$baseUrl/auth/update'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'name': name,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Update failed';
      }
    } catch (e) {
      return 'Network error: Please check your connection';
    }
  }

  static Future<String?> deleteAccount() async {
    try {
      final token = await _getToken();
      if (token == null) return 'Not authenticated';

      final response = await _http.delete(
        Uri.parse('$baseUrl/auth/delete'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        await _clearToken();
        return null;
      } else {
        final error = jsonDecode(response.body);
        return error['error'] ?? 'Delete failed';
      }
    } catch (e) {
      return 'Network error: Please check your connection';
    }
  }

  // Item methods
  static Future<List<Item>> getAllItems() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _http.get(
        Uri.parse('$baseUrl/items'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Item(
          id: json['id'],
          title: json['title'],
          description: json['description'] ?? '',
          location: json['location'] ?? '',
          dateTime: DateTime.parse(json['dateTime']),
          isLost: json['isLost'],
          contactInfo: json['contactInfo'] ?? '',
          category: ItemCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
            orElse: () => ItemCategory.other,
          ),
          imagePath: json['imagePath'],
        )).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  static Future<List<Item>> getUserItems() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await _http.get(
        Uri.parse('$baseUrl/items/my-items'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Item(
          id: json['id'],
          title: json['title'],
          description: json['description'] ?? '',
          location: json['location'] ?? '',
          dateTime: DateTime.parse(json['dateTime']),
          isLost: json['isLost'],
          contactInfo: json['contactInfo'] ?? '',
          category: ItemCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
            orElse: () => ItemCategory.other,
          ),
          imagePath: json['imagePath'],
        )).toList();
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  static Future<bool> createItem(Item item) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await _http.post(
        Uri.parse('$baseUrl/items'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'title': item.title,
          'description': item.description,
          'location': item.location,
          'dateTime': item.dateTime.toIso8601String(),
          'isLost': item.isLost,
          'contactInfo': item.contactInfo,
          'category': item.category.toString(),
          'imagePath': item.imagePath,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteItem(String itemId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await _http.delete(
        Uri.parse('$baseUrl/items/$itemId'),
        headers: _getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}