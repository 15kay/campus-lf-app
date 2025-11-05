import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';
import '../services/firebase_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/logger.dart';



class MessagesScreen extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final String? directChatEmail;
  final String? directChatName;
  
  const MessagesScreen({
    super.key,
    required this.messages,
    this.directChatEmail,
    this.directChatName,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupLiveMessages();
    if (widget.directChatEmail != null && widget.directChatName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDirectChat();
      });
    }
  }

  void _setupLiveMessages() async {
    final currentUserEmail = await AuthService.getCurrentUserEmail();
    if (currentUserEmail == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    Logger.info('Setting up live messages for: $currentUserEmail');
    
    // Listen to messages in real-time
    FirebaseFirestore.instance
        .collection('messages')
        .where('receiverEmail', isEqualTo: currentUserEmail)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['isFromMe'] = false;
        return data;
      }).toList();
      
      // Sort by timestamp
      messages.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      Logger.success('Live update: ${messages.length} messages');
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty 
                      ? _buildEmptyState() 
                      : _buildMessagesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              try {
                Navigator.of(context).pop();
              } catch (e) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Chat with other users',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_messages.where((m) => !(m['isRead'] ?? true)).length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.message_outlined, size: 64, color: Color(0xFF8E8E93)),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Messages will appear here when someone\ncontacts you about your items',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getAvatarColor(message['senderName'] ?? 'User'),
              child: Text(
                (message['senderName'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    message['senderName'] ?? 'Anonymous',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  message['createdAt'] != null 
                      ? DateFormat('MMM dd, HH:mm').format((message['createdAt'] as Timestamp).toDate())
                      : 'Just now',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  message['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: !(message['isRead'] ?? true) ? Colors.red : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF8E8E93)),
              ],
            ),
            onTap: () => _openChat(message),
          ),
        );
      },
    );
  }

  void _openChat(Map<String, dynamic> message) async {
    // Mark message as read
    if (!(message['isRead'] ?? true)) {
      try {
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(message['id'])
            .update({'isRead': true});
      } catch (e) {
        Logger.error('Failed to mark message as read: $e');
      }
    }
    
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            contactId: message['senderId'],
            contactName: message['senderName'],
            contactEmail: message['senderEmail'],
          ),
        ),
      );
    }
  }

  void _openDirectChat() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            contactName: widget.directChatName!,
            contactEmail: widget.directChatEmail!,
            itemTitle: 'Item Inquiry',
          ),
        ),
      );
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
      Colors.pink.shade600,
    ];
    
    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class ChatScreen extends StatefulWidget {
  final String? contactName;
  final String? contactId;
  final String? contactEmail;
  final String? itemTitle;
  final String? itemId;

  const ChatScreen({
    super.key,
    this.contactName,
    this.contactId,
    this.contactEmail,
    this.itemTitle,
    this.itemId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _setupLiveChatMessages();
  }

  void _setupLiveChatMessages() async {
    final currentUserEmail = await AuthService.getCurrentUserEmail();
    if (currentUserEmail == null || widget.contactEmail == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    // Listen to messages between current user and contact
    FirebaseFirestore.instance
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((snapshot) {
      final messages = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderEmail = data['senderEmail'] ?? '';
        final receiverEmail = data['receiverEmail'] ?? '';
        
        // Show messages between current user and contact
        final isConversationMessage = 
            (senderEmail == currentUserEmail && receiverEmail == widget.contactEmail) ||
            (senderEmail == widget.contactEmail && receiverEmail == currentUserEmail);
            
        if (isConversationMessage) {
          final isFromMe = senderEmail == currentUserEmail;
          messages.add({
            'content': data['content'] ?? '',
            'isFromMe': isFromMe,
            'timestamp': data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            'senderName': isFromMe ? 'You' : (data['senderName'] ?? 'User'),
            'type': data['type'] ?? 'text',
            'imageUrl': data['imageUrl'],
            'messageId': doc.id,
          });
        }
      }
      
      if (mounted) {
        setState(() {
          _chatMessages.clear();
          _chatMessages.addAll(messages);
          _isLoading = false;
        });
        Logger.success('Chat updated: ${messages.length} messages, images: ${messages.where((m) => m['type'] == 'image').length}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildModernAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _chatMessages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        reverse: true,
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final messageData = _chatMessages[_chatMessages.length - 1 - index];
                          return _buildModernChatBubble(messageData);
                        },
                      ),
          ),
          _buildModernMessageInput(),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              try {
                Navigator.of(context).pop();
              } catch (e) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black,
            child: Text(
              (widget.contactName ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName ?? 'Unknown User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (widget.itemTitle != null)
                  Text(
                    'About: ${widget.itemTitle}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  )
                else if (widget.contactEmail != null)
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start the conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a message to begin chatting',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChatBubble(Map<String, dynamic> messageData) {
    final isFromMe = messageData['isFromMe'] ?? false;
    final content = messageData['content'] ?? '';
    final timestamp = messageData['timestamp'] as DateTime? ?? DateTime.now();
    final type = messageData['type'] ?? 'text';
    final imageUrl = messageData['imageUrl'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF6C7B7F),
              child: Text(
                (widget.contactName ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(type == 'image' ? 4 : 16),
                    decoration: BoxDecoration(
                      color: isFromMe ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isFromMe ? 20 : 4),
                        bottomRight: Radius.circular(isFromMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (type == 'image' && imageUrl != null) ...
                          _buildModernImageMessage(imageUrl),
                        if (type == 'text' && content.isNotEmpty)
                          Text(
                            content,
                            style: TextStyle(
                              color: isFromMe ? Colors.white : Colors.black,
                              fontSize: type == 'emoji' ? 28 : 15,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      DateFormat('HH:mm').format(timestamp),
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.black,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildModernImageMessage(String imageUrl) {
    return [
      Container(
        constraints: const BoxConstraints(
          maxWidth: 240,
          maxHeight: 180,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 240,
                height: 180,
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 240,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'Image failed to load',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildModernMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showEmojiPicker,
                  icon: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Color(0xFF8E8E93),
                    size: 22,
                  ),
                ),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(
                    Icons.image_outlined,
                    color: Color(0xFF8E8E93),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage({String? content, String? type, String? imageUrl}) async {
    final messageContent = content ?? _messageController.text.trim();
    if (messageContent.isEmpty && imageUrl == null) return;

    _messageController.clear();

    try {
      final currentUserId = await AuthService.getCurrentUserId();
      final currentUserName = await AuthService.getCurrentUserName();
      final currentUserEmail = await AuthService.getCurrentUserEmail();
      
      final messageData = {
        'senderId': currentUserId,
        'senderName': currentUserName ?? 'User',
        'senderEmail': currentUserEmail,
        'receiverEmail': widget.contactEmail,
        'content': messageContent,
        'type': type ?? 'text',
        'itemTitle': widget.itemTitle,
        'itemId': widget.itemId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };
      
      if (imageUrl != null) messageData['imageUrl'] = imageUrl;
      
      await FirebaseFirestore.instance.collection('messages').add(messageData);
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, ErrorHandler.getFirebaseErrorMessage(e.toString()));
      }
    }
  }

  void _showEmojiPicker() {
    final emojis = ['😀', '😂', '😍', '🥰', '😊', '😎', '🤔', '😢', '😡', '👍', '👎', '❤️', '🔥', '💯', '🎉', '👏'];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: emojis.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () {
              Navigator.pop(context);
              _sendMessage(content: emojis[index], type: 'emoji');
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    
    try {
      final imageUrl = await FirebaseStorageService.uploadPickedImage(
        image,
        'chat_images',
      );
      _sendMessage(type: 'image', imageUrl: imageUrl, content: 'Image');
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Failed to send image');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}