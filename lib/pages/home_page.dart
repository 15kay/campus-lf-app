import 'package:flutter/material.dart';
import '../models.dart';
import '../services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_page.dart';
import 'chat_page.dart';
import 'my_reports_page.dart';

class HomePage extends StatelessWidget {
  final void Function(Report) onOpenDetails;
  final VoidCallback onCreateReport;
  const HomePage({super.key, required this.onOpenDetails, required this.onCreateReport});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Report>>(
      stream: FirebaseService.getAllReportsStream(),
      builder: (context, snapshot) {
        final allReports = snapshot.data ?? [];
        
        // Show all reports to all users
        final reports = allReports;
            
        return _buildContent(context, reports);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Report> reports) {
    final categories = {
      'Bags': Icons.backpack,
      'Electronics': Icons.memory,
      'Keys': Icons.vpn_key,
      'Cards': Icons.credit_card,
      'Clothing': Icons.checkroom,
      'Books': Icons.menu_book,
    };

    // Fallback name for welcome banner
    final fallbackFirst = (FirebaseAuth.instance.currentUser?.displayName ?? '')
        .trim()
        .split(' ')
        .firstOrNull ?? (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'User');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern Hero Section
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1), // Modern Indigo
                        const Color(0xFF8B5CF6), // Modern Purple
                        const Color(0xFF06B6D4), // Modern Cyan
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Professional Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'web/CampusLF_Logo.png',
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.school_rounded,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // App Title
                      Text(
                        'Campus Lost & Found',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Welcome Message
                      Text(
                        'Welcome back, ${fallbackFirst.isEmpty ? 'Student' : fallbackFirst}!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your trusted platform for campus lost & found items',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Search Bar Section
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search for lost or found items...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.filter_list_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                           Navigator.of(context).push(
                             MaterialPageRoute(builder: (_) => SearchPage(onOpenDetails: onOpenDetails)),
                           );
                         },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => SearchPage(onOpenDetails: onOpenDetails)),
                       );
                     },
                    readOnly: true,
                  ),
                ),
                const SizedBox(height: 24),
                // Dashboard Statistics Section
                Text(
                  'Dashboard Overview', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatisticsCards(context, reports),
                const SizedBox(height: 32),
                // Professional Quick Actions Section
                Text(
                  'Quick Actions', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Report Item'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: onCreateReport,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.search_rounded, size: 20),
                        label: const Text('Search Items'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const _QuickSearchPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.folder_open_rounded, size: 20),
                        label: const Text('My Reports'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () => _navigateToMyReports(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Professional Categories Section
                Text(
                  'Browse Categories', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.entries.map((e) {
                      final isSelected = reports.any((r) => r.category == e.key);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text(
                            e.key,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          avatar: Icon(
                            e.value, 
                            size: 18,
                            color: isSelected 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                          ),
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          side: BorderSide(
                            color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          onSelected: (_) {},
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Reports', 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            height: 300,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (ctx, i) {
                final r = reports.isNotEmpty ? reports[i % reports.length] : null;
                if (r == null) return const SizedBox.shrink();
                return Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onOpenDetails(r),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image section
                          Container(
                            height: 110,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              color: r.imageBytes == null 
                                ? Theme.of(context).colorScheme.surfaceContainerHighest
                                : null,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: r.imageBytes != null
                                ? Image.memory(
                                    r.imageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context).colorScheme.surfaceContainerHighest,
                                          Theme.of(context).colorScheme.surfaceContainer,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            r.status == 'Lost' ? Icons.search_rounded : Icons.inventory_2_rounded,
                                            size: 32,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'No Image',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          // Content section
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                  // Title and status row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.itemName,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(r.status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                r.status,
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: _getStatusColor(r.status),
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: r.status == 'Lost' 
                                            ? Theme.of(context).colorScheme.errorContainer
                                            : Theme.of(context).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          r.status == 'Lost' ? Icons.search_rounded : Icons.check_circle_rounded,
                                          color: r.status == 'Lost' 
                                            ? Theme.of(context).colorScheme.onErrorContainer
                                            : Theme.of(context).colorScheme.onPrimaryContainer,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  // Location and time info
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                r.location,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatDate(r.date),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Contact button for other users' reports
                                  if (r.uid != FirebaseAuth.instance.currentUser?.uid) ...[
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _contactReporter(context, r),
                                        icon: const Icon(Icons.chat_bubble_outline, size: 14),
                                        label: const Text('Contact', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orange.shade700,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          minimumSize: const Size(0, 24),
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Resolution buttons for unresolved items
                                  if (r.status != 'Resolved' && r.status != 'Returned') ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showResolutionDialog(context, r, 'Resolved'),
                                            icon: const Icon(Icons.check_circle, size: 14),
                                            label: const Text('Resolved', style: TextStyle(fontSize: 11)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green.shade700,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              minimumSize: const Size(0, 24),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showResolutionDialog(context, r, 'Returned'),
                                            icon: const Icon(Icons.assignment_return, size: 14),
                                            label: const Text('Returned', style: TextStyle(fontSize: 11)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.blue.shade700,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              minimumSize: const Size(0, 24),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemCount: reports.length < 5 ? reports.length : 5,
            ),
          ),
        ),
        // Add section header for latest reports
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text('Latest Reports', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ),
        SliverList.builder(
          itemCount: reports.length,
          itemBuilder: (ctx, i) {
            final r = reports[i];
            return Card(
              elevation: 2,
              child: InkWell(
                onTap: () => onOpenDetails(r),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Image or icon container
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: r.imageBytes != null 
                            ? null 
                            : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE0C200)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: r.imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                r.imageBytes!,
                                fit: BoxFit.cover,
                                width: 60,
                                height: 60,
                              ),
                            )
                          : Icon(
                              r.status == 'Lost' ? Icons.search : Icons.check_circle, 
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Wrap(spacing: 8, runSpacing: 4, children: [
                              _tag(r.status, color: _getStatusColor(r.status)),
                              _tag(r.location),
                              _tag(r.category),
                            ]),
                            const SizedBox(height: 6),
                            Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Contact button - always visible for other users' reports
                                if (r.uid != FirebaseAuth.instance.currentUser?.uid) ...[
                                  TextButton.icon(
                                    onPressed: () => _contactReporter(context, r),
                                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                    label: const Text('Contact'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.orange.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                // Resolution buttons - only for unresolved items
                                if (r.status != 'Resolved' && r.status != 'Returned') ...[
                                  TextButton.icon(
                                    onPressed: () => _showResolutionDialog(context, r, 'Resolved'),
                                    icon: const Icon(Icons.check_circle, size: 16),
                                    label: const Text('Mark Resolved'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _showResolutionDialog(context, r, 'Returned'),
                                    icon: const Icon(Icons.assignment_return, size: 16),
                                    label: const Text('Returned'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue.shade700,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _tag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF1B5E20)).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: (color ?? const Color(0xFF1B5E20)).withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color ?? const Color(0xFF1B5E20), fontSize: 12)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Lost':
        return Colors.red.shade600;
      case 'Found':
        return Colors.green.shade700;
      case 'Resolved':
        return Colors.blue.shade700;
      case 'Returned':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showResolutionDialog(BuildContext context, Report report, String newStatus) {
    final TextEditingController notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as $newStatus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to mark "${report.itemName}" as $newStatus?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Resolution Notes (Optional)',
                hintText: 'Add any additional details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final currentUser = FirebaseService.getCurrentUser();
                if (currentUser != null) {
                  await FirebaseService.resolveReport(
                    report.reportId,
                    currentUser.uid,
                    newStatus,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Item marked as $newStatus successfully!')),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Mark as $newStatus'),
          ),
        ],
      ),
    );
  }

  void _contactReporter(BuildContext context, Report report) async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to contact the reporter')),
        );
        return;
      }

      if (report.uid == currentUser.uid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot contact yourself')),
        );
        return;
      }

      // Get the other user's information
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(report.uid)
          .get();
      
      if (!otherUserDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
        return;
      }

      final otherUserData = otherUserDoc.data()!;
      final otherUserName = otherUserData['name'] ?? 'Unknown User';

      // Create conversation object
      final sortedUids = [currentUser.uid, report.uid]..sort();
      final conversationId = '${sortedUids[0]}_${sortedUids[1]}';
      
      final conversation = Conversation(
        id: conversationId,
        participants: [currentUser.uid, report.uid],
        messages: [],
        lastActivity: DateTime.now(),
      );

      // Create chat entry so both users can see the conversation in their chat list
      final chatId = conversationId;
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'participants': [currentUser.uid, report.uid],
        'lastMessage': 'Chat started about: ${report.itemName}',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'conversationId': conversationId,
        'unreadCount_${currentUser.uid}': 0,
        'unreadCount_${report.uid}': 1,
      }, SetOptions(merge: true));

      // Navigate to chat page
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(conversation: conversation),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting chat: $e')),
      );
    }
  }

  Widget _buildStatisticsCards(BuildContext context, List<Report> reports) {
    final totalReports = reports.length;
    final lostItems = reports.where((r) => r.status == 'Lost').length;
    final foundItems = reports.where((r) => r.status == 'Found').length;
    final recentReports = reports.where((r) => 
      DateTime.now().difference(r.timestamp).inDays <= 7
    ).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Reports',
            totalReports.toString(),
            Icons.assignment_rounded,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Lost Items',
            lostItems.toString(),
            Icons.search_rounded,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Found Items',
            foundItems.toString(),
            Icons.check_circle_rounded,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'This Week',
            recentReports.toString(),
            Icons.schedule_rounded,
            Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMyReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyReportsPage(),
      ),
    );
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
}

class _QuickSearchPage extends StatelessWidget {
  const _QuickSearchPage();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Search')),
      body: StreamBuilder<List<Report>>(
        stream: FirebaseService.getAllReportsStream(),
        builder: (context, snapshot) {
          final allReports = snapshot.data ?? [];
          
          // Show all reports to all users
          final reports = allReports;
              
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (ctx, i) {
              final r = reports[i];
              return ListTile(
                leading: CircleAvatar(backgroundColor: Colors.grey.shade300, child: Icon(r.status == 'Lost' ? Icons.search : Icons.check_circle)),
                title: Text(r.itemName),
                subtitle: Text('${r.status} • ${r.location}'),
                onTap: () => Navigator.pop(context),
              );
            },
          );
        },
      ),
    );
  }
}