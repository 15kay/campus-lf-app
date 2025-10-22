import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';
import '../models.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32), // Professional green
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32), // Professional green
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : const Text(
                'Chats',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
        elevation: 2,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete_all') {
                _showDeleteAllChatsDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Chats'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('chats')
              .where('participants', arrayContains: _auth.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2E7D32), // Professional green
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No chats yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start a conversation with someone',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Sort the documents by lastMessageTime manually
            final sortedDocs = snapshot.data!.docs.toList();
            sortedDocs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['lastMessageTime'] as Timestamp?;
              final bTime = bData['lastMessageTime'] as Timestamp?;
              
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              
              return bTime.compareTo(aTime); // Descending order (newest first)
            });

            // Filter chats based on search query (searching in last message content)
            final filteredDocs = _searchQuery.isEmpty
                ? sortedDocs
                : sortedDocs.where((doc) {
                    final chatData = doc.data() as Map<String, dynamic>;
                    final participants = List<String>.from(chatData['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                      (id) => id != _auth.currentUser?.uid,
                      orElse: () => '',
                    );
                    
                    if (otherUserId.isEmpty) return false;
                    
                    // Check if last message contains search query
                    final lastMessage = (chatData['lastMessage'] ?? '').toString().toLowerCase();
                    return lastMessage.contains(_searchQuery);
                  }).toList();

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: filteredDocs.length,
              itemBuilder: (context, index) {
                final chatDoc = filteredDocs[index];
                final chatData = chatDoc.data() as Map<String, dynamic>;
                
                return _buildChatListItem(chatDoc.id, chatData);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatListItem(String chatId, Map<String, dynamic> chatData) {
    final participants = List<String>.from(chatData['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != _auth.currentUser?.uid,
      orElse: () => '',
    );

    // Skip this chat if otherUserId is empty to prevent Firestore errors
    if (otherUserId.isEmpty) {
      print('WARNING: Skipping chat with empty otherUserId - ChatId: $chatId');
      return const SizedBox.shrink(); // Return empty widget
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        String userName = 'Unknown User';
        String userEmail = '';
        
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          userName = userData['name'] ?? 'Unknown User';
          userEmail = userData['email'] ?? '';
        }

        final lastMessage = chatData['lastMessage'] ?? 'No messages yet';
        final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
        final unreadCount = chatData['unreadCount_${_auth.currentUser?.uid}'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onLongPress: () {
              _showChatOptionsDialog(chatId, otherUserId, userName);
            },
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF2E7D32), // Professional green
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(lastMessageTime),
                  style: TextStyle(
                    color: unreadCount > 0 ? const Color(0xFF2E7D32) : Colors.grey[500], // Professional green
                    fontSize: 12,
                    fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32), // Professional green
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            onTap: () {
              // Create a conversation object for navigation
              final currentUserId = _auth.currentUser?.uid ?? '';
              final conversationId = chatData['conversationId']?.isNotEmpty == true 
                  ? chatData['conversationId'] 
                  : chatId; // Use chatId as fallback
              
              print('DEBUG: Chat list item tapped');
              print('DEBUG: ChatId: $chatId');
              print('DEBUG: ConversationId: $conversationId');
              print('DEBUG: CurrentUserId: $currentUserId');
              print('DEBUG: OtherUserId: $otherUserId');
              
              final conversation = Conversation(
                id: conversationId,
                participants: [currentUserId, otherUserId],
                messages: [], // Empty messages list for navigation
                lastActivity: (chatData['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => ChatPage(
                    conversation: conversation,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(messageTime);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return DateFormat('EEEE').format(messageTime);
    } else {
      // Older - show date
      return DateFormat('dd/MM/yyyy').format(messageTime);
    }
  }

  void _showChatOptionsDialog(String chatId, String otherUserId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chat with $userName'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chatId);
            },
            child: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _blockContact(otherUserId, userName);
            },
            child: const Text('Block Contact', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteChat(String chatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestore.collection('chats').doc(chatId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting chat: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _blockContact(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block $userName'),
        content: Text('Are you sure you want to block $userName? You will no longer receive messages from this user.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUserId = _auth.currentUser?.uid;
                if (currentUserId != null) {
                  // Add to blocked users list
                  await _firestore.collection('users').doc(currentUserId).update({
                    'blockedUsers': FieldValue.arrayUnion([userId])
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$userName has been blocked'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error blocking contact: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllChatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Chats'),
        content: const Text('Are you sure you want to delete ALL chats? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final currentUserId = _auth.currentUser?.uid;
                if (currentUserId != null) {
                  final chats = await _firestore
                      .collection('chats')
                      .where('participants', arrayContains: currentUserId)
                      .get();
                  
                  final batch = _firestore.batch();
                  for (var doc in chats.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All chats deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting chats: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}