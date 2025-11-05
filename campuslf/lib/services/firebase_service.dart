// Placeholder Firebase service - Firebase removed from project
// This file is kept to prevent import errors during transition

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Mock methods to prevent errors
  Future<dynamic> signUp(String email, String password) async {
    return null;
  }

  Future<dynamic> signIn(String email, String password) async {
    return null;
  }

  Future<dynamic> signInAnonymously() async {
    return null;
  }

  Future<void> signOut() async {}

  Future<dynamic> getCurrentUser() async {
    return null;
  }

  dynamic get currentUser => null;

  Stream<dynamic> get authStateChanges => const Stream.empty();

  Future<String?> addItem(dynamic item) async {
    return null;
  }

  Stream<List<dynamic>> getItems() {
    return Stream.value([]);
  }

  Future<bool> createUserProfile(Map<String, dynamic> userData) async {
    return false;
  }

  void dispose() {}
}