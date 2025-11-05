import '../models/item.dart';
import 'notification_service.dart';

class MatchingService {
  static final MatchingService _instance = MatchingService._internal();
  factory MatchingService() => _instance;
  MatchingService._internal();

  List<ItemMatch> findMatches(Item newItem, List<Item> existingItems) {
    final matches = <ItemMatch>[];
    
    for (final item in existingItems) {
      if (item.id == newItem.id || item.isLost == newItem.isLost) continue;
      
      final score = _calculateMatchScore(newItem, item);
      if (score > 0.6) {
        matches.add(ItemMatch(
          item1: newItem,
          item2: item,
          score: score,
          reasons: _getMatchReasons(newItem, item),
        ));
        
        // Send notification for high-confidence matches
        if (score > 0.8) {
          NotificationService().showItemMatch(
            newItem.isLost ? newItem : item,
            newItem.isLost ? item : newItem,
          );
        }
      }
    }
    
    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }

  double _calculateMatchScore(Item item1, Item item2) {
    double score = 0.0;
    
    // Category match (40% weight)
    if (item1.category == item2.category) {
      score += 0.4;
    }
    
    // Title similarity (30% weight)
    final titleSimilarity = _calculateStringSimilarity(
      item1.title.toLowerCase(),
      item2.title.toLowerCase(),
    );
    score += titleSimilarity * 0.3;
    
    // Description similarity (20% weight)
    final descSimilarity = _calculateStringSimilarity(
      item1.description.toLowerCase(),
      item2.description.toLowerCase(),
    );
    score += descSimilarity * 0.2;
    
    // Location proximity (10% weight)
    if (item1.location.toLowerCase().contains(item2.location.toLowerCase()) ||
        item2.location.toLowerCase().contains(item1.location.toLowerCase())) {
      score += 0.1;
    }
    
    return score;
  }

  double _calculateStringSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    
    final words1 = str1.split(' ');
    final words2 = str2.split(' ');
    
    int commonWords = 0;
    for (final word1 in words1) {
      if (words2.any((word2) => word2.contains(word1) || word1.contains(word2))) {
        commonWords++;
      }
    }
    
    return commonWords / (words1.length + words2.length - commonWords);
  }

  List<String> _getMatchReasons(Item item1, Item item2) {
    final reasons = <String>[];
    
    if (item1.category == item2.category) {
      reasons.add('Same category: ${Item.getCategoryName(item1.category)}');
    }
    
    if (item1.title.toLowerCase().contains(item2.title.toLowerCase()) ||
        item2.title.toLowerCase().contains(item1.title.toLowerCase())) {
      reasons.add('Similar titles');
    }
    
    if (item1.location.toLowerCase().contains(item2.location.toLowerCase()) ||
        item2.location.toLowerCase().contains(item1.location.toLowerCase())) {
      reasons.add('Same location area');
    }
    
    final timeDiff = item1.dateTime.difference(item2.dateTime).inDays.abs();
    if (timeDiff <= 3) {
      reasons.add('Reported within $timeDiff days');
    }
    
    return reasons;
  }
}

class ItemMatch {
  final Item item1;
  final Item item2;
  final double score;
  final List<String> reasons;

  ItemMatch({
    required this.item1,
    required this.item2,
    required this.score,
    required this.reasons,
  });

  Item get lostItem => item1.isLost ? item1 : item2;
  Item get foundItem => item1.isLost ? item2 : item1;
}