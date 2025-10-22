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
    
    // Context-aware responses
    if (query.contains('report') || query.contains('lost') || query.contains('found')) {
      return const _AgentMessage(
        sender: 'agent',
        text: '📝 I can help you report a lost or found item! Would you like me to guide you through the process or open the report form directly?',
        messageType: _MessageType.actionable,
        suggestedActions: [
          _SuggestedAction(label: 'Open Report Form', action: 'open_report'),
          _SuggestedAction(label: 'Guide Me Through', action: 'guide_report'),
        ],
      );
    }
    

    
    if (query.contains('profile') || query.contains('account') || query.contains('settings')) {
      return const _AgentMessage(
        sender: 'agent',
        text: '👤 I can help you update your profile information. This helps other users contact you when they find your items!',
        messageType: _MessageType.actionable,
        suggestedActions: [
          _SuggestedAction(label: 'Update Profile', action: 'open_profile'),
          _SuggestedAction(label: 'Privacy Settings', action: 'privacy_settings'),
        ],
      );
    }
    
    if (query.contains('help') || query.contains('how') || query.contains('tutorial')) {
      return const _AgentMessage(
        sender: 'agent',
        text: '💡 I\'m here to help! I can assist with reporting items, providing smart suggestions based on your activity, and automating common tasks. What specific help do you need?',
        messageType: _MessageType.helpful,
      );
    }
    
    if (query.contains('suggestion') || query.contains('recommend') || query.contains('smart')) {
      return _AgentMessage(
        sender: 'agent',
        text: _generateSmartSuggestions(),
        messageType: _MessageType.suggestions,
      );
    }
    
    // Default intelligent response
    return const _AgentMessage(
      sender: 'agent',
      text: '🤖 I understand you\'re looking for assistance. I\'m an AI agent designed to help with lost and found items. I can help you report items, provide personalized suggestions, and automate tasks. How can I assist you today?',
      messageType: _MessageType.text,
    );
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

  void _handleQuickAction(String action) {
    switch (action) {
      case 'report_item':
        _navigateToReport();
        break;
      
      case 'smart_suggestions':
        _showSmartSuggestions();
        break;
      case 'update_profile':
        _navigateToProfile();
        break;
      case 'open_report':
        _navigateToReport();
        break;
      case 'guide_report':
        _startGuidedReport();
        break;
      case 'open_profile':
        _navigateToProfile();
        break;
    }
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