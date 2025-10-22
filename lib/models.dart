import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfile {
  String uid;
  String name;
  String studentNumber;
  String email;
  String gender;
  String phone;
  bool isAdmin;
  Uint8List? profileImageBytes;

  UserProfile({
    required this.uid,
    required this.name,
    required this.studentNumber,
    required this.email,
    required this.gender,
    this.phone = '',
    this.isAdmin = false,
    this.profileImageBytes,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'studentNumber': studentNumber,
    'email': email,
    'gender': gender,
    'phone': phone,
    'isAdmin': isAdmin,
    'profileImageBase64': profileImageBytes != null ? base64Encode(profileImageBytes!) : null,
  };

  static UserProfile fromJson(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    studentNumber: map['studentNumber'] ?? '',
    email: map['email'] ?? '',
    gender: map['gender'] ?? 'Other',
    phone: map['phone'] ?? '',
    isAdmin: map['isAdmin'] ?? false,
    profileImageBytes: map['profileImageBase64'] != null ? base64Decode(map['profileImageBase64']) : null,
  );
}

class Report {
  String reportId;
  String uid; // Reporter's user ID
  String itemName;
  String type; // 'Lost' or 'Found'
  String status; // 'Lost', 'Found', 'Resolved', 'Returned'
  String description;
  String location;
  DateTime date;
  String category;
  Uint8List? imageBytes;
  DateTime timestamp;
  String? resolvedBy; // UID of user who resolved/claimed the item
  DateTime? resolvedAt; // When the item was resolved
  String? resolutionNotes; // Additional notes about resolution

  Report({
    required this.reportId,
    required this.uid,
    required this.itemName,
    required this.type,
    required this.status,
    required this.description,
    required this.location,
    required this.date,
    required this.category,
    this.imageBytes,
    required this.timestamp,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
  });

  Map<String, dynamic> toJson() => {
    'reportId': reportId,
    'uid': uid,
    'itemName': itemName,
    'type': type,
    'status': status,
    'description': description,
    'location': location,
    'date': date.toIso8601String(),
    'category': category,
    'imageBase64': imageBytes != null ? base64Encode(imageBytes!) : null,
    'timestamp': timestamp.toIso8601String(),
    'resolvedBy': resolvedBy,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'resolutionNotes': resolutionNotes,
  };

  static Report fromJson(Map<String, dynamic> map) => Report(
    reportId: map['reportId'] ?? '',
    uid: map['uid'] ?? '',
    itemName: map['itemName'] ?? '',
    type: map['type'] ?? 'Lost',
    status: map['status'] ?? 'Pending',
    description: map['description'] ?? '',
    location: map['location'] ?? '',
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    category: map['category'] ?? 'General',
    imageBytes: map['imageBase64'] != null ? base64Decode(map['imageBase64']) : null,
    timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    resolvedBy: map['resolvedBy'],
    resolvedAt: map['resolvedAt'] != null ? DateTime.tryParse(map['resolvedAt']) : null,
    resolutionNotes: map['resolutionNotes'],
  );
}

// Demo reports removed - now using Firebase Firestore for real-time data

// Message and Conversation classes for chat functionality
class Message {
  final String id;
  final String fromUid;
  final String toUid;
  final String content;
  final DateTime timestamp;
  final String type;
  String status; // 'sending', 'delivered', 'read' - mutable for status updates
  final String? imageUrl;
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final String? mimeType;
  final String? audioUrl;
  final String? callKind; // 'video' or 'voice'
  final int? callDurationSeconds;

  String get text => content;

  Message({
    required this.id,
    required this.fromUid,
    required this.toUid,
    String? text,
    DateTime? timestamp,
    this.type = 'text',
    this.status = 'delivered', // Default to delivered instead of sending
    this.imageUrl,
    this.attachmentBytes,
    this.attachmentName,
    this.mimeType,
    this.audioUrl,
    this.callKind,
    this.callDurationSeconds,
  })  : content = text ?? '',
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'fromUid': fromUid,
    'toUid': toUid,
    'participants': [fromUid, toUid], // For efficient querying
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'status': status,
    'imageUrl': imageUrl,
    'attachmentBytes': attachmentBytes != null ? base64Encode(attachmentBytes!) : null,
    'attachmentName': attachmentName,
    'mimeType': mimeType,
    'audioUrl': audioUrl,
    'callKind': callKind,
    'callDurationSeconds': callDurationSeconds,
  };

  static Message fromJson(Map<String, dynamic> map) => Message(
    id: map['id'] ?? '',
    fromUid: map['fromUid'] ?? '',
    toUid: map['toUid'] ?? '',
    text: (map['content'] ?? map['text']) ?? '',
    timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    type: (map['type'] ?? 'text'),
    status: map['status'] ?? 'delivered', // Default to delivered for existing messages
    imageUrl: map['imageUrl'],
    attachmentBytes: map['attachmentBytes'] != null ? base64Decode(map['attachmentBytes']) : null,
    attachmentName: map['attachmentName'],
    mimeType: map['mimeType'],
    audioUrl: map['audioUrl'],
    callKind: map['callKind'],
    callDurationSeconds: map['callDurationSeconds'],
  );
}

