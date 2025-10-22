import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import '../models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;
  const ChatPage({super.key, required this.conversation});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  final ap.AudioPlayer _player = ap.AudioPlayer();

  String _otherUserName = '';
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  int? _playingIndex;

  // Professional color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF757575);

  // Dummy theme change function for navigation
  static void _dummyThemeChange(ThemeMode mode) {
    // This is a placeholder - theme changes will be handled by the main app
  }
  
  // Additional state variables
  bool _isTyping = false;
  Timer? _typingTimer;
  
  // Local state for instant message display
  final List<Message> _localMessages = [];
  final Set<String> _pendingMessageIds = {};

  @override
  void initState() {
    super.initState();
    
    // Debug: Log conversation details
    print('DEBUG: Chat page initialized');
    print('DEBUG: Conversation ID: ${widget.conversation.id}');
    print('DEBUG: Participants: ${widget.conversation.participants}');
    print('DEBUG: UserA: ${widget.conversation.userA}');
    print('DEBUG: UserB: ${widget.conversation.userB}');
    
    // Validate conversation ID to prevent empty document path errors
    if (widget.conversation.id.isEmpty) {
      print('ERROR: Conversation ID is empty, cannot initialize chat');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid conversation. Please try again.'))
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }
    
    // Validate participants
    if (widget.conversation.participants.length < 2 || 
        widget.conversation.userA.isEmpty || 
        widget.conversation.userB.isEmpty) {
      print('ERROR: Invalid conversation participants');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid conversation participants. Please try again.'))
          );
          Navigator.of(context).pop();
        }
      });
      return;
    }
    
    // Ensure conversation document exists in Firestore
    _db.collection('conversations').doc(widget.conversation.id).set({
      'id': widget.conversation.id,
      'participants': [widget.conversation.userA, widget.conversation.userB],
      'lastActivity': DateTime.now(),
    }, SetOptions(merge: true));
    
    // Listen to authentication state changes
    _auth.authStateChanges().listen((user) {
      if (user == null && mounted) {
        // User logged out, navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication lost. Please log in again.'))
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
    
    // Mark messages as read when chat is opened
    _markMessagesAsRead();
    
    // Fetch other user's name
    _fetchOtherUserName();
  }

  Future<void> _fetchOtherUserName() async {
    try {
      final currentUid = _auth.currentUser?.uid ?? '';
      final otherUid = widget.conversation.userA == currentUid 
          ? widget.conversation.userB 
          : widget.conversation.userA;
      
      final userDoc = await _db.collection('users').doc(otherUid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['name'] != null) {
          setState(() {
            _otherUserName = userData['name'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
      // Fallback to UID if name fetch fails
      final currentUid = _auth.currentUser?.uid ?? '';
      final otherUid = widget.conversation.userA == currentUid 
          ? widget.conversation.userB 
          : widget.conversation.userA;
      setState(() {
        _otherUserName = otherUid;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _player.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _addMessage(Message msg) async {
    print('DEBUG: Attempting to send message: ${msg.text}');
    print('DEBUG: From UID: ${msg.fromUid}');
    print('DEBUG: To UID: ${msg.toUid}');
    print('DEBUG: Conversation ID: ${widget.conversation.id}');
    
    // Validate message data to prevent empty document paths
    if (msg.id.isEmpty || msg.fromUid.isEmpty || msg.toUid.isEmpty || widget.conversation.id.isEmpty) {
      print('ERROR: Invalid message data - empty IDs detected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message: Invalid data'))
        );
      }
      return;
    }
    
    // Add to local state immediately for instant UI display
    setState(() {
      _localMessages.add(msg);
      _pendingMessageIds.add(msg.id);
    });
    print('DEBUG: Message added to local state for instant display');
    print('DEBUG: Local messages count: ${_localMessages.length}');
    print('DEBUG: Pending message IDs: $_pendingMessageIds');
    
    // Persist to Firestore in the background
    try {
      // Ensure conversation document exists in Firestore
      await _db.collection('conversations').doc(widget.conversation.id).set({
        'participants': [msg.fromUid, msg.toUid],
        'lastActivity': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('DEBUG: Conversation document ensured in Firestore');
      
      // Persist message to Firestore and update last activity
      final msgData = {
        'id': msg.id,
        'fromUid': msg.fromUid,
        'toUid': msg.toUid,
        'content': msg.text, // Store as 'content' to match retrieval
        'timestamp': msg.timestamp,
        'type': msg.type,
        'status': 'delivered', // Set directly to delivered for faster UI updates
        'imageUrl': msg.imageUrl,
        'attachmentName': msg.attachmentName,
        'mimeType': msg.mimeType,
        'audioUrl': msg.audioUrl,
        'callKind': msg.callKind,
        'callDurationSeconds': msg.callDurationSeconds,
      };
      
      print('DEBUG: Message data prepared: $msgData');
      
      await _db.collection('conversations').doc(widget.conversation.id)
        .collection('messages').doc(msg.id).set(msgData);
        
      print('DEBUG: Message successfully written to Firestore with delivered status');
      
      await _db.collection('conversations').doc(widget.conversation.id)
        .set({'lastActivity': DateTime.now()}, SetOptions(merge: true));

      // Create/update chat document for both users to ensure they both see the conversation
      final chatId = _getChatId(msg.fromUid, msg.toUid);
      final recipientId = msg.toUid;
      
      // Validate chatId before using it
      if (chatId.isEmpty) {
        print('ERROR: Failed to generate valid chatId for users: ${msg.fromUid}, ${msg.toUid}');
        throw Exception('Invalid chat ID generated');
      }
      
      // Get user profiles for display names
      final senderDoc = await _db.collection('users').doc(msg.fromUid).get();
      final recipientDoc = await _db.collection('users').doc(msg.toUid).get();
      
      final senderName = senderDoc.exists ? (senderDoc.data()?['name'] ?? 'Unknown') : 'Unknown';
      final recipientName = recipientDoc.exists ? (recipientDoc.data()?['name'] ?? 'Unknown') : 'Unknown';
      
      await _db.collection('chats').doc(chatId).set({
        'participants': [msg.fromUid, msg.toUid],
        'conversationId': widget.conversation.id,
        'lastMessage': msg.type == 'text' ? msg.text :
                      msg.type == 'image' ? '📷 Photo' :
                      msg.type == 'audio' ? '🎵 Voice message' :
                      msg.type == 'call' ? '📞 ${msg.callKind != null ? '${msg.callKind![0].toUpperCase()}${msg.callKind!.substring(1)}' : 'Call'}' : 'Message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_$recipientId': FieldValue.increment(1),
        'senderName': senderName,
        'recipientName': recipientName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('DEBUG: Chat document created/updated for both users');
      print('DEBUG: Chat ID: $chatId');
      print('DEBUG: Participants: [${msg.fromUid}, ${msg.toUid}]');

      // Auto-scroll after message appears via stream
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      print('DEBUG: Error sending message: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      
      // Update local message status to failed
      setState(() {
        final localMsgIndex = _localMessages.indexWhere((m) => m.id == msg.id);
        if (localMsgIndex != -1) {
          _localMessages[localMsgIndex].status = 'failed';
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // Check authentication first
    if (!_isUserAuthenticated()) return;
    
    final uid = _auth.currentUser!.uid;
    
    // Additional validation for conversation data
    if (widget.conversation.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid conversation. Please try again.')));
      Navigator.of(context).pop();
      return;
    }
    
    final otherUid = widget.conversation.userA == uid ? widget.conversation.userB : widget.conversation.userA;
    if (otherUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid recipient. Please try again.')));
      return;
    }
    final msg = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      fromUid: uid,
      toUid: otherUid,
      text: text,
      timestamp: DateTime.now(),
      type: 'text',
      status: 'delivered', // Set to delivered for immediate UI feedback
    );
    print('DEBUG: Created message with status: ${msg.status}');
    _controller.clear();
    _addMessage(msg);
  }

  Future<void> _simulateUserBMessage() async {
    print('DEBUG: Simulating message from User B');
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUid = widget.conversation.userA == uid ? widget.conversation.userB : widget.conversation.userA;

    // Create a list of test messages from User B
    final testMessages = [
      'Hello! This is a test message from User B 👋',
      'How are you doing?',
      'The message sync is working great! 🎉',
      'This message was simulated for testing purposes',
      'You should see this message appear in real-time',
    ];
    
    final randomMessage = testMessages[DateTime.now().millisecond % testMessages.length];
    
    try {
      // Create message data directly in Firestore (simulating User B sending it)
      final msgData = {
        'id': 'msg_userb_${DateTime.now().millisecondsSinceEpoch}',
        'fromUid': otherUid, // From User B
        'toUid': uid, // To current user
        'content': randomMessage,
        'timestamp': DateTime.now(),
        'type': 'text',
        'status': 'delivered',
        'imageUrl': null,
        'attachmentName': null,
        'mimeType': null,
        'audioUrl': null,
        'callKind': null,
        'callDurationSeconds': null,
      };
      
      print('DEBUG: Simulating User B message: $msgData');
      
      // Add directly to Firestore (bypassing local state since it's from another user)
      await _db.collection('conversations').doc(widget.conversation.id)
        .collection('messages').doc(msgData['id'] as String).set(msgData);
        
      print('DEBUG: User B message successfully added to Firestore');
      
      // Update conversation last activity
      await _db.collection('conversations').doc(widget.conversation.id)
        .set({'lastActivity': DateTime.now()}, SetOptions(merge: true));
        
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Simulated User B message - check if it appears!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error simulating User B message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simulate User B message: $e')),
        );
      }
    }
  }

  Future<void> _simulateUserAMessage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final otherUserId = widget.conversation.participants.firstWhere((id) => id != uid);
      
      final msgData = {
        'id': 'test_${DateTime.now().millisecondsSinceEpoch}_a',
        'senderId': uid, // Current user (User A)
        'recipientId': otherUserId,
        'conversationId': widget.conversation.id,
        'content': 'Hello from User A! This is a test message to verify User A → User B messaging works.',
        'timestamp': DateTime.now(),
        'type': 'text',
        'status': 'delivered',
        'imageUrl': null,
        'attachmentName': null,
        'mimeType': null,
        'audioUrl': null,
        'callKind': null,
        'callDurationSeconds': null,
      };
      
      print('DEBUG: Simulating User A message: $msgData');
      
      // Add directly to Firestore
      await _db.collection('conversations').doc(widget.conversation.id)
        .collection('messages').doc(msgData['id'] as String).set(msgData);
        
      print('DEBUG: User A message successfully added to Firestore');
      
      // Update conversation last activity
      await _db.collection('conversations').doc(widget.conversation.id)
        .set({'lastActivity': DateTime.now()}, SetOptions(merge: true));
        
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Simulated User A message - this should appear as YOUR message!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error simulating User A message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simulate User A message: $e')),
        );
      }
    }
  }

  Future<void> _simulateConversation() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final otherUserId = widget.conversation.participants.firstWhere((id) => id != uid);
      
      // Simulate a conversation with multiple messages
      final messages = [
        {
          'senderId': uid,
          'content': 'Hey! Are you free to chat?',
          'delay': 0,
        },
        {
          'senderId': otherUserId,
          'content': 'Hi! Yes, I\'m here. What\'s up?',
          'delay': 2000,
        },
        {
          'senderId': uid,
          'content': 'Just testing the message sync between our accounts',
          'delay': 4000,
        },
        {
          'senderId': otherUserId,
          'content': 'Cool! I can see your messages perfectly 👍',
          'delay': 6000,
        },
        {
          'senderId': uid,
          'content': 'Awesome! The bidirectional sync is working!',
          'delay': 8000,
        },
      ];

      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        
        // Wait for the specified delay
        final delay = msg['delay'] as int;
        if (delay > 0) {
          await Future.delayed(Duration(milliseconds: delay));
        }
        
        final msgData = {
          'id': 'test_conv_${DateTime.now().millisecondsSinceEpoch}_$i',
          'senderId': msg['senderId'],
          'recipientId': msg['senderId'] == uid ? otherUserId : uid,
          'conversationId': widget.conversation.id,
          'content': msg['content'],
          'timestamp': DateTime.now(),
          'type': 'text',
          'status': 'delivered',
          'imageUrl': null,
          'attachmentName': null,
          'mimeType': null,
          'audioUrl': null,
          'callKind': null,
          'callDurationSeconds': null,
        };
        
        print('DEBUG: Adding conversation message ${i + 1}: ${msg['content']}');
        
        // Add to Firestore
        await _db.collection('conversations').doc(widget.conversation.id)
          .collection('messages').doc(msgData['id'] as String).set(msgData);
      }
      
      // Update conversation last activity
      await _db.collection('conversations').doc(widget.conversation.id)
        .set({'lastActivity': DateTime.now()}, SetOptions(merge: true));
        
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Simulated full conversation - watch messages appear in real-time!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error simulating conversation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to simulate conversation: $e')),
        );
      }
    }
  }



  // Voice: start/stop recording, append audio message
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required')));
          }
        }
      } else {
        final path = await _recorder.stop();
        setState(() => _isRecording = false);
        if (path != null && path.isNotEmpty) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          if (uid.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to send a voice message.')));
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
            }
            return;
          }
          final toUid = widget.conversation.userA == uid ? widget.conversation.userB : widget.conversation.userA;

          String finalAudioUrl = path; // default to local path (non-web)
          try {
            if (kIsWeb) {
              // Fetch blob bytes from the returned web blob URL and upload to Firebase Storage
              final response = await http.get(Uri.parse(path));
              final bytes = response.bodyBytes;
              final storagePath = 'voice/${widget.conversation.id}/${DateTime.now().millisecondsSinceEpoch}.wav';
              final ref = _storage.ref(storagePath);
              await ref.putData(bytes, SettableMetadata(contentType: 'audio/wav'));
              finalAudioUrl = await ref.getDownloadURL();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload voice message: $e')));
            }
          }

          final msg = Message(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            fromUid: uid,
            toUid: toUid,
            text: '',
            timestamp: DateTime.now(),
            type: 'audio',
            status: 'delivered', // Set to delivered for immediate UI feedback
            audioUrl: finalAudioUrl,
          );
          _addMessage(msg);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recording error: $e')));
      }
    }
  }

  // Voice: play/pause audio messages - Fixed to use Firestore data
  Future<void> _togglePlay(String audioUrl, int index) async {
    if (audioUrl.isEmpty) return;
    try {
      if (_playingIndex == index) {
        await _player.pause();
        setState(() => _playingIndex = null);
        return;
      }
      await _player.stop();
      final ap.Source src = kIsWeb ? ap.UrlSource(audioUrl) : ap.DeviceFileSource(audioUrl);
      await _player.play(src);
      setState(() => _playingIndex = index);
      _player.onPlayerStateChanged.listen((state) {
        if (state == ap.PlayerState.completed) {
          if (mounted) setState(() => _playingIndex = null);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  // Add camera functionality
  Future<void> _pickCameraImage() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
      if (xfile == null) return;
      await _processImageAttachment(xfile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _pickImageAttachment() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
      if (xfile == null) return;
      await _processImageAttachment(xfile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to attach image: $e')),
        );
      }
    }
  }

  Future<void> _processImageAttachment(XFile xfile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (!mounted) return;
    if (uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to attach images.')));
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    try {
      final bytes = await xfile.readAsBytes();
      final fileExt = xfile.name.split('.').last.toLowerCase();
      final storagePath = 'chatAttachments/${widget.conversation.id}/${DateTime.now().millisecondsSinceEpoch}_${xfile.name}';
      final ref = _storage.ref(storagePath);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/$fileExt'));
      final downloadUrl = await ref.getDownloadURL();

      final msg = Message(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        fromUid: uid,
        toUid: widget.conversation.userA == uid ? widget.conversation.userB : widget.conversation.userA,
        text: '',
        timestamp: DateTime.now(),
        type: 'image',
        status: 'delivered', // Set to delivered for immediate UI feedback
        imageUrl: downloadUrl,
        attachmentName: xfile.name,
        mimeType: 'image/$fileExt',
      );
      await _addMessage(msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Professional light background
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32), // Professional green
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2), // Professional blue
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _otherUserName.isNotEmpty ? _otherUserName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUserName.isNotEmpty ? _otherUserName : 'Chat',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('conversations').doc(widget.conversation.id)
                .collection('messages').orderBy('timestamp').snapshots(),
              builder: (ctx, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                
                // Debug: Log incoming data
                print('DEBUG: StreamBuilder triggered');
                print('DEBUG: Snapshot has data: ${snapshot.hasData}');
                print('DEBUG: Snapshot error: ${snapshot.error}');
                print('DEBUG: Documents count: ${docs.length}');
                print('DEBUG: Listening to conversation: ${widget.conversation.id}');
                
                // Convert Firestore docs to Message objects
                List<Message> firestoreMessages = docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final ts = d['timestamp'];
                  final dt = ts is Timestamp ? ts.toDate() : (ts is String ? DateTime.tryParse(ts) : DateTime.now());
                  
                  // Debug: Log each message
                  print('DEBUG: Firestore message - ID: ${d['id']}, From: ${d['fromUid']}, To: ${d['toUid']}, Content: ${d['content']}');
                  
                  return Message(
                    id: d['id'] ?? '',
                    fromUid: d['fromUid'] ?? '',
                    toUid: d['toUid'] ?? '',
                    text: d['content'] ?? '',
                    timestamp: dt,
                    type: d['type'] ?? 'text',
                    status: d['status'] ?? 'delivered',
                    imageUrl: d['imageUrl'],
                    attachmentName: d['attachmentName'],
                    mimeType: d['mimeType'],
                    audioUrl: d['audioUrl'],
                    callKind: d['callKind'],
                    callDurationSeconds: d['callDurationSeconds'],
                  );
                }).where((message) {
                  // Filter out messages with empty UIDs to prevent document path errors
                  if (message.id.isEmpty || message.fromUid.isEmpty || message.toUid.isEmpty) {
                    print('WARNING: Filtering out message with empty UIDs - ID: ${message.id}, From: ${message.fromUid}, To: ${message.toUid}');
                    return false;
                  }
                  return true;
                }).toList();
                
                // Remove local messages that are now in Firestore
                _localMessages.removeWhere((localMsg) => 
                  firestoreMessages.any((fsMsg) => fsMsg.id == localMsg.id));
                _pendingMessageIds.removeWhere((id) => 
                  firestoreMessages.any((fsMsg) => fsMsg.id == id));
                
                // Combine local and Firestore messages, then sort by timestamp
                List<Message> allMessages = [..._localMessages, ...firestoreMessages];
                allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                
                // Debug: Log message count and details
                print('DEBUG: StreamBuilder updated with ${firestoreMessages.length} Firestore messages, ${_localMessages.length} local messages');
                print('DEBUG: Total combined messages: ${allMessages.length}');
                if (_localMessages.isNotEmpty) {
                  print('DEBUG: Local messages: ${_localMessages.map((m) => '${m.id}: ${m.text}').join(', ')}');
                }
                
                // Auto-scroll when new messages arrive
                if (allMessages.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: allMessages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    // Show typing indicator as last item
                    if (i == allMessages.length && _isTyping) {
                      return _buildTypingIndicator();
                    }
                    
                    final m = allMessages[i];
                    final isMe = m.fromUid == uid;
                    return _buildChatMessage(m, isMe, i);
                  },
                );
              },
            ),
          ),
          _buildChatInputBar(),
          if (_showEmojiPicker)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _controller.text += emoji.emoji;
                  setState(() {}); // Update send button state
                },
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    backgroundColor: const Color(0xFFF0F0F0),
                    columns: 7,
                    emojiSizeMax: 32,
                  ),
                  skinToneConfig: const SkinToneConfig(),
                  categoryViewConfig: const CategoryViewConfig(),
                  bottomActionBarConfig: const BottomActionBarConfig(),
                  searchViewConfig: const SearchViewConfig(),
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildChatMessage(Message m, bool isMe, int index) {
    return Container(
      margin: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 64 : 8,
        right: isMe ? 8 : 64,
      ),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF2E7D32) : Colors.white, // Professional green for sent messages
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageContent(m, isMe, index),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(m.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildDeliveryStatus(m),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined, 
                        color: const Color(0xFF757575)
                      ),
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
                        onChanged: (text) {
                          setState(() {}); // Update send button state
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Color(0xFF757575)),
                      onPressed: _pickImageAttachment,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Color(0xFF757575)),
                      onPressed: _pickImageAttachment,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _controller.text.trim().isNotEmpty
                ? GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32), // Professional green
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )
                : GestureDetector(
                    onLongPressStart: (_) => _toggleRecording(),
                    onLongPressEnd: (_) => _toggleRecording(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isRecording ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32), // Professional red/green
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message m, bool isMe, int index) {
    switch (m.type) {
      case 'image':
        if (m.imageUrl != null && m.imageUrl!.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              m.imageUrl!,
              fit: BoxFit.cover,
              width: 200,
              height: 200,
            ),
          );
        } else if (m.attachmentBytes != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              m.attachmentBytes!,
              fit: BoxFit.cover,
              width: 200,
              height: 200,
            ),
          );
        }
        return Text(
          m.text.isNotEmpty ? m.text : 'Image attachment',
          style: const TextStyle(fontSize: 14),
        );

      case 'audio':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _playingIndex == index ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFF2E7D32), // Professional green
                ),
                onPressed: () => _togglePlay(m.audioUrl ?? '', index), // Fixed audio playback
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 8),
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0), // Professional light gray
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  width: 60, // Simulate audio progress
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32), // Professional green
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:15', // Placeholder duration
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      default:
        return Text(
          m.text,
          style: const TextStyle(fontSize: 14),
        );
    }
  }

  void _handleTyping() {
    if (!_isTyping) {
      setState(() {
        _isTyping = true;
      });
    }
    
    // Cancel previous timer
    _typingTimer?.cancel();
    
    // Set new timer to stop typing indicator after 2 seconds of inactivity
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  Widget _buildTypingIndicator() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUid = widget.conversation.userA == uid ? widget.conversation.userB : widget.conversation.userA;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                   '$otherUid is typing...',
                   style: TextStyle(
                     color: Colors.grey[600],
                     fontSize: 14,
                     fontStyle: FontStyle.italic,
                   ),
                 ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryStatus(Message message) {
    print('DEBUG: Building delivery status for message: ${message.id}, status: ${message.status}');
    // Use actual message status instead of time-based simulation
    switch (message.status) {
      case 'sending':
        // Sending (clock icon)
        return const Icon(
          Icons.access_time,
          size: 16,
          color: Colors.white70,
        );
      case 'delivered':
        // Delivered (single check)
        return const Icon(
          Icons.done,
          size: 16,
          color: Colors.white70,
        );
      case 'read':
        // Read (double check, blue)
        return const Icon(
          Icons.done_all,
          size: 16,
          color: Colors.blue,
        );
      case 'failed':
        // Failed (error icon, red)
        return const Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red,
        );
      default:
        // Default to delivered for unknown status
        return const Icon(
          Icons.done,
          size: 16,
          color: Colors.white70,
        );
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }



  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId.isEmpty) return;
      
      // Validate conversation data
      if (widget.conversation.id.isEmpty || 
          widget.conversation.userA.isEmpty || 
          widget.conversation.userB.isEmpty) {
        print('ERROR: Invalid conversation data in _markMessagesAsRead');
        return;
      }

      // Create or update chat document for unread count tracking
      final chatId = _getChatId(widget.conversation.userA, widget.conversation.userB);
      if (chatId.isEmpty) {
        print('ERROR: Generated empty chatId in _markMessagesAsRead');
        return;
      }
      
      await _db.collection('chats').doc(chatId).set({
        'participants': [widget.conversation.userA, widget.conversation.userB],
        'conversationId': widget.conversation.id,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'Chat opened',
        'unreadCount_$currentUserId': 0, // Reset unread count for current user
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
    }
  }

  String _getChatId(String uid1, String uid2) {
    // Validate input UIDs
    if (uid1.isEmpty || uid2.isEmpty) {
      print('ERROR: Empty UID provided to _getChatId: uid1="$uid1", uid2="$uid2"');
      return '';
    }
    
    // Create consistent chat ID regardless of order
    final sortedUids = [uid1, uid2]..sort();
    return '${sortedUids[0]}_${sortedUids[1]}';
  }

  bool _isUserAuthenticated() {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to continue'))
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return false;
    }
    return true;
  }
}