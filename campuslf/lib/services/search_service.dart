import '../models/item.dart';
import 'database_service.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DatabaseService _db = DatabaseService();

  Future<List<Item>> searchItems({
    String? query,
    ItemCategory? category,
    bool? isLost,
    String? location,
  }) async {
    List<Item> items = await _db.getAllItems();

    if (query != null && query.isNotEmpty) {
      items = await _db.searchItems(query);
    }

    if (category != null) {
      items = items.where((item) => item.category == category).toList();
    }

    if (isLost != null) {
      items = items.where((item) => item.isLost == isLost).toList();
    }

    if (location != null && location.isNotEmpty) {
      items = items.where((item) => 
        item.location.toLowerCase().contains(location.toLowerCase())
      ).toList();
    }

    return items;
  }

  Future<List<Item>> getRecentItems({int limit = 10}) async {
    final items = await _db.getAllItems();
    return items.take(limit).toList();
  }

  Future<List<Item>> getSimilarItems(Item item) async {
    final items = await _db.getAllItems();
    return items.where((i) => 
      i.id != item.id &&
      (i.category == item.category || 
       i.location.toLowerCase().contains(item.location.toLowerCase()))
    ).take(5).toList();
  }
}