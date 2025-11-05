import 'package:flutter/material.dart';

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.toString(),
    'location': location,
    'contactInfo': contactInfo,
    'dateTime': dateTime.toIso8601String(),
    'isLost': isLost ? 1 : 0,
    'imagePath': imagePath,
    'imagePaths': imagePaths,
    'likes': likes,
    'comments': comments.map((c) => c.toJson()).toList(),
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    ItemCategory category;
    if (json['category'] is String) {
      category = ItemCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => ItemCategory.other,
      );
    } else {
      category = ItemCategory.values[json['category'] ?? 0];
    }
    
    List<String>? imagePaths;
    if (json['imagePaths'] != null) {
      imagePaths = List<String>.from(json['imagePaths']);
    }
    
    List<String> likes = [];
    if (json['likes'] != null) {
      likes = List<String>.from(json['likes']);
    }
    
    List<Comment> comments = [];
    if (json['comments'] != null) {
      comments = (json['comments'] as List)
          .map((c) => Comment.fromJson(c))
          .toList();
    }
    
    return Item(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: category,
      location: json['location'],
      contactInfo: json['contactInfo'],
      dateTime: DateTime.parse(json['dateTime']),
      isLost: json['isLost'] == 1 || json['isLost'] == true,
      imagePath: json['imagePath'],
      imagePaths: imagePaths,
      likes: likes,
      comments: comments,
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