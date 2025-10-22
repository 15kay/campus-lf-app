import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, int> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await FirebaseService.getReportsStatistics();
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.report), text: 'Reports'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildReportsTab(),
          _buildUsersTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatisticsGrid(),
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    final mainStats = [
      {'title': 'Total Reports', 'value': _statistics['total'] ?? 0, 'icon': Icons.report, 'color': Colors.blue},
      {'title': 'Lost Items', 'value': _statistics['lost'] ?? 0, 'icon': Icons.search, 'color': Colors.red},
      {'title': 'Found Items', 'value': _statistics['found'] ?? 0, 'icon': Icons.check_circle, 'color': Colors.green},
      {'title': 'Resolved', 'value': _statistics['resolved'] ?? 0, 'icon': Icons.done_all, 'color': Colors.purple},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: mainStats.length,
      itemBuilder: (context, index) {
        final stat = mainStats[index];
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 32,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  '${stat['value']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stat['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<List<Report>>(
      stream: FirebaseService.getAllReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];
        final recentReports = reports.take(5).toList();

        return Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentReports.length,
            itemBuilder: (context, index) {
              final report = recentReports[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: report.type == 'Lost' ? Colors.red : Colors.green,
                  child: Icon(
                    report.type == 'Lost' ? Icons.search : Icons.check_circle,
                    color: Colors.white,
                  ),
                ),
                title: Text(report.itemName),
                subtitle: Text('${report.type} • ${report.location}'),
                trailing: Chip(
                  label: Text(
                    report.status,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: report.status == 'Resolved' 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    return StreamBuilder<List<Report>>(
      stream: FirebaseService.getAllReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final reports = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: report.type == 'Lost' ? Colors.red : Colors.green,
                  child: Icon(
                    report.type == 'Lost' ? Icons.search : Icons.check_circle,
                    color: Colors.white,
                  ),
                ),
                title: Text(report.itemName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${report.type} • ${report.category}'),
                    Text('Location: ${report.location}'),
                    Text('Status: ${report.status}'),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleReportAction(value, report),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'resolve',
                      child: Text('Mark as Resolved'),
                    ),
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('Mark as Pending'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Report'),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<UserProfile>>(
      stream: FirebaseService.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF075E54),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    Text('Phone: ${user.phone}'),
                    if (user.isAdmin) 
                      const Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleUserAction(value, user),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: user.isAdmin ? 'remove_admin' : 'make_admin',
                      child: Text(user.isAdmin ? 'Remove Admin' : 'Make Admin'),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleReportAction(String action, Report report) async {
    try {
      switch (action) {
        case 'resolve':
          await FirebaseService.updateReportStatus(report.reportId, 'Resolved');
          break;
        case 'pending':
          await FirebaseService.updateReportStatus(report.reportId, 'Pending');
          break;
        case 'delete':
          final confirmed = await _showDeleteConfirmation();
          if (confirmed) {
            await FirebaseService.deleteReportAsAdmin(report.reportId);
          }
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action completed successfully')),
        );
      }
      
      // Refresh statistics
      _loadStatistics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleUserAction(String action, UserProfile user) async {
    try {
      switch (action) {
        case 'make_admin':
          await FirebaseService.setUserAdminStatus(user.uid, true);
          break;
        case 'remove_admin':
          await FirebaseService.setUserAdminStatus(user.uid, false);
          break;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User status updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }
}