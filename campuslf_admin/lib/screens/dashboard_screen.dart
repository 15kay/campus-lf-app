import 'package:flutter/material.dart';
import 'dart:async';
import '../models/item.dart';
import '../services/realtime_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/live_analytics_chart.dart';
import '../services/forum_service_admin.dart';
import 'dart:html' as html;
import '../services/users_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Item> _items = [];
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _users = {};
  List<Map<String, dynamic>> _messages = [];
  Map<String, int> _categoryStats = {};
  late AnimationController _animationController;
  final _realtimeService = RealtimeService();
  final _usersService = UsersService();
  final _forumService = ForumServiceAdmin();
  StreamSubscription? _itemsSubscription;
  StreamSubscription? _statsSubscription;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _categorySubscription;
  StreamSubscription? _usersRealSubscription;
  List<Map<String, dynamic>> _usersReal = [];
  List<Map<String, dynamic>> _forumPosts = [];
  StreamSubscription? _forumSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Defer heavy real-time subscriptions to after first frame for faster first paint
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRealTimeUpdates();
    });
  }

  void _startRealTimeUpdates() {
    _realtimeService.startListening();
    
    _itemsSubscription = _realtimeService.itemsStream.listen((items) {
      if (mounted) setState(() => _items = items);
    });
    
    _statsSubscription = _realtimeService.statsStream.listen((analytics) {
      if (mounted) setState(() => _analytics = analytics);
    });
    
    _usersSubscription = _realtimeService.usersStream.listen((users) {
      if (mounted) setState(() => _users = users);
    });
    
    _messagesSubscription = _realtimeService.messagesStream.listen((messages) {
      if (mounted) setState(() => _messages = messages);
    });
    
    _categorySubscription = _realtimeService.categoryStatsStream.listen((stats) {
      if (mounted) setState(() => _categoryStats = stats);
    });

    _usersRealSubscription = _usersService.getUsersStream().listen((list) {
      if (mounted) setState(() => _usersReal = list);
    });

    _forumSubscription = _forumService.getPostsStream().listen((posts) {
      if (mounted) setState(() => _forumPosts = posts);
    });
  }

  @override
  void dispose() {
    _itemsSubscription?.cancel();
    _statsSubscription?.cancel();
    _usersSubscription?.cancel();
    _messagesSubscription?.cancel();
    _categorySubscription?.cancel();
    _usersRealSubscription?.cancel();
    _forumSubscription?.cancel();
    _realtimeService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D3A),
        title: const Text('WSU Admin', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildMobileDrawer(),
      body: _buildMainContent(),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A1D3A),
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: const Color(0xFF1A1D3A),
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent() {
    final items = [
      {'icon': Icons.dashboard, 'title': 'Dashboard'},
      {'icon': Icons.inventory, 'title': 'Items'},
      {'icon': Icons.analytics, 'title': 'Analytics'},
      {'icon': Icons.forum, 'title': 'Forum'},
      {'icon': Icons.people, 'title': 'Users'},
      {'icon': Icons.message, 'title': 'Messages'},
      {'icon': Icons.settings, 'title': 'Settings'},
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'WSU Admin',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedIndex == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF667EEA).withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: const Color(0xFF667EEA), width: 1) : null,
                ),
                child: ListTile(
                  leading: Icon(
                    items[index]['icon'] as IconData,
                    color: isSelected ? const Color(0xFF667EEA) : Colors.white70,
                  ),
                  title: Text(
                    items[index]['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (ResponsiveLayout.isMobile(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return _buildItemsManagement();
      case 2: return _buildAnalytics();
      case 3: return _buildForum();
      case 4: return _buildUsers();
      case 5: return _buildMessages();
      case 6: return _buildSettings();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Dashboard', 'Real-time campus monitoring'),
          const SizedBox(height: 32),
          _buildStatsGrid(),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildChart(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildRecentActivity(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 8),
              const SizedBox(width: 8),
              const Text('Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: () async {
                  // Logout and navigate back to Login
                  await AuthService.logout();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildStatsGrid() {
    final stats = [
      {'title': 'Total Items', 'value': '${_analytics['totalItems'] ?? 0}', 'icon': Icons.inventory, 'color': const Color(0xFF667EEA)},
      {'title': 'Lost Items', 'value': '${_analytics['lostItems'] ?? 0}', 'icon': Icons.search_off, 'color': const Color(0xFFFF6B6B)},
      {'title': 'Found Items', 'value': '${_analytics['foundItems'] ?? 0}', 'icon': Icons.check_circle, 'color': const Color(0xFF4ECDC4)},
      {'title': 'Active Users', 'value': '${_users['activeUsers'] ?? 0}', 'icon': Icons.people, 'color': const Color(0xFF45B7D1)},
    ];

    return ResponsiveBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 768) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D3A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      stat['icon'] as IconData,
                      color: stat['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const Icon(Icons.trending_up, color: Colors.green, size: 16),
                ],
              ),
              const Spacer(),
              Text(
                stat['value'] as String,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
      },
    );
  }



  Widget _buildItemsManagement() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Items Management', 'Manage lost and found items'),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D3A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0E27),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: item.isLost ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Item.getCategoryIcon(item.category),
                                  color: item.isLost ? Colors.red : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      item.description,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${item.location} • ${item.getTimeAgo()}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: item.isLost ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.isLost ? 'Lost' : 'Found',
                                  style: TextStyle(
                                    color: item.isLost ? Colors.red : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Analytics', 'Performance insights and reports'),
          const SizedBox(height: 32),
          _buildStatsGrid(),
        ],
      ),
    );
  }

  Widget _buildUsers() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('User Management', 'Manage system users'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (q) => setState(() {
                          _usersReal = _usersReal.where((u) {
                            final name = (u['name'] ?? '').toString().toLowerCase();
                            final email = (u['email'] ?? '').toString().toLowerCase();
                            return name.contains(q.toLowerCase()) || email.contains(q.toLowerCase());
                          }).toList();
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _usersReal.isEmpty
                    ? const Center(
                        child: Text('No users found', style: TextStyle(color: Colors.white70)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _usersReal.length,
                        itemBuilder: (context, index) {
                          final user = _usersReal[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0E27),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (user['name'] ?? 'Unknown') as String,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        (user['email'] ?? '') as String,
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                      ),
                                      Text(
                                        'Status: ${(user['status'] ?? 'active')}',
                                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  color: const Color(0xFF1A1D3A),
                                  iconColor: Colors.white70,
                                  onSelected: (value) async {
                                    if (value.startsWith('status:')) {
                                      final status = value.split(':').last;
                                      await _usersService.updateUserStatus(user['uid'] as String, status);
                                    } else if (value == 'role_admin') {
                                      await _usersService.updateUserRole(user['uid'] as String, 'admin');
                                    } else if (value == 'role_user') {
                                      await _usersService.updateUserRole(user['uid'] as String, 'user');
                                    } else if (value == 'delete') {
                                      await _usersService.deleteUserDoc(user['uid'] as String);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'status:active', child: Text('Set Active', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'status:inactive', child: Text('Set Inactive', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'status:banned', child: Text('Ban User', style: TextStyle(color: Colors.white))),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(value: 'role_admin', child: Text('Mark as Admin (doc only)', style: TextStyle(color: Colors.white))),
                                    const PopupMenuItem(value: 'role_user', child: Text('Mark as User (doc only)', style: TextStyle(color: Colors.white))),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(value: 'delete', child: Text('Delete User Doc', style: TextStyle(color: Colors.white))),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Messages', 'Monitor user conversations'),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D3A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search conversations...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle, color: Colors.green, size: 8),
                            const SizedBox(width: 8),
                            Text(
                              '${_messages.length} Active',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _messages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message_outlined, size: 64, color: Colors.white30),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'User conversations will appear here',
                                  style: TextStyle(fontSize: 14, color: Colors.white54),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A0E27),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: const Icon(Icons.chat_bubble, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                message['itemTitle'] ?? 'Unknown Item',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                _formatMessageTime(message['lastMessageTime']),
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            message['lastMessage'] ?? '',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Settings', 'System configuration'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D3A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Center(
              child: Text(
                'System Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildChart() {
    // Avoid building chart until analytics are ready
    if (_analytics.isEmpty || (_analytics['totalItems'] ?? 0) == 0) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D3A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text(
            'Loading analytics...',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return LiveAnalyticsChart(
      analytics: _analytics,
      categoryStats: _categoryStats,
    );
  }

  Widget _buildForum() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('Forum Management', 'Manage posts and comments'),
          const SizedBox(height: 32),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreatePostDialog(),
                icon: const Icon(Icons.post_add),
                label: const Text('New Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _exportPostsCsv,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Export CSV', style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _forumPosts.isEmpty
                ? const Center(child: Text('No forum posts yet', style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: _forumPosts.length,
                    itemBuilder: (context, index) {
                      final post = _forumPosts[index];
                      return _buildForumPostCard(post);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildForumPostCard(Map<String, dynamic> post) {
    final commentsStream = _forumService.getCommentsStream(post['id'] as String);
    final category = (post['category'] ?? 'General') as String;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(post['content'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text('Category: $category • Author: ${post['userName']}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1A1D3A),
                iconColor: Colors.white70,
                onSelected: (value) async {
                  if (value.startsWith('category:')) {
                    final cat = value.split(':').last;
                    await _forumService.updatePost(post['id'] as String, {'category': cat});
                  } else if (value == 'delete') {
                    await _forumService.deletePost(post['id'] as String);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'category:General', child: Text('Set Category: General', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: 'category:Lost', child: Text('Set Category: Lost', style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: 'category:Found', child: Text('Set Category: Found', style: TextStyle(color: Colors.white))),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Text('Delete Post', style: TextStyle(color: Colors.white))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Text('Comments', style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: commentsStream,
            builder: (context, snapshot) {
              final comments = snapshot.data ?? [];
              return Column(
                children: [
                  for (final c in comments)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0E27),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${c['userName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text('${c['text']}', style: TextStyle(color: Colors.white.withOpacity(0.9))),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _forumService.deleteComment(post['id'] as String, c['id'] as String);
                            },
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          ),
                        ],
                      ),
                    ),
                  _buildAddCommentField(post['id'] as String),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommentField(String postId) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            await _forumService.addComment(postId: postId, text: text, adminName: 'Admin');
            controller.clear();
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
          child: const Text('Send'),
        ),
      ],
    );
  }

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'General';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D3A),
        title: const Text('Create New Post', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: category,
              dropdownColor: const Color(0xFF1A1D3A),
              items: const [
                DropdownMenuItem(value: 'General', child: Text('General', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Lost', child: Text('Lost', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'Found', child: Text('Found', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => category = v ?? 'General',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) return;
              await _forumService.addPost(title: title, content: content, category: category, adminName: 'Admin');
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _exportPostsCsv() {
    final rows = <List<String>>[
      ['id', 'title', 'content', 'category', 'userName', 'createdAt'],
      ..._forumPosts.map((p) => [
            (p['id'] ?? '').toString(),
            (p['title'] ?? '').toString(),
            (p['content'] ?? '').toString(),
            (p['category'] ?? '').toString(),
            (p['userName'] ?? '').toString(),
            (p['createdAt'] ?? '').toString(),
          ]),
    ];
    final csv = rows.map((r) => r.map(_escapeCsv).join(',')).join('\n');
    final bytes = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(bytes);
    final anchor = html.AnchorElement(href: url)
      ..download = 'forum_posts.csv'
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  String _escapeCsv(String input) {
    final needsQuotes = input.contains(',') || input.contains('\n') || input.contains('"');
    var s = input.replaceAll('"', '""');
    return needsQuotes ? '"$s"' : s;
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _items.take(5).length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E27),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.isLost ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.isLost ? Icons.search_off : Icons.check_circle,
                          color: item.isLost ? Colors.red : Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.getTimeAgo(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }








}