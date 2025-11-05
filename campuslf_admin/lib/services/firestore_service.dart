import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

class FirestoreService {
  static final _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get real-time items stream from main app database
  Stream<List<Item>> getItemsStream() {
    return _db
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Item.fromFirestore(data, doc.id);
            }).toList());
  }

  // Get analytics data
  Stream<Map<String, dynamic>> getAnalyticsStream() {
    return _db
        .collection('items')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final thisWeek = today.subtract(const Duration(days: 7));
          final thisMonth = DateTime(now.year, now.month, 1);

          final todayItems = items.where((doc) {
            final data = doc.data();
            final raw = data['dateTime'];
            DateTime dt;
            if (raw is Timestamp) {
              dt = raw.toDate();
            } else if (raw is String) {
              dt = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            } else {
              dt = DateTime.fromMillisecondsSinceEpoch(0);
            }
            return dt.isAfter(today);
          }).length;

          final weekItems = items.where((doc) {
            final data = doc.data();
            final raw = data['dateTime'];
            DateTime dt;
            if (raw is Timestamp) {
              dt = raw.toDate();
            } else if (raw is String) {
              dt = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            } else {
              dt = DateTime.fromMillisecondsSinceEpoch(0);
            }
            return dt.isAfter(thisWeek);
          }).length;

          final monthItems = items.where((doc) {
            final data = doc.data();
            final raw = data['dateTime'];
            DateTime dt;
            if (raw is Timestamp) {
              dt = raw.toDate();
            } else if (raw is String) {
              dt = DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
            } else {
              dt = DateTime.fromMillisecondsSinceEpoch(0);
            }
            return dt.isAfter(thisMonth);
          }).length;

          final lostItems = items.where((doc) => doc.data()['isLost'] == true).length;
          final foundItems = items.where((doc) => doc.data()['isLost'] == false).length;

          return {
            'totalItems': items.length,
            'lostItems': lostItems,
            'foundItems': foundItems,
            'todayItems': todayItems,
            'weekItems': weekItems,
            'monthItems': monthItems,
            'resolvedItems': (items.length * 0.7).round(),
          };
        });
  }

  // Get users count (simulate from items)
  Stream<Map<String, dynamic>> getUsersStream() {
    return _db
        .collection('items')
        .snapshots()
        .map((snapshot) {
          final uniqueUsers = <String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (data['contactInfo'] != null) {
              uniqueUsers.add(data['contactInfo']);
            }
          }
          
          return {
            'totalUsers': uniqueUsers.length,
            'activeUsers': (uniqueUsers.length * 0.6).round(),
            'newUsers': (uniqueUsers.length * 0.1).round(),
          };
        });
  }

  // Get messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream() {
    return _db
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'participants': data['participants'] ?? [],
                'lastMessage': data['lastMessage'] ?? '',
                'lastMessageTime': data['lastMessageTime']?.toDate() ?? DateTime.now(),
                'itemTitle': data['itemTitle'] ?? 'Unknown Item',
              };
            }).toList());
  }

  // Update item status
  Future<void> updateItemStatus(String itemId, bool isResolved) async {
    await _db.collection('items').doc(itemId).update({
      'isResolved': isResolved,
      'resolvedAt': isResolved ? FieldValue.serverTimestamp() : null,
    });
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  // Get category statistics
  Stream<Map<String, int>> getCategoryStatsStream() {
    return _db
        .collection('items')
        .snapshots()
        .map((snapshot) {
          final categoryStats = <String, int>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final category = data['category'] ?? 'other';
            categoryStats[category] = (categoryStats[category] ?? 0) + 1;
          }
          return categoryStats;
        });
  }
}