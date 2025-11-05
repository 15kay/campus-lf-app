import 'package:flutter/material.dart';

class UserManagement extends StatefulWidget {
  final bool isDarkMode;

  const UserManagement({super.key, required this.isDarkMode});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _userTypeFilter = 'All';

  final List<User> _users = _generateMockUsers();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildUserStats(),
          const SizedBox(height: 24),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllUsers(),
                _buildActiveUsers(),
                _buildBannedUsers(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Manage campus users and permissions',
              style: TextStyle(
                fontSize: 16,
                color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _exportUsers,
              icon: const Icon(Icons.download),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserStats() {
    final totalUsers = _users.length;
    final activeUsers = _users.where((u) => u.status == UserStatus.active).length;
    final bannedUsers = _users.where((u) => u.status == UserStatus.banned).length;
    final studentsCount = _users.where((u) => u.type == UserType.student).length;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Users', totalUsers.toString(), Icons.people, Colors.blue)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Active', activeUsers.toString(), Icons.check_circle, Colors.green)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Students', studentsCount.toString(), Icons.school, Colors.orange)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Banned', bannedUsers.toString(), Icons.block, Colors.red)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey.shade400, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: widget.isDarkMode ? Colors.white70 : Colors.grey.shade600,
        tabs: const [
          Tab(text: 'All Users'),
          Tab(text: 'Active'),
          Tab(text: 'Banned'),
        ],
      ),
    );
  }

  Widget _buildAllUsers() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildSearchAndFilter(),
        const SizedBox(height: 16),
        Expanded(child: _buildUsersTable(_getFilteredUsers())),
      ],
    );
  }

  Widget _buildActiveUsers() {
    final activeUsers = _users.where((u) => u.status == UserStatus.active).toList();
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(child: _buildUsersTable(activeUsers)),
      ],
    );
  }

  Widget _buildBannedUsers() {
    final bannedUsers = _users.where((u) => u.status == UserStatus.banned).toList();
    return Column(
      children: [
        const SizedBox(height: 16),
        Expanded(child: _buildUsersTable(bannedUsers)),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
            ),
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _userTypeFilter,
          dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A3E) : Colors.white,
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
          ),
          items: ['All', 'Student', 'Staff', 'Admin'].map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) => setState(() => _userTypeFilter = value!),
        ),
      ],
    );
  }

  Widget _buildUsersTable(List<User> users) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          headingTextStyle: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          dataTextStyle: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
          columns: const [
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Reports')),
            DataColumn(label: Text('Karma')),
            DataColumn(label: Text('Last Active')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) => _buildUserRow(user)).toList(),
        ),
      ),
    );
  }

  DataRow _buildUserRow(User user) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _getUserTypeColor(user.type),
                child: Text(
                  user.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getUserTypeColor(user.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.type.name.toUpperCase(),
              style: TextStyle(
                color: _getUserTypeColor(user.type),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(user.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.status.name.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(user.status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(Text(user.reportsCount.toString())),
        DataCell(Text(user.karma.toString())),
        DataCell(Text(_formatLastActive(user.lastActive))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () => _editUser(user),
                tooltip: 'Edit User',
              ),
              IconButton(
                icon: Icon(
                  user.status == UserStatus.banned ? Icons.check : Icons.block,
                  size: 18,
                  color: user.status == UserStatus.banned ? Colors.green : Colors.red,
                ),
                onPressed: () => _toggleUserStatus(user),
                tooltip: user.status == UserStatus.banned ? 'Unban User' : 'Ban User',
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<User> _getFilteredUsers() {
    return _users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _userTypeFilter == 'All' ||
          user.type.name.toLowerCase() == _userTypeFilter.toLowerCase();

      return matchesSearch && matchesType;
    }).toList();
  }

  Color _getUserTypeColor(UserType type) {
    switch (type) {
      case UserType.student:
        return Colors.blue;
      case UserType.staff:
        return Colors.green;
      case UserType.admin:
        return Colors.purple;
    }
  }

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.orange;
      case UserStatus.banned:
        return Colors.red;
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Online';
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text('Add user functionality coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editUser(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${user.name}'),
        content: const Text('Edit user functionality coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(User user) {
    setState(() {
      user.status = user.status == UserStatus.banned 
          ? UserStatus.active 
          : UserStatus.banned;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${user.name} has been ${user.status == UserStatus.banned ? 'banned' : 'unbanned'}',
        ),
        backgroundColor: user.status == UserStatus.banned ? Colors.red : Colors.green,
      ),
    );
  }

  void _exportUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting users data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  static List<User> _generateMockUsers() {
    return [
      User(
        id: '1',
        name: 'John Doe',
        email: '202012345@mywsu.ac.za',
        type: UserType.student,
        status: UserStatus.active,
        reportsCount: 5,
        karma: 150,
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      User(
        id: '2',
        name: 'Sarah Wilson',
        email: 's+wilson@wsu.ac.za',
        type: UserType.staff,
        status: UserStatus.active,
        reportsCount: 12,
        karma: 280,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      User(
        id: '3',
        name: 'Mike Johnson',
        email: 'admin@wsu.ac.za',
        type: UserType.admin,
        status: UserStatus.active,
        reportsCount: 0,
        karma: 500,
        lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      User(
        id: '4',
        name: 'Emma Brown',
        email: '202012346@mywsu.ac.za',
        type: UserType.student,
        status: UserStatus.banned,
        reportsCount: 2,
        karma: 50,
        lastActive: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final UserType type;
  UserStatus status;
  final int reportsCount;
  final int karma;
  final DateTime lastActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.status,
    required this.reportsCount,
    required this.karma,
    required this.lastActive,
  });
}

enum UserType { student, staff, admin }
enum UserStatus { active, inactive, banned }