enum MessageType { text, image, audio, call }

class Conversation {
  final String id;
  final List<String> participants;
  final List<Message> messages;
  DateTime lastActivity;

  Conversation({
    required this.id,
    required this.participants,
    required this.messages,
    required this.lastActivity,
  });

  String get userA => participants.isNotEmpty ? participants[0] : '';
  String get userB => participants.length > 1 ? participants[1] : '';

  Map<String, dynamic> toJson() => {
    'id': id,
    'participants': participants,
    'messages': messages.map((m) => m.toJson()).toList(),
    'lastActivity': lastActivity.toIso8601String(),
  };

  static Conversation fromJson(Map<String, dynamic> map) => Conversation(
    id: map['id'] ?? '',
    participants: List<String>.from(map['participants'] ?? []),
    messages: (map['messages'] as List?)?.map((m) => Message.fromJson(m)).toList() ?? [],
    lastActivity: DateTime.tryParse(map['lastActivity'] ?? '') ?? DateTime.now(),
  );
}

// Mock conversation data
final List<Conversation> demoConversations = [];

// Helper function to ensure a conversation exists between two users
Conversation ensureConversation(String uid1, String uid2) {
  // Check if conversation already exists
  final existingConv = demoConversations.where((c) =>
    c.participants.contains(uid1) && c.participants.contains(uid2)
  ).firstOrNull;
  
  if (existingConv != null) return existingConv;
  
  // Create consistent conversation ID that matches chat ID format
  final sortedUids = [uid1, uid2]..sort();
  final conversationId = '${sortedUids[0]}_${sortedUids[1]}';
  
  // Create new conversation
  final newConv = Conversation(
    id: conversationId,
    participants: [uid1, uid2],
    messages: [],
    lastActivity: DateTime.now(),
  );
  
  demoConversations.add(newConv);
  return newConv;
}

// Persistence functions for user profiles and reports
Future<void> saveUserProfile(UserProfile profile) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Fallback to SharedPreferences if not authenticated
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', jsonEncode(profile.toJson()));
      return;
    }

    final db = FirebaseFirestore.instance;
    String? profileImageUrl;

    // Upload profile image to Firebase Storage if present
    if (profile.profileImageBytes != null) {
      try {
        final storage = FirebaseStorage.instance;
        final ref = storage.ref('profile_images/$uid.jpg');
        await ref.putData(profile.profileImageBytes!);
        profileImageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Failed to upload profile image: $e');
        // Continue without image if upload fails
      }
    }

    // Save profile to Firestore
    final profileData = {
      'uid': profile.uid,
      'name': profile.name,
      'studentNumber': profile.studentNumber,
      'email': profile.email,
      'gender': profile.gender,
      'profileImageUrl': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await db.collection('users').doc(uid).set(profileData, SetOptions(merge: true));
    
    // Also save to SharedPreferences as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  } catch (e) {
    debugPrint('Failed to save user profile: $e');
    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }
}

Future<UserProfile?> loadUserProfile() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Fallback to SharedPreferences if not authenticated
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString('user_profile');
      if (profileString != null) {
        return UserProfile.fromJson(jsonDecode(profileString));
      }
      return null;
    }

    final db = FirebaseFirestore.instance;
    final doc = await db.collection('users').doc(uid).get();
    
    if (doc.exists) {
      final data = doc.data()!;
      Uint8List? imageBytes;
      
      // Download profile image if URL exists
      if (data['profileImageUrl'] != null) {
        try {
          final storage = FirebaseStorage.instance;
          final ref = storage.refFromURL(data['profileImageUrl']);
          imageBytes = await ref.getData();
        } catch (e) {
          debugPrint('Failed to download profile image: $e');
          // Continue without image if download fails
        }
      }
      
      return UserProfile(
        uid: data['uid'] ?? uid,
        name: data['name'] ?? '',
        studentNumber: data['studentNumber'] ?? '',
        email: data['email'] ?? '',
        gender: data['gender'] ?? 'Other',
        profileImageBytes: imageBytes,
      );
    } else {
      // No Firestore document, try SharedPreferences fallback
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString('user_profile');
      if (profileString != null) {
        return UserProfile.fromJson(jsonDecode(profileString));
      }
      
      // Create default profile from Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return UserProfile(
          uid: user.uid,
          name: user.displayName ?? user.email?.split('@').first ?? 'User',
          studentNumber: '',
          email: user.email ?? '',
          gender: 'Other',
        );
      }
    }
  } catch (e) {
    debugPrint('Failed to load user profile from Firestore: $e');
    // Fallback to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('user_profile');
    if (profileString != null) {
      return UserProfile.fromJson(jsonDecode(profileString));
    }
  }
  
  return null;
}

// Data persistence now handled by Firebase Firestore
Future<void> initializeData() async {
  // Firebase initialization is handled in main.dart
  // No local data loading needed - using real-time Firestore streams
}

// Helper function to get email for a user ID
String getEmailForUid(String uid) {
  // For authenticated users, return current user email or fallback
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && currentUser.uid == uid) {
    return currentUser.email ?? 'user@campus.edu';
  }
  
  // Fallback for demo/unknown users
  return 'user@campus.edu';
}