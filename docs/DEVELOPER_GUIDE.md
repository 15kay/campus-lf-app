# Campus Lost & Found - Developer Guide

## 📋 Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Project Architecture](#project-architecture)
3. [Code Structure](#code-structure)
4. [Data Models](#data-models)
5. [Firebase Integration](#firebase-integration)
6. [State Management](#state-management)
7. [UI Components](#ui-components)
8. [API Documentation](#api-documentation)
9. [Development Workflows](#development-workflows)
10. [Testing Guidelines](#testing-guidelines)
11. [Performance Optimization](#performance-optimization)
12. [Debugging and Troubleshooting](#debugging-and-troubleshooting)
13. [Contributing Guidelines](#contributing-guidelines)

---

## 🛠️ Development Environment Setup

### Prerequisites

```yaml
Required Software:
  - Flutter SDK: 3.24.0 or higher
  - Dart SDK: 3.5.0 or higher
  - Android Studio: Latest stable version
  - Xcode: 15.0+ (for iOS development)
  - VS Code: Latest version (recommended)
  - Git: Latest version
  - Node.js: 18.0+ (for Firebase CLI)

Development Tools:
  - Firebase CLI: Latest version
  - Chrome: Latest version (for web debugging)
  - Android Emulator or Physical Device
  - iOS Simulator or Physical Device
```

### IDE Configuration

#### VS Code Extensions
```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "ms-vscode.vscode-json",
    "bradlc.vscode-tailwindcss",
    "formulahendry.auto-rename-tag",
    "christian-kohler.path-intellisense",
    "ms-vscode.vscode-typescript-next"
  ]
}
```

#### VS Code Settings
```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.lineLength": 120
}
```

### Project Setup

#### 1. Clone Repository
```bash
git clone https://github.com/your-org/campus_lf_app.git
cd campus_lf_app
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init

# Generate Firebase configuration
flutterfire configure
```

#### 4. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
# Add your Firebase configuration
# Add API keys and secrets
```

---

## 🏗️ Project Architecture

### Architectural Pattern

The Campus Lost & Found app follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (UI Components, Pages, Widgets)    │
├─────────────────────────────────────┤
│           Business Logic Layer      │
│     (State Management, Services)    │
├─────────────────────────────────────┤
│             Data Layer              │
│   (Models, Repositories, APIs)      │
├─────────────────────────────────────┤
│          Infrastructure Layer       │
│    (Firebase, Storage, Network)     │
└─────────────────────────────────────┘
```

### Design Patterns Used

#### 1. Model-View-Controller (MVC)
```dart
// Model
class Report {
  final String reportId;
  final String itemName;
  // ... other properties
}

// View
class ReportPage extends StatefulWidget {
  // UI implementation
}

// Controller
class ReportController {
  Future<void> submitReport(Report report) async {
    // Business logic
  }
}
```

#### 2. Repository Pattern
```dart
abstract class ReportRepository {
  Future<List<Report>> getAllReports();
  Future<Report?> getReportById(String id);
  Future<void> createReport(Report report);
  Future<void> updateReport(Report report);
  Future<void> deleteReport(String id);
}

class FirebaseReportRepository implements ReportRepository {
  final FirebaseFirestore _firestore;
  
  @override
  Future<List<Report>> getAllReports() async {
    // Firebase implementation
  }
}
```

#### 3. Observer Pattern
```dart
// Using StreamBuilder for real-time updates
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
    .collection('reports')
    .snapshots(),
  builder: (context, snapshot) {
    // UI updates automatically when data changes
  },
)
```

#### 4. Singleton Pattern
```dart
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();
  
  // Configuration properties
}
```

### State Management Strategy

#### Local State Management
- **StatefulWidget**: For simple, component-level state
- **ValueNotifier**: For reactive programming patterns
- **StreamController**: For event-driven state changes

#### Global State Management
- **Provider**: For dependency injection and state sharing
- **Riverpod**: For advanced state management (future enhancement)
- **Bloc**: For complex business logic (future enhancement)

---

## 📁 Code Structure

### Directory Organization

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Main app configuration
├── firebase_options.dart     # Firebase configuration
├── models.dart              # Data models and demo data
├── pages/                   # UI pages and screens
│   ├── home_page.dart       # Landing page
│   ├── report_page.dart     # Item reporting
│   ├── search_page.dart     # Search functionality
│   ├── chat_page.dart       # Messaging interface
│   ├── video_call_page.dart # Video calling
│   ├── profile_page.dart    # User profile
│   ├── settings_page.dart   # App settings
│   ├── my_reports_page.dart # User's reports
│   ├── about_page.dart      # About information
│   ├── manual_page.dart     # User manual
│   └── chatbot_page.dart    # AI chatbot
├── services/                # Business logic services
│   ├── auth_service.dart    # Authentication
│   ├── firestore_service.dart # Database operations
│   ├── storage_service.dart # File storage
│   ├── notification_service.dart # Push notifications
│   └── webrtc_service.dart  # Video calling
├── widgets/                 # Reusable UI components
│   ├── common/              # Common widgets
│   ├── forms/               # Form components
│   └── cards/               # Card components
├── utils/                   # Utility functions
│   ├── constants.dart       # App constants
│   ├── helpers.dart         # Helper functions
│   └── validators.dart      # Input validation
└── themes/                  # UI themes and styling
    ├── app_theme.dart       # Main theme
    └── colors.dart          # Color definitions
```

### File Naming Conventions

```yaml
Files:
  - snake_case for all file names
  - Descriptive names indicating purpose
  - Suffix with file type (_page, _service, _widget)

Classes:
  - PascalCase for class names
  - Descriptive and specific names
  - Suffix with type (Page, Service, Widget)

Variables:
  - camelCase for variables and functions
  - Descriptive names
  - Boolean variables start with 'is', 'has', 'can'

Constants:
  - UPPER_SNAKE_CASE for constants
  - Group related constants in classes
```

### Import Organization

```dart
// 1. Dart core libraries
import 'dart:async';
import 'dart:convert';

// 2. Flutter framework
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 4. Local imports
import '../models.dart';
import '../services/auth_service.dart';
import '../widgets/common/loading_widget.dart';
```

---

## 📊 Data Models

### Core Models

#### User Profile Model
```dart
class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String? phoneNumber;
  final String department;
  final String role; // 'student', 'faculty', 'staff'
  final bool isVerified;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic> preferences;
  final int reputationScore;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.phoneNumber,
    required this.department,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    required this.lastActive,
    this.preferences = const {},
    this.reputationScore = 0,
  });

  // JSON serialization
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      photoURL: json['photoURL'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      department: json['department'] as String,
      role: json['role'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      reputationScore: json['reputationScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'department': department,
      'role': role,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'preferences': preferences,
      'reputationScore': reputationScore,
    };
  }

  // Copy with method for immutable updates
  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? department,
    String? role,
    bool? isVerified,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
    int? reputationScore,
  }) {
    return UserProfile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
      reputationScore: reputationScore ?? this.reputationScore,
    );
  }
}
```

#### Report Model
```dart
class Report {
  final String reportId;
  final String uid;
  final String itemName;
  final String status; // 'Lost' or 'Found'
  final String description;
  final String location;
  final DateTime date;
  final String category;
  final DateTime timestamp;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final List<String> tags;
  final GeoPoint? coordinates;

  const Report({
    required this.reportId,
    required this.uid,
    required this.itemName,
    required this.status,
    required this.description,
    required this.location,
    required this.date,
    required this.category,
    required this.timestamp,
    this.imageUrls = const [],
    this.metadata = const {},
    this.isResolved = false,
    this.resolvedBy,
    this.resolvedAt,
    this.tags = const [],
    this.coordinates,
  });

  // JSON serialization
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportId: json['reportId'] as String,
      uid: json['uid'] as String,
      itemName: json['itemName'] as String,
      status: json['status'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedBy: json['resolvedBy'] as String?,
      resolvedAt: json['resolvedAt'] != null 
        ? DateTime.parse(json['resolvedAt'] as String) 
        : null,
      tags: List<String>.from(json['tags'] ?? []),
      coordinates: json['coordinates'] != null 
        ? GeoPoint(json['coordinates']['latitude'], json['coordinates']['longitude'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'uid': uid,
      'itemName': itemName,
      'status': status,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'imageUrls': imageUrls,
      'metadata': metadata,
      'isResolved': isResolved,
      'resolvedBy': resolvedBy,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'tags': tags,
      'coordinates': coordinates != null 
        ? {'latitude': coordinates!.latitude, 'longitude': coordinates!.longitude}
        : null,
    };
  }
}
```

#### Message Model
```dart
class Message {
  final String id;
  final String fromUid;
  final String toUid;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  final String? attachmentName;
  final String? mimeType;
  final String? audioUrl;
  final String? callKind;
  final int? callDurationSeconds;
  final bool isRead;
  final bool isDelivered;

  const Message({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageUrl,
    this.attachmentName,
    this.mimeType,
    this.audioUrl,
    this.callKind,
    this.callDurationSeconds,
    this.isRead = false,
    this.isDelivered = false,
  });

  // Factory constructors for different message types
  factory Message.text({
    required String id,
    required String fromUid,
    required String toUid,
    required String text,
    DateTime? timestamp,
  }) {
    return Message(
      id: id,
      fromUid: fromUid,
      toUid: toUid,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.text,
    );
  }

  factory Message.image({
    required String id,
    required String fromUid,
    required String toUid,
    required String imageUrl,
    String text = '',
    DateTime? timestamp,
  }) {
    return Message(
      id: id,
      fromUid: fromUid,
      toUid: toUid,
      text: text,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.image,
      imageUrl: imageUrl,
    );
  }

  factory Message.audio({
    required String id,
    required String fromUid,
    required String toUid,
    required String audioUrl,
    DateTime? timestamp,
  }) {
    return Message(
      id: id,
      fromUid: fromUid,
      toUid: toUid,
      text: '',
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.audio,
      audioUrl: audioUrl,
    );
  }
}

enum MessageType {
  text,
  image,
  audio,
  video,
  file,
  location,
  call,
}
```

#### Conversation Model
```dart
class Conversation {
  final String id;
  final String userA;
  final String userB;
  final String? reportId;
  final DateTime lastActivity;
  final Message? lastMessage;
  final Map<String, int> unreadCounts;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const Conversation({
    required this.id,
    required this.userA,
    required this.userB,
    this.reportId,
    required this.lastActivity,
    this.lastMessage,
    this.unreadCounts = const {},
    this.isActive = true,
    this.metadata = const {},
  });

  // Helper methods
  String getOtherUserId(String currentUserId) {
    return currentUserId == userA ? userB : userA;
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  bool hasUnreadMessages(String userId) {
    return getUnreadCount(userId) > 0;
  }
}
```

### Model Validation

```dart
class ModelValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validateItemName(String? itemName) {
    if (itemName == null || itemName.isEmpty) {
      return 'Item name is required';
    }
    if (itemName.length < 2) {
      return 'Item name must be at least 2 characters';
    }
    if (itemName.length > 100) {
      return 'Item name must be less than 100 characters';
    }
    return null;
  }

  static String? validateDescription(String? description) {
    if (description == null || description.isEmpty) {
      return 'Description is required';
    }
    if (description.length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (description.length > 1000) {
      return 'Description must be less than 1000 characters';
    }
    return null;
  }
}
```

---

## 🔥 Firebase Integration

### Firestore Database Structure

```
/users/{userId}
  - uid: string
  - displayName: string
  - email: string
  - photoURL: string?
  - department: string
  - role: string
  - isVerified: boolean
  - createdAt: timestamp
  - lastActive: timestamp
  - preferences: map
  - reputationScore: number

/reports/{reportId}
  - reportId: string
  - uid: string
  - itemName: string
  - status: string ('Lost' | 'Found')
  - description: string
  - location: string
  - date: timestamp
  - category: string
  - timestamp: timestamp
  - imageUrls: array
  - metadata: map
  - isResolved: boolean
  - resolvedBy: string?
  - resolvedAt: timestamp?
  - tags: array
  - coordinates: geopoint?

/conversations/{conversationId}
  - id: string
  - participants: array
  - reportId: string?
  - lastActivity: timestamp
  - metadata: map
  
  /messages/{messageId}
    - id: string
    - fromUid: string
    - toUid: string
    - content: string
    - timestamp: timestamp
    - type: string
    - imageUrl: string?
    - audioUrl: string?
    - isRead: boolean
    - isDelivered: boolean

/notifications/{notificationId}
  - id: string
  - userId: string
  - type: string
  - title: string
  - body: string
  - data: map
  - isRead: boolean
  - createdAt: timestamp
```

### Firestore Service Implementation

```dart
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // User operations
  static Future<void> createUser(UserProfile user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson());
  }
  
  static Future<UserProfile?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromJson(doc.data()!);
    }
    return null;
  }
  
  static Future<void> updateUser(UserProfile user) async {
    await _db.collection('users').doc(user.uid).update(user.toJson());
  }
  
  // Report operations
  static Future<void> createReport(Report report) async {
    await _db.collection('reports').doc(report.reportId).set(report.toJson());
  }
  
  static Future<List<Report>> getReports({
    String? status,
    String? category,
    String? location,
    int limit = 50,
  }) async {
    Query query = _db.collection('reports').orderBy('timestamp', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (location != null) {
      query = query.where('location', isEqualTo: location);
    }
    
    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }
  
  static Stream<List<Report>> getReportsStream({
    String? status,
    String? category,
    String? location,
  }) {
    Query query = _db.collection('reports').orderBy('timestamp', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (location != null) {
      query = query.where('location', isEqualTo: location);
    }
    
    return query.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>)).toList()
    );
  }
  
  // Message operations
  static Future<void> sendMessage(String conversationId, Message message) async {
    final batch = _db.batch();
    
    // Add message
    batch.set(
      _db.collection('conversations').doc(conversationId).collection('messages').doc(message.id),
      message.toJson(),
    );
    
    // Update conversation last activity
    batch.update(
      _db.collection('conversations').doc(conversationId),
      {
        'lastActivity': FieldValue.serverTimestamp(),
        'lastMessage': message.toJson(),
      },
    );
    
    await batch.commit();
  }
  
  static Stream<List<Message>> getMessagesStream(String conversationId) {
    return _db
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList()
      );
  }
  
  // Search operations
  static Future<List<Report>> searchReports(String query) async {
    // Note: Firestore doesn't support full-text search natively
    // This is a simplified implementation
    final snapshot = await _db
      .collection('reports')
      .where('itemName', isGreaterThanOrEqualTo: query)
      .where('itemName', isLessThanOrEqualTo: query + '\uf8ff')
      .get();
    
    return snapshot.docs.map((doc) => Report.fromJson(doc.data())).toList();
  }
}
```

### Firebase Storage Service

```dart
class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  static Future<String> uploadImage(
    Uint8List imageBytes,
    String path,
    String fileName,
  ) async {
    try {
      final ref = _storage.ref().child(path).child(fileName);
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  static Future<String> uploadAudio(
    Uint8List audioBytes,
    String path,
    String fileName,
  ) async {
    try {
      final ref = _storage.ref().child(path).child(fileName);
      final uploadTask = ref.putData(
        audioBytes,
        SettableMetadata(contentType: 'audio/m4a'),
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }
  
  static Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}
```

### Firebase Authentication Service

```dart
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static User? get currentUser => _auth.currentUser;
  
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  static Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for that email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('The account already exists for that email.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
```

---

## 🎛️ State Management

### Local State Management

#### StatefulWidget Pattern
```dart
class ReportPage extends StatefulWidget {
  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Electronics';
  String _selectedLocation = 'Library';
  List<Uint8List> _images = [];
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      // Submit report logic
      final report = Report(
        reportId: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: AuthService.currentUser!.uid,
        itemName: _itemNameController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        location: _selectedLocation,
        status: 'Lost',
        date: DateTime.now(),
        timestamp: DateTime.now(),
      );
      
      await FirestoreService.createReport(report);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
```

#### ValueNotifier Pattern
```dart
class SearchController {
  final ValueNotifier<String> searchQuery = ValueNotifier('');
  final ValueNotifier<List<Report>> searchResults = ValueNotifier([]);
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  
  void updateQuery(String query) {
    searchQuery.value = query;
    _performSearch();
  }
  
  Future<void> _performSearch() async {
    if (searchQuery.value.isEmpty) {
      searchResults.value = [];
      return;
    }
    
    isLoading.value = true;
    try {
      final results = await FirestoreService.searchReports(searchQuery.value);
      searchResults.value = results;
    } catch (e) {
      searchResults.value = [];
    } finally {
      isLoading.value = false;
    }
  }
  
  void dispose() {
    searchQuery.dispose();
    searchResults.dispose();
    isLoading.dispose();
  }
}

// Usage in widget
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchController _controller = SearchController();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: _controller.updateQuery,
          decoration: InputDecoration(
            hintText: 'Search for items...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _controller.isLoading,
            builder: (context, isLoading, child) {
              if (isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              
              return ValueListenableBuilder<List<Report>>(
                valueListenable: _controller.searchResults,
                builder: (context, results, child) {
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return ReportCard(report: results[index]);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Global State Management with Provider

#### App State Provider
```dart
class AppState extends ChangeNotifier {
  UserProfile? _currentUser;
  List<Report> _userReports = [];
  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  UserProfile? get currentUser => _currentUser;
  List<Report> get userReports => _userReports;
  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // User management
  Future<void> loadCurrentUser() async {
    if (AuthService.currentUser == null) return;
    
    _setLoading(true);
    try {
      _currentUser = await FirestoreService.getUser(AuthService.currentUser!.uid);
      await loadUserReports();
      await loadConversations();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> updateUser(UserProfile user) async {
    try {
      await FirestoreService.updateUser(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Report management
  Future<void> loadUserReports() async {
    if (_currentUser == null) return;
    
    try {
      _userReports = await FirestoreService.getUserReports(_currentUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  Future<void> addReport(Report report) async {
    try {
      await FirestoreService.createReport(report);
      _userReports.insert(0, report);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Conversation management
  Future<void> loadConversations() async {
    if (_currentUser == null) return;
    
    try {
      _conversations = await FirestoreService.getUserConversations(_currentUser!.uid);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

#### Provider Setup
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        StreamProvider<User?>(
          create: (_) => AuthService.authStateChanges,
          initialData: null,
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

#### Using Provider in Widgets
```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (appState.error != null) {
          return ErrorWidget(
            error: appState.error!,
            onRetry: () => appState.loadCurrentUser(),
          );
        }
        
        return Column(
          children: [
            if (appState.currentUser != null)
              WelcomeCard(user: appState.currentUser!),
            Expanded(
              child: ReportsList(reports: appState.userReports),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 🎨 UI Components

### Design System

#### Color Palette
```dart
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFFBBDEFB);
  
  // Secondary colors
  static const Color secondary = Color(0xFF4CAF50);
  static const Color secondaryDark = Color(0xFF388E3C);
  static const Color secondaryLight = Color(0xFFC8E6C9);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Neutral colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF212121);
  static const Color onBackground = Color(0xFF212121);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  
  // WhatsApp-style colors for chat
  static const Color chatGreen = Color(0xFF25D366);
  static const Color chatDarkGreen = Color(0xFF128C7E);
  static const Color chatLightGreen = Color(0xFFDCF8C6);
  static const Color chatGray = Color(0xFFF0F0F0);
}
```

#### Typography
```dart
class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.surface,
  );
}
```

### Reusable Components

#### Custom Button Component
```dart
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final IconData? icon;
  
  const AppButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          elevation: _getElevation(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_getForegroundColor()),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: _getIconSize()),
                  SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      ),
    );
  }
  
  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }
  
  Color _getBackgroundColor() {
    switch (type) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.secondary:
        return AppColors.secondary;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
    }
  }
  
  Color _getForegroundColor() {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return AppColors.surface;
      case ButtonType.outline:
      case ButtonType.text:
        return AppColors.primary;
    }
  }
  
  double _getElevation() {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return 2;
      case ButtonType.outline:
      case ButtonType.text:
        return 0;
    }
  }
  
  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }
```

#### Report Card Component
```dart
class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final bool showActions;
  
  const ReportCard({
    Key? key,
    required this.report,
    this.onTap,
    this.showActions = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.status,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatDate(report.date),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                report.itemName,
                style: AppTextStyles.headline3,
              ),
              SizedBox(height: 8),
              Text(
                report.description,
                style: AppTextStyles.bodyText2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    report.location,
                    style: AppTextStyles.bodyText2,
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.category,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (showActions) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Contact',
                        type: ButtonType.outline,
                        size: ButtonSize.small,
                        icon: Icons.message,
                        onPressed: () => _contactUser(context),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: 'Call',
                        type: ButtonType.primary,
                        size: ButtonSize.small,
                        icon: Icons.phone,
                        onPressed: () => _callUser(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor() {
    switch (report.status) {
      case 'Lost':
        return AppColors.error;
      case 'Found':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _contactUser(BuildContext context) {
    // Navigate to chat page
  }
  
  void _callUser(BuildContext context) {
    // Initiate video call
  }
}
```

#### Loading Widget
```dart
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool showMessage;
  
  const LoadingWidget({
    Key? key,
    this.message,
    this.showMessage = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          if (showMessage) ...[
            SizedBox(height: 16),
            Text(
              message ?? 'Loading...',
              style: AppTextStyles.bodyText2,
            ),
          ],
        ],
      ),
    );
  }
}
```

#### Error Widget
```dart
class ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final IconData? icon;
  
  const ErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.headline3,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: AppTextStyles.bodyText2,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24),
              AppButton(
                text: 'Try Again',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 📡 API Documentation

### REST API Endpoints

#### Authentication Endpoints
```yaml
POST /auth/login
  Description: Authenticate user with email and password
  Request Body:
    email: string (required)
    password: string (required)
  Response:
    200: { user: UserProfile, token: string }
    401: { error: "Invalid credentials" }
    400: { error: "Validation error" }

POST /auth/register
  Description: Register new user account
  Request Body:
    email: string (required)
    password: string (required)
    displayName: string (required)
    department: string (required)
    role: string (required)
  Response:
    201: { user: UserProfile, token: string }
    400: { error: "Validation error" }
    409: { error: "Email already exists" }

POST /auth/logout
  Description: Logout current user
  Headers:
    Authorization: Bearer <token>
  Response:
    200: { message: "Logged out successfully" }

POST /auth/forgot-password
  Description: Send password reset email
  Request Body:
    email: string (required)
  Response:
    200: { message: "Password reset email sent" }
    404: { error: "User not found" }
```

#### User Endpoints
```yaml
GET /users/profile
  Description: Get current user profile
  Headers:
    Authorization: Bearer <token>
  Response:
    200: UserProfile
    401: { error: "Unauthorized" }

PUT /users/profile
  Description: Update user profile
  Headers:
    Authorization: Bearer <token>
  Request Body:
    displayName: string (optional)
    department: string (optional)
    phoneNumber: string (optional)
    preferences: object (optional)
  Response:
    200: UserProfile
    400: { error: "Validation error" }
    401: { error: "Unauthorized" }

POST /users/upload-avatar
  Description: Upload user profile photo
  Headers:
    Authorization: Bearer <token>
    Content-Type: multipart/form-data
  Request Body:
    avatar: file (required)
  Response:
    200: { photoURL: string }
    400: { error: "Invalid file format" }
    413: { error: "File too large" }
```

#### Report Endpoints
```yaml
GET /reports
  Description: Get list of reports with filtering
  Query Parameters:
    status: string (optional) - 'Lost' or 'Found'
    category: string (optional)
    location: string (optional)
    search: string (optional)
    limit: number (optional, default: 50)
    offset: number (optional, default: 0)
  Response:
    200: { reports: Report[], total: number, hasMore: boolean }

GET /reports/:id
  Description: Get specific report by ID
  Parameters:
    id: string (required)
  Response:
    200: Report
    404: { error: "Report not found" }

POST /reports
  Description: Create new report
  Headers:
    Authorization: Bearer <token>
  Request Body:
    itemName: string (required)
    description: string (required)
    status: string (required) - 'Lost' or 'Found'
    category: string (required)
    location: string (required)
    date: string (required, ISO format)
    images: string[] (optional, base64 encoded)
  Response:
    201: Report
    400: { error: "Validation error" }
    401: { error: "Unauthorized" }

PUT /reports/:id
  Description: Update existing report
  Headers:
    Authorization: Bearer <token>
  Parameters:
    id: string (required)
  Request Body:
    itemName: string (optional)
    description: string (optional)
    category: string (optional)
    location: string (optional)
    isResolved: boolean (optional)
  Response:
    200: Report
    400: { error: "Validation error" }
    401: { error: "Unauthorized" }
    403: { error: "Not authorized to update this report" }
    404: { error: "Report not found" }

DELETE /reports/:id
  Description: Delete report
  Headers:
    Authorization: Bearer <token>
  Parameters:
    id: string (required)
  Response:
    204: No content
    401: { error: "Unauthorized" }
    403: { error: "Not authorized to delete this report" }
    404: { error: "Report not found" }
```

#### Conversation Endpoints
```yaml
GET /conversations
  Description: Get user's conversations
  Headers:
    Authorization: Bearer <token>
  Response:
    200: Conversation[]

GET /conversations/:id/messages
  Description: Get messages in conversation
  Headers:
    Authorization: Bearer <token>
  Parameters:
    id: string (required)
  Query Parameters:
    limit: number (optional, default: 50)
    before: string (optional, message ID)
  Response:
    200: { messages: Message[], hasMore: boolean }

POST /conversations/:id/messages
  Description: Send message in conversation
  Headers:
    Authorization: Bearer <token>
  Parameters:
    id: string (required)
  Request Body:
    text: string (required)
    type: string (optional, default: 'text')
    imageUrl: string (optional)
    audioUrl: string (optional)
  Response:
    201: Message
    400: { error: "Validation error" }
    401: { error: "Unauthorized" }
    404: { error: "Conversation not found" }
```

### WebSocket API

#### Connection
```javascript
// Connect to WebSocket
const ws = new WebSocket('wss://api.campus-lf.com/ws');

// Authentication
ws.send(JSON.stringify({
  type: 'auth',
  token: 'your-jwt-token'
}));
```

#### Message Types
```yaml
Real-time Messages:
  - new_message: New message in conversation
  - message_read: Message read receipt
  - user_typing: User typing indicator
  - user_online: User online status
  - new_match: New report match found
  - report_updated: Report status changed

Message Format:
  type: string
  data: object
  timestamp: string (ISO format)
  userId: string (sender ID)
```

#### Example WebSocket Messages
```javascript
// New message
{
  "type": "new_message",
  "data": {
    "conversationId": "conv_123",
    "message": {
      "id": "msg_456",
      "fromUid": "user_789",
      "text": "I think I found your phone!",
      "timestamp": "2025-01-15T10:30:00Z"
    }
  }
}

// Typing indicator
{
  "type": "user_typing",
  "data": {
    "conversationId": "conv_123",
    "userId": "user_789",
    "isTyping": true
  }
}

// New match
{
  "type": "new_match",
  "data": {
    "reportId": "report_123",
    "matchedReportId": "report_456",
    "confidence": 0.85
  }
}
```

### Firebase API Integration

#### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports are readable by all authenticated users
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.auth.uid == resource.data.uid;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.uid || 
         request.auth.token.admin == true);
      allow delete: if request.auth != null && 
        request.auth.uid == resource.data.uid;
    }
    
    // Conversations are accessible by participants
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
      }
    }
    
    // Notifications are readable by the target user
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow write: if request.auth != null && 
        request.auth.token.admin == true;
    }
  }
}
```

#### Firebase Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile photos
    match /users/{userId}/profile/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == userId &&
        request.resource.size < 5 * 1024 * 1024 && // 5MB limit
        request.resource.contentType.matches('image/.*');
    }
    
    // Report images
    match /reports/{reportId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.resource.size < 10 * 1024 * 1024 && // 10MB limit
        request.resource.contentType.matches('image/.*');
    }
    
    // Chat media
    match /conversations/{conversationId}/{fileName} {
      allow read, write: if request.auth != null;
      // Additional validation can be added based on conversation participants
    }
  }
}
```

---

## 🔄 Development Workflows

### Git Workflow

#### Branch Strategy
```yaml
Branch Types:
  main: Production-ready code
  develop: Integration branch for features
  feature/*: Individual feature development
  hotfix/*: Critical bug fixes
  release/*: Release preparation

Branch Naming:
  feature/user-authentication
  feature/report-submission
  hotfix/login-bug-fix
  release/v1.2.0
```

#### Commit Message Convention
```yaml
Format: <type>(<scope>): <description>

Types:
  feat: New feature
  fix: Bug fix
  docs: Documentation changes
  style: Code style changes (formatting, etc.)
  refactor: Code refactoring
  test: Adding or updating tests
  chore: Maintenance tasks

Examples:
  feat(auth): add Google OAuth integration
  fix(chat): resolve message ordering issue
  docs(api): update authentication endpoints
  style(ui): improve button component styling
  refactor(models): simplify Report class structure
  test(auth): add unit tests for login flow
  chore(deps): update Firebase SDK to v10.0.0
```

#### Pull Request Process
```yaml
1. Create Feature Branch:
   git checkout develop
   git pull origin develop
   git checkout -b feature/new-feature

2. Development:
   - Write code following style guidelines
   - Add/update tests
   - Update documentation
   - Commit changes with conventional messages

3. Pre-PR Checklist:
   - [ ] All tests pass
   - [ ] Code follows style guidelines
   - [ ] Documentation updated
   - [ ] No merge conflicts with develop
   - [ ] Feature is complete and tested

4. Create Pull Request:
   - Clear title and description
   - Link related issues
   - Add screenshots for UI changes
   - Request appropriate reviewers

5. Code Review:
   - Address reviewer feedback
   - Update code as needed
   - Ensure CI/CD passes

6. Merge:
   - Squash and merge to develop
   - Delete feature branch
   - Update local develop branch
```

### Code Quality Standards

#### Linting Configuration
```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
  
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - avoid_unnecessary_containers
    - prefer_single_quotes
    - sort_child_properties_last
    - use_key_in_widget_constructors
    - prefer_const_declarations
    - unnecessary_null_checks
```

#### Code Formatting
```dart
// Use dart format for consistent formatting
// Configure your IDE to format on save

// Example of well-formatted code
class ReportService {
  static const String _collectionName = 'reports';
  
  static Future<List<Report>> getReports({
    String? status,
    String? category,
    int limit = 50,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection(_collectionName)
          .orderBy('timestamp', descending: true);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      final snapshot = await query.limit(limit).get();
      
      return snapshot.docs
          .map((doc) => Report.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }
}
```

### Testing Strategy

#### Unit Testing
```dart
// test/models/report_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/models.dart';

void main() {
  group('Report Model Tests', () {
    test('should create Report from JSON correctly', () {
      // Arrange
      final json = {
        'reportId': 'test_123',
        'uid': 'user_456',
        'itemName': 'iPhone 13',
        'status': 'Lost',
        'description': 'Black iPhone 13 with blue case',
        'location': 'Library',
        'date': '2025-01-15T10:30:00.000Z',
        'category': 'Electronics',
        'timestamp': '2025-01-15T10:30:00.000Z',
      };
      
      // Act
      final report = Report.fromJson(json);
      
      // Assert
      expect(report.reportId, equals('test_123'));
      expect(report.itemName, equals('iPhone 13'));
      expect(report.status, equals('Lost'));
      expect(report.category, equals('Electronics'));
    });
    
    test('should convert Report to JSON correctly', () {
      // Arrange
      final report = Report(
        reportId: 'test_123',
        uid: 'user_456',
        itemName: 'iPhone 13',
        status: 'Lost',
        description: 'Black iPhone 13 with blue case',
        location: 'Library',
        date: DateTime.parse('2025-01-15T10:30:00.000Z'),
        category: 'Electronics',
        timestamp: DateTime.parse('2025-01-15T10:30:00.000Z'),
      );
      
      // Act
      final json = report.toJson();
      
      // Assert
      expect(json['reportId'], equals('test_123'));
      expect(json['itemName'], equals('iPhone 13'));
      expect(json['status'], equals('Lost'));
    });
  });
}
```

#### Widget Testing
```dart
// test/widgets/report_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/widgets/report_card.dart';
import 'package:campus_lf_app/models.dart';

void main() {
  group('ReportCard Widget Tests', () {
    late Report testReport;
    
    setUp(() {
      testReport = Report(
        reportId: 'test_123',
        uid: 'user_456',
        itemName: 'Test Item',
        status: 'Lost',
        description: 'Test description',
        location: 'Test Location',
        date: DateTime.now(),
        category: 'Electronics',
        timestamp: DateTime.now(),
      );
    });
    
    testWidgets('should display report information correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(report: testReport),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('Lost'), findsOneWidget);
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
    });
    
    testWidgets('should call onTap when card is tapped', (tester) async {
      // Arrange
      bool wasTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              report: testReport,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );
      
      // Act
      await tester.tap(find.byType(ReportCard));
      await tester.pump();
      
      // Assert
      expect(wasTapped, isTrue);
    });
  });
}
```

#### Integration Testing
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('App Integration Tests', () {
    testWidgets('complete report submission flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to report page
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Fill out form
      await tester.enterText(find.byKey(Key('itemName')), 'Test Item');
      await tester.enterText(find.byKey(Key('description')), 'Test Description');
      
      // Select category
      await tester.tap(find.byKey(Key('categoryDropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();
      
      // Submit form
      await tester.tap(find.byKey(Key('submitButton')));
      await tester.pumpAndSettle();
      
      // Verify success
      expect(find.text('Report submitted successfully!'), findsOneWidget);
    });
  });
}
```

### Performance Optimization

#### Image Optimization
```dart
class OptimizedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  
  const OptimizedImageWidget({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.error),
      ),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );
  }
}
```

#### List Performance
```dart
class OptimizedReportsList extends StatelessWidget {
  final List<Report> reports;
  
  const OptimizedReportsList({
    Key? key,
    required this.reports,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: ReportCard(
            key: ValueKey(reports[index].reportId),
            report: reports[index],
          ),
        );
      },
      // Add caching for better performance
      cacheExtent: 1000,
    );
  }
}
```

#### Memory Management
```dart
class ChatPageController extends ChangeNotifier {
  final List<Message> _messages = [];
  static const int _maxMessages = 100;
  
  void addMessage(Message message) {
    _messages.insert(0, message);
    
    // Limit messages in memory
    if (_messages.length > _maxMessages) {
      _messages.removeRange(_maxMessages, _messages.length);
    }
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    _messages.clear();
    super.dispose();
  }
}
```

### Debugging and Troubleshooting

#### Debug Configuration
```dart
// lib/utils/debug_config.dart
class DebugConfig {
  static const bool isDebugMode = kDebugMode;
  static const bool enableLogging = true;
  static const bool enablePerformanceOverlay = false;
  
  static void log(String message, [String? tag]) {
    if (enableLogging && isDebugMode) {
      print('${tag ?? 'DEBUG'}: $message');
    }
  }
  
  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (enableLogging) {
      print('ERROR: $message');
      if (error != null) print('Error details: $error');
      if (stackTrace != null) print('Stack trace: $stackTrace');
    }
  }
}
```

#### Error Handling
```dart
class ErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    DebugConfig.logError('Unhandled error', error, stackTrace);
    
    // Report to crash analytics in production
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
  }
  
  static Widget buildErrorWidget(FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (kDebugMode)
              Text(
                details.exception.toString(),
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
```

#### Common Issues and Solutions

```yaml
Issue: "Firebase not initialized"
Solution: 
  - Ensure Firebase.initializeApp() is called in main()
  - Check firebase_options.dart is properly configured
  - Verify platform-specific configuration files

Issue: "Permission denied for camera/microphone"
Solution:
  - Add permissions to platform manifests
  - Request permissions at runtime
  - Handle permission denied gracefully

Issue: "Network request failed"
Solution:
  - Check internet connectivity
  - Implement retry logic
  - Add proper error handling
  - Verify Firebase security rules

Issue: "Widget disposed error"
Solution:
  - Check mounted property before setState
  - Properly dispose controllers and streams
  - Use StatefulWidget lifecycle correctly

Issue: "Memory leaks"
Solution:
  - Dispose controllers and listeners
  - Cancel subscriptions in dispose()
  - Use weak references where appropriate
  - Monitor memory usage with DevTools
```

### Contributing Guidelines

#### Code Review Checklist
```yaml
Functionality:
  - [ ] Feature works as expected
  - [ ] Edge cases are handled
  - [ ] Error handling is implemented
  - [ ] Performance is acceptable

Code Quality:
  - [ ] Code follows style guidelines
  - [ ] Functions are well-named and focused
  - [ ] Comments explain complex logic
  - [ ] No code duplication

Testing:
  - [ ] Unit tests are included
  - [ ] Tests cover edge cases
  - [ ] Integration tests pass
  - [ ] Manual testing completed

Documentation:
  - [ ] Code is self-documenting
  - [ ] API changes are documented
  - [ ] README updated if needed
  - [ ] Comments are helpful

Security:
  - [ ] No hardcoded secrets
  - [ ] Input validation implemented
  - [ ] Security best practices followed
  - [ ] Dependencies are secure
```

#### Development Environment
```bash
# Setup development environment
flutter doctor -v
flutter pub get
flutter pub run build_runner build

# Run tests
flutter test
flutter test integration_test/

# Code analysis
flutter analyze
dart format --set-exit-if-changed .

# Build for different platforms
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

## 📚 Additional Resources

### Learning Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design Guidelines](https://material.io/design)

### Tools and Extensions
- [Flutter Inspector](https://docs.flutter.dev/development/tools/flutter-inspector)
- [Firebase Console](https://console.firebase.google.com/)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Android Studio Flutter Plugin](https://plugins.jetbrains.com/plugin/9212-flutter)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Firebase Community](https://firebase.google.com/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub Discussions](https://github.com/flutter/flutter/discussions)

---

*This developer guide is a living document and should be updated as the project evolves. For questions or suggestions, please contact the development team.*