import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add item to Firestore
  Future<void> addItem(Item item) async {
    await _db.collection('items').doc(item.id).set({
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'location': item.location,
      'dateTime': item.dateTime.toIso8601String(),
      'isLost': item.isLost,
      'contactInfo': item.contactInfo,
      'category': item.category.toString(),
      'imagePaths': item.imagePaths,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all items stream
  Stream<List<Item>> getItemsStream() {
    return _db
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Item(
                id: data['id'],
                title: data['title'],
                description: data['description'],
                location: data['location'],
                dateTime: DateTime.parse(data['dateTime']),
                isLost: data['isLost'],
                contactInfo: data['contactInfo'],
                category: ItemCategory.values.firstWhere(
                  (e) => e.toString() == data['category'],
                  orElse: () => ItemCategory.other,
                ),
                imagePaths: List<String>.from(data['imagePaths'] ?? []),
              );
            }).toList());
  }

  // Add message to Firestore
  Future<void> addMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String content,
    String? itemTitle,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'itemTitle': itemTitle,
    });
    
    // Update chat metadata
    await _db.collection('chats').doc(chatId).set({
      'participants': [senderId, 'other_user'],
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'itemTitle': itemTitle,
    }, SetOptions(merge: true));
  }
  
  // Create or get chat ID for item conversation
  String getChatId(String itemId, String userId) {
    return 'item_${itemId}_user_$userId';
  }

  // Get messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'senderId': data['senderId'],
                'senderName': data['senderName'],
                'content': data['content'],
                'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
                'itemTitle': data['itemTitle'],
                'isFromMe': data['senderId'] == 'current_user',
              };
            }).toList());
  }

  // Get user conversations
  Stream<List<Map<String, dynamic>>> getUserConversations(String userId) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'chatId': doc.id,
                'participants': data['participants'],
                'lastMessage': data['lastMessage'],
                'lastMessageTime': data['lastMessageTime']?.toDate(),
                'itemTitle': data['itemTitle'],
              };
            }).toList());
  }
}