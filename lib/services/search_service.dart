import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import 'offline_service.dart';
import 'location_service.dart';

class SearchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _reportsCollection = 'reports';

  // Search with advanced filters
  static Future<SearchResult> searchReports({
    String? searchTerm,
    SearchFilters? filters,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    bool useCache = true,
  }) async {
    try {
      final startTime = DateTime.now().millisecondsSinceEpoch;

      // Check if offline and use cache
      if (!OfflineService.isOnline && useCache) {
        final cachedResults = _searchCachedReports(
          searchTerm: searchTerm,
          filters: filters,
          limit: limit,
        );
        
        return SearchResult(
          reports: cachedResults,
          hasMore: false,
          isFromCache: true,
          totalResults: cachedResults.length,
          searchTime: DateTime.now().millisecondsSinceEpoch - startTime,
        );
      }

      // Build Firestore query
      Query query = _firestore.collection(_reportsCollection);

      // Apply filters
      if (filters != null) {
        query = _applyFilters(query, filters);
      }

      // Apply text search if provided
      if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        final term = searchTerm.trim().toLowerCase();
        
        // For better text search, we'll use array-contains for keywords
        // This requires preprocessing text into keywords during report creation
        query = query.where('searchKeywords', arrayContainsAny: _generateKeywords(term));
      }

      // Apply sorting
      if (filters?.sortBy != null) {
        query = _applySorting(query, filters!.sortBy!, filters.sortOrder ?? SortOrder.descending);
      } else {
        // Default sort by timestamp
        query = query.orderBy('timestamp', descending: true);
      }

      // Apply pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      // Execute query
      final snapshot = await query.get();
      
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Apply additional filters that can't be done in Firestore
      final filteredReports = _applyClientSideFilters(reports, searchTerm, filters);

      final searchTime = DateTime.now().millisecondsSinceEpoch - startTime;

      // Log analytics
      await AnalyticsService.logSearch(
        searchTerm: searchTerm ?? '',
        resultsCount: filteredReports.length,
        filters: filters?.toMap(),
      );

      // Save search term to history
      if (searchTerm != null && searchTerm.trim().isNotEmpty) {
        await OfflineService.addSearchTerm(searchTerm.trim());
      }

      return SearchResult(
        reports: filteredReports,
        hasMore: snapshot.docs.length == limit,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        isFromCache: false,
        totalResults: filteredReports.length,
        searchTime: searchTime,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error searching reports: $e');
      }
      
      await AnalyticsService.logError(
        errorType: 'search_error',
        errorMessage: e.toString(),
      );

      // Fallback to cached search if online search fails
      if (useCache) {
        final cachedResults = _searchCachedReports(
          searchTerm: searchTerm,
          filters: filters,
          limit: limit,
        );
        
        return SearchResult(
          reports: cachedResults,
          hasMore: false,
          isFromCache: true,
          totalResults: cachedResults.length,
          searchTime: 0,
          error: e.toString(),
        );
      }

      return SearchResult(
        reports: [],
        hasMore: false,
        isFromCache: false,
        totalResults: 0,
        searchTime: 0,
        error: e.toString(),
      );
    }
  }

  // Search cached reports (offline)
  static List<Map<String, dynamic>> _searchCachedReports({
    String? searchTerm,
    SearchFilters? filters,
    int limit = 20,
  }) {
    return OfflineService.getCachedReports(
      category: filters?.category,
      status: filters?.status,
      searchTerm: searchTerm,
    ).take(limit).toList();
  }

  // Apply Firestore filters
  static Query _applyFilters(Query query, SearchFilters filters) {
    // Status filter
    if (filters.status != null && filters.status!.isNotEmpty) {
      query = query.where('status', isEqualTo: filters.status);
    }

    // Category filter
    if (filters.category != null && filters.category!.isNotEmpty) {
      query = query.where('category', isEqualTo: filters.category);
    }

    // Date range filter
    if (filters.dateFrom != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: filters.dateFrom!.millisecondsSinceEpoch);
    }
    if (filters.dateTo != null) {
      query = query.where('timestamp', isLessThanOrEqualTo: filters.dateTo!.millisecondsSinceEpoch);
    }

    // User filter
    if (filters.userId != null && filters.userId!.isNotEmpty) {
      query = query.where('userId', isEqualTo: filters.userId);
    }

    // Has images filter
    if (filters.hasImages == true) {
      query = query.where('hasImages', isEqualTo: true);
    }

    // Resolved filter
    if (filters.isResolved != null) {
      query = query.where('isResolved', isEqualTo: filters.isResolved);
    }

    return query;
  }

  // Apply sorting
  static Query _applySorting(Query query, SortBy sortBy, SortOrder sortOrder) {
    final descending = sortOrder == SortOrder.descending;

    switch (sortBy) {
      case SortBy.timestamp:
        return query.orderBy('timestamp', descending: descending);
      case SortBy.title:
        return query.orderBy('title', descending: descending);
      case SortBy.category:
        return query.orderBy('category', descending: descending);
      case SortBy.status:
        return query.orderBy('status', descending: descending);
      case SortBy.location:
        return query.orderBy('location', descending: descending);
      case SortBy.relevance:
        // For relevance, we'll use timestamp as fallback
        return query.orderBy('timestamp', descending: true);
      case SortBy.dateDesc:
        return query.orderBy('timestamp', descending: true);
      case SortBy.dateAsc:
        return query.orderBy('timestamp', descending: false);
      case SortBy.nameAsc:
        return query.orderBy('title', descending: false);
      case SortBy.nameDesc:
        return query.orderBy('title', descending: true);
    }
  }

  // Apply client-side filters
  static List<Map<String, dynamic>> _applyClientSideFilters(
    List<Map<String, dynamic>> reports,
    String? searchTerm,
    SearchFilters? filters,
  ) {
    var filteredReports = reports;

    // Location-based filtering
    if (filters?.location != null && filters!.location!.isNotEmpty) {
      filteredReports = filteredReports.where((report) {
        final reportLocation = report['location'] as String? ?? '';
        return reportLocation.toLowerCase().contains(filters.location!.toLowerCase());
      }).toList();
    }

    // Distance-based filtering
    if (filters?.maxDistance != null && filters!.latitude != null && filters.longitude != null) {
      filteredReports = filteredReports.where((report) {
        final reportLat = report['latitude'] as double?;
        final reportLon = report['longitude'] as double?;
        
        if (reportLat == null || reportLon == null) return true;
        
        final distance = LocationService.calculateDistance(
          filters.latitude!,
          filters.longitude!,
          reportLat,
          reportLon,
        );
        
        return distance <= filters.maxDistance! * 1000; // Convert km to meters
      }).toList();
    }

    // Text search refinement
    if (searchTerm != null && searchTerm.trim().isNotEmpty) {
      final term = searchTerm.trim().toLowerCase();
      filteredReports = filteredReports.where((report) {
        final title = (report['title'] as String? ?? '').toLowerCase();
        final description = (report['description'] as String? ?? '').toLowerCase();
        final location = (report['location'] as String? ?? '').toLowerCase();
        final category = (report['category'] as String? ?? '').toLowerCase();
        
        return title.contains(term) ||
               description.contains(term) ||
               location.contains(term) ||
               category.contains(term);
      }).toList();
    }

    // Tags filter
    if (filters?.tags != null && filters!.tags!.isNotEmpty) {
      filteredReports = filteredReports.where((report) {
        final reportTags = List<String>.from(report['tags'] ?? []);
        return filters.tags!.any((tag) => reportTags.contains(tag));
      }).toList();
    }

    return filteredReports;
  }

  // Generate keywords for search
  static List<String> _generateKeywords(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final keywords = <String>{};
    
    for (final word in words) {
      if (word.length >= 2) {
        keywords.add(word);
        
        // Add partial matches
        for (int i = 2; i <= word.length; i++) {
          keywords.add(word.substring(0, i));
        }
      }
    }
    
    return keywords.toList();
  }

  // Get search suggestions
  static Future<List<String>> getSearchSuggestions(String query, {int limit = 10}) async {
    try {
      final suggestions = <String>[];
      
      // Add search history
      final history = OfflineService.getSearchHistory(limit: 5);
      suggestions.addAll(history.where((term) => 
        term.toLowerCase().contains(query.toLowerCase())
      ));

      // Add category suggestions
      final categories = await getCategories();
      suggestions.addAll(categories.where((category) =>
        category.toLowerCase().contains(query.toLowerCase())
      ));

      // Add location suggestions
      final locations = LocationService.getLocationSuggestions(query);
      suggestions.addAll(locations.map((loc) => loc.name));

      // Remove duplicates and limit
      return suggestions.toSet().take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting search suggestions: $e');
      }
      return [];
    }
  }

  // Get available categories
  static Future<List<String>> getCategories() async {
    try {
      // This could be cached or fetched from Firestore
      return [
        'Electronics',
        'Clothing',
        'Books',
        'Accessories',
        'Documents',
        'Keys',
        'Bags',
        'Sports Equipment',
        'Jewelry',
        'Other',
      ];
    } catch (e) {
      return [];
    }
  }

  // Get available statuses
  static List<String> getStatuses() {
    return ['lost', 'found', 'resolved', 'expired'];
  }

  // Get popular search terms
  static Future<List<String>> getPopularSearchTerms({int limit = 10}) async {
    try {
      // This would typically come from analytics data
      // For now, return some common terms
      return [
        'phone',
        'keys',
        'wallet',
        'laptop',
        'backpack',
        'glasses',
        'watch',
        'earphones',
        'book',
        'jacket',
      ];
    } catch (e) {
      return [];
    }
  }

  // Save search result interaction
  static Future<void> logSearchResultTap({
    required String searchTerm,
    required String itemId,
    required int position,
  }) async {
    await AnalyticsService.logSearchResultTap(
      searchTerm: searchTerm,
      itemId: itemId,
      position: position,
    );
  }

  // Get search analytics
  static Future<SearchAnalytics> getSearchAnalytics() async {
    try {
      // This would typically come from your analytics service
      // For now, return mock data
      return SearchAnalytics(
        totalSearches: 1250,
        averageResultsPerSearch: 8.5,
        topSearchTerms: [
          SearchTerm('phone', 156),
          SearchTerm('keys', 134),
          SearchTerm('wallet', 98),
          SearchTerm('laptop', 87),
          SearchTerm('backpack', 76),
        ],
        searchSuccessRate: 0.73,
        averageSearchTime: 245, // milliseconds
      );
    } catch (e) {
      return SearchAnalytics.empty();
    }
  }
}

// Data models
class SearchFilters {
  final String? status;
  final String? category;
  final String? location;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? userId;
  final bool? hasImages;
  final bool? isResolved;
  final List<String>? tags;
  final double? latitude;
  final double? longitude;
  final double? maxDistance; // in kilometers
  final SortBy? sortBy;
  final SortOrder? sortOrder;

  SearchFilters({
    this.status,
    this.category,
    this.location,
    this.dateFrom,
    this.dateTo,
    this.userId,
    this.hasImages,
    this.isResolved,
    this.tags,
    this.latitude,
    this.longitude,
    this.maxDistance,
    this.sortBy,
    this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'category': category,
      'location': location,
      'dateFrom': dateFrom?.millisecondsSinceEpoch,
      'dateTo': dateTo?.millisecondsSinceEpoch,
      'userId': userId,
      'hasImages': hasImages,
      'isResolved': isResolved,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
      'maxDistance': maxDistance,
      'sortBy': sortBy?.toString(),
      'sortOrder': sortOrder?.toString(),
    };
  }

  SearchFilters copyWith({
    String? status,
    String? category,
    String? location,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? userId,
    bool? hasImages,
    bool? isResolved,
    List<String>? tags,
    double? latitude,
    double? longitude,
    double? maxDistance,
    SortBy? sortBy,
    SortOrder? sortOrder,
  }) {
    return SearchFilters(
      status: status ?? this.status,
      category: category ?? this.category,
      location: location ?? this.location,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      userId: userId ?? this.userId,
      hasImages: hasImages ?? this.hasImages,
      isResolved: isResolved ?? this.isResolved,
      tags: tags ?? this.tags,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxDistance: maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class SearchResult {
  final List<Map<String, dynamic>> reports;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final bool isFromCache;
  final int totalResults;
  final int searchTime; // in milliseconds
  final String? error;

  SearchResult({
    required this.reports,
    required this.hasMore,
    this.lastDocument,
    required this.isFromCache,
    required this.totalResults,
    required this.searchTime,
    this.error,
  });
}

class SearchAnalytics {
  final int totalSearches;
  final double averageResultsPerSearch;
  final List<SearchTerm> topSearchTerms;
  final double searchSuccessRate;
  final int averageSearchTime;

  SearchAnalytics({
    required this.totalSearches,
    required this.averageResultsPerSearch,
    required this.topSearchTerms,
    required this.searchSuccessRate,
    required this.averageSearchTime,
  });

  factory SearchAnalytics.empty() {
    return SearchAnalytics(
      totalSearches: 0,
      averageResultsPerSearch: 0.0,
      topSearchTerms: [],
      searchSuccessRate: 0.0,
      averageSearchTime: 0,
    );
  }
}

class SearchTerm {
  final String term;
  final int count;

  SearchTerm(this.term, this.count);
}

enum SortBy {
  timestamp,
  title,
  category,
  status,
  location,
  relevance,
  dateDesc,
  dateAsc,
  nameAsc,
  nameDesc,
}

enum SortOrder {
  ascending,
  descending,
}