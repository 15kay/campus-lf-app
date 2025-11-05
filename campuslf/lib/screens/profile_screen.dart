import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';

import 'messages_screen.dart';
import 'my_reports_screen.dart';
import 'account_settings_screen.dart';
import 'report_screen.dart';
import 'search_screen.dart';
import 'campus_map_screen.dart';
import 'analytics_screen.dart';
import 'user_manual_screen.dart';
import 'help_agent_screen.dart';
import 'change_password_screen.dart';
import 'privacy_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userKarma;
  final int totalItems;
  final List<Item> items;

  const ProfileScreen({super.key, required this.userKarma, required this.totalItems, required this.items});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, String?> _userData = {};
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final data = await AuthService.getUserRegistrationData();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 20),
                    _buildProfileDetails(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildSettingsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _userData['name'] ?? 'User';
    final email = _userData['email'] ?? 'user@wsu.ac.za';
    final studentId = _userData['studentId'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          if (studentId.isNotEmpty)
            Text(
              'Student ID: $studentId',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeaderStat('${widget.userKarma}', 'Karma', Icons.star),
              _buildHeaderStat('${widget.totalItems}', 'Reports', Icons.report),
              _buildHeaderStat('Active', 'Status', Icons.verified),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }



  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('${widget.userKarma}', 'Karma Points', Icons.star, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('${widget.totalItems}', 'Total Reports', Icons.report, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('${_getResolvedCount()}', 'Resolved', Icons.check_circle, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    final name = _userData['name'] ?? 'User';
    final email = _userData['email'] ?? 'user@wsu.ac.za';
    final studentId = _userData['studentId'] ?? '';
    final phone = _userData['phone'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow(Icons.person_outline, 'Full Name', name),
          if (studentId.isNotEmpty) _buildDetailRow(Icons.badge_outlined, 'Student ID', studentId),
          _buildDetailRow(Icons.email_outlined, 'Email Address', email),
          if (phone.isNotEmpty && phone != '+27 ') _buildDetailRow(Icons.phone_outlined, 'Phone Number', phone),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildActionCard('Report Item', Icons.add_circle_outline, Colors.blue),
              _buildActionCard('My Reports', Icons.list_alt_outlined, Colors.green),
              _buildActionCard('Messages', Icons.message_outlined, Colors.purple),
              _buildActionCard('Search Items', Icons.search_outlined, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _handleAction(context, title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingTile('Notifications', Icons.notifications_outlined, hasSwitch: true),
        _buildSettingTile('Account settings', Icons.settings_outlined),
        _buildSettingTile('Change password', Icons.lock_outline),
        _buildSettingTile('User Manual', Icons.book_outlined),
        _buildSettingTile('Help Assistant', Icons.support_agent_outlined),
        _buildSettingTile('Help & support', Icons.help_outline),
        _buildSettingTile('Privacy policy', Icons.privacy_tip_outlined),
        _buildSettingTile('About', Icons.info_outline),
        _buildSettingTile('Logout', Icons.logout, isLogout: true),
      ],
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'Report Item':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportScreen(
              onSubmit: (item) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item reported successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        );
        break;
      case 'My Reports':
        _showMyReports(context);
        break;
      case 'Messages':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesScreen(messages: [])),
        );
        break;
      case 'Search Items':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(items: widget.items),
          ),
        );
        break;
      case 'Campus Map':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampusMapScreen(items: widget.items),
          ),
        );
        break;
      case 'Analytics':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalyticsScreen(items: widget.items),
          ),
        );
        break;
      case 'Achievements':
        _showAchievements(context);
        break;
    }
  }

  Widget _buildSettingTile(String title, IconData icon, {bool hasSwitch = false, bool isLogout = false}) {
    return Builder(
      builder: (context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: isLogout ? Colors.red : Colors.grey.shade700, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: isLogout ? Colors.red : Colors.black,
            ),
          ),
          trailing: hasSwitch 
            ? Switch(
                value: _notificationsEnabled,
                onChanged: (value) async {
                  HapticFeedback.selectionClick();
                  setState(() => _notificationsEnabled = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('notifications_enabled', value);
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                      ),
                    );
                  }
                },
                thumbColor: WidgetStateProperty.all(Colors.black),
              )
            : Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          onTap: hasSwitch ? null : () {
            HapticFeedback.lightImpact();
            _handleMenuTap(context, title);
          },
          onLongPress: () async {
            // Hidden debug action: long-press on About to run migration
            if (title == 'About') {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              HapticFeedback.mediumImpact();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Run Data Migration?'),
                  content: const Text('This will backfill Firebase UIDs into legacy data (items, forum posts, messages). Proceed?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Run')),
                  ],
                ),
              );
              if (confirmed == true) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Starting migration...')),
                );
                try {
                  await RealtimeService().migrateLegacyData();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Migration completed successfully'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Migration failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            }
          },
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String title) {
    switch (title) {
      case 'Account settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
        );
        break;
      case 'Change password':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
        );
        break;
      case 'User Manual':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserManualScreen()),
        );
        break;
      case 'Help Assistant':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpAgentScreen()),
        );
        break;
      case 'Help & support':
        _showHelpSupport(context);
        break;
      case 'Privacy policy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyScreen()),
        );
        break;
      case 'About':
        _showAbout(context);
        break;
      case 'Logout':
        _showLogoutDialog(context);
        break;
    }
  }



  void _showMyReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyReportsScreen(items: widget.items),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.support_agent, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Help & Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSupportSection(
                  'WSU Lost & Found Support Team',
                  [
                    '📧 lostfound@wsu.ac.za',
                    '📞 +27 43 702 9111',
                    '📍 Student Affairs Office, Building A',
                    '🏫 Buffalo City Campus, Walter Sisulu University',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSupportSection(
                  'Office Hours',
                  [
                    '🕒 Monday - Friday: 8:00 AM - 4:30 PM',
                    '🕒 Saturday: 8:00 AM - 12:00 PM',
                    '🚫 Sunday: Closed',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSupportSection(
                  'Emergency Contacts',
                  [
                    '🚨 Campus Security: +27 43 702 9999 (24/7)',
                    '🏥 Campus Clinic: +27 43 702 9200',
                    '🚑 Emergency Services: 10111',
                  ],
                ),
                const SizedBox(height: 16),
                _buildSupportSection(
                  'Quick Help',
                  [
                    '📱 In-app Help Assistant (AI powered)',
                    '📚 User Manual & Tutorials',
                    '💬 Community Forum Support',
                    '📧 Email Support (24-48h response)',
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HelpAgentScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                        child: const Text('Get Help', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSupportSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        )),
      ],
    );
  }



  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.search, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WSU Lost & Found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Version 2.1.0 (Stable)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildAboutSection(
                  'University Information',
                  [
                    '🏫 Walter Sisulu University',
                    '📍 Eastern Cape, South Africa',
                    '🌐 www.wsu.ac.za',
                    '📞 +27 43 702 9111',
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutSection(
                  'WSU Campuses',
                  [
                    '🏫 Buffalo City Campus (Main)',
                    '🏫 Butterworth Campus',
                    '🏫 Queenstown Campus',
                    '🏫 Mthatha Campus',
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutSection(
                  'App Purpose',
                  [
                    'Official lost and found platform for all WSU campuses',
                    'Connecting students, staff, and visitors across 4 campuses',
                    'Promoting campus safety and community support',
                    'Reducing item loss through technology',
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutSection(
                  'Key Features',
                  [
                    '📱 Report lost/found items with photos',
                    '🔍 Advanced search and filtering',
                    '💬 Real-time messaging system',
                    '🎯 Smart matching algorithms',
                    '⭐ Karma-based reputation system',
                    '📊 Analytics and insights',
                    '🔔 Push notifications',
                    '🌐 Web and mobile platforms',
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutSection(
                  'Development Team',
                  [
                    '💻 WSU IT Department',
                    '👥 Student Affairs Office',
                    '🔒 Campus Security Services',
                    '🎨 UI/UX Design Team',
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutSection(
                  'Technology Stack',
                  [
                    '💙 Built with Flutter Framework',
                    '☁️ Firebase Backend Services',
                    '📱 Cross-platform (iOS, Android, Web)',
                    '🔒 End-to-end encryption',
                    '📊 Real-time database',
                  ],
                ),
                const SizedBox(height: 16),
                _buildAboutSection(
                  'Privacy & Security',
                  [
                    '🔒 POPIA compliant data handling',
                    '🛡️ Secure user authentication',
                    '📝 Privacy-first design',
                    '🚫 No data sharing with third parties',
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '© 2025 Walter Sisulu University. All rights reserved.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text('Close', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAboutSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item.startsWith('•') ? item : '• $item',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        )),
      ],
    );
  }

  int _getResolvedCount() {
    return (widget.totalItems * 0.7).round();
  }



  void _showAchievements(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Achievements'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAchievementTile('🏆 First Report', 'Submit your first lost/found item', true),
              _buildAchievementTile('💬 Communicator', 'Send 10 messages', true),
              _buildAchievementTile('🎯 Match Maker', 'Help reunite 5 items', widget.userKarma > 100),
              _buildAchievementTile('⭐ Rising Star', 'Reach 200 karma points', widget.userKarma > 200),
              _buildAchievementTile('🔍 Detective', 'Find 10 lost items', false),
              _buildAchievementTile('🏅 Campus Hero', 'Reach 500 karma points', false),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(String title, String description, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUnlocked ? Colors.amber.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isUnlocked ? Icons.check_circle : Icons.lock,
            color: isUnlocked ? Colors.amber : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.black : Colors.grey,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? Colors.grey.shade700 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await AuthService.logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(this.context, '/', (route) => false);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pushReplacementNamed(this.context, '/');
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}