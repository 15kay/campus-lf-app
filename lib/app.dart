import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'models.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/match_notification_handler.dart';
import 'widgets/notification_toast.dart';
import 'pages/home_page.dart';
import 'pages/report_page.dart';
import 'pages/my_reports_page.dart';
import 'pages/search_page.dart';
import 'pages/profile_page.dart';
import 'pages/settings_page.dart';
import 'pages/about_page.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/chat_page.dart';
import 'pages/chat_list_page.dart';
import 'pages/agent_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/item_details_page.dart';
import 'pages/matches_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void _updateThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  Widget build(BuildContext context) {
    // Modern Contemporary Color Palette
    const primaryColor = Color(0xFF6366F1); // Modern Indigo
    const secondaryColor = Color(0xFF8B5CF6); // Modern Purple
    const accentColor = Color(0xFF06B6D4); // Modern Cyan
    const surfaceColor = Color(0xFFFCFCFD); // Ultra Light Surface
    const errorColor = Color(0xFFEF4444); // Modern Red
    const successColor = Color(0xFF10B981); // Modern Green
    const warningColor = Color(0xFFF59E0B); // Modern Amber
    
    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: surfaceColor,
      error: errorColor,
    );
    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      error: errorColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F0F23), // Modern Dark Surface
    );

    return MaterialApp(
      title: 'Campus Lost & Found',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: lightScheme.surface,
        // Professional Typography System
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25),
          displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        // Professional Card Design
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          surfaceTintColor: lightScheme.surfaceTint,
        ),
        // Enhanced Navigation Bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: lightScheme.surface,
          indicatorColor: lightScheme.secondaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.1),
        ),
        // Professional AppBar Design
        appBarTheme: AppBarTheme(
          backgroundColor: lightScheme.surface,
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          surfaceTintColor: lightScheme.surfaceTint,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18, 
            fontWeight: FontWeight.w600, 
            color: lightScheme.onSurface,
            letterSpacing: -0.25,
          ),
          centerTitle: true,
        ),
        // Professional Button Styles
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(88, 48), // Increased min width for better UX
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            foregroundColor: lightScheme.onPrimary,
            backgroundColor: lightScheme.primary,
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.2),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(88, 48),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: lightScheme.outline, width: 1.5),
          ),
        ),
        // Professional Input Design
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: lightScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightScheme.outline.withValues(alpha: 0.5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightScheme.outline.withValues(alpha: 0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightScheme.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightScheme.error, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: lightScheme.error, width: 2),
          ),
          labelStyle: GoogleFonts.inter(
            color: lightScheme.onSurfaceVariant, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.inter(
            color: lightScheme.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          floatingLabelStyle: GoogleFonts.inter(
            color: lightScheme.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Professional SnackBar Design
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: lightScheme.inverseSurface,
          contentTextStyle: GoogleFonts.inter(
            color: lightScheme.onInverseSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 6,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: darkScheme.surface,
        // Professional Typography System (Dark)
        textTheme: GoogleFonts.interTextTheme(ThemeData(brightness: Brightness.dark).textTheme).copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25),
          displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500),
        ),
        // Professional Card Design (Dark)
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          surfaceTintColor: darkScheme.surfaceTint,
        ),
        // Enhanced Navigation Bar (Dark)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkScheme.surface,
          indicatorColor: darkScheme.secondaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkScheme.surface,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkScheme.onSurface),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            foregroundColor: darkScheme.onPrimary,
            backgroundColor: darkScheme.primary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkScheme.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkScheme.error, width: 1.5),
          ),
          labelStyle: TextStyle(color: darkScheme.onSurfaceVariant, fontSize: 14),
          hintStyle: TextStyle(color: darkScheme.onSurfaceVariant.withValues(alpha: 0.8)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: darkScheme.inverseSurface,
          contentTextStyle: TextStyle(color: darkScheme.onInverseSurface),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          print('DEBUG AUTH: ConnectionState: ${snapshot.connectionState}');
          print('DEBUG AUTH: HasData: ${snapshot.hasData}');
          print('DEBUG AUTH: HasError: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('DEBUG AUTH: Error: ${snapshot.error}');
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('DEBUG AUTH: Waiting for authentication state...');
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            print('DEBUG AUTH: User authenticated - UID: ${snapshot.data?.uid}, Email: ${snapshot.data?.email}');
            return MainScaffold(
              onThemeModeChanged: _updateThemeMode,
              themeMode: _themeMode,
            );
          }
          print('DEBUG AUTH: No authenticated user found - showing landing page');
          return LandingPage(
            onContinue: (ctx) {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => MainScaffold(
                    onThemeModeChanged: _updateThemeMode,
                    themeMode: _themeMode,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final Widget page;
  _NavItem(this.title, this.icon, this.page);
}

class ItemDetailsPage extends StatelessWidget {
  final Report report;
  const ItemDetailsPage({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLost = report.status.toLowerCase() == 'lost';
    final statusColor = isLost ? cs.errorContainer : cs.tertiaryContainer;
    final statusTextColor = isLost ? cs.onErrorContainer : cs.onTertiaryContainer;

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFE0C200)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(isLost ? Icons.search : Icons.check_circle, color: Colors.black87),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          report.itemName,
                          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Chip(
                        label: Text(report.status),
                        backgroundColor: statusColor,
                        labelStyle: tt.bodyMedium?.copyWith(color: statusTextColor, fontWeight: FontWeight.w600),
                      ),
                      Chip(label: Text(report.category)),
                      Chip(label: Text(report.location)),
                      Chip(label: Text('Date: ${report.date.toIso8601String().substring(0,10)}')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Details card with icon rows
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Details', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.category),
                    title: const Text('Category'),
                    subtitle: Text(report.category),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place),
                    title: const Text('Location'),
                    subtitle: Text(report.location),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Date'),
                    subtitle: Text(report.date.toIso8601String().substring(0,10)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(report.description.isNotEmpty ? report.description : 'No additional description provided.', style: tt.bodyMedium),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reporter contact card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reporter Contact', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  FutureBuilder<String>(
                    future: getEmailForUidAsync(report.uid),
                    builder: (context, snapshot) {
                      final email = snapshot.data ?? 'Loading...';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: cs.secondaryContainer,
                          child: Text(
                            (report.uid.isNotEmpty ? report.uid[0] : '?').toUpperCase(),
                            style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(email.split('@').first),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Email: $email'),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Email'),
                        onPressed: () async {
                          final email = await getEmailForUidAsync(report.uid);
                          Clipboard.setData(ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied')));
                        },
                      ),
                      OutlinedButton.icon(
                         icon: const Icon(Icons.chat_bubble_outline),
                         label: const Text('Message In-App'),
                         onPressed: () async {
                           final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                           if (currentUid.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to send messages.')));
                             Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
                             return;
                           }
                           
                           if (currentUid == report.uid) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot message yourself!')));
                             return;
                           }
                           
                           try {
                             // Show loading indicator
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Starting conversation...'), duration: Duration(seconds: 2))
                             );
                             
                             // Create conversation in Firestore
                             final conversationId = '${currentUid}_${report.uid}_${DateTime.now().millisecondsSinceEpoch}';
                             await FirebaseFirestore.instance.collection('conversations').doc(conversationId).set({
                               'participants': [currentUid, report.uid],
                               'lastActivity': FieldValue.serverTimestamp(),
                               'createdAt': FieldValue.serverTimestamp(),
                             });
                             
                             // Add an automatic initial message about the item
                             final initialMessageId = 'initial_${DateTime.now().millisecondsSinceEpoch}';
                             final initialMessage = 'Hi! I\'m interested in your ${report.status.toLowerCase()} item: "${report.itemName}" that was reported at ${report.location}. Can we discuss this?';
                             
                             await FirebaseFirestore.instance
                                 .collection('conversations')
                                 .doc(conversationId)
                                 .collection('messages')
                                 .doc(initialMessageId)
                                 .set({
                               'id': initialMessageId,
                               'content': initialMessage,
                               'fromUid': currentUid,
                               'toUid': report.uid,
                               'timestamp': FieldValue.serverTimestamp(),
                               'isRead': false,
                             });
                             
                             // Update conversation's last activity
                             await FirebaseFirestore.instance.collection('conversations').doc(conversationId).update({
                               'lastActivity': FieldValue.serverTimestamp(),
                             });
                             
                             // Create chat entry so both users can see the conversation in their chat list
                             final sortedUids = [currentUid, report.uid]..sort();
                             final chatId = '${sortedUids[0]}_${sortedUids[1]}';
                             
                             // Get user profiles for display names
                             final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
                             final reporterDoc = await FirebaseFirestore.instance.collection('users').doc(report.uid).get();
                             
                             final currentUserName = currentUserDoc.exists ? (currentUserDoc.data()?['name'] ?? 'Unknown') : 'Unknown';
                             final reporterName = reporterDoc.exists ? (reporterDoc.data()?['name'] ?? 'Unknown') : 'Unknown';
                             
                             await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                               'participants': [currentUid, report.uid],
                               'conversationId': conversationId,
                               'lastMessage': initialMessage,
                               'lastMessageTime': FieldValue.serverTimestamp(),
                               'unreadCount_${report.uid}': 1, // Reporter has 1 unread message
                               'unreadCount_$currentUid': 0, // Current user has no unread messages
                               'senderName': currentUserName,
                               'recipientName': reporterName,
                               'createdAt': FieldValue.serverTimestamp(),
                             });
                             
                             // Create conversation object for navigation
                             final conv = Conversation(
                               id: conversationId,
                               participants: [currentUid, report.uid],
                               messages: [],
                               lastActivity: DateTime.now(),
                             );
                             
                             // Navigate to chat page
                             Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(conversation: conv)));
                             
                             // Show success message
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Conversation started! Your message has been sent.'), duration: Duration(seconds: 3))
                             );
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('Failed to start conversation: $e'))
                             );
                           }
                         },
                         style: OutlinedButton.styleFrom(side: BorderSide(color: cs.primary)),
                       ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.mail_outline),
                        label: const Text('Email Reporter'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final email = await getEmailForUidAsync(report.uid);
                          final subject = Uri.encodeComponent('[Lost & Found] Regarding: ${report.itemName}');
                          final body = Uri.encodeComponent('Hi, I saw your ${report.status.toLowerCase()} report for "${report.itemName}" at ${report.location} on ${report.date.toIso8601String().substring(0,10)}.\n\nCould we connect to resolve this?');
                          final uri = Uri.parse('mailto:$email?subject=$subject&body=$body');
                          final can = await canLaunchUrl(uri);
                          if (can) {
                            await launchUrl(uri);
                          } else {
                            messenger.showSnackBar(const SnackBar(content: Text('Unable to open email app')));
                          }
                        },
                        style: OutlinedButton.styleFrom(side: BorderSide(color: cs.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode) onThemeModeChanged;
  const MainScaffold({super.key, required this.themeMode, required this.onThemeModeChanged});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupNotificationHandling();
  }

  void _setupNotificationHandling() {
    // Set up notification tap handler for navigation
    NotificationService.setNotificationTapHandler((payload) {
      _handleNotificationTap(payload);
    });

    // Initialize match notification handler
    MatchNotificationHandler.initialize();
  }

  void _handleNotificationTap(Map<String, dynamic> payload) {
    final type = payload['type'] as String?;
    
    switch (type) {
      case 'match':
        final matchId = payload['matchId'] as String?;
        final itemId = payload['itemId'] as String?;
        if (matchId != null && itemId != null) {
          _navigateToMatchDetails(matchId, itemId);
        } else {
          // Navigate to matches page if specific match data is not available
          setState(() => _currentIndex = 1); // Matches tab
        }
        break;
      case 'message':
        final chatId = payload['chatId'] as String?;
        if (chatId != null) {
          _navigateToChatDetails(chatId);
        } else {
          // Navigate to chat list if specific chat data is not available
          setState(() => _currentIndex = 3); // Chat tab
        }
        break;
      default:
        // Default to home page
        setState(() => _currentIndex = 0);
    }
  }

  void _navigateToMatchDetails(String matchId, String itemId) {
    // Navigate to matches page and then to specific match
    setState(() => _currentIndex = 1); // Matches tab
    
    // Show match notification toast
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        NotificationToast.showMatchNotification(
          context,
          itemName: 'Your Item',
          matchedUserName: 'Someone',
          onTap: () {
            // Additional navigation logic if needed
          },
        );
      }
    });
  }

  void _navigateToChatDetails(String chatId) {
    // Navigate to chat list and then to specific chat
    setState(() => _currentIndex = 3); // Chat tab
    
    // Additional logic to open specific chat could be added here
  }

  List<_NavItem> get _mainItems => [
        _NavItem(
          'Home',
          Icons.home,
          HomePage(
            onOpenDetails: _openDetails,
            onCreateReport: () => _navigateToReportPage(),
          ),
        ),
        _NavItem('Matches', Icons.compare_arrows, const MatchesPage()),
        _NavItem('My Reports', Icons.assignment, const MyReportsPage()),
        _NavItem('Chat', Icons.chat, const ChatListPage()),
        _NavItem('Profile', Icons.account_circle, ProfilePage(onProfileUpdated: _onProfileUpdated)),
      ];

  void _openDetails(Report r) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItemDetailsPage(report: r)));
  }

  void _navigateToReportPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportPage(onSubmit: _addReport),
      ),
    );
  }

  void _addReport(Report r) async {
    try {
      await FirebaseService.addReport(r);
      
      // Check for potential matches and send notifications
      await MatchNotificationHandler.handleNewReport(r);
      
      setState(() => _currentIndex = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${r.type} item "${r.itemName}" reported successfully! Your report is now visible to other users.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _openDetails(r),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
    }
  }

  void _deleteReport(Report r) async {
    try {
      await FirebaseService.deleteReport(r.reportId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete report: $e')));
    }
  }

  void _editReport(Report report) async {
    await _showEditReportDialog(report);
  }

  Future<void> _showEditReportDialog(Report report) async {
    final statusController = TextEditingController(text: report.status);
    final descriptionController = TextEditingController(text: report.description);
    final locationController = TextEditingController(text: report.location);
    
    String selectedStatus = report.status;
    final statusOptions = ['Pending', 'Found', 'Lost', 'Resolved', 'Cancelled'];
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Edit Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name (read-only)
                Text(
                  'Item: ${report.itemName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status dropdown
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: statusOptions.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Update description...',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Location
                Text(
                  'Location',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Update location...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      // Create updated report
      final updatedReport = Report(
        reportId: report.reportId,
        uid: report.uid,
        itemName: report.itemName,
        type: report.type,
        status: selectedStatus,
        description: descriptionController.text.trim(),
        location: locationController.text.trim(),
        date: report.date,
        category: report.category,
        imageBytes: report.imageBytes,
        timestamp: report.timestamp,
      );
      
      try {
        await FirebaseService.updateReport(updatedReport);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report updated successfully!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    // Dispose controllers
    statusController.dispose();
    descriptionController.dispose();
    locationController.dispose();
  }

  void _onProfileUpdated(UserProfile profile) {
    saveUserProfile(profile);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
  }

  void _exitToLanding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LandingPage(
          onContinue: (ctx) {
            Navigator.of(ctx).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainScaffold(
                  onThemeModeChanged: widget.onThemeModeChanged,
                  themeMode: widget.themeMode,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = _mainItems.map((e) => e.title).toList();
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                 borderRadius: BorderRadius.circular(16),
                 child: SvgPicture.asset(
                   'web/logo.svg',
                   width: 32,
                   height: 32,
                   placeholderBuilder: (context) => const Icon(
                     Icons.school,
                     size: 20,
                     color: Color(0xFF075E54),
                   ),
                 ),
               ),
            ),
            const SizedBox(width: 8),
            Text(titles[_currentIndex], style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.note_add), tooltip: 'Report Item', onPressed: () => setState(() => _currentIndex = 1)),
          IconButton(icon: const Icon(Icons.exit_to_app), tooltip: 'Exit', onPressed: () => _confirmExit(context, _exitToLanding)),
          FutureBuilder<bool>(
            future: FirebaseService.isUserAuthenticated() 
                ? FirebaseService.isUserAdmin(FirebaseService.getCurrentUser()!.uid)
                : Future.value(false),
            builder: (context, isAdminSnapshot) {
              final isAdmin = isAdminSnapshot.data ?? false;
              return PopupMenuButton<String>(
                tooltip: 'More',
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'settings', child: ListTile(leading: Icon(Icons.settings), title: Text('Settings'))),
                  const PopupMenuItem(value: 'about', child: ListTile(leading: Icon(Icons.info), title: Text('About'))),
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'admin', 
                      child: ListTile(
                        leading: Icon(Icons.admin_panel_settings), 
                        title: Text('Admin Dashboard')
                      )
                    ),
                  const PopupMenuItem(value: 'signout', child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out'))),
                 ],
                 onSelected: (value) async {
              if (value == 'settings') {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SettingsPage(themeMode: widget.themeMode, onThemeModeChanged: widget.onThemeModeChanged),
                ));
              } else if (value == 'about') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()));
              } else if (value == 'admin') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboard()));
              } else if (value == 'signout') {
                final navigator = Navigator.of(context);
                try {
                  await FirebaseAuth.instance.signOut();
                } catch (_) {}
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => LandingPage(
                      onContinue: (ctx) {
                        Navigator.of(ctx).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => MainScaffold(
                              onThemeModeChanged: widget.onThemeModeChanged,
                              themeMode: widget.themeMode,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  (route) => false,
                );
              }
            },
          );
        },
      ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
          ),
        ),
      ),
      body: Stack(
         children: [
           // Primary content
           isWide
               ? Row(
                   children: [
                     Container(
                       margin: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.surface,
                         borderRadius: BorderRadius.circular(16),
                         boxShadow: [
                           BoxShadow(
                             color: Colors.black.withValues(alpha: 0.06),
                             blurRadius: 12,
                             offset: const Offset(0, 6),
                           ),
                         ],
                       ),
                       child: NavigationRail(
                         backgroundColor: Colors.transparent,
                         selectedIndex: _currentIndex,
                         onDestinationSelected: (i) => setState(() => _currentIndex = i),
                         labelType: NavigationRailLabelType.all,
                         leading: const SizedBox(height: 8),
                         groupAlignment: -0.9,
                         destinations: _mainItems
                             .asMap()
                             .entries
                             .map((entry) {
                               final index = entry.key;
                               final item = entry.value;
                               
                               // Special handling for Chat tab (index 3) to show unread badge
                               if (index == 3 && FirebaseAuth.instance.currentUser != null) {
                                 return NavigationRailDestination(
                                   icon: StreamBuilder<QuerySnapshot>(
                                     stream: FirebaseFirestore.instance
                                         .collection('chats')
                                         .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                                         .snapshots(),
                                     builder: (context, snapshot) {
                                       int totalUnread = 0;
                                       if (snapshot.hasData) {
                                         for (var doc in snapshot.data!.docs) {
                                           final data = doc.data() as Map<String, dynamic>;
                                           final unreadCount = data['unreadCount_${FirebaseAuth.instance.currentUser?.uid}'] ?? 0;
                                           totalUnread += unreadCount as int;
                                         }
                                       }
                                       
                                       return Stack(
                                         children: [
                                           Icon(item.icon),
                                           if (totalUnread > 0)
                                             Positioned(
                                               right: 0,
                                               top: 0,
                                               child: Container(
                                                 padding: const EdgeInsets.all(2),
                                                 decoration: BoxDecoration(
                                                   color: Colors.red,
                                                   borderRadius: BorderRadius.circular(10),
                                                 ),
                                                 constraints: const BoxConstraints(
                                                   minWidth: 16,
                                                   minHeight: 16,
                                                 ),
                                                 child: Text(
                                                   totalUnread > 99 ? '99+' : totalUnread.toString(),
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
                                   ),
                                   selectedIcon: StreamBuilder<QuerySnapshot>(
                                     stream: FirebaseFirestore.instance
                                         .collection('chats')
                                         .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                                         .snapshots(),
                                     builder: (context, snapshot) {
                                       int totalUnread = 0;
                                       if (snapshot.hasData) {
                                         for (var doc in snapshot.data!.docs) {
                                           final data = doc.data() as Map<String, dynamic>;
                                           final unreadCount = data['unreadCount_${FirebaseAuth.instance.currentUser?.uid}'] ?? 0;
                                           totalUnread += unreadCount as int;
                                         }
                                       }
                                       
                                       return Stack(
                                         children: [
                                           Icon(item.icon, color: Theme.of(context).colorScheme.secondary),
                                           if (totalUnread > 0)
                                             Positioned(
                                               right: 0,
                                               top: 0,
                                               child: Container(
                                                 padding: const EdgeInsets.all(2),
                                                 decoration: BoxDecoration(
                                                   color: Colors.red,
                                                   borderRadius: BorderRadius.circular(10),
                                                 ),
                                                 constraints: const BoxConstraints(
                                                   minWidth: 16,
                                                   minHeight: 16,
                                                 ),
                                                 child: Text(
                                                   totalUnread > 99 ? '99+' : totalUnread.toString(),
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
                                   ),
                                   label: Text(item.title),
                                 );
                               }
                               
                               // Default navigation destination for other tabs
                               return NavigationRailDestination(
                                 icon: Icon(item.icon),
                                 selectedIcon: Icon(item.icon, color: Theme.of(context).colorScheme.secondary),
                                 label: Text(item.title),
                               );
                             })
                             .toList(),
                       ),
                     ),
                     const VerticalDivider(width: 1),
                     Expanded(
                       child: IndexedStack(index: _currentIndex, children: _mainItems.map((e) => e.page).toList()),
                     ),
                   ],
                 )
               : IndexedStack(index: _currentIndex, children: _mainItems.map((e) => e.page).toList()),

           // Bottom-right agent launcher - positioned above Profile tab
           Positioned(
             right: 12,
             bottom: isWide ? 12 : 84, // keep above bottom navigation on narrow screens
             child: SafeArea(
               child: Semantics(
                 button: true,
                 label: 'Open Assistant',
                 child: Material(
                   color: Theme.of(context).colorScheme.primary,
                   elevation: 6,
                   borderRadius: BorderRadius.circular(24),
                   child: InkWell(
                     borderRadius: BorderRadius.circular(24),
                     onTap: () => Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => const AgentPage()),
                     ),
                     child: Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(Icons.psychology, color: Theme.of(context).colorScheme.onPrimary),
                           const SizedBox(width: 8),
                           Text(
                             'Assistant',
                             style: TextStyle(
                               color: Theme.of(context).colorScheme.onPrimary,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ),
               ),
             ),
           ),
         ],
       ),
      bottomNavigationBar: isWide
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: NavigationBar(
                      backgroundColor: Colors.transparent,
                      height: 72,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (i) => setState(() => _currentIndex = i),
                      destinations: _mainItems
                          .asMap()
                          .entries
                          .map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            
                            // Special handling for Chat tab (index 3) to show unread badge
                            if (index == 3 && FirebaseAuth.instance.currentUser != null) {
                              return NavigationDestination(
                                icon: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('chats')
                                      .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int totalUnread = 0;
                                    if (snapshot.hasData) {
                                      for (var doc in snapshot.data!.docs) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        final unreadCount = data['unreadCount_${FirebaseAuth.instance.currentUser?.uid}'] ?? 0;
                                        totalUnread += unreadCount as int;
                                      }
                                    }
                                    
                                    return Stack(
                                      children: [
                                        Icon(item.icon),
                                        if (totalUnread > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                totalUnread > 99 ? '99+' : totalUnread.toString(),
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
                                ),
                                selectedIcon: StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('chats')
                                      .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    int totalUnread = 0;
                                    if (snapshot.hasData) {
                                      for (var doc in snapshot.data!.docs) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        final unreadCount = data['unreadCount_${FirebaseAuth.instance.currentUser?.uid}'] ?? 0;
                                        totalUnread += unreadCount as int;
                                      }
                                    }
                                    
                                    return Stack(
                                      children: [
                                        Icon(item.icon, color: Theme.of(context).colorScheme.secondary),
                                        if (totalUnread > 0)
                                          Positioned(
                                            right: 0,
                                            top: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                totalUnread > 99 ? '99+' : totalUnread.toString(),
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
                                ),
                                label: item.title,
                              );
                            }
                            
                            // Default navigation destination for other tabs
                            return NavigationDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.icon, color: Theme.of(context).colorScheme.secondary),
                              label: item.title,
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
            ),
          ),
    );
  }
}

String _colorToHex(Color c) {
  String toHex(int n) => n.toRadixString(16).padLeft(2, '0');
  final r = (c.r * 255.0).round() & 0xff;
  final g = (c.g * 255.0).round() & 0xff;
  final b = (c.b * 255.0).round() & 0xff;
  return '#${toHex(r)}${toHex(g)}${toHex(b)}';
}
String _brandLogoSvg(Color primary, Color secondary, Color onPrimary) {
  final p = _colorToHex(primary);
  final s = _colorToHex(secondary);
  final w = _colorToHex(onPrimary);
  return '''
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="$p"/>
      <stop offset="100%" stop-color="$s"/>
    </linearGradient>
  </defs>
  <circle cx="32" cy="32" r="28" fill="url(#g)"/>
  <g fill="$w">
    <circle cx="28" cy="28" r="10" fill="$w" opacity="0.9"/>
    <rect x="40" y="40" width="12" height="4" rx="2" transform="rotate(45 46 42)"/>
  </g>
</svg>
''';
}

class LandingPage extends StatelessWidget {
  final void Function(BuildContext) onContinue;
  const LandingPage({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.string(_brandLogoSvg(cs.primary, cs.secondary, cs.onPrimary), height: 64),
                                const SizedBox(height: 12),
                                Text('Campus Lost & Found', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Find your belongings quickly and report lost or found items across campus.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 14, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      runSpacing: 12,
                      spacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          ),
                          label: const Text('Login'),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.app_registration),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterPage())),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(64, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            side: BorderSide(color: cs.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          label: const Text('Register'),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.lock_reset),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          label: const Text('Forgot Password?'),
                        ),
                        // TextButton.icon(
                        //   icon: const Icon(Icons.explore),
                        //   onPressed: () => onContinue(context),
                        //   style: TextButton.styleFrom(minimumSize: const Size(64, 48), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        //   label: const Text('Continue as Guest'),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom-right chatbot launcher on landing
          Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: Semantics(
                button: true,
                label: 'Open Assistant',
                child: Material(
                  color: cs.primary,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AgentPage()),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, color: cs.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Assistant',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address first')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to $email'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address';
          break;
        default:
          message = e.message ?? 'Failed to send password reset email';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = cred.user ?? FirebaseAuth.instance.currentUser;
      if (!mounted) return;

      // Navigate immediately to app for faster UX
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainScaffold(onThemeModeChanged: (m) {}, themeMode: ThemeMode.system),
        ),
      );

      // Background: fetch Firestore profile with timeout and update local model
      if (user != null) {
        try {
          final docFuture = FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          final doc = await docFuture.timeout(const Duration(seconds: 4));
          final data = doc.data();
          final String? rawName = data?['fullName'] as String?;
          final String nameField = (rawName != null && rawName.trim().isNotEmpty)
              ? rawName.trim()
              : (user.displayName ?? (user.email?.split('@').first ?? 'User'));
          final String studentNo = (data?['studentNumber'] as String?)?.trim() ?? '';
          final String email = user.email ?? ((data?['email'] as String?) ?? '');

          final profile = UserProfile(
            uid: user.uid,
            name: nameField,
            studentNumber: studentNo,
            email: email,
            gender: 'Other',
            profileImageBytes: null,
          );
          await saveUserProfile(profile);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Welcome, ${nameField.split(' ').first}!')),
            );
          }
        } catch (_) {
          // Fallback: minimal profile from FirebaseAuth user
          final fallbackName = user.displayName ?? (user.email?.split('@').first ?? 'User');
          final fallbackEmail = user.email ?? '';
          final profile = UserProfile(
            uid: user.uid,
            name: fallbackName,
            studentNumber: '',
            email: fallbackEmail,
            gender: 'Other',
            profileImageBytes: null,
          );
          await saveUserProfile(profile);
        }
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Login failed';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error during login')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Welcome back', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _signIn,
              child: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Signing in...'),
                      ],
                    )
                  : const Text('Login'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resetPassword,
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: cs.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Back', style: TextStyle(color: cs.primary))),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _studentController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final conf = _confirmController.text;
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    if (pass != conf) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      // Persist user profile to Firestore
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fullName': _nameController.text.trim(),
          'studentNumber': _studentController.text.trim(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful. Please log in.')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Registration failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unexpected error during registration')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create your account', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: _studentController, decoration: const InputDecoration(labelText: 'Student Number')),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 12),
            TextField(controller: _confirmController, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Register'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Back', style: TextStyle(color: cs.primary))),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox and follow the instructions.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
      
      // Navigate back to landing page after successful email send
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email address.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;
        default:
          message = 'Failed to send reset email. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.lock_reset,
              size: 80,
              color: cs.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Forgot Your Password?',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: cs.surface,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Reset Email'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back to Login',
                style: TextStyle(color: cs.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmExit(BuildContext context, VoidCallback onExit) async {
  final shouldExit = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exit'),
      content: const Text('Do you want to return to the Landing Page?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Exit')),
      ],
    ),
  );
  if (shouldExit == true) {
    onExit();
  }
}