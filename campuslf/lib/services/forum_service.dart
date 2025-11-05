import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<List<Map<String, dynamic>>> getForumPosts() {
    return _firestore
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  static Future<void> createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('forum_posts').add({
      'userId': user.uid,
      'title': title,
      'content': content,
      'category': category,
      'viewCount': 0,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getComments(String postId) {
    return _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  static Future<void> addComment(String postId, String content) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('forum_posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}