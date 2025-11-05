import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class FirebaseTest {
  static Future<void> testConnection() async {
    try {
      Logger.info('Testing Firebase connection...');
      
      // Test Firestore connection
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });
      Logger.success('Firestore connection successful');
      
      // Test Auth connection
      final auth = FirebaseAuth.instance;
      Logger.success('Firebase Auth initialized: ${auth.app.name}');
      
      Logger.success('All Firebase services connected successfully');
    } catch (e) {
      Logger.error('Firebase connection failed: $e');
    }
  }
  
  static Future<void> testRegistration() async {
    try {
      Logger.info('Testing registration with dummy data...');
      
      final auth = FirebaseAuth.instance;
      final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@mywsu.ac.za';
      
      final credential = await auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'test123456',
      );
      
      if (credential.user != null) {
        Logger.success('Test registration successful');
        await credential.user!.delete();
        Logger.success('Test user cleaned up');
      }
    } catch (e) {
      Logger.error('Test registration failed: $e');
    }
  }
}