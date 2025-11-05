import 'dart:async';
import '../models/item.dart';

class MockRealtimeService {
  final _itemsController = StreamController<List<Item>>.broadcast();
  final _postsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _messagesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  List<Item> _items = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _messages = [];

  MockRealtimeService() {
    _seedData();
  }

  void _seedData() {
    _items = [
      Item(
        id: 'mock1',
        title: 'Lost Backpack',
        description: 'Black backpack near cafeteria',
        location: 'Cafeteria',
        dateTime: DateTime.now().subtract(const Duration(hours: 2)),
        isLost: true,
        contactInfo: 'student@wsu.ac.za',
        category: ItemCategory.bags,
      ),
      Item(
        id: 'mock2',
        title: 'Found Student Card',
        description: 'WSU student card found outside library',
        location: 'Library',
        dateTime: DateTime.now().subtract(const Duration(hours: 5)),
        isLost: false,
        contactInfo: 'finder@wsu.ac.za',
        category: ItemCategory.documents,
      ),
    ];
    _posts = [
      {
        'id': 'p1',
        'title': 'Welcome to the forum',
        'content': 'Share lost and found items here',
        'category': 'General',
        'userId': 'guest',
        'userName': 'Guest',
        'createdAt': DateTime.now(),
        'likes': 0,
      },
    ];
    _messages = [
      {
        'id': 'm1',
        'senderId': 'guest',
        'senderName': 'Guest',
        'content': 'Hi, is the backpack still available?',
        'createdAt': DateTime.now(),
        'isRead': false,
      },
    ];
    _itemsController.add(_items);
    _postsController.add(_posts);
    _messagesController.add(_messages);
  }

  Stream<List<Item>> getItemsStream() => _itemsController.stream;
  Stream<List<Map<String, dynamic>>> getForumPostsStream() => _postsController.stream;
  Stream<List<Map<String, dynamic>>> getMessagesStream(String userId) => _messagesController.stream;

  Future<void> addItem(Item item) async {
    _items.insert(0, item);
    _itemsController.add(List<Item>.from(_items));
  }

  Future<void> addForumPost({required String title, required String content, required String category}) async {
    _posts.insert(0, {
      'id': 'p${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'content': content,
      'category': category,
      'userId': 'guest',
      'userName': 'Guest',
      'createdAt': DateTime.now(),
      'likes': 0,
    });
    _postsController.add(List<Map<String, dynamic>>.from(_posts));
  }

  Future<void> sendMessage({required String receiverId, required String content}) async {
    _messages.insert(0, {
      'id': 'm${DateTime.now().millisecondsSinceEpoch}',
      'senderId': 'guest',
      'senderName': 'Guest',
      'content': content,
      'createdAt': DateTime.now(),
      'isRead': false,
    });
    _messagesController.add(List<Map<String, dynamic>>.from(_messages));
  }

  void dispose() {
    _itemsController.close();
    _postsController.close();
    _messagesController.close();
  }
}