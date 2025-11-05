import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../services/mock_realtime_service.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'report_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'forum_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  int _userKarma = 285;
  dynamic _dataService; // RealtimeService or MockRealtimeService
  bool _isGuest = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initService();
    _loadUserKarma();
  }

  Future<void> _initService() async {
    final isGuest = await AuthService.isGuest();
    final service = isGuest ? MockRealtimeService() : RealtimeService();
    
    if (mounted) {
      setState(() {
        _dataService = service;
        _isGuest = isGuest;
        _isInitialized = true;
      });
      
      _ensureData();
    }
  }

  Future<void> _ensureData() async {
    if (_dataService is RealtimeService) {
      await (_dataService).ensureSampleData();
    }
  }

  Future<void> _loadUserKarma() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userKarma = prefs.getInt('user_karma') ?? 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userKarma = 0;
        });
      }
    }
  }

  void _addKarma(int points) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userKarma += points;
        });
        await prefs.setInt('user_karma', _userKarma);
      }
    } catch (e) {
      // Silently fail - karma update is not critical
    }
  }

  void _addItem(Item item) async {
    if (_dataService == null) return;
    
    try {
      await _dataService.addItem(item);
      _addKarma(10);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _dataService == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return StreamBuilder<List<Item>>(
      stream: _dataService.getItemsStream(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        
        final List<Widget> pages = [
          HomeScreen(items: items, userKarma: _userKarma, onKarmaUpdate: _addKarma),
          ReportScreen(onSubmit: _addItem),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _dataService.getForumPostsStream(),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              return ForumScreen(posts: posts);
            },
          ),
          FutureBuilder<String?>(
            future: AuthService.getCurrentUserEmail(),
            builder: (context, emailSnapshot) {
              final userEmail = emailSnapshot.data ?? '';
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _dataService.getMessagesStream(userEmail),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];
                  return MessagesScreen(messages: messages);
                },
              );
            },
          ),
          ProfileScreen(userKarma: _userKarma, totalItems: items.length, items: items),
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              if (_isGuest)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFFFF59D), // Amber 200
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.black87, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Guest mode: using mock data only. Sign in to save data to Firebase.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: pages,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: () async {
              await AuthService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  this.context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            tooltip: 'Exit to Login',
            child: const Icon(Icons.exit_to_app, color: Colors.white),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: Colors.black,
              unselectedItemColor: const Color(0xFF8E8E93),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 24),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline, size: 24),
                  label: 'Report',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.forum_outlined, size: 24),
                  label: 'Forum',
                ),
                BottomNavigationBarItem(
                  icon: FutureBuilder<String?>(
                    future: AuthService.getCurrentUserEmail(),
                    builder: (context, emailSnapshot) {
                      final userEmail = emailSnapshot.data ?? '';
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _dataService.getMessagesStream(userEmail),
                        builder: (context, snapshot) {
                          final messages = snapshot.data ?? [];
                          final unreadCount = messages.where((m) => !(m['isRead'] ?? true)).length;
                          return Stack(
                            children: [
                              const Icon(Icons.message, size: 24),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  label: 'Messages',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 24),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}