# 📡 API Documentation

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Data Models](#data-models)
- [Firestore API](#firestore-api)
- [Storage API](#storage-api)
- [Realtime Database API](#realtime-database-api)
- [Cloud Functions](#cloud-functions)
- [WebRTC Signaling](#webrtc-signaling)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [SDK Usage Examples](#sdk-usage-examples)

## Overview

Campus Lost & Found uses Firebase as its primary backend service, providing a comprehensive set of APIs for authentication, data storage, real-time communication, and file management. This document outlines all available APIs and their usage patterns.

### Base Configuration

```dart
// Firebase initialization
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Service instances
final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;
final storage = FirebaseStorage.instance;
final database = FirebaseDatabase.instance;
```

## Authentication

### Firebase Authentication API

#### **Sign Up**
```dart
Future<UserCredential> signUp({
  required String email,
  required String password,
  required String name,
  required String studentNumber,
}) async {
  try {
    UserCredential result = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user profile
    await createUserProfile(result.user!.uid, {
      'name': name,
      'email': email,
      'studentNumber': studentNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return result;
  } catch (e) {
    throw AuthException(e.toString());
  }
}
```

#### **Sign In**
```dart
Future<UserCredential> signIn({
  required String email,
  required String password,
}) async {
  try {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    throw AuthException(e.toString());
  }
}
```

#### **Sign Out**
```dart
Future<void> signOut() async {
  await auth.signOut();
}
```

#### **Password Reset**
```dart
Future<void> resetPassword(String email) async {
  await auth.sendPasswordResetEmail(email: email);
}
```

## Data Models

### User Model
```dart
class UserProfile {
  final String uid;
  final String name;
  final String studentNumber;
  final String email;
  final String? gender;
  final String? profileImage;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.studentNumber,
    required this.email,
    this.gender,
    this.profileImage,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      studentNumber: data['studentNumber'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'],
      profileImage: data['profileImage'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen']?.toDate(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'studentNumber': studentNumber,
      'email': email,
      'gender': gender,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
```

### Report Model
```dart
class Report {
  final String? id;
  final String uid;
  final String itemName;
  final String status; // 'Lost' or 'Found'
  final String description;
  final String location;
  final String category;
  final DateTime date;
  final String? imageUrl;
  final bool isActive;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    this.id,
    required this.uid,
    required this.itemName,
    required this.status,
    required this.description,
    required this.location,
    required this.category,
    required this.date,
    this.imageUrl,
    this.isActive = true,
    this.views = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      uid: data['uid'] ?? '',
      itemName: data['itemName'] ?? '',
      status: data['status'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      category: data['category'] ?? '',
      date: data['date']?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      views: data['views'] ?? 0,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'itemName': itemName,
      'status': status,
      'description': description,
      'location': location,
      'category': category,
      'date': Timestamp.fromDate(date),
      'imageUrl': imageUrl,
      'isActive': isActive,
      'views': views,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
```

### Message Model
```dart
class Message {
  final String? id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final String type; // 'text', 'image', 'file'
  final String? mediaUrl;
  final String deliveryStatus; // 'sent', 'delivered', 'read'
  final DateTime timestamp;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = 'text',
    this.mediaUrl,
    this.deliveryStatus = 'sent',
    required this.timestamp,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      mediaUrl: data['mediaUrl'],
      deliveryStatus: data['deliveryStatus'] ?? 'sent',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'mediaUrl': mediaUrl,
      'deliveryStatus': deliveryStatus,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
```

## Firestore API

### Users Collection

#### **Create User Profile**
```dart
Future<void> createUserProfile(String uid, Map<String, dynamic> userData) async {
  await firestore.collection('users').doc(uid).set({
    ...userData,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### **Get User Profile**
```dart
Future<UserProfile?> getUserProfile(String uid) async {
  DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
  if (doc.exists) {
    return UserProfile.fromFirestore(doc);
  }
  return null;
}
```

#### **Update User Profile**
```dart
Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
  await firestore.collection('users').doc(uid).update({
    ...updates,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### **Update Online Status**
```dart
Future<void> updateOnlineStatus(String uid, bool isOnline) async {
  await firestore.collection('users').doc(uid).update({
    'isOnline': isOnline,
    'lastSeen': FieldValue.serverTimestamp(),
  });
}
```

### Reports Collection

#### **Create Report**
```dart
Future<String> createReport(Report report) async {
  DocumentReference docRef = await firestore.collection('reports').add({
    ...report.toFirestore(),
    'createdAt': FieldValue.serverTimestamp(),
  });
  return docRef.id;
}
```

#### **Get Reports**
```dart
Future<List<Report>> getReports({
  String? status,
  String? location,
  String? category,
  int limit = 20,
  DocumentSnapshot? lastDocument,
}) async {
  Query query = firestore.collection('reports')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true);

  if (status != null) {
    query = query.where('status', isEqualTo: status);
  }
  if (location != null) {
    query = query.where('location', isEqualTo: location);
  }
  if (category != null) {
    query = query.where('category', isEqualTo: category);
  }

  query = query.limit(limit);

  if (lastDocument != null) {
    query = query.startAfterDocument(lastDocument);
  }

  QuerySnapshot snapshot = await query.get();
  return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
}
```

#### **Search Reports**
```dart
Future<List<Report>> searchReports(String searchTerm) async {
  // Note: Firestore doesn't support full-text search natively
  // This is a simplified implementation
  QuerySnapshot snapshot = await firestore.collection('reports')
      .where('isActive', isEqualTo: true)
      .orderBy('itemName')
      .startAt([searchTerm])
      .endAt([searchTerm + '\uf8ff'])
      .get();

  return snapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();
}
```

#### **Update Report**
```dart
Future<void> updateReport(String reportId, Map<String, dynamic> updates) async {
  await firestore.collection('reports').doc(reportId).update({
    ...updates,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### **Delete Report**
```dart
Future<void> deleteReport(String reportId) async {
  await firestore.collection('reports').doc(reportId).update({
    'isActive': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
```

#### **Increment Report Views**
```dart
Future<void> incrementReportViews(String reportId) async {
  await firestore.collection('reports').doc(reportId).update({
    'views': FieldValue.increment(1),
  });
}
```

### Conversations Collection

#### **Create or Get Conversation**
```dart
Future<String> createOrGetConversation(String userA, String userB) async {
  // Check if conversation already exists
  QuerySnapshot existing = await firestore.collection('conversations')
      .where('userA', isEqualTo: userA)
      .where('userB', isEqualTo: userB)
      .get();

  if (existing.docs.isEmpty) {
    existing = await firestore.collection('conversations')
        .where('userA', isEqualTo: userB)
        .where('userB', isEqualTo: userA)
        .get();
  }

  if (existing.docs.isNotEmpty) {
    return existing.docs.first.id;
  }

  // Create new conversation
  DocumentReference docRef = await firestore.collection('conversations').add({
    'userA': userA,
    'userB': userB,
    'lastMessage': '',
    'lastMessageTime': FieldValue.serverTimestamp(),
    'unreadCountA': 0,
    'unreadCountB': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  return docRef.id;
}
```

#### **Get User Conversations**
```dart
Stream<List<Conversation>> getUserConversations(String userId) {
  return firestore.collection('conversations')
      .where('userA', isEqualTo: userId)
      .orderBy('lastMessageTime', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    List<Conversation> conversations = [];
    
    for (DocumentSnapshot doc in snapshot.docs) {
      conversations.add(Conversation.fromFirestore(doc));
    }

    // Also get conversations where user is userB
    QuerySnapshot userBConversations = await firestore.collection('conversations')
        .where('userB', isEqualTo: userId)
        .orderBy('lastMessageTime', descending: true)
        .get();

    for (DocumentSnapshot doc in userBConversations.docs) {
      conversations.add(Conversation.fromFirestore(doc));
    }

    // Sort by last message time
    conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    
    return conversations;
  });
}
```

### Messages Collection

#### **Send Message**
```dart
Future<String> sendMessage(Message message) async {
  // Add message to messages collection
  DocumentReference messageRef = await firestore.collection('messages').add(
    message.toFirestore()
  );

  // Update conversation with last message
  await firestore.collection('conversations').doc(message.conversationId).update({
    'lastMessage': message.content,
    'lastMessageTime': FieldValue.serverTimestamp(),
    'unreadCountA': FieldValue.increment(message.senderId == message.receiverId ? 0 : 1),
    'unreadCountB': FieldValue.increment(message.senderId == message.receiverId ? 1 : 0),
  });

  return messageRef.id;
}
```

#### **Get Messages**
```dart
Stream<List<Message>> getMessages(String conversationId) {
  return firestore.collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => 
          snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
}
```

#### **Mark Messages as Read**
```dart
Future<void> markMessagesAsRead(String conversationId, String userId) async {
  // Update message delivery status
  WriteBatch batch = firestore.batch();
  
  QuerySnapshot unreadMessages = await firestore.collection('messages')
      .where('conversationId', isEqualTo: conversationId)
      .where('receiverId', isEqualTo: userId)
      .where('deliveryStatus', isNotEqualTo: 'read')
      .get();

  for (DocumentSnapshot doc in unreadMessages.docs) {
    batch.update(doc.reference, {'deliveryStatus': 'read'});
  }

  await batch.commit();

  // Reset unread count in conversation
  await firestore.collection('conversations').doc(conversationId).update({
    'unreadCountA': 0, // Adjust based on which user is reading
    'unreadCountB': 0,
  });
}
```

## Storage API

### File Upload

#### **Upload Profile Image**
```dart
Future<String> uploadProfileImage(String userId, File imageFile) async {
  try {
    String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = storage.ref().child('users/$userId/$fileName');
    
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    throw StorageException(e.toString());
  }
}
```

#### **Upload Report Image**
```dart
Future<String> uploadReportImage(String reportId, File imageFile) async {
  try {
    String fileName = 'report_${reportId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = storage.ref().child('reports/$fileName');
    
    // Compress image before upload
    File compressedImage = await compressImage(imageFile);
    
    UploadTask uploadTask = ref.putFile(compressedImage);
    TaskSnapshot snapshot = await uploadTask;
    
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    throw StorageException(e.toString());
  }
}
```

#### **Upload Chat Media**
```dart
Future<String> uploadChatMedia(String conversationId, File mediaFile, String type) async {
  try {
    String extension = type == 'image' ? 'jpg' : 'mp4';
    String fileName = 'chat_${conversationId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    Reference ref = storage.ref().child('chat_media/$fileName');
    
    UploadTask uploadTask = ref.putFile(mediaFile);
    TaskSnapshot snapshot = await uploadTask;
    
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  } catch (e) {
    throw StorageException(e.toString());
  }
}
```

#### **Delete File**
```dart
Future<void> deleteFile(String fileUrl) async {
  try {
    Reference ref = storage.refFromURL(fileUrl);
    await ref.delete();
  } catch (e) {
    print('Error deleting file: $e');
  }
}
```

## Realtime Database API

### Typing Indicators

#### **Set Typing Status**
```dart
Future<void> setTypingStatus(String conversationId, String userId, bool isTyping) async {
  await database.ref('typing/$conversationId/$userId').set(isTyping);
}
```

#### **Listen to Typing Status**
```dart
Stream<bool> getTypingStatus(String conversationId, String otherUserId) {
  return database.ref('typing/$conversationId/$otherUserId')
      .onValue
      .map((event) => event.snapshot.value as bool? ?? false);
}
```

### Presence System

#### **Set User Presence**
```dart
Future<void> setUserPresence(String userId, bool isOnline) async {
  await database.ref('presence/$userId').set({
    'isOnline': isOnline,
    'lastSeen': ServerValue.timestamp,
  });
}
```

#### **Listen to User Presence**
```dart
Stream<Map<String, dynamic>> getUserPresence(String userId) {
  return database.ref('presence/$userId')
      .onValue
      .map((event) => Map<String, dynamic>.from(event.snapshot.value as Map? ?? {}));
}
```

### WebRTC Signaling

#### **Create Call**
```dart
Future<String> createCall({
  required String callerId,
  required String receiverId,
  required String type, // 'video' or 'voice'
  required Map<String, dynamic> offer,
}) async {
  DatabaseReference callRef = database.ref('calls').push();
  
  await callRef.set({
    'callerId': callerId,
    'receiverId': receiverId,
    'type': type,
    'status': 'ringing',
    'offer': offer,
    'createdAt': ServerValue.timestamp,
  });

  return callRef.key!;
}
```

#### **Answer Call**
```dart
Future<void> answerCall(String callId, Map<String, dynamic> answer) async {
  await database.ref('calls/$callId').update({
    'answer': answer,
    'status': 'active',
  });
}
```

#### **End Call**
```dart
Future<void> endCall(String callId) async {
  await database.ref('calls/$callId').update({
    'status': 'ended',
    'endedAt': ServerValue.timestamp,
  });
}
```

#### **Add ICE Candidate**
```dart
Future<void> addIceCandidate(String callId, Map<String, dynamic> candidate) async {
  await database.ref('calls/$callId/candidates').push().set(candidate);
}
```

## Cloud Functions

### Notification Functions

#### **Send Push Notification**
```javascript
// Cloud Function example
exports.sendNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const receiverId = message.receiverId;
    
    // Get receiver's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(receiverId)
      .get();
    
    const fcmToken = userDoc.data().fcmToken;
    
    if (fcmToken) {
      const payload = {
        notification: {
          title: 'New Message',
          body: message.content,
          icon: '/icon-192x192.png',
        },
        data: {
          conversationId: message.conversationId,
          senderId: message.senderId,
        },
      };
      
      await admin.messaging().sendToDevice(fcmToken, payload);
    }
  });
```

## Error Handling

### Custom Exception Classes

```dart
class ApiException implements Exception {
  final String message;
  final String? code;
  
  ApiException(this.message, [this.code]);
  
  @override
  String toString() => 'ApiException: $message';
}

class AuthException extends ApiException {
  AuthException(String message) : super(message, 'auth_error');
}

class StorageException extends ApiException {
  StorageException(String message) : super(message, 'storage_error');
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message, 'network_error');
}
```

### Error Handling Wrapper

```dart
Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on FirebaseAuthException catch (e) {
    throw AuthException(e.message ?? 'Authentication failed');
  } on FirebaseException catch (e) {
    throw ApiException(e.message ?? 'Firebase operation failed', e.code);
  } catch (e) {
    throw ApiException('Unexpected error occurred: $e');
  }
}
```

## Rate Limiting

### Firestore Rate Limits
- **Writes**: 1 write per second per document
- **Reads**: No limit on reads
- **Queries**: 1 query per second per collection

### Storage Rate Limits
- **Uploads**: 1000 operations per second
- **Downloads**: No limit
- **Bandwidth**: 5 GB per day (free tier)

### Best Practices
- Implement client-side caching
- Use batch operations for multiple writes
- Implement exponential backoff for retries
- Monitor usage with Firebase Analytics

## SDK Usage Examples

### Complete Example: Creating a Report

```dart
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> createReport({
    required String itemName,
    required String status,
    required String description,
    required String location,
    required String category,
    required DateTime date,
    File? imageFile,
  }) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadReportImage(imageFile);
      }
      
      // Create report object
      Report report = Report(
        uid: FirebaseAuth.instance.currentUser!.uid,
        itemName: itemName,
        status: status,
        description: description,
        location: location,
        category: category,
        date: date,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('reports')
          .add(report.toFirestore());
      
      return docRef.id;
    } catch (e) {
      throw ApiException('Failed to create report: $e');
    }
  }

  Future<String> _uploadReportImage(File imageFile) async {
    String fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child('reports/$fileName');
    
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    
    return await snapshot.ref.getDownloadURL();
  }
}
```

This API documentation provides comprehensive coverage of all Firebase services used in the Campus Lost & Found application, including practical examples and best practices for implementation.