import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  static const String _messagesKey = 'user_messages';

  Future<void> addMessage(Map<String, dynamic> messageData) async {
    final prefs = await SharedPreferences.getInstance();
    final existingMessages = await getMessages();
    
    existingMessages.add(messageData);
    await prefs.setString(_messagesKey, jsonEncode(existingMessages));
  }
  
  Future<void> addMessageWithDetails({
    required String senderName,
    required String senderEmail,
    required String content,
    required String itemTitle,
    bool isFromMe = false,
  }) async {
    final messageData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'senderName': senderName,
      'senderEmail': senderEmail,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'isFromMe': isFromMe,
      'itemTitle': itemTitle,
    };
    
    await addMessage(messageData);
  }

  Future<List<Map<String, dynamic>>> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString(_messagesKey);
    
    if (messagesJson == null) return [];
    
    final List<dynamic> messagesList = jsonDecode(messagesJson);
    return messagesList.cast<Map<String, dynamic>>();
  }

  Future<void> clearMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_messagesKey);
  }
}