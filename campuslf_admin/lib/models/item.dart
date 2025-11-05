import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCategory { electronics, clothing, books, accessories, keys, other, bags, documents, sports, personal, academic }

class Item {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final bool isLost;
  final String contactInfo;
  final ItemCategory category;
  final String? imagePath;
  final List<String>? imagePaths;
  final List<String> likes;
  final List<Comment> comments;
  final bool isResolved;
  final DateTime? resolvedAt;

  Item({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.isLost,
    required this.contactInfo,
    required this.category,
    this.imagePath,
    this.imagePaths,
    this.likes = const [],
    this.comments = const [],
    this.isResolved = false,
    this.resolvedAt,
  });

  bool isLikedBy(String userId) => likes.contains(userId);
  int get likesCount => likes.length;
  int get commentsCount => comments.length;

  static String getCategoryName(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics: return 'Electronics';
      case ItemCategory.clothing: return 'Clothing';
      case ItemCategory.books: return 'Books';
      case ItemCategory.accessories: return 'Accessories';
      case ItemCategory.keys: return 'Keys';
      case ItemCategory.bags: return 'Bags';
      case ItemCategory.documents: return 'Documents';
      case ItemCategory.sports: return 'Sports';
      case ItemCategory.personal: return 'Personal';
      case ItemCategory.academic: return 'Academic';
      case ItemCategory.other: return 'Other';
    }
  }

  static IconData getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics: return Icons.phone_android;
      case ItemCategory.clothing: return Icons.checkroom;
      case ItemCategory.books: return Icons.book;
      case ItemCategory.accessories: return Icons.watch;
      case ItemCategory.keys: return Icons.key;
      case ItemCategory.bags: return Icons.backpack;
      case ItemCategory.documents: return Icons.description;
      case ItemCategory.sports: return Icons.sports_basketball;
      case ItemCategory.personal: return Icons.person;
      case ItemCategory.academic: return Icons.school;
      case ItemCategory.other: return Icons.more_horiz;
    }
  }

  static Color getCategoryColor(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics: return Colors.blue;
      case ItemCategory.clothing: return Colors.purple;
      case ItemCategory.books: return Colors.green;
      case ItemCategory.accessories: return Colors.pink;
      case ItemCategory.keys: return Colors.orange;
      case ItemCategory.bags: return Colors.brown;
      case ItemCategory.documents: return Colors.grey;
      case ItemCategory.sports: return Colors.red;
      case ItemCategory.personal: return Colors.teal;
      case ItemCategory.academic: return Colors.indigo;
      case ItemCategory.other: return Colors.blueGrey;
    }
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  factory Item.fromFirestore(Map<String, dynamic> data, String docId) {
    ItemCategory category;
    if (data['category'] is String) {
      category = ItemCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => ItemCategory.other,
      );
    } else {
      category = ItemCategory.values[data['category'] ?? 0];
    }
    
    List<String>? imagePaths;
    if (data['imagePaths'] != null) {
      imagePaths = List<String>.from(data['imagePaths']);
    }
    
    List<String> likes = [];
    if (data['likes'] != null) {
      likes = List<String>.from(data['likes']);
    }
    
    List<Comment> comments = [];
    if (data['comments'] != null) {
      comments = (data['comments'] as List)
          .map((c) => Comment.fromJson(c))
          .toList();
    }
    
    // Normalize dateTime field that may be stored as String ISO8601 or Firestore Timestamp
    DateTime parsedDateTime;
    final rawDateTime = data['dateTime'];
    if (rawDateTime is DateTime) {
      parsedDateTime = rawDateTime;
    } else if (rawDateTime is String) {
      parsedDateTime = DateTime.tryParse(rawDateTime) ?? DateTime.now();
    } else if (rawDateTime is Timestamp) {
      parsedDateTime = rawDateTime.toDate();
    } else {
      parsedDateTime = DateTime.now();
    }

    return Item(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: category,
      location: data['location'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      dateTime: parsedDateTime,
      isLost: data['isLost'] == true,
      imagePath: data['imagePath'],
      imagePaths: imagePaths,
      likes: likes,
      comments: comments,
      isResolved: data['isResolved'] == true,
      resolvedAt: data['resolvedAt']?.toDate(),
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime dateTime;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.dateTime,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'text': text,
    'dateTime': dateTime.toIso8601String(),
  };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    userId: json['userId'],
    userName: json['userName'],
    text: json['text'],
    dateTime: DateTime.parse(json['dateTime']),
  );

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}