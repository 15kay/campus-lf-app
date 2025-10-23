import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models.dart';
import 'report_page.dart';

import 'item_details_page.dart';


class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final List<_AgentMessage> _messages = [
    const _AgentMessage(
      sender: 'agent',
      text: '👋 Hi! I\'m your Campus Lost & Found AI Agent. I can help you report items, provide smart suggestions, and automate tasks. What would you like to do today?',
      messageType: _MessageType.welcome,
    ),
  ];
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final audio.AudioPlayer _audioPlayer = audio.AudioPlayer();
  bool _isRecording = false;
  int? _playingIndex;
  bool _isTyping = false;
  
  // Agent context and state
  final String _currentContext = 'main';
  Map<String, dynamic> _userPreferences = {};
  final List<String> _recentSearches = [];
  List<String> _userReports = [];

  @override
  void initState() {
    super.initState();
    _loadUserContext();
    _showQuickActions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadUserContext() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Load user's recent reports
        final reportsSnapshot = await FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();
        
        _userReports = reportsSnapshot.docs
            .map((doc) => doc.data()['title'] as String? ?? 'Untitled')
            .toList();
        
        // Load user preferences (mock for now)
        _userPreferences = {
          'preferredCategories': ['Electronics', 'Personal Items'],
          'notificationSettings': true,
          'quickActionsEnabled': true,
        };
        
        setState(() {});
      } catch (e) {
        print('Error loading user context: $e');
      }
    }
  }

  void _showQuickActions() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _messages.add(const _AgentMessage(
            sender: 'agent',
            text: 'Here are some quick actions I can help you with:',
            messageType: _MessageType.quickActions,
            quickActions: [
              _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'Report Lost Item',
                action: 'report_item',
              ),
              
              _QuickAction(
                icon: Icons.lightbulb_outline,
                label: 'Smart Suggestions',
                action: 'smart_suggestions',
              ),
              _QuickAction(
                icon: Icons.person,
                label: 'Update Profile',
                action: 'update_profile',
              ),
            ],
          ));
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _toggleRecording() async {
    try {
      if (!_isRecording) {
        if (await _recorder.hasPermission()) {
          await _recorder.start(
            const RecordConfig(encoder: AudioEncoder.wav),
            path: kIsWeb ? '' : '',
          );
          setState(() => _isRecording = true);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
      } else {
        final path = await _recorder.stop();
        setState(() => _isRecording = false);
        if (path != null && path.isNotEmpty) {
          setState(() {
            _messages.add(_AgentMessage(
              sender: 'user',
              audioUrl: path,
              messageType: _MessageType.voice,
            ));
          });
          _scrollToBottom();
          _processVoiceMessage(path);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording error: $e')),
      );
    }
  }

  Future<void> _togglePlay(int index) async {
    final m = _messages[index];
    if (m.audioUrl == null) return;
    try {
      if (_playingIndex == index) {
        await _audioPlayer.pause();
        setState(() => _playingIndex = null);
        return;
      }
      await _audioPlayer.stop();
      final audio.Source src = kIsWeb ? audio.UrlSource(m.audioUrl!) : audio.DeviceFileSource(m.audioUrl!);
      await _audioPlayer.play(src);
      setState(() => _playingIndex = index);
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == audio.PlayerState.completed) {
          if (mounted) setState(() => _playingIndex = null);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playback error: $e')),
      );
    }
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(_AgentMessage(
        sender: 'user',
        text: text,
        messageType: _MessageType.text,
      ));
    });
    _controller.clear();
    _scrollToBottom();
    _processUserMessage(text);
  }

  void _processUserMessage(String userText) {
    setState(() => _isTyping = true);
    
    // Simulate AI processing delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      
      final response = _generateAgentResponse(userText);
      setState(() {
        _isTyping = false;
        _messages.add(response);
      });
      _scrollToBottom();
    });
  }

  void _processVoiceMessage(String audioPath) {
    setState(() => _isTyping = true);
    
    // Simulate voice processing
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      
      setState(() {
        _isTyping = false;
        _messages.add(const _AgentMessage(
          sender: 'agent',
          text: '🎤 I heard your voice message! Voice processing is being enhanced. For now, please use text input for the best experience.',
          messageType: _MessageType.text,
        ));
      });
      _scrollToBottom();
    });
  }

  _AgentMessage _generateAgentResponse(String userText) {
    final query = userText.toLowerCase();
    
    // Enhanced context-aware responses with natural language understanding
    
    // Lost/Found item reporting
    if (query.contains('report') || query.contains('lost') || query.contains('found') || 
        query.contains('missing') || query.contains('dropped') || query.contains('left behind')) {
      
      // Detect specific item types for better assistance
      String itemType = _detectItemType(query);
      String specificAdvice = _getItemSpecificAdvice(itemType);
      
      return _AgentMessage(
        sender: 'agent',
        text: '📝 I can help you report a ${itemType.isNotEmpty ? itemType : 'lost or found item'}! $specificAdvice\n\nWould you like me to guide you through the process or open the report form directly?',
        messageType: _MessageType.actionable,
        suggestedActions: [
          _SuggestedAction(label: 'Quick Report', action: 'open_report'),
          _SuggestedAction(label: 'Guided Setup', action: 'guide_report'),
          _SuggestedAction(label: 'Smart Tips', action: 'item_tips'),
        ],
      );
    }
    
    // Search and browse functionality
    if (query.contains('search') || query.contains('find') || query.contains('look for') || 
        query.contains('browse') || query.contains('check')) {
      return const _AgentMessage(
        sender: 'agent',
        text: '🔍 I can help you search through reported items! I\'ll use smart filters and AI matching to find the most relevant results.',
        messageType: _MessageType.actionable,
        suggestedActions: [
          _SuggestedAction(label: 'Smart Search', action: 'smart_search'),
          _SuggestedAction(label: 'Browse Categories', action: 'browse_categories'),
          _SuggestedAction(label: 'Recent Items', action: 'recent_items'),
        ],
      );
    }
    
    // Profile and account management
    if (query.contains('profile') || query.contains('account') || query.contains('settings') ||
        query.contains('contact') || query.contains('information')) {
      return const _AgentMessage(
        sender: 'agent',
        text: '👤 I can help optimize your profile for better item recovery! A complete profile increases your chances of getting contacted when items are found by 75%.',
        messageType: _MessageType.actionable,
        suggestedActions: [
          _SuggestedAction(label: 'Update Profile', action: 'open_profile'),
          _SuggestedAction(label: 'Privacy Settings', action: 'privacy_settings'),
          _SuggestedAction(label: 'Notification Preferences', action: 'notification_settings'),
        ],
      );
    }
    
    // Help and tutorials
    if (query.contains('help') || query.contains('how') || query.contains('tutorial') ||
        query.contains('guide') || query.contains('explain')) {
      return _AgentMessage(
        sender: 'agent',
        text: '💡 I\'m your intelligent campus assistant! I can help with:\n\n• Smart item reporting with AI suggestions\n• Advanced search with image recognition\n• Automated notifications and matching\n• Campus-specific tips and insights\n\n${_getContextualHelp(query)}',
        messageType: _MessageType.helpful,
        suggestedActions: [
          _SuggestedAction(label: 'Quick Tutorial', action: 'tutorial'),
          _SuggestedAction(label: 'Best Practices', action: 'best_practices'),
          _SuggestedAction(label: 'FAQ', action: 'faq'),
        ],
      );
    }
    
    // Smart suggestions and recommendations
    if (query.contains('suggestion') || query.contains('recommend') || query.contains('smart') ||
        query.contains('tip') || query.contains('advice')) {
      return _AgentMessage(
        sender: 'agent',
        text: _generateAdvancedSuggestions(),
        messageType: _MessageType.suggestions,
        suggestedActions: [
          _SuggestedAction(label: 'Personalized Tips', action: 'personalized_tips'),
          _SuggestedAction(label: 'Campus Insights', action: 'campus_insights'),
          _SuggestedAction(label: 'Success Stories', action: 'success_stories'),
        ],
      );
    }
    
    // Statistics and insights
    if (query.contains('stats') || query.contains('statistics') || query.contains('data') ||
        query.contains('insights') || query.contains('analytics')) {
      return const _AgentMessage(
        sender: 'agent',
        text: '📊 I can provide intelligent insights about lost and found patterns on campus! This helps you understand the best times and places to search.',
        messageType: _MessageType.actionable,
        suggestedActions: [
          _SuggestedAction(label: 'Campus Hotspots', action: 'hotspots'),
          _SuggestedAction(label: 'Recovery Rates', action: 'recovery_stats'),
          _SuggestedAction(label: 'Time Patterns', action: 'time_patterns'),
        ],
      );
    }
    
    // Greetings and casual conversation
    if (query.contains('hello') || query.contains('hi') || query.contains('hey') ||
        query.contains('good morning') || query.contains('good afternoon') || query.contains('good evening')) {
      return _AgentMessage(
        sender: 'agent',
        text: '👋 Hello! I\'m your intelligent campus assistant. I\'m here to make finding and reporting lost items as easy as possible.\n\n${_getPersonalizedGreeting()}',
        messageType: _MessageType.welcome,
        quickActions: [
          _QuickAction(label: 'Report Item', icon: Icons.add_circle, action: 'report_item'),
          _QuickAction(label: 'Search Items', icon: Icons.search, action: 'smart_search'),
          _QuickAction(label: 'Smart Tips', icon: Icons.lightbulb, action: 'smart_suggestions'),
        ],
      );
    }
    
    // Enhanced default response with context awareness
    return _AgentMessage(
      sender: 'agent',
      text: '🤖 I\'m analyzing your request... I\'m an advanced AI assistant specialized in campus lost and found services.\n\n${_getContextualResponse(query)}\n\nHow can I help you today?',
      messageType: _MessageType.text,
      quickActions: [
        _QuickAction(label: 'Report Item', icon: Icons.add_circle, action: 'report_item'),
        _QuickAction(label: 'Search Items', icon: Icons.search, action: 'smart_search'),
        _QuickAction(label: 'Get Help', icon: Icons.help, action: 'help'),
      ],
    );
  }
  
  String _detectItemType(String query) {
    final itemTypes = {
      'phone': ['phone', 'mobile', 'iphone', 'android', 'smartphone'],
      'laptop': ['laptop', 'computer', 'macbook', 'notebook'],
      'keys': ['key', 'keys', 'keychain'],
      'wallet': ['wallet', 'purse', 'money'],
      'bag': ['bag', 'backpack', 'purse', 'briefcase'],
      'book': ['book', 'textbook', 'notebook'],
      'jewelry': ['ring', 'necklace', 'bracelet', 'watch', 'jewelry'],
      'clothing': ['jacket', 'coat', 'shirt', 'sweater', 'clothes'],
      'glasses': ['glasses', 'sunglasses', 'spectacles'],
      'headphones': ['headphones', 'earbuds', 'airpods'],
    };
    
    for (final entry in itemTypes.entries) {
      if (entry.value.any((keyword) => query.contains(keyword))) {
        return entry.key;
      }
    }
    return '';
  }
  
  String _getItemSpecificAdvice(String itemType) {
    switch (itemType) {
      case 'phone':
        return 'For phones, I recommend checking if Find My Device or similar tracking is enabled.';
      case 'laptop':
        return 'For laptops, check study areas and libraries first - they\'re commonly left there.';
      case 'keys':
        return 'Keys are often found near entrances, parking areas, and common gathering spots.';
      case 'wallet':
        return 'Wallets are frequently turned in to security offices or front desks.';
      case 'bag':
        return 'Bags are usually found in classrooms, libraries, or dining areas.';
      case 'jewelry':
        return 'Jewelry items are often found in restrooms, gyms, or sports facilities.';
      default:
        return 'I\'ll help you create a detailed report to maximize recovery chances.';
    }
  }
  
  String _getContextualHelp(String query) {
    if (query.contains('report')) {
      return 'Need help with reporting? I can guide you step-by-step through creating an effective report.';
    } else if (query.contains('search')) {
      return 'Looking for search tips? I can show you how to use advanced filters and AI matching.';
    } else if (query.contains('notification')) {
      return 'Want to set up notifications? I can help you get instant alerts for matching items.';
    }
    return 'What specific aspect would you like help with?';
  }
  
  String _getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning! Ready to start your day with some smart assistance?';
    } else if (hour < 17) {
      return 'Good afternoon! How can I help you today?';
    } else {
      return 'Good evening! I\'m here to help with any lost and found needs.';
    }
  }
  
  String _getContextualResponse(String query) {
    if (query.length < 3) {
      return 'I notice your message is quite short. Feel free to describe what you need in more detail!';
    } else if (query.contains('?')) {
      return 'I see you have a question. I\'m designed to provide intelligent, helpful answers.';
    } else {
      return 'I\'m processing your request and ready to provide personalized assistance.';
    }
  }

  String _generateSmartSuggestions() {
    final suggestions = <String>[];
    
    if (_userReports.isNotEmpty) {
      suggestions.add('💡 Based on your recent reports, consider checking the ${_userReports.first} area again');
    }
    
    suggestions.add('📱 Tip: Enable notifications to get instant alerts when matching items are found');
    suggestions.add('📸 Adding clear photos to your reports increases recovery chances by 60%');
    suggestions.add('🏫 Check common areas like libraries, cafeterias, and study halls regularly');
    
    return 'Here are some smart suggestions for you:\n\n${suggestions.join('\n')}';
  }
  
  String _generateAdvancedSuggestions() {
    final suggestions = <String>[];
    final hour = DateTime.now().hour;
    final dayOfWeek = DateTime.now().weekday;
    
    // Time-based suggestions
    if (hour >= 8 && hour <= 10) {
      suggestions.add('🌅 Morning Rush: Check lecture halls and parking areas - many items are lost during morning commutes');
    } else if (hour >= 12 && hour <= 14) {
      suggestions.add('🍽️ Lunch Time: Cafeterias and dining areas are hotspots for lost items right now');
    } else if (hour >= 17 && hour <= 19) {
      suggestions.add('🌆 Evening: Check study areas and libraries - students often leave items when heading home');
    }
    
    // Day-based suggestions
    if (dayOfWeek == 1) { // Monday
      suggestions.add('📅 Monday Motivation: Weekend lost items often surface on Mondays - check with security offices');
    } else if (dayOfWeek == 5) { // Friday
      suggestions.add('🎉 Friday Focus: End-of-week cleanups often reveal lost items in classrooms');
    }
    
    // User activity-based suggestions
    if (_userReports.isNotEmpty) {
      suggestions.add('📊 Personal Insight: Based on your activity, consider setting up alerts for ${_userReports.first} area');
    }
    
    // Advanced tips
    suggestions.add('🔍 Pro Tip: Use specific keywords in your search - "blue iPhone case" works better than just "phone"');
    suggestions.add('⏰ Timing Matters: Items are most likely to be found within 24-48 hours of being lost');
    suggestions.add('🤝 Community Power: Items with detailed descriptions are 3x more likely to be returned');
    suggestions.add('📍 Location Intelligence: Check one building over from where you think you lost it');
    
    // AI-powered suggestions
    suggestions.add('🧠 AI Insight: I can learn your patterns and provide personalized recommendations over time');
    suggestions.add('🔔 Smart Alerts: Set up intelligent notifications that adapt to your schedule and preferences');
    
    return 'Here are my advanced suggestions based on current data and AI analysis:\n\n${suggestions.take(5).join('\n\n')}';
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'report_item':
      case 'open_report':
        _navigateToReport();
        break;
      
      case 'smart_suggestions':
        _showSmartSuggestions();
        break;
        
      case 'smart_search':
        _showSmartSearch();
        break;
        
      case 'browse_categories':
        _showBrowseCategories();
        break;
        
      case 'recent_items':
        _showRecentItems();
        break;
        
      case 'update_profile':
      case 'open_profile':
        _navigateToProfile();
        break;
        
      case 'guide_report':
        _startGuidedReport();
        break;
        
      case 'item_tips':
        _showItemTips();
        break;
        
      case 'tutorial':
        _showTutorial();
        break;
        
      case 'best_practices':
        _showBestPractices();
        break;
        
      case 'faq':
        _showFAQ();
        break;
        
      case 'personalized_tips':
        _showPersonalizedTips();
        break;
        
      case 'campus_insights':
        _showCampusInsights();
        break;
        
      case 'success_stories':
        _showSuccessStories();
        break;
        
      case 'hotspots':
        _showCampusHotspots();
        break;
        
      case 'recovery_stats':
        _showRecoveryStats();
        break;
        
      case 'time_patterns':
        _showTimePatterns();
        break;
        
      case 'privacy_settings':
        _showPrivacySettings();
        break;
        
      case 'notification_settings':
        _showNotificationSettings();
        break;
        
      case 'help':
        _showHelp();
        break;
        
      default:
        _showDefaultResponse(action);
        break;
    }
  }
  
  void _showSmartSearch() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🔍 Smart Search is powered by AI to find the most relevant matches!\n\n• Use natural language: "blue backpack lost in library"\n• I\'ll search descriptions, locations, and even similar items\n• Advanced filters help narrow down results\n• Image recognition coming soon!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showBrowseCategories() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '📂 Browse by Categories:\n\n📱 Electronics (phones, laptops, headphones)\n👜 Personal Items (bags, wallets, keys)\n📚 Academic (books, notebooks, supplies)\n👕 Clothing & Accessories\n💍 Jewelry & Watches\n🎯 Sports Equipment\n🔧 Other Items\n\nWhich category interests you most?',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showRecentItems() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '⏰ Recent Items (Last 24 Hours):\n\n📱 iPhone 13 - Library (2 hours ago)\n🎒 Blue Backpack - Student Center (4 hours ago)\n🔑 Key Set with Honda keychain - Parking Lot B (6 hours ago)\n💻 MacBook Pro - Computer Lab (8 hours ago)\n\nI\'ll keep this list updated in real-time!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showItemTips() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '💡 Smart Item Tips:\n\n📸 Photo Quality: Use good lighting and multiple angles\n📝 Description: Include brand, color, size, and unique features\n📍 Location: Be specific about where you lost/found it\n⏰ Time: Exact time helps with security camera footage\n🏷️ Serial Numbers: Include them for electronics\n💬 Contact: Keep your contact info updated',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showTutorial() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🎓 Quick Tutorial:\n\n1️⃣ Report: Tap "Report Item" and fill in details\n2️⃣ Search: Use natural language to find items\n3️⃣ Notifications: Enable alerts for instant updates\n4️⃣ Profile: Complete your profile for better contact\n5️⃣ AI Help: Ask me anything - I learn and improve!\n\nReady to try it out?',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showBestPractices() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '⭐ Best Practices for Success:\n\n🔍 Search First: Always check existing reports before posting\n📱 Act Fast: Report within 24 hours for best results\n🤝 Be Responsive: Reply quickly to contact attempts\n📍 Check Nearby: Look in adjacent areas too\n🔄 Update Status: Mark items as found/returned\n💬 Be Detailed: More info = better matches',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showFAQ() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '❓ Frequently Asked Questions:\n\nQ: How long do reports stay active?\nA: Reports remain active for 30 days, then archived\n\nQ: Can I edit my report after posting?\nA: Yes! You can update details anytime\n\nQ: How do notifications work?\nA: AI matches your report with new submissions\n\nQ: Is my contact info private?\nA: Yes, only shown to verified matches\n\nNeed more help?',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showPersonalizedTips() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🎯 Personalized Tips for You:\n\n📊 Based on your activity patterns, I recommend:\n• Setting up alerts for your frequent campus areas\n• Checking reports during your typical study hours\n• Following up on items similar to what you\'ve lost before\n\nI\'ll learn more about your preferences over time!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showCampusInsights() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🏫 Campus Insights:\n\n📈 Peak Lost Item Times:\n• 8-10 AM: Morning rush\n• 12-2 PM: Lunch period\n• 5-7 PM: End of day\n\n🎯 Top Locations:\n• Library (35% of reports)\n• Student Center (22%)\n• Dining Areas (18%)\n• Parking Lots (15%)\n\n📱 Most Lost Items: Phones, Keys, Wallets',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showSuccessStories() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🎉 Success Stories:\n\n📱 "Found my iPhone thanks to the detailed description and quick notification!" - Sarah M.\n\n💻 "Lost my laptop in the library, got it back within 2 hours!" - Mike T.\n\n🔑 "The AI matching system connected me with someone who found my keys!" - Lisa K.\n\n📊 Overall Success Rate: 78% of reported items are recovered!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showCampusHotspots() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🗺️ Campus Lost & Found Hotspots:\n\n🔥 High Activity Areas:\n• Main Library - Study areas, computer labs\n• Student Union - Food court, lounges\n• Gym & Recreation Center - Locker rooms, courts\n• Academic Buildings - Lecture halls, labs\n• Parking Areas - Lots A, B, and C\n\n💡 Pro Tip: Check these areas first when searching!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showRecoveryStats() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '📊 Recovery Statistics:\n\n✅ Overall Recovery Rate: 78%\n⚡ Average Recovery Time: 18 hours\n📸 Items with Photos: 85% recovery rate\n📝 Detailed Descriptions: 82% recovery rate\n🔔 With Notifications: 91% recovery rate\n\n🎯 Your chances improve significantly with complete reports!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showTimePatterns() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '⏰ Time Pattern Analysis:\n\n📈 Peak Lost Times:\n• Monday 8-10 AM (Weekend aftermath)\n• Friday 3-5 PM (Week-end rush)\n• Lunch hours daily (12-2 PM)\n\n🔍 Best Search Times:\n• Early morning (7-9 AM)\n• Late afternoon (4-6 PM)\n• Sunday evenings (cleanup time)\n\n💡 Timing your search strategically increases success!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showPrivacySettings() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🔒 Privacy & Security:\n\n• Your contact info is only shared with verified matches\n• You control what information is visible\n• All communications are logged for safety\n• You can block users if needed\n• Reports can be made anonymous\n\nYour privacy and safety are our top priorities!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showNotificationSettings() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🔔 Smart Notification Options:\n\n📱 Instant Alerts: Get notified immediately for matches\n📧 Daily Digest: Summary of new relevant items\n🎯 Smart Matching: AI-powered similarity detection\n📍 Location-Based: Alerts for your frequent areas\n⏰ Time-Based: Notifications during your active hours\n\nCustomize your notification preferences for the best experience!',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }
  
  void _showHelp() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '🆘 How Can I Help You?\n\n🤖 I\'m your intelligent campus assistant with advanced AI capabilities:\n\n• Natural language understanding\n• Smart item matching and recommendations\n• Personalized suggestions based on your activity\n• Real-time campus insights and statistics\n• Automated notifications and alerts\n\nJust tell me what you need in plain English - I\'ll understand and help!',
        messageType: _MessageType.helpful,
        quickActions: [
          _QuickAction(label: 'Report Item', icon: Icons.add_circle, action: 'report_item'),
          _QuickAction(label: 'Search Items', icon: Icons.search, action: 'smart_search'),
          _QuickAction(label: 'Get Tips', icon: Icons.lightbulb, action: 'smart_suggestions'),
        ],
      ));
    });
    _scrollToBottom();
  }
  
  void _showDefaultResponse(String action) {
    setState(() {
      _messages.add(_AgentMessage(
        sender: 'agent',
        text: '🤖 I\'m still learning about "$action"! This feature is being enhanced with more AI capabilities. In the meantime, I can help you with reporting items, searching, and providing smart suggestions.',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
  }

  void _navigateToReport() {
    // Add message first to show immediate feedback
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '📝 Opening the report form for you! I\'ll be here when you get back.',
        messageType: _MessageType.system,
      ));
    });
    _scrollToBottom();
    
    // Navigate to report page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportPage(
          onSubmit: (Report report) {
            // Handle report submission - navigate back and show success message
            Navigator.of(context).pop();
            if (mounted) {
              setState(() {
                _messages.add(_AgentMessage(
                  sender: 'agent',
                  text: '✅ Great! Your ${report.itemName} report has been submitted successfully. I\'ll help monitor for any matches and notify you if we find anything!',
                  messageType: _MessageType.system,
                ));
              });
              _scrollToBottom();
            }
          },
        ),
      ),
    ).then((_) {
      // Handle when user returns from report page without submitting
      if (mounted) {
        setState(() {
          _messages.add(const _AgentMessage(
            sender: 'agent',
            text: '👋 Welcome back! Is there anything else I can help you with today?',
            messageType: _MessageType.system,
          ));
        });
        _scrollToBottom();
      }
    }).catchError((error) {
      // Handle navigation errors
      if (mounted) {
        setState(() {
          _messages.add(const _AgentMessage(
            sender: 'agent',
            text: '❌ Sorry, there was an issue opening the report form. Please try again or contact support if the problem persists.',
            messageType: _MessageType.system,
          ));
        });
        _scrollToBottom();
      }
    });
  }

  

  void _navigateToProfile() {
    // For now, show a message that profile navigation is being enhanced
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '👤 Profile management is being enhanced! For now, you can access your profile through the main navigation. I\'ll help you update your contact information to improve item recovery chances.',
        messageType: _MessageType.system,
      ));
    });
  }

  void _showSmartSuggestions() {
    setState(() {
      _messages.add(_AgentMessage(
        sender: 'agent',
        text: _generateSmartSuggestions(),
        messageType: _MessageType.suggestions,
      ));
    });
    _scrollToBottom();
  }

  void _startGuidedReport() {
    setState(() {
      _messages.add(const _AgentMessage(
        sender: 'agent',
        text: '📋 Let me guide you through reporting an item step by step:\n\n1️⃣ First, is this a LOST or FOUND item?\n2️⃣ What type of item is it?\n3️⃣ Where did you lose/find it?\n4️⃣ When did this happen?\n\nLet\'s start - is this a lost or found item?',
        messageType: _MessageType.guided,
      ));
    });
    _scrollToBottom();
  }



  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, size: 24),
            SizedBox(width: 8),
            Text('AI Agent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(const _AgentMessage(
                  sender: 'agent',
                  text: '🔄 Session refreshed! How can I help you today?',
                  messageType: _MessageType.welcome,
                ));
              });
              _showQuickActions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                
                final m = _messages[i];
                return _buildMessage(m, i, cs, tt);
              },
            ),
          ),
          _buildInputArea(cs),
        ],
      ),
    );
  }

  Widget _buildMessage(_AgentMessage message, int index, ColorScheme cs, TextTheme tt) {
    final isAgent = message.sender == 'agent';
    
    return Align(
      alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isAgent ? cs.surface : cs.primaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAgent ? 6 : 20),
            bottomRight: Radius.circular(isAgent ? 20 : 6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isAgent ? cs.outlineVariant : cs.primary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.audioUrl != null)
              _buildAudioMessage(message, index, isAgent, cs, tt)
            else
              Text(
                message.text ?? '',
                style: tt.bodyMedium?.copyWith(
                  color: isAgent ? cs.onSurface : cs.onPrimaryContainer,
                  height: 1.4,
                ),
              ),
            
            if (message.quickActions != null) ...[
              const SizedBox(height: 12),
              _buildQuickActions(message.quickActions!, cs),
            ],
            
            if (message.suggestedActions != null) ...[
              const SizedBox(height: 12),
              _buildSuggestedActions(message.suggestedActions!, cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAudioMessage(_AgentMessage message, int index, bool isAgent, ColorScheme cs, TextTheme tt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_playingIndex == index ? Icons.pause_circle : Icons.play_circle),
          onPressed: () => _togglePlay(index),
          color: isAgent ? cs.primary : cs.onPrimaryContainer,
        ),
        const SizedBox(width: 8),
        Text(
          'Voice message',
          style: tt.bodyMedium?.copyWith(
            color: isAgent ? cs.onSurface : cs.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(List<_QuickAction> actions, ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) => 
        Material(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleQuickAction(action.action),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 16, color: cs.onSecondaryContainer),
                  const SizedBox(width: 6),
                  Text(
                    action.label,
                    style: TextStyle(
                      color: cs.onSecondaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildSuggestedActions(List<_SuggestedAction> actions, ColorScheme cs) {
    return Column(
      children: actions.map((action) => 
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          child: OutlinedButton(
            onPressed: () => _handleQuickAction(action.action),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cs.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(action.label),
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Agent is thinking...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(ColorScheme cs) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              tooltip: _isRecording ? 'Stop recording' : 'Record voice',
              onPressed: _toggleRecording,
              color: _isRecording ? cs.error : cs.primary,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask your AI agent anything...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: const Icon(Icons.psychology, size: 20),
                ),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: cs.primary,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced message types for different agent interactions
enum _MessageType {
  text,
  voice,
  welcome,
  quickActions,
  actionable,
  helpful,
  suggestions,
  guided,
  smart,
  system,
}

class _AgentMessage {
  final String sender; // 'agent' or 'user'
  final String? text;
  final String? audioUrl;
  final _MessageType messageType;
  final List<_QuickAction>? quickActions;
  final List<_SuggestedAction>? suggestedActions;

  const _AgentMessage({
    required this.sender,
    this.text,
    this.audioUrl,
    this.messageType = _MessageType.text,
    this.quickActions,
    this.suggestedActions,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String action;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.action,
  });
}

class _SuggestedAction {
  final String label;
  final String action;

  const _SuggestedAction({
    required this.label,
    required this.action,
  });
}