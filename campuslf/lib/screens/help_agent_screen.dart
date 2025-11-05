import 'package:flutter/material.dart';


class HelpAgentScreen extends StatefulWidget {
  const HelpAgentScreen({super.key});

  @override
  State<HelpAgentScreen> createState() => _HelpAgentScreenState();
}

class _HelpAgentScreenState extends State<HelpAgentScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late TabController _tabController;
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi! I'm your WSU Lost & Found assistant. 👋\n\nI can help you with:\n• Reporting items\n• Searching tips\n• Safety guidelines\n• System features\n\nWhat would you like to know?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  final List<FAQ> _faqs = [
    FAQ(
      question: 'How do I report a lost item?',
      answer: 'To report a lost item:\n1. Tap "Report" in the bottom navigation\n2. Select "Lost Item"\n3. Fill in item details (name, description, location)\n4. Add photos if available\n5. Provide your contact information\n6. Submit the report\n\nYour report will be visible to all WSU community members.',
      category: 'Reporting',
    ),
    FAQ(
      question: 'How do I report a found item?',
      answer: 'To report a found item:\n1. Tap "Report" in the bottom navigation\n2. Select "Found Item"\n3. Describe the item in detail\n4. Add clear photos\n5. Specify where you found it\n6. Submit the report\n\nThe owner will be able to contact you through the app.',
      category: 'Reporting',
    ),
    FAQ(
      question: 'How does the karma system work?',
      answer: 'Karma points reward helpful community members:\n\n• +10 points: Report an item\n• +15 points: Successfully reunite an item\n• +5 points: Receive positive feedback\n• +3 points: Active forum participation\n\nHigher karma increases your credibility and unlocks special features.',
      category: 'System',
    ),
    FAQ(
      question: 'How do I search for my lost item?',
      answer: 'To search for items:\n1. Use the search bar on the home screen\n2. Enter keywords (item name, brand, color)\n3. Apply category filters\n4. Check the date range\n5. Browse through results\n6. Tap items for full details\n\nTip: Check both "Found Items" and forum posts.',
      category: 'Searching',
    ),
    FAQ(
      question: 'How do I contact someone about an item?',
      answer: 'To contact item reporters:\n1. Open the item details\n2. Tap "Send Message" or "Contact"\n3. Use the in-app messaging system\n4. Arrange a safe meetup location\n\nAlways meet in public campus areas during daylight hours.',
      category: 'Communication',
    ),
    FAQ(
      question: 'What safety guidelines should I follow?',
      answer: 'Safety is our priority:\n\n🏫 Meet in public campus areas only\n👥 Bring a friend if possible\n🌅 Meet during daylight hours\n📱 Use in-app messaging\n🆔 Verify ownership before handover\n🚨 Report suspicious activity\n📞 Contact security if needed: +27 43 702 9111',
      category: 'Safety',
    ),
    FAQ(
      question: 'How do I verify item ownership?',
      answer: 'To verify ownership:\n\n📋 Ask for specific details not in the post\n🏷️ Check for unique identifiers (serial numbers, scratches)\n📱 Ask them to describe contents (for bags/wallets)\n🆔 Request student ID verification\n📸 Compare with original photos\n\nIf unsure, involve campus security.',
      category: 'Safety',
    ),
    FAQ(
      question: 'What items are commonly lost on campus?',
      answer: 'Most commonly lost items:\n\n📱 Mobile phones and chargers\n💻 Laptops and tablets\n🔑 Keys and keychains\n👜 Bags and wallets\n📚 Textbooks and notebooks\n🎧 Headphones and earbuds\n👕 Clothing items\n🆔 Student ID cards\n⌚ Watches and jewelry',
      category: 'General',
    ),
    FAQ(
      question: 'How long are items kept in the system?',
      answer: 'Item retention policy:\n\n📅 Lost reports: Active for 6 months\n📅 Found reports: Active for 3 months\n📅 Resolved items: Archived after 30 days\n📅 Inactive accounts: Data removed after 1 year\n\nYou can extend or close your reports anytime.',
      category: 'System',
    ),
    FAQ(
      question: 'Can I edit or delete my reports?',
      answer: 'Managing your reports:\n\n✏️ Edit: Go to Profile > My Reports > Edit\n❌ Delete: Swipe left on report or use menu\n✅ Mark as resolved: Tap "Mark as Found"\n📧 Update contact info in Account Settings\n\nDeleted reports cannot be recovered.',
      category: 'System',
    ),
  ];

  final Map<String, String> _responses = {
    'report': 'I can help you with reporting items! Check the FAQ section above or ask me specific questions about the reporting process.',
    'search': 'Need help searching for items? The FAQ section has detailed instructions, or feel free to ask me anything specific!',
    'message': 'Questions about messaging? Check the Communication section in FAQ or ask me directly!',
    'karma': 'Want to know about karma points? Check the System section in FAQ for detailed information!',
    'safety': 'Safety is important! Check our comprehensive safety guidelines in the FAQ section above.',
    'contact': 'WSU Lost & Found Support:\n\n📧 lostfound@wsu.ac.za\n📞 +27 43 702 9111\n📍 Student Affairs Office\n\n🏫 Available at all WSU campuses:\n• Buffalo City Campus (Main)\n• Butterworth Campus\n• Queenstown Campus\n• Mthatha Campus\n\n🕒 Office Hours:\n   Mon-Fri: 8:00 AM - 4:30 PM\n   Sat: 8:00 AM - 12:00 PM\n\n🚨 Emergency: Campus Security\n📞 +27 43 702 9999 (24/7)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.support_agent, color: Colors.white, size: 18),
            ),
            SizedBox(width: 12),
            Text(
              'Help Assistant',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.black,
        tabs: const [
          Tab(text: 'FAQ'),
          Tab(text: 'Chat'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFAQSection(),
        _buildChatSection(),
      ],
    );
  }

  Widget _buildFAQSection() {
    final categories = _faqs.map((faq) => faq.category).toSet().toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find quick answers to common questions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map((category) => _buildFAQCategory(category)),
        ],
      ),
    );
  }

  Widget _buildFAQCategory(String category) {
    final categoryFAQs = _faqs.where((faq) => faq.category == category).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(category),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...categoryFAQs.map((faq) => _buildFAQItem(faq)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFAQItem(FAQ faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Reporting': return Colors.blue;
      case 'Searching': return Colors.green;
      case 'Communication': return Colors.orange;
      case 'Safety': return Colors.red;
      case 'System': return Colors.purple;
      case 'General': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildChatSection() {
    return Column(
      children: [
        _buildQuickActions(),
        Expanded(child: _buildChatArea()),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Help',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickActionChip('How to report?', 'report'),
              _buildQuickActionChip('How to search?', 'search'),
              _buildQuickActionChip('Send messages?', 'message'),
              _buildQuickActionChip('Karma system?', 'karma'),
              _buildQuickActionChip('Safety tips?', 'safety'),
              _buildQuickActionChip('Contact support?', 'contact'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, String key) {
    return GestureDetector(
      onTap: () => _sendQuickResponse(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.support_agent, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.black : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.green,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.black),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _messageController.clear();
    _generateResponse(userMessage);
  }

  void _sendQuickResponse(String key) {
    final response = _responses[key] ?? 'I can help you with that. Please ask me more specific questions.';
    
    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _generateResponse(String userMessage) {
    String response = 'I understand you need help. Here are some options:\n\n';
    
    final message = userMessage.toLowerCase();
    
    if (message.contains('report') || message.contains('lost') || message.contains('found')) {
      response = _responses['report']!;
    } else if (message.contains('search') || message.contains('find')) {
      response = _responses['search']!;
    } else if (message.contains('message') || message.contains('contact') || message.contains('chat')) {
      response = _responses['message']!;
    } else if (message.contains('karma') || message.contains('points')) {
      response = _responses['karma']!;
    } else if (message.contains('safe') || message.contains('security')) {
      response = _responses['safety']!;
    } else if (message.contains('support') || message.contains('help') || message.contains('phone')) {
      response = _responses['contact']!;
    } else {
      response = 'I can help you with:\n• Reporting items\n• Searching for items\n• Messaging system\n• Karma points\n• Safety guidelines\n• Contact support\n\nWhat would you like to know more about?';
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

class FAQ {
  final String question;
  final String answer;
  final String category;

  FAQ({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}