import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../utils/logger.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _isAdminKey = 'is_admin';
  static const String _isGuestKey = 'is_guest';
  
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    // Prefer stored user id; fallback to Firebase currentUser uid if available
    return prefs.getString(_userIdKey) ?? _auth.currentUser?.uid;
  }

  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> setCurrentUser({
    required String userId,
    required String userName,
    required String userEmail,
    bool isAdmin = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setBool(_isAdminKey, isAdmin);
  }

  static Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) != null;
  }

  static Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  static Future<String?> register({
    required String email,
    required String password,
    required String name,
    String? studentId,
    String? phone,
  }) async {
    try {
      Logger.info('Registration attempt: $email');
      Logger.debug('Firebase Auth instance: ${_auth.app.name}');
      Logger.debug('Project ID: ${_auth.app.options.projectId}');
      
      if (password.length < 6) {
        Logger.error('Password too short');
        return 'Password must be at least 6 characters long';
      }
      
      Logger.info('Creating Firebase user...');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = credential.user;
      if (user == null) {
        Logger.error('Firebase user creation returned null');
        return 'Failed to create user account';
      }
      
      Logger.success('Firebase user created successfully!');
      Logger.info('   UID: ${user.uid}');
      Logger.info('   Email: ${user.email}');
      Logger.info('   Email Verified: ${user.emailVerified}');
      
      final uid = user.uid;
      Logger.info('Saving user data to Firestore...');
      
      final userData = {
        'name': name,
        'email': email,
        'studentId': studentId ?? '',
        'phone': phone ?? '',
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      final userDocRef = _firestore.collection('users').doc(uid);
      await userDocRef.set(userData);
      Logger.success('User data saved to Firestore');
      
      // Verify the document was created
      final savedDoc = await userDocRef.get();
      if (savedDoc.exists) {
        Logger.success('Firestore document verified: ${savedDoc.data()}');
      } else {
        Logger.warning('Firestore document not found after creation');
      }
      
      // Store locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data_$email', '$name|${studentId ?? ''}|${phone ?? ''}');
      
      await setCurrentUser(
        userId: uid,
        userName: name,
        userEmail: email,
        isAdmin: false,
      );
      
      Logger.success('Registration completed successfully');
      return null;
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      Logger.error('Firebase Auth error: ${e.code} - ${e.message}');
      Logger.error('   Stack trace: ${e.stackTrace}');
      
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled. Please contact support.';
        default:
          return 'Registration failed: ${e.message ?? e.code}';
      }
    } catch (e, stackTrace) {
      Logger.error('Registration error (unknown): $e');
      Logger.error('   Stack trace: $stackTrace');
      return 'Registration failed: ${e.toString()}';
    }
  }

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      Logger.info('Login attempt: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        Logger.error('Login returned null user');
        return 'Login failed - no user returned';
      }
      
      Logger.success('Firebase login successful: ${user.uid}');
      
      final uid = user.uid;
      String userName = email.split('@')[0].toUpperCase();

      // Try to read profile from Firestore
      final userRef = _firestore.collection('users').doc(uid);
      final doc = await userRef.get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && (data['name'] as String?)?.isNotEmpty == true) {
          userName = data['name'];
        }
        Logger.success('User profile loaded from Firestore: $userName');
      } else {
        Logger.warning('No Firestore profile found, creating minimal profile');
        await userRef.set({
          'name': userName,
          'email': email,
          'studentId': '',
          'phone': '',
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await setCurrentUser(
        userId: uid,
        userName: userName,
        userEmail: email,
        isAdmin: false,
      );
      
      Logger.success('Login completed successfully');
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      Logger.error('Login error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'No account found for this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        default:
          return 'Login failed: ${e.message ?? e.code}';
      }
    } catch (e) {
      Logger.error('Login error (unknown): $e');
      return 'Login failed: ${e.toString()}';
    }
  }

  static Future<void> loginGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await setCurrentUser(
      userId: 'guest',
      userName: 'Guest',
      userEmail: 'guest@local',
      isAdmin: false,
    );
    await prefs.setBool(_isGuestKey, true);
  }

  static Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('user-not-found')) {
        return 'No account found for this email.';
      } else if (msg.contains('invalid-email')) {
        return 'Please enter a valid email address.';
      } else if (msg.contains('network-request-failed')) {
        return 'Network error. Please check your internet connection.';
      }
      return 'Failed to send reset email: ${e.toString()}';
    }
  }

  static Future<bool> accountExists(String email) async {
    try {
      // Use createUserWithEmailAndPassword to check if account exists
      // This will throw 'email-already-in-use' if account exists
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: 'temp-password-for-check',
      );
      // If we reach here, account doesn't exist, so delete the temp account
      await _auth.currentUser?.delete();
      Logger.info('Account check for $email: NOT FOUND');
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Logger.info('Account check for $email: EXISTS');
        return true;
      }
      Logger.error('Account check error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      Logger.error('Account check error (unknown): $e');
      return false;
    }
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    final userName = prefs.getString(_userNameKey);
    final userEmail = prefs.getString(_userEmailKey);
    final isAdmin = prefs.getBool(_isAdminKey) ?? false;
    
    if (userId != null && userName != null && userEmail != null) {
      return User(
        id: userId,
        name: userName,
        email: userEmail,
        isAdmin: isAdmin,
      );
    }
    return null;
  }

  static Future<Map<String, String?>> getUserRegistrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);
    
    if (email != null) {
      final userData = prefs.getString('user_data_$email');
      if (userData != null) {
        final parts = userData.split('|');
        return {
          'name': parts.isNotEmpty ? parts[0] : name,
          'email': email,
          'studentId': parts.length > 1 ? parts[1] : '',
          'phone': parts.length > 2 ? parts[2] : '+27 ',
        };
      }
    }
    
    return {
      'name': name,
      'email': email,
      'studentId': '',
      'phone': '+27 ',
    };
  }

  static Future<String?> updateUserData({
    String? name,
    String? phone,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final updateData = <String, dynamic>{};
        if (name != null) updateData['name'] = name;
        if (phone != null) updateData['phone'] = phone;
        
        await _firestore.collection('users').doc(currentUser.uid).update(updateData);
        
        if (name != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userNameKey, name);
        }
        return null;
      }
    } catch (e) {
      return e.toString();
    }
    return 'Failed to update user data';
  }

  static Future<String?> deleteAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).delete();
        
        final userItems = await _firestore
            .collection('items')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
        
        for (var doc in userItems.docs) {
          await doc.reference.delete();
        }
        
        await currentUser.delete();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        
        return null;
      }
    } catch (e) {
      return e.toString();
    }
    return 'Failed to delete account';
  }

  // Test Firebase connection
  static Future<bool> testFirebaseConnection() async {
    try {
      Logger.info('Testing Firebase connection...');
      Logger.debug('   Auth instance: ${_auth.app.name}');
      Logger.debug('   Project ID: ${_auth.app.options.projectId}');
      Logger.debug('   Auth domain: ${_auth.app.options.authDomain}');
      
      // Try to get current user (should be null if not logged in)
      final currentUser = _auth.currentUser;
      Logger.debug('   Current user: ${currentUser?.uid ?? 'null'}');
      
      return true;
    } catch (e) {
      Logger.error('Firebase connection test failed: $e');
      return false;
    }
  }
}