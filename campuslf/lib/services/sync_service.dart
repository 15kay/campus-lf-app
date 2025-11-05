import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../models/message.dart';
import 'database_service.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _localDb = DatabaseService();

  // Sync items to cloud
  Future<void> syncItemToCloud(Item item) async {
    try {
      await _firestore.collection('items').doc(item.id).set(item.toJson());
    } catch (e) {
      // Fail silently - local data is primary
    }
  }

  // Sync items from cloud
  Future<void> syncItemsFromCloud() async {
    try {
      final snapshot = await _firestore.collection('items').get();
      for (final doc in snapshot.docs) {
        final item = Item.fromJson(doc.data());
        await _localDb.insertItem(item);
      }
    } catch (e) {
      // Fail silently - local data is primary
    }
  }

  // Sync messages to cloud
  Future<void> syncMessageToCloud(Message message) async {
    try {
      await _firestore.collection('messages').doc(message.id).set(message.toJson());
    } catch (e) {
      // Fail silently
    }
  }

  // Background sync (called periodically)
  Future<void> backgroundSync() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;

      // Sync local items to cloud
      final localItems = await _localDb.getAllItems();
      for (final item in localItems) {
        await syncItemToCloud(item);
      }

      // Sync cloud items to local
      await syncItemsFromCloud();
    } catch (e) {
      // Fail silently - local operation continues
    }
  }
}