import 'package:cloud_firestore/cloud_firestore.dart';

class UsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'uid': doc.id,
                'name': data['name'] ?? '',
                'email': data['email'] ?? '',
                'phone': data['phone'] ?? '',
                'studentId': data['studentId'] ?? '',
                'createdAt': data['createdAt'],
                'status': data['status'] ?? 'active',
                'role': data['role'] ?? 'user',
              };
            }).toList());
  }

  Future<void> updateUserStatus(String uid, String status) async {
    await _firestore.collection('users').doc(uid).set({
      'status': status,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).set({
      'role': role,
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserDoc(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}