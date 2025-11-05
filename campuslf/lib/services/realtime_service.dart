import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item.dart';
import 'auth_service.dart';
import '../utils/logger.dart';

class RealtimeService {
  static final _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Resolve a Firebase UID from an email by looking up the users collection
  Future<String?> resolveUidByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // users doc id is UID
      }
    } catch (e) {
      Logger.error('resolveUidByEmail error for $email: $e');
    }
    return null;
  }
  
  Stream<List<Item>> getItemsStream() {
    return _firestore
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          return Item(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            location: data['location'] ?? '',
            dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isLost: data['isLost'] ?? false,
            contactInfo: data['contactInfo'] ?? '',
            category: ItemCategory.values.firstWhere(
              (e) => e.toString() == data['category'],
              orElse: () => ItemCategory.other,
            ),
            imagePath: data['imagePath'],
            imagePaths: (data['imagePaths'] as List?)?.map((e) => e.toString()).toList(),
            likes: (data['likes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          );
        } catch (e) {
          return Item(
            id: doc.id,
            title: 'Error Item',
            description: 'Error loading item',
            location: 'Unknown',
            dateTime: DateTime.now(),
            isLost: true,
            contactInfo: 'error@wsu.ac.za',
            category: ItemCategory.other,
          );
        }
      }).toList();
    });
  }

  Future<void> addItem(Item item) async {
    final userData = await AuthService.getUserRegistrationData();
    final userEmail = userData['email'] ?? 'user@wsu.ac.za';
    final userId = _auth.currentUser?.uid ?? await AuthService.getCurrentUserId() ?? userEmail;
    
    await _firestore.collection('items').add({
      'title': item.title,
      'description': item.description,
      'location': item.location,
      'dateTime': Timestamp.fromDate(item.dateTime),
      'isLost': item.isLost,
      'contactInfo': item.contactInfo,
      'category': item.category.toString(),
      'imagePath': item.imagePath,
      if (item.imagePaths != null) 'imagePaths': item.imagePaths,
      'likes': item.likes, // initialize empty likes list
      'userId': userId,
      'userEmail': userEmail,
      'userName': userData['name'] ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Item>> getUserItemsStream({required String userId, String? userEmail}) {
    // Merge results where userId matches or userEmail matches for backward compatibility
    final byIdStream = _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    final byEmailStream = (userEmail != null)
        ? _firestore
            .collection('items')
            .where('userEmail', isEqualTo: userEmail)
            .orderBy('createdAt', descending: true)
            .snapshots()
        : const Stream.empty();

  return StreamZip([byIdStream, byEmailStream]).map((snapshots) {
      // snapshots[0] = byId, snapshots[1] = byEmail
      final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
      for (final snap in snapshots) {
        docs.addAll(snap.docs);
      }
      // Deduplicate by doc.id
      final seen = <String>{};
      return docs.where((d) => seen.add(d.id)).map((doc) {
        final data = doc.data();
        return Item(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isLost: data['isLost'] ?? false,
          contactInfo: data['contactInfo'] ?? '',
          category: ItemCategory.values.firstWhere(
            (e) => e.toString() == data['category'],
            orElse: () => ItemCategory.other,
          ),
          imagePath: data['imagePath'],
          imagePaths: (data['imagePaths'] as List?)?.map((e) => e.toString()).toList(),
          likes: (data['likes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        );
      }).toList();
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _firestore.collection('items').doc(itemId).update(data);
  }

  Stream<List<Map<String, dynamic>>> getForumPostsStream() {
    return _firestore
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'category': data['category'] ?? 'General',
          'userId': data['userId'] ?? '',
          'userName': data['userName'] ?? 'Anonymous',
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'likes': data['likes'] ?? 0,
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String userEmail) {
    // Return messages where current user is the receiver
    return _firestore
        .collection('messages')
        .where('receiverEmail', isEqualTo: userEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'senderId': data['senderId'] ?? '',
          'senderName': data['senderName'] ?? 'Anonymous',
          'senderEmail': data['senderEmail'] ?? '',
          'content': data['content'] ?? '',
          'type': data['type'] ?? 'text',
          'imageUrl': data['imageUrl'],
          'createdAt': data['createdAt'] ?? Timestamp.now(),
          'isRead': data['isRead'] ?? false,
        };
      }).toList();
    });
  }

  Future<void> addForumPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final userData = await AuthService.getUserRegistrationData();
    final userId = _auth.currentUser?.uid ?? await AuthService.getCurrentUserId() ?? userData['email'] ?? 'user@wsu.ac.za';
    await _firestore.collection('forum_posts').add({
      'title': title,
      'content': content,
      'category': category,
      'userId': userId,
      'userEmail': userData['email'] ?? 'user@wsu.ac.za',
      'userName': userData['name'] ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
    });
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final userData = await AuthService.getUserRegistrationData();
    final userEmail = userData['email'] ?? 'user@wsu.ac.za';
    final userId = _auth.currentUser?.uid ?? await AuthService.getCurrentUserId() ?? userEmail;
    // If receiverId looks like an email, try to resolve to UID
    String resolvedReceiverId = receiverId;
    String? receiverEmail;
    if (receiverId.contains('@')) {
      receiverEmail = receiverId;
      resolvedReceiverId = await resolveUidByEmail(receiverId) ?? receiverId;
    }
    await _firestore.collection('messages').add({
      'senderId': userId,
      'senderName': userData['name'] ?? 'User',
      'receiverId': resolvedReceiverId,
      if (receiverEmail != null) 'receiverEmail': receiverEmail,
      'content': content,
      // Include both UID and email for compatibility in participants
      'participants': [userId, userEmail, resolvedReceiverId, if (receiverEmail != null) receiverEmail],
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> likeForumPost(String postId) async {
    await _firestore.collection('forum_posts').doc(postId).update({
      'likes': FieldValue.increment(1),
    });
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'content': data['content'] ?? '',
                'userId': data['userId'] ?? '',
                'userName': data['userName'] ?? 'Anonymous',
                'createdAt': data['createdAt'] ?? Timestamp.now(),
              };
            }).toList());
  }

  Future<void> addForumComment({required String postId, required String content}) async {
    final userData = await AuthService.getUserRegistrationData();
    final userId = _auth.currentUser?.uid ?? await AuthService.getCurrentUserId() ?? userData['email'] ?? 'user@wsu.ac.za';
    await _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .add({
      'content': content,
      'userId': userId,
      'userName': userData['name'] ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureSampleData() async {
    try {
      final itemsSnapshot = await _firestore.collection('items').limit(1).get();
      if (itemsSnapshot.docs.isEmpty) {
        await _firestore.collection('items').add({
          'title': 'Lost iPhone 13',
          'description': 'Blue iPhone 13 Pro lost near library',
          'location': 'Main Library',
          'dateTime': Timestamp.now(),
          'isLost': true,
          'contactInfo': 'student1@wsu.ac.za',
          'category': 'ItemCategory.electronics',
          'userId': 'student1@wsu.ac.za',
          'userName': 'John Doe',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      final forumSnapshot = await _firestore.collection('forum_posts').limit(1).get();
      if (forumSnapshot.docs.isEmpty) {
        await _firestore.collection('forum_posts').add({
          'title': 'Welcome to WSU Lost & Found',
          'content': 'This is the official lost and found forum for WSU students',
          'category': 'General',
          'userId': 'admin@wsu.ac.za',
          'userName': 'WSU Admin',
          'createdAt': FieldValue.serverTimestamp(),
          'likes': 0,
        });
      }
    } catch (e) {
      Logger.error('Error creating sample data: $e');
    }
  }
  
  // One-time migration: backfill UID into legacy documents that only have emails
  Future<void> migrateLegacyData() async {
    try {
      // Migrate items: set userId to UID if currently an email
      final itemsSnap = await _firestore.collection('items').get();
      for (final doc in itemsSnap.docs) {
        final data = doc.data();
        final userId = data['userId'];
        final userEmail = data['userEmail'] ?? data['contactInfo'];
        if (userId is String && userId.contains('@')) {
          final uid = await resolveUidByEmail(userId) ?? (userEmail is String ? await resolveUidByEmail(userEmail) : null);
          if (uid != null) {
            await doc.reference.update({'userId': uid, if (userEmail != null) 'userEmail': userEmail});
          }
        } else if (userId == null && userEmail is String) {
          final uid = await resolveUidByEmail(userEmail);
          if (uid != null) {
            await doc.reference.update({'userId': uid, 'userEmail': userEmail});
          }
        }
      }

      // Migrate forum posts: set userId to UID if currently an email
      final forumSnap = await _firestore.collection('forum_posts').get();
      for (final doc in forumSnap.docs) {
        final data = doc.data();
        final userId = data['userId'];
        final userEmail = data['userEmail'] ?? data['userId'];
        if (userId is String && userId.contains('@')) {
          final uid = await resolveUidByEmail(userId) ?? (userEmail is String ? await resolveUidByEmail(userEmail) : null);
          if (uid != null) {
            await doc.reference.update({'userId': uid, if (userEmail != null) 'userEmail': userEmail});
          }
        }
      }

      // Migrate messages: ensure senderId/receiverId are UIDs and participants include UIDs
      final messagesSnap = await _firestore.collection('messages').get();
      for (final doc in messagesSnap.docs) {
        final data = doc.data();
        String senderId = (data['senderId'] ?? '') as String;
        String receiverId = (data['receiverId'] ?? '') as String;
        final senderEmail = data['senderEmail'] ?? (senderId.contains('@') ? senderId : null);
        final receiverEmail = data['receiverEmail'] ?? (receiverId.contains('@') ? receiverId : null);
        if (senderId.contains('@')) {
          final uid = await resolveUidByEmail(senderId) ?? (senderEmail is String ? await resolveUidByEmail(senderEmail) : null);
          if (uid != null) senderId = uid;
        }
        if (receiverId.contains('@')) {
          final uid = await resolveUidByEmail(receiverId) ?? (receiverEmail is String ? await resolveUidByEmail(receiverEmail) : null);
          if (uid != null) receiverId = uid;
        }
        final participants = <String>{};
        for (final p in (data['participants'] ?? []) as List<dynamic>) {
          participants.add(p.toString());
        }
        participants.add(senderId);
        if (senderEmail is String) participants.add(senderEmail);
        participants.add(receiverId);
        if (receiverEmail is String) participants.add(receiverEmail);
        await doc.reference.update({
          'senderId': senderId,
          'receiverId': receiverId,
          'participants': participants.toList(),
          if (senderEmail is String) 'senderEmail': senderEmail,
          if (receiverEmail is String) 'receiverEmail': receiverEmail,
        });
      }
      Logger.success('Migration completed successfully');
    } catch (e) {
      Logger.error('Migration error: $e');
    }
  }
}
