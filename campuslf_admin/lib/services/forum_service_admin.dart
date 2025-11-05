import 'package:cloud_firestore/cloud_firestore.dart';

class ForumServiceAdmin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream forum posts
  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return _firestore
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'title': data['title'] ?? '',
                'content': data['content'] ?? '',
                'category': data['category'] ?? 'General',
                'userId': data['userId'] ?? '',
                'userName': data['userName'] ?? 'Unknown',
                'createdAt': data['createdAt'],
                'likes': data['likes'] ?? 0,
              };
            }).toList());
  }

  Future<void> addPost({
    required String title,
    required String content,
    String category = 'General',
    String adminName = 'Admin',
  }) async {
    await _firestore.collection('forum_posts').add({
      'title': title,
      'content': content,
      'category': category,
      'userId': 'admin',
      'userName': adminName,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
    });
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    await _firestore.collection('forum_posts').doc(postId).set(data, SetOptions(merge: true));
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('forum_posts').doc(postId).delete();
  }

  // Comments
  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'text': data['text'] ?? '',
                'userId': data['userId'] ?? '',
                'userName': data['userName'] ?? 'Unknown',
                'createdAt': data['createdAt'],
              };
            }).toList());
  }

  Future<void> addComment({
    required String postId,
    required String text,
    String adminName = 'Admin',
  }) async {
    await _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .add({
      'text': text,
      'userId': 'admin',
      'userName': adminName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    await _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}