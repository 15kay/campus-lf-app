import 'package:flutter/material.dart';
import '../models.dart';
import '../services/firebase_service.dart';
import '../services/search_service.dart';
import '../services/analytics_service.dart';

class SearchPage extends StatefulWidget {
  final void Function(Report) onOpenDetails;
  const SearchPage({super.key, required this.onOpenDetails});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  // SearchService uses static methods
  // Analytics service removed - TODO: Implement proper analytics
  
  String _query = '';
  SearchFilters _filters = SearchFilters();
  List<Report> _searchResults = [];
  List<String> _searchSuggestions = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  late AnimationController _filterAnimationController;
  late Animation<double> _filterAnimation;
  late AnimationController _resultsAnimationController;
  late Animation<Offset> _resultsSlideAnimation;

  final List<String> _locations = const [
    'All', 'Library', 'Lecture Hall', 'Cafeteria', 'Admin', 'Residence', 'Parking'
  ];
  final List<String> _categories = const [
    'All', 'Electronics', 'Bags', 'Books', 'Cards', 'Clothing', 'Keys', 'General'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    _resultsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _resultsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultsAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final results = await SearchService.searchReports(filters: _filters);
      final suggestions = <String>[]; // Placeholder for suggestions
      setState(() {
        _searchResults = results.reports.map((data) => Report.fromJson(data)).toList();
        _searchSuggestions = suggestions;
        _isLoading = false;
      });
      _resultsAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query != _query) {
      setState(() => _query = query);
      _performSearch();
    }
  }

  void _performSearch() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await SearchService.searchReports(
        searchTerm: _query.isEmpty ? null : _query,
        filters: _filters,
      );
      setState(() {
        _searchResults = results.reports.map((data) => Report.fromJson(data)).toList();
        _isLoading = false;
      });
      
      // Log search analytics
      if (_query.isNotEmpty) {
        // TODO: Implement search analytics
      }
      
      _resultsAnimationController.reset();
      _resultsAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleFilters() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _clearFilters() {
    setState(() {
      _filters = SearchFilters();
      _searchController.clear();
      _query = '';
    });
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    _resultsAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: CustomScrollView(
        slivers: [
          _buildSearchHeader(),
          if (_showFilters) _buildFiltersSection(),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return SliverToBoxAdapter(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search Lost & Found',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Find what you\'re looking for',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by item name, description...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: const Color(0xFF6366F1),
              size: 24,
            ),
          ),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.grey[500],
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                    _performSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.tune_rounded,
            label: 'Filters',
            isActive: _showFilters,
            onTap: _toggleFilters,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.clear_all_rounded,
            label: 'Clear',
            onTap: _clearFilters,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.sort_rounded,
            label: 'Sort',
            onTap: _showSortOptions,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _filterAnimation,
        builder: (context, child) {
          return SizeTransition(
            sizeFactor: _filterAnimation,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterRow(
                    'Status',
                    _filters.status ?? 'All',
                    ['All', 'Lost', 'Found'],
                    (value) => setState(() {
                      _filters = _filters.copyWith(
                        status: value == 'All' ? null : value,
                      );
                      _performSearch();
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterRow(
                    'Location',
                    _filters.location ?? 'All',
                    _locations,
                    (value) => setState(() {
                      _filters = _filters.copyWith(
                        location: value == 'All' ? null : value,
                      );
                      _performSearch();
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterRow(
                    'Category',
                    _filters.category ?? 'All',
                    _categories,
                    (value) => setState(() {
                      _filters = _filters.copyWith(
                        category: value == 'All' ? null : value,
                      );
                      _performSearch();
                    }),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(
    String title,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: const Color(0xFF6366F1),
              ),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF374151),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => onChanged(value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _resultsSlideAnimation,
        builder: (context, child) {
          return SlideTransition(
            position: _resultsSlideAnimation,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResultsHeader(),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_searchResults.isEmpty)
                    _buildEmptyState()
                  else
                    _buildResultsList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isLoading 
              ? 'Searching...'
              : '${_searchResults.length} result${_searchResults.length != 1 ? 's' : ''} found',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        if (_searchResults.isNotEmpty)
          TextButton.icon(
            onPressed: _showSortOptions,
            icon: Icon(
              Icons.sort_rounded,
              size: 18,
              color: const Color(0xFF6366F1),
            ),
            label: Text(
              'Sort',
              style: TextStyle(
                color: const Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for items...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final report = _searchResults[index];
        return _buildResultCard(report, index);
      },
    );
  }

  Widget _buildResultCard(Report report, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            widget.onOpenDetails(report);
            // TODO: Implement search result click analytics
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: report.status == 'Lost'
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF10B981), const Color(0xFF059669)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    report.status == 'Lost' 
                        ? Icons.search_rounded 
                        : Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.itemName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            report.status,
                            report.status == 'Lost' 
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            report.location,
                            const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            report.category,
                            const Color(0xFF8B5CF6),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort by',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSortOption('Newest First', SortBy.dateDesc),
                    _buildSortOption('Oldest First', SortBy.dateAsc),
                    _buildSortOption('A-Z', SortBy.nameAsc),
                    _buildSortOption('Z-A', SortBy.nameDesc),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, SortBy sortBy) {
    final isSelected = _filters.sortBy == sortBy;
    
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF374151),
        ),
      ),
      trailing: isSelected 
          ? Icon(
              Icons.check_rounded,
              color: const Color(0xFF6366F1),
            )
          : null,
      onTap: () {
        setState(() {
          _filters = _filters.copyWith(sortBy: sortBy);
        });
        _performSearch();
        Navigator.pop(context);
      },
    );
  }
}