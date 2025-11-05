import '../models/item.dart';

class ItemMatch {
  final Item item;
  final double similarity;
  final List<String> matchReasons;

  ItemMatch({
    required this.item,
    required this.similarity,
    required this.matchReasons,
  });
}

class SmartMatchingService {
  static final SmartMatchingService _instance = SmartMatchingService._internal();
  factory SmartMatchingService() => _instance;
  SmartMatchingService._internal();

  List<ItemMatch> findMatches(Item targetItem, List<Item> allItems) {
    final matches = <ItemMatch>[];
    
    for (final item in allItems) {
      if (item.id == targetItem.id || item.isLost == targetItem.isLost) continue;
      
      final match = _calculateMatch(targetItem, item);
      if (match.similarity > 0.3) {
        matches.add(match);
      }
    }
    
    matches.sort((a, b) => b.similarity.compareTo(a.similarity));
    return matches.take(5).toList();
  }

  ItemMatch _calculateMatch(Item item1, Item item2) {
    double similarity = 0.0;
    final reasons = <String>[];

    // Category match (40% weight)
    if (item1.category == item2.category) {
      similarity += 0.4;
      reasons.add('Same category');
    }

    // Title similarity (30% weight)
    final titleSimilarity = _calculateTextSimilarity(item1.title, item2.title);
    similarity += titleSimilarity * 0.3;
    if (titleSimilarity > 0.5) {
      reasons.add('Similar title');
    }

    // Description similarity (20% weight)
    final descSimilarity = _calculateTextSimilarity(item1.description, item2.description);
    similarity += descSimilarity * 0.2;
    if (descSimilarity > 0.3) {
      reasons.add('Similar description');
    }

    // Location proximity (10% weight)
    final locationSimilarity = _calculateLocationSimilarity(item1.location, item2.location);
    similarity += locationSimilarity * 0.1;
    if (locationSimilarity > 0.5) {
      reasons.add('Same location');
    }

    return ItemMatch(
      item: item2,
      similarity: similarity,
      matchReasons: reasons,
    );
  }

  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(' ');
    final words2 = text2.toLowerCase().split(' ');
    
    int commonWords = 0;
    for (final word in words1) {
      if (words2.contains(word) && word.length > 2) {
        commonWords++;
      }
    }
    
    final totalWords = (words1.length + words2.length) / 2;
    return totalWords > 0 ? commonWords / totalWords : 0.0;
  }

  double _calculateLocationSimilarity(String loc1, String loc2) {
    if (loc1.toLowerCase() == loc2.toLowerCase()) return 1.0;
    
    final words1 = loc1.toLowerCase().split(' ');
    final words2 = loc2.toLowerCase().split(' ');
    
    for (final word in words1) {
      if (words2.contains(word)) return 0.7;
    }
    
    return 0.0;
  }
}