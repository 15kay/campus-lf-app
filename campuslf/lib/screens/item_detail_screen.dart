import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../models/item.dart';
import '../services/realtime_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

import 'messages_screen.dart';
import 'smart_matches_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  final Function(int) onKarmaUpdate;
  final List<Item>? allItems;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.onKarmaUpdate,
    this.allItems,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> with TickerProviderStateMixin {
  bool _isBookmarked = false;
  int _selectedImageIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late List<String> _images;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _commentController = TextEditingController();
  late Item _currentItem;

  // Images used for preview and management
  List<String> get _itemImages => _images;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    // Initialize images from item
    if (widget.item.imagePaths != null && widget.item.imagePaths!.isNotEmpty) {
      _images = List<String>.from(widget.item.imagePaths!);
    } else if (widget.item.imagePath != null) {
      _images = [widget.item.imagePath!];
    } else {
      _images = ['placeholder'];
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildLikesAndComments() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          FutureBuilder<String?>(
            future: AuthService.getCurrentUserId(),
            builder: (context, snapshot) {
              final userId = snapshot.data ?? '';
              final isLiked = _currentItem.isLikedBy(userId);
              return GestureDetector(
                onTap: () => _toggleLike(userId),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentItem.likesCount}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 32),
          GestureDetector(
            onTap: () => _showCommentInput(),
            child: Row(
              children: [
                const Icon(Icons.comment_outlined, color: Colors.grey, size: 24),
                const SizedBox(width: 8),
                Text(
                  '${_currentItem.commentsCount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_currentItem.comments.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMMENTS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...(_currentItem.comments.take(3).map((comment) => _buildCommentItem(comment))),
          if (_currentItem.comments.length > 3)
            TextButton(
              onPressed: () => _showAllComments(),
              child: Text('View all ${_currentItem.comments.length} comments'),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                comment.getTimeAgo(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            comment.text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLike(String userId) async {
    if (userId.isEmpty) return;
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final newLikes = List<String>.from(_currentItem.likes);
      if (_currentItem.isLikedBy(userId)) {
        newLikes.remove(userId);
      } else {
        newLikes.add(userId);
      }
      
      await RealtimeService().updateItem(_currentItem.id, {'likes': newLikes});
      
      setState(() {
        _currentItem = Item(
          id: _currentItem.id,
          title: _currentItem.title,
          description: _currentItem.description,
          location: _currentItem.location,
          dateTime: _currentItem.dateTime,
          isLost: _currentItem.isLost,
          contactInfo: _currentItem.contactInfo,
          category: _currentItem.category,
          imagePath: _currentItem.imagePath,
          imagePaths: _currentItem.imagePaths,
          likes: newLikes,
          comments: _currentItem.comments,
        );
      });
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to update like: $e')),
        );
      }
    }
  }

  void _showCommentInput() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Comment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your comment...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addComment(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final userId = await AuthService.getCurrentUserId() ?? '';
      final userName = await AuthService.getCurrentUserName() ?? 'User';
      
      final comment = Comment(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        text: text,
        dateTime: DateTime.now(),
      );
      
      final newComments = List<Comment>.from(_currentItem.comments);
      newComments.add(comment);
      
      await RealtimeService().updateItem(_currentItem.id, {
        'comments': newComments.map((c) => c.toJson()).toList(),
      });
      
      setState(() {
        _currentItem = Item(
          id: _currentItem.id,
          title: _currentItem.title,
          description: _currentItem.description,
          location: _currentItem.location,
          dateTime: _currentItem.dateTime,
          isLost: _currentItem.isLost,
          contactInfo: _currentItem.contactInfo,
          category: _currentItem.category,
          imagePath: _currentItem.imagePath,
          imagePaths: _currentItem.imagePaths,
          likes: _currentItem.likes,
          comments: newComments,
        );
      });
      
      _commentController.clear();
      navigator.pop();
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to add comment: $e')),
        );
      }
    }
  }

  void _showAllComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Comments (${_currentItem.comments.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _currentItem.comments.length,
                  itemBuilder: (context, index) => _buildCommentItem(_currentItem.comments[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildImageGallery(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildItemInfo(),
                  _buildDescription(),
                  _buildLikesAndComments(),
                  _buildCommentsList(),
                  _buildSpecs(),
                  _buildContactSection(),
                  _buildActionButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
            icon: Icon(
              _isBookmarked ? Icons.favorite : Icons.favorite_border,
              color: _isBookmarked ? Colors.red : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedImageIndex = index;
                });
              },
              itemCount: _itemImages.length,
              itemBuilder: (context, index) {
                final imagePath = _itemImages[index];
                
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                  child: Center(
                    child: imagePath == 'placeholder'
                        ? Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: widget.item.isLost ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Item.getCategoryIcon(widget.item.category),
                              color: widget.item.isLost ? Colors.red : Colors.green,
                              size: 80,
                            ),
                          )
                        : Container(
                            margin: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: imagePath.startsWith('http')
                                  ? Image.network(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 200,
                                          height: 200,
                                          decoration: BoxDecoration(
                                            color: widget.item.isLost ? Colors.red.shade100 : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(
                                            Item.getCategoryIcon(widget.item.category),
                                            color: widget.item.isLost ? Colors.red : Colors.green,
                                            size: 80,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Item.getCategoryIcon(widget.item.category),
                                        color: widget.item.isLost ? Colors.red : Colors.green,
                                        size: 80,
                                      ),
                                    ),
                            ),
                          ),
                  ),
                );
              },
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedImageIndex + 1}/${_itemImages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _itemImages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _selectedImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _selectedImageIndex == index
                          ? Colors.black
                          : Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.item.isLost ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  widget.item.isLost ? 'LOST ITEM' : 'FOUND ITEM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  DateFormat('MMM dd').format(widget.item.dateTime),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.item.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Item.getCategoryName(widget.item.category),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.item.location,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESCRIPTION',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.item.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecs() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETAILS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Status', widget.item.isLost ? 'Lost' : 'Found'),
          _buildSpecRow('Category', Item.getCategoryName(widget.item.category)),
          _buildSpecRow('Location', widget.item.location),
          _buildSpecRow('Date Reported', DateFormat('MMMM dd, yyyy').format(widget.item.dateTime)),
          _buildSpecRow('Time', DateFormat('HH:mm').format(widget.item.dateTime)),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTACT OWNER',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.email, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.item.contactInfo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getReporterName() {
    // Extract name from email format
    final email = widget.item.contactInfo;
    if (email.contains('@mywsu.ac.za')) {
      // Student format: 202012345@mywsu.ac.za
      if (email.startsWith('20')) {
        return 'Student ${email.split('@')[0]}';
      }
      // Staff format: j+doe@wsu.ac.za
      else {
        final username = email.split('@')[0];
        if (username.contains('+')) {
          final parts = username.split('+');
          return '${parts[0].toUpperCase()}. ${parts[1].split('').map((e) => e.toUpperCase()).join('')}';
        }
        return username.split('').map((e) => e.toUpperCase()).join('');
      }
    }
    return 'Item Reporter';
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                
                try {
                  final currentUserId = await AuthService.getCurrentUserId();
                  final currentUserName = await AuthService.getCurrentUserName();
                  final currentUserEmail = await AuthService.getCurrentUserEmail();
                  final receiverEmail = widget.item.contactInfo;
                  final content = "Hi! I'm interested in your ${widget.item.title}. Is it still available?";
                  
                  if (currentUserId == null || currentUserEmail == null) {
                    throw Exception('User not logged in');
                  }
                  
                  // Prevent messaging yourself
                  if (currentUserEmail == receiverEmail) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('You cannot message yourself about your own item'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  // Store message directly in Firestore
                  await FirebaseFirestore.instance.collection('messages').add({
                    'senderId': currentUserId,
                    'senderName': currentUserName ?? 'User',
                    'senderEmail': currentUserEmail,
                    'receiverEmail': receiverEmail,
                    'content': content,
                    'itemTitle': widget.item.title,
                    'itemId': widget.item.id,
                    'createdAt': FieldValue.serverTimestamp(),
                    'isRead': false,
                  });
                  
                  Logger.success('Message stored in Firestore');
                  Logger.info('   From: $currentUserEmail');
                  Logger.info('   To: $receiverEmail');
                  Logger.info('   Content: $content');

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Message sent successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Navigate to chat screen
                    navigator.push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          contactName: _getReporterName(),
                          contactEmail: receiverEmail,
                          itemTitle: widget.item.title,
                          itemId: widget.item.id,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  Logger.error('Send message error: $e');
                  if (mounted) {
                    ErrorHandler.showError(context, ErrorHandler.getFirebaseErrorMessage(e.toString()));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'SEND MESSAGE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      if (widget.allItems != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SmartMatchesScreen(
                              targetItem: widget.item,
                              allItems: widget.allItems!,
                              onKarmaUpdate: widget.onKarmaUpdate,
                            ),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      side: const BorderSide(color: Colors.blue),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 14),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'MATCHES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FutureBuilder<String?>(
                  future: AuthService.getCurrentUserEmail(),
                  builder: (context, snap) {
                    final email = snap.data;
                    final isOwner = email != null && email == widget.item.contactInfo;
                    if (!isOwner) return const SizedBox.shrink();
                    return SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _showManagePhotos,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library, size: 14),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'MANAGE PHOTOS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                width: 44,
                child: OutlinedButton(
                  onPressed: () {
                    widget.onKarmaUpdate(5);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Thanks for helping! +5 karma points'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.check, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showManagePhotos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Manage Photos', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    final img = _images[index];
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                        clipBehavior: Clip.antiAlias,
                        child: img.startsWith('http')
                            ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
                            : (img == 'placeholder' ? const Icon(Icons.image) : const Icon(Icons.image)),
                      ),
                      title: Text('Image ${index + 1}${index == 0 ? ' (Main)' : ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.star),
                            tooltip: 'Make main photo',
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              // Move selected image to front
                              final img = _images.removeAt(index);
                              _images.insert(0, img);
                              setState(() {});
                              await RealtimeService().updateItem(widget.item.id, {
                                'imagePaths': _images,
                                'imagePath': _images.first,
                              });
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(content: Text('Set as main photo')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _replacePhoto(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletePhoto(index),
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
      },
    );
  }

  Future<void> _deletePhoto(int index) async {
    try {
      // Confirm deletion
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove photo?'),
          content: const Text('This photo will be removed from the item. You can undo right after.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
          ],
        ),
      );
      if (confirm != true) return;

      final removedUrl = _images[index];
      // Delete from storage if it is a remote URL
      if (removedUrl.startsWith('http')) {
        await FirebaseStorageService.deleteImage(removedUrl);
      }
      setState(() {
        _images.removeAt(index);
        if (_images.isEmpty) {
          _images = ['placeholder'];
        }
      });
      // Update Firestore document
      await RealtimeService().updateItem(widget.item.id, {
        'imagePaths': _images.first == 'placeholder' ? [] : _images,
        'imagePath': _images.first == 'placeholder' ? null : _images.first,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo removed'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () async {
                setState(() {
                  if (_images.first == 'placeholder') {
                    _images = [removedUrl];
                  } else {
                    _images.insert(index, removedUrl);
                  }
                });
                await RealtimeService().updateItem(widget.item.id, {
                  'imagePaths': _images,
                  'imagePath': _images.isNotEmpty ? _images.first : null,
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e')),
        );
      }
    }
  }

  Future<void> _replacePhoto(int index) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      String? url;
      final isGuest = await AuthService.isGuest();
      if (!isGuest) {
        // Show progress dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Uploading photo'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Please wait...'),
                ],
              ),
            ),
          );
        }
        url = await FirebaseStorageService.uploadImageWithProgress(
          picked,
          'items',
          (p) {
            // Progress callback - no UI updates needed
          },
        );
        if (mounted) navigator.pop();
      } else {
        url = picked.path; // local preview for guest
      }
      if (url != null) {
        setState(() {
          _images[index] = url!;
        });
        await RealtimeService().updateItem(widget.item.id, {
          'imagePaths': _images,
          'imagePath': _images.isNotEmpty ? _images.first : null,
        });
        if (mounted) navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to replace photo: $e')),
        );
      }
    }
  }
}