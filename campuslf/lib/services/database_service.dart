import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'campuslf.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        isLost INTEGER NOT NULL,
        contactInfo TEXT NOT NULL,
        category TEXT NOT NULL,
        userId TEXT,
        imagePath TEXT,
        status TEXT DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        senderId TEXT NOT NULL,
        receiverId TEXT NOT NULL,
        itemId TEXT,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE forum_posts (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        likes INTEGER DEFAULT 0,
        replies INTEGER DEFAULT 0
      )
    ''');
  }

  // Item operations
  Future<void> insertItem(Item item) async {
    final db = await database;
    await db.insert('items', item.toJson(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Item>> getAllItems() async {
    final db = await database;
    final maps = await db.query('items', orderBy: 'dateTime DESC');
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  Future<List<Item>> getItemsByCategory(ItemCategory category) async {
    final db = await database;
    final maps = await db.query(
      'items',
      where: 'category = ?',
      whereArgs: [category.toString()],
      orderBy: 'dateTime DESC',
    );
    return maps.map((map) => Item.fromJson(map)).toList();
  }

  Future<void> updateItemStatus(String itemId, String status) async {
    final db = await database;
    await db.update(
      'items',
      {'status': status},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteItem(String itemId) async {
    final db = await database;
    await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
  }

  // Message operations
  Future<void> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getMessages(String userId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'senderId = ? OR receiverId = ?',
      whereArgs: [userId, userId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<void> markMessageAsRead(String messageId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  // Forum operations
  Future<void> insertForumPost(Map<String, dynamic> post) async {
    final db = await database;
    await db.insert('forum_posts', post);
  }

  Future<List<Map<String, dynamic>>> getForumPosts() async {
    final db = await database;
    return await db.query('forum_posts', orderBy: 'timestamp DESC');
  }

  Future<void> likePost(String postId) async {
    final db = await database;
    await db.rawUpdate('UPDATE forum_posts SET likes = likes + 1 WHERE id = ?', [postId]);
  }
}