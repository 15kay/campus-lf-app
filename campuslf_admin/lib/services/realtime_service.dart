import 'dart:async';
import '../models/item.dart';
import 'firestore_service.dart';

class RealtimeService {
  static final _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final _firestoreService = FirestoreService();
  
  Stream<List<Item>> get itemsStream => _firestoreService.getItemsStream();
  Stream<Map<String, dynamic>> get statsStream => _firestoreService.getAnalyticsStream();
  Stream<Map<String, dynamic>> get usersStream => _firestoreService.getUsersStream();
  Stream<List<Map<String, dynamic>>> get messagesStream => _firestoreService.getMessagesStream();
  Stream<Map<String, int>> get categoryStatsStream => _firestoreService.getCategoryStatsStream();

  void startListening() {
    // Real-time streams are automatically handled by Firestore
  }

  Future<void> updateItemStatus(String itemId, bool isResolved) async {
    await _firestoreService.updateItemStatus(itemId, isResolved);
  }

  Future<void> deleteItem(String itemId) async {
    await _firestoreService.deleteItem(itemId);
  }

  void dispose() {
    // Firestore streams are automatically disposed
  }
}