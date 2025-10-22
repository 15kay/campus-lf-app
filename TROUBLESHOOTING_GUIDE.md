# Troubleshooting Guide & FAQ
## Campus Lost & Found Application

### Table of Contents
1. [Quick Troubleshooting](#quick-troubleshooting)
2. [Installation Issues](#installation-issues)
3. [Authentication Problems](#authentication-problems)
4. [App Performance Issues](#app-performance-issues)
5. [Firebase Connection Issues](#firebase-connection-issues)
6. [UI/UX Problems](#uiux-problems)
7. [File Upload Issues](#file-upload-issues)
8. [Messaging Problems](#messaging-problems)
9. [Search and Filter Issues](#search-and-filter-issues)
10. [Platform-Specific Issues](#platform-specific-issues)
11. [Development Environment Issues](#development-environment-issues)
12. [Deployment Problems](#deployment-problems)
13. [Frequently Asked Questions](#frequently-asked-questions)
14. [Error Codes Reference](#error-codes-reference)
15. [Getting Help](#getting-help)

---

## Quick Troubleshooting

### First Steps for Any Issue
1. **Check your internet connection**
2. **Restart the application**
3. **Clear app cache/data**
4. **Update to the latest version**
5. **Check system requirements**

### Emergency Contacts
- **Technical Support**: support@campus-lf.edu
- **Emergency Hotline**: +1-800-CAMPUS-LF
- **Status Page**: https://status.campus-lf.edu

### System Status Check
```bash
# Check if services are running
curl -f https://api.campus-lf.edu/v1/health || echo "API is down"
curl -f https://campus-lf.edu || echo "Website is down"
```

---

## Installation Issues

### Flutter Installation Problems

#### Issue: Flutter SDK not found
**Symptoms:**
- Command `flutter` not recognized
- Build fails with "Flutter SDK not found"

**Solutions:**
```bash
# 1. Download and install Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# 2. Verify installation
flutter doctor

# 3. Fix any issues reported by flutter doctor
flutter doctor --android-licenses  # Accept Android licenses
```

#### Issue: Dart SDK version mismatch
**Symptoms:**
- Error: "The current Dart SDK version is X.X.X"
- Build fails with version conflicts

**Solutions:**
```bash
# 1. Update Flutter (includes Dart)
flutter upgrade

# 2. Check versions
flutter --version
dart --version

# 3. Clean and rebuild
flutter clean
flutter pub get
```

#### Issue: Android SDK issues
**Symptoms:**
- Android build fails
- "Android SDK not found" error

**Solutions:**
```bash
# 1. Install Android Studio and SDK
# Download from: https://developer.android.com/studio

# 2. Set environment variables
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 3. Accept licenses
flutter doctor --android-licenses

# 4. Install required SDK components
sdkmanager "platforms;android-33" "build-tools;33.0.0"
```

#### Issue: iOS build issues (macOS only)
**Symptoms:**
- iOS build fails
- Xcode errors

**Solutions:**
```bash
# 1. Install Xcode from App Store
# 2. Install Xcode command line tools
sudo xcode-select --install

# 3. Accept Xcode license
sudo xcodebuild -license accept

# 4. Install CocoaPods
sudo gem install cocoapods

# 5. Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
```

### Dependency Issues

#### Issue: Package version conflicts
**Symptoms:**
- `flutter pub get` fails
- Version solving failed

**Solutions:**
```yaml
# 1. Check pubspec.yaml for conflicts
# 2. Update dependencies
flutter pub upgrade

# 3. Override specific versions if needed
dependency_overrides:
  package_name: ^1.0.0

# 4. Clear pub cache
flutter pub cache repair
```

#### Issue: Firebase setup problems
**Symptoms:**
- Firebase initialization fails
- "No Firebase App" error

**Solutions:**
```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Login to Firebase
firebase login

# 3. Configure Firebase for Flutter
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Verify configuration files exist
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist
```

---

## Authentication Problems

### Sign-In Issues

#### Issue: Email/Password sign-in fails
**Symptoms:**
- "Invalid email or password" error
- Sign-in button doesn't respond

**Solutions:**
```dart
// 1. Check email format
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}

// 2. Verify Firebase Auth is enabled
// Go to Firebase Console > Authentication > Sign-in method

// 3. Check error handling
try {
  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
} catch (e) {
  print('Sign-in error: $e');
  // Handle specific error codes
}
```

#### Issue: Google Sign-In not working
**Symptoms:**
- Google Sign-In popup doesn't appear
- "Sign-in cancelled" error

**Solutions:**
```bash
# 1. Check Google Sign-In configuration
# Verify SHA-1 fingerprint in Firebase Console

# 2. Get SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# 3. Add fingerprint to Firebase Console
# Go to Project Settings > Your apps > SHA certificate fingerprints

# 4. Update google-services.json
# Download updated file from Firebase Console
```

#### Issue: Email verification not working
**Symptoms:**
- Verification email not received
- Email verification fails

**Solutions:**
```dart
// 1. Check spam folder
// 2. Resend verification email
User? user = FirebaseAuth.instance.currentUser;
if (user != null && !user.emailVerified) {
  await user.sendEmailVerification();
}

// 3. Check email template in Firebase Console
// Go to Authentication > Templates

// 4. Verify email domain is not blocked
// Check Firebase Console > Authentication > Settings
```

### Session Management Issues

#### Issue: User gets logged out frequently
**Symptoms:**
- Session expires quickly
- "User not authenticated" errors

**Solutions:**
```dart
// 1. Check token refresh
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user == null) {
    // Redirect to login
  } else {
    // User is signed in
  }
});

// 2. Implement proper session handling
class AuthService {
  static Future<void> refreshToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.getIdToken(true); // Force refresh
    }
  }
}

// 3. Check network connectivity
// Poor connection can cause auth issues
```

---

## App Performance Issues

### Slow App Startup

#### Issue: App takes too long to start
**Symptoms:**
- Long splash screen duration
- App appears frozen on startup

**Solutions:**
```dart
// 1. Optimize main() function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize only essential services
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

// 2. Use lazy loading for heavy operations
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: _initializeApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return HomePage();
          }
          return SplashScreen();
        },
      ),
    );
  }
}

// 3. Profile app startup
flutter run --profile
// Use DevTools to analyze performance
```

### Memory Issues

#### Issue: App crashes due to memory
**Symptoms:**
- App crashes randomly
- "Out of memory" errors
- Slow performance

**Solutions:**
```dart
// 1. Optimize image loading
Image.network(
  imageUrl,
  cacheWidth: 300, // Resize images
  cacheHeight: 300,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)

// 2. Dispose controllers properly
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose(); // Important!
    super.dispose();
  }
}

// 3. Use ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

### UI Lag and Stuttering

#### Issue: UI feels laggy or stutters
**Symptoms:**
- Animations are choppy
- Scrolling is not smooth
- UI freezes during operations

**Solutions:**
```dart
// 1. Use const constructors
const Text('Hello World') // Instead of Text('Hello World')

// 2. Avoid expensive operations in build()
class MyWidget extends StatelessWidget {
  final String expensiveData = _computeExpensiveData(); // Wrong!
  
  @override
  Widget build(BuildContext context) {
    final data = _computeExpensiveData(); // Wrong!
    return Text(data);
  }
}

// Correct approach:
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String? _data;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  void _loadData() async {
    final data = await _computeExpensiveData();
    setState(() {
      _data = data;
    });
  }
}

// 3. Use RepaintBoundary for complex widgets
RepaintBoundary(
  child: ComplexWidget(),
)
```

---

## Firebase Connection Issues

### Firestore Problems

#### Issue: Firestore queries fail
**Symptoms:**
- "Permission denied" errors
- Queries return empty results
- Connection timeouts

**Solutions:**
```javascript
// 1. Check Firestore security rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.uid;
    }
  }
}

// 2. Verify network connectivity
// 3. Check Firebase project configuration
// 4. Test with Firebase emulator
firebase emulators:start --only firestore
```

```dart
// 5. Add proper error handling
try {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('reports')
      .where('status', isEqualTo: 'lost')
      .get();
} on FirebaseException catch (e) {
  print('Firestore error: ${e.code} - ${e.message}');
  // Handle specific error codes
  switch (e.code) {
    case 'permission-denied':
      // Handle permission error
      break;
    case 'unavailable':
      // Handle network error
      break;
  }
}
```

#### Issue: Real-time updates not working
**Symptoms:**
- Data doesn't update in real-time
- Listeners not triggered

**Solutions:**
```dart
// 1. Check listener setup
StreamSubscription? _subscription;

@override
void initState() {
  super.initState();
  _subscription = FirebaseFirestore.instance
      .collection('reports')
      .snapshots()
      .listen((snapshot) {
    // Handle updates
  });
}

@override
void dispose() {
  _subscription?.cancel(); // Important!
  super.dispose();
}

// 2. Verify Firestore rules allow reads
// 3. Check network connectivity
// 4. Test offline persistence
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

### Firebase Storage Issues

#### Issue: File uploads fail
**Symptoms:**
- Upload progress stops
- "Upload failed" errors
- Files not appearing in storage

**Solutions:**
```dart
// 1. Check file size limits
const int maxFileSize = 10 * 1024 * 1024; // 10MB
if (file.lengthSync() > maxFileSize) {
  throw Exception('File too large');
}

// 2. Verify storage rules
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /report_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == userId &&
        request.resource.size < 10 * 1024 * 1024;
    }
  }
}

// 3. Add upload progress tracking
UploadTask uploadTask = storageRef.putFile(file);
uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
  double progress = snapshot.bytesTransferred / snapshot.totalBytes;
  print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
});

// 4. Handle upload errors
try {
  await uploadTask;
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'unauthorized':
      print('User not authorized to upload');
      break;
    case 'canceled':
      print('Upload canceled');
      break;
    case 'unknown':
      print('Unknown error occurred');
      break;
  }
}
```

---

## UI/UX Problems

### Layout Issues

#### Issue: Widgets overflow or don't fit properly
**Symptoms:**
- "RenderFlex overflowed" errors
- Text gets cut off
- Widgets appear outside screen bounds

**Solutions:**
```dart
// 1. Use Flexible or Expanded widgets
Row(
  children: [
    Expanded(
      child: Text('This text will wrap properly'),
    ),
    Icon(Icons.star),
  ],
)

// 2. Handle text overflow
Text(
  'Very long text that might overflow',
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)

// 3. Use SingleChildScrollView for scrollable content
SingleChildScrollView(
  child: Column(
    children: [
      // Your widgets here
    ],
  ),
)

// 4. Use LayoutBuilder for responsive design
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return DesktopLayout();
    } else {
      return MobileLayout();
    }
  },
)
```

#### Issue: Images not loading or displaying incorrectly
**Symptoms:**
- Broken image icons
- Images appear stretched or distorted
- Slow image loading

**Solutions:**
```dart
// 1. Add error handling for network images
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return CircularProgressIndicator(
      value: loadingProgress.expectedTotalBytes != null
          ? loadingProgress.cumulativeBytesLoaded / 
            loadingProgress.expectedTotalBytes!
          : null,
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.error);
  },
)

// 2. Use CachedNetworkImage for better performance
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fit: BoxFit.cover,
)

// 3. Optimize image sizes
// Resize images on server or use Firebase Storage transforms
```

### Navigation Issues

#### Issue: Navigation not working properly
**Symptoms:**
- Pages don't navigate
- Back button doesn't work
- Navigation stack issues

**Solutions:**
```dart
// 1. Check route definitions
MaterialApp(
  routes: {
    '/': (context) => HomePage(),
    '/login': (context) => LoginPage(),
    '/profile': (context) => ProfilePage(),
  },
  onGenerateRoute: (settings) {
    // Handle dynamic routes
    if (settings.name?.startsWith('/report/') == true) {
      final reportId = settings.name!.split('/')[2];
      return MaterialPageRoute(
        builder: (context) => ReportDetailPage(reportId: reportId),
      );
    }
    return null;
  },
)

// 2. Use proper navigation methods
// Push new page
Navigator.pushNamed(context, '/profile');

// Replace current page
Navigator.pushReplacementNamed(context, '/login');

// Pop to root
Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

// 3. Handle back button on Android
WillPopScope(
  onWillPop: () async {
    // Custom back button behavior
    return true; // Allow back
  },
  child: Scaffold(
    // Your page content
  ),
)
```

---

## File Upload Issues

### Image Upload Problems

#### Issue: Images fail to upload
**Symptoms:**
- Upload progress bar stuck
- "Upload failed" error messages
- Images don't appear after upload

**Solutions:**
```dart
// 1. Check file format and size
bool isValidImage(File file) {
  final extension = path.extension(file.path).toLowerCase();
  final validExtensions = ['.jpg', '.jpeg', '.png', '.gif'];
  final maxSize = 10 * 1024 * 1024; // 10MB
  
  return validExtensions.contains(extension) && 
         file.lengthSync() <= maxSize;
}

// 2. Compress images before upload
Future<File> compressImage(File file) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    '${file.parent.path}/compressed_${path.basename(file.path)}',
    quality: 85,
    minWidth: 1920,
    minHeight: 1080,
  );
  return result ?? file;
}

// 3. Implement retry mechanism
Future<String> uploadWithRetry(File file, {int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await _uploadFile(file);
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
    }
  }
  throw Exception('Upload failed after $maxRetries attempts');
}

// 4. Show upload progress
StreamBuilder<TaskSnapshot>(
  stream: uploadTask.snapshotEvents,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final progress = snapshot.data!.bytesTransferred / 
                      snapshot.data!.totalBytes;
      return LinearProgressIndicator(value: progress);
    }
    return Container();
  },
)
```

### File Permission Issues

#### Issue: Can't access device files
**Symptoms:**
- "Permission denied" when accessing gallery
- File picker doesn't open
- Camera access denied

**Solutions:**
```xml
<!-- Android: Add permissions to android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.CAMERA" />
```

```xml
<!-- iOS: Add permissions to ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
```

```dart
// Request permissions at runtime
Future<bool> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.storage,
  ].request();
  
  return statuses.values.every((status) => status.isGranted);
}

// Check permissions before file operations
if (await requestPermissions()) {
  // Proceed with file operations
} else {
  // Show permission denied message
}
```

---

## Messaging Problems

### Chat Issues

#### Issue: Messages not sending or receiving
**Symptoms:**
- Messages appear stuck in "sending" state
- New messages don't appear
- Chat history missing

**Solutions:**
```dart
// 1. Check Firestore connection
Future<void> testFirestoreConnection() async {
  try {
    await FirebaseFirestore.instance
        .collection('test')
        .doc('connection')
        .set({'timestamp': FieldValue.serverTimestamp()});
    print('Firestore connection OK');
  } catch (e) {
    print('Firestore connection failed: $e');
  }
}

// 2. Implement proper message status tracking
enum MessageStatus { sending, sent, delivered, read, failed }

class Message {
  final String id;
  final String content;
  final String senderId;
  final DateTime timestamp;
  final MessageStatus status;
  
  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.timestamp,
    this.status = MessageStatus.sending,
  });
}

// 3. Add retry mechanism for failed messages
Future<void> sendMessageWithRetry(Message message) async {
  try {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
    
    // Update status to sent
    _updateMessageStatus(message.id, MessageStatus.sent);
  } catch (e) {
    // Update status to failed
    _updateMessageStatus(message.id, MessageStatus.failed);
    
    // Show retry option
    _showRetryOption(message);
  }
}
```

#### Issue: Real-time messaging not working
**Symptoms:**
- Messages appear with delay
- Need to refresh to see new messages
- Typing indicators not working

**Solutions:**
```dart
// 1. Set up proper Firestore listeners
StreamSubscription? _messagesSubscription;

void _listenToMessages() {
  _messagesSubscription = FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .listen(
    (snapshot) {
      final messages = snapshot.docs
          .map((doc) => Message.fromMap(doc.data()))
          .toList();
      setState(() {
        _messages = messages;
      });
    },
    onError: (error) {
      print('Messages listener error: $error');
      // Implement reconnection logic
    },
  );
}

@override
void dispose() {
  _messagesSubscription?.cancel();
  super.dispose();
}

// 2. Implement typing indicators
Timer? _typingTimer;

void _onTyping() {
  // Send typing indicator
  FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .update({
    'typing.${currentUserId}': FieldValue.serverTimestamp(),
  });
  
  // Clear typing after 3 seconds
  _typingTimer?.cancel();
  _typingTimer = Timer(Duration(seconds: 3), () {
    _clearTyping();
  });
}

void _clearTyping() {
  FirebaseFirestore.instance
      .collection('conversations')
      .doc(conversationId)
      .update({
    'typing.${currentUserId}': FieldValue.delete(),
  });
}
```

### Video Call Issues

#### Issue: Video calls fail to connect
**Symptoms:**
- "Connection failed" errors
- Video/audio not working
- Call drops frequently

**Solutions:**
```dart
// 1. Check WebRTC permissions
Future<bool> checkWebRTCPermissions() async {
  final cameraPermission = await Permission.camera.request();
  final microphonePermission = await Permission.microphone.request();
  
  return cameraPermission.isGranted && microphonePermission.isGranted;
}

// 2. Test network connectivity
Future<bool> testNetworkForWebRTC() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}

// 3. Implement connection retry logic
class VideoCallService {
  int _retryCount = 0;
  static const int maxRetries = 3;
  
  Future<void> initiateCall() async {
    try {
      await _setupWebRTCConnection();
    } catch (e) {
      if (_retryCount < maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 2));
        await initiateCall();
      } else {
        throw Exception('Failed to connect after $maxRetries attempts');
      }
    }
  }
}

// 4. Handle network changes
ConnectivityResult? _previousConnectivity;

void _listenToConnectivityChanges() {
  Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
    if (_previousConnectivity == ConnectivityResult.none && 
        result != ConnectivityResult.none) {
      // Network restored, attempt to reconnect
      _reconnectCall();
    }
    _previousConnectivity = result;
  });
}
```

---

## Search and Filter Issues

### Search Not Working

#### Issue: Search returns no results
**Symptoms:**
- Search always returns empty
- Filters don't work
- Search is very slow

**Solutions:**
```dart
// 1. Check Firestore indexes
// Go to Firebase Console > Firestore > Indexes
// Create composite indexes for complex queries

// 2. Implement proper search logic
Future<List<Report>> searchReports(String query) async {
  if (query.isEmpty) {
    return await _getAllReports();
  }
  
  // Convert query to lowercase for case-insensitive search
  final lowerQuery = query.toLowerCase();
  
  try {
    // Search in item names
    final nameResults = await FirebaseFirestore.instance
        .collection('reports')
        .where('itemNameLower', isGreaterThanOrEqualTo: lowerQuery)
        .where('itemNameLower', isLessThan: lowerQuery + 'z')
        .get();
    
    // Search in descriptions
    final descResults = await FirebaseFirestore.instance
        .collection('reports')
        .where('descriptionLower', arrayContains: lowerQuery)
        .get();
    
    // Combine and deduplicate results
    final allDocs = [...nameResults.docs, ...descResults.docs];
    final uniqueDocs = allDocs.toSet().toList();
    
    return uniqueDocs
        .map((doc) => Report.fromMap(doc.data()))
        .toList();
  } catch (e) {
    print('Search error: $e');
    return [];
  }
}

// 3. Optimize search performance with pagination
Future<SearchResults> searchWithPagination({
  required String query,
  DocumentSnapshot? lastDocument,
  int limit = 20,
}) async {
  Query baseQuery = FirebaseFirestore.instance.collection('reports');
  
  if (query.isNotEmpty) {
    baseQuery = baseQuery
        .where('itemNameLower', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('itemNameLower', isLessThan: query.toLowerCase() + 'z');
  }
  
  if (lastDocument != null) {
    baseQuery = baseQuery.startAfterDocument(lastDocument);
  }
  
  final snapshot = await baseQuery.limit(limit).get();
  
  return SearchResults(
    reports: snapshot.docs.map((doc) => Report.fromMap(doc.data())).toList(),
    lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
    hasMore: snapshot.docs.length == limit,
  );
}
```

#### Issue: Filters not working correctly
**Symptoms:**
- Filter combinations don't work
- Some filter options missing
- Filters reset unexpectedly

**Solutions:**
```dart
// 1. Implement proper filter state management
class SearchFilters {
  final List<String> locations;
  final List<String> categories;
  final List<String> statuses;
  final DateRange? dateRange;
  
  SearchFilters({
    this.locations = const [],
    this.categories = const [],
    this.statuses = const [],
    this.dateRange,
  });
  
  SearchFilters copyWith({
    List<String>? locations,
    List<String>? categories,
    List<String>? statuses,
    DateRange? dateRange,
  }) {
    return SearchFilters(
      locations: locations ?? this.locations,
      categories: categories ?? this.categories,
      statuses: statuses ?? this.statuses,
      dateRange: dateRange ?? this.dateRange,
    );
  }
  
  bool get hasActiveFilters {
    return locations.isNotEmpty ||
           categories.isNotEmpty ||
           statuses.isNotEmpty ||
           dateRange != null;
  }
}

// 2. Build Firestore query with filters
Query _buildFilteredQuery(SearchFilters filters) {
  Query query = FirebaseFirestore.instance.collection('reports');
  
  if (filters.locations.isNotEmpty) {
    query = query.where('location', whereIn: filters.locations);
  }
  
  if (filters.categories.isNotEmpty) {
    query = query.where('category', whereIn: filters.categories);
  }
  
  if (filters.statuses.isNotEmpty) {
    query = query.where('status', whereIn: filters.statuses);
  }
  
  if (filters.dateRange != null) {
    query = query
        .where('timestamp', isGreaterThanOrEqualTo: filters.dateRange!.start)
        .where('timestamp', isLessThanOrEqualTo: filters.dateRange!.end);
  }
  
  return query;
}

// 3. Handle filter UI state
class FilterWidget extends StatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onFiltersChanged;
  
  @override
  _FilterWidgetState createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  late SearchFilters _filters;
  
  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }
  
  void _updateFilters(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });
    widget.onFiltersChanged(_filters);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Location filter
        FilterChipGroup(
          title: 'Location',
          options: ['Library', 'Cafeteria', 'Gym', 'Classroom'],
          selectedOptions: _filters.locations,
          onChanged: (selected) {
            _updateFilters(_filters.copyWith(locations: selected));
          },
        ),
        // Category filter
        FilterChipGroup(
          title: 'Category',
          options: ['Electronics', 'Clothing', 'Books', 'Other'],
          selectedOptions: _filters.categories,
          onChanged: (selected) {
            _updateFilters(_filters.copyWith(categories: selected));
          },
        ),
        // Clear filters button
        if (_filters.hasActiveFilters)
          ElevatedButton(
            onPressed: () {
              _updateFilters(SearchFilters());
            },
            child: Text('Clear Filters'),
          ),
      ],
    );
  }
}
```

---

## Platform-Specific Issues

### Android Issues

#### Issue: App crashes on Android
**Symptoms:**
- App closes unexpectedly
- "Unfortunately, app has stopped" message
- App won't start on certain devices

**Solutions:**
```bash
# 1. Check Android logs
adb logcat | grep -i flutter

# 2. Enable debugging
flutter run --debug
flutter logs

# 3. Check minimum SDK version
# android/app/build.gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21  # Ensure compatibility
        targetSdkVersion 33
    }
}

# 4. Check for ProGuard issues (release builds)
# android/app/build.gradle
buildTypes {
    release {
        minifyEnabled false  # Disable if causing issues
        useProguard false
    }
}
```

#### Issue: Android permissions not working
**Symptoms:**
- Permission dialogs don't appear
- Features requiring permissions fail silently

**Solutions:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add required permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- For Android 11+ file access -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
</manifest>
```

```dart
// Request permissions properly
Future<void> requestAndroidPermissions() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    
    if (androidInfo.version.sdkInt >= 30) {
      // Android 11+ requires special handling
      await Permission.manageExternalStorage.request();
    } else {
      await Permission.storage.request();
    }
    
    await Permission.camera.request();
  }
}
```

### iOS Issues

#### Issue: iOS build fails
**Symptoms:**
- Xcode build errors
- Code signing issues
- App Store submission rejected

**Solutions:**
```bash
# 1. Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter build ios

# 2. Update iOS deployment target
# ios/Podfile
platform :ios, '12.0'  # Minimum supported version

# 3. Fix code signing
# Open ios/Runner.xcworkspace in Xcode
# Select Runner project > Signing & Capabilities
# Set correct Team and Bundle Identifier

# 4. Check Info.plist permissions
# ios/Runner/Info.plist
<key>NSCameraUsageDescription</key>
<string>Camera access needed for photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access needed</string>
```

#### Issue: iOS app rejected by App Store
**Symptoms:**
- App Store review rejection
- Missing required metadata
- Privacy policy issues

**Solutions:**
```xml
<!-- ios/Runner/Info.plist -->
<!-- Add required privacy descriptions -->
<key>NSCameraUsageDescription</key>
<string>This app uses camera to take photos of lost/found items</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>This app accesses photo library to select images for reports</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Location is used to help find nearby lost items</string>
```

```
App Store Requirements Checklist:
□ Privacy Policy URL provided
□ Support URL provided
□ App description is clear and accurate
□ Screenshots show actual app functionality
□ All required permissions have usage descriptions
□ App follows Apple's Human Interface Guidelines
□ No placeholder content or test data
□ App works on all supported device sizes
```

### Web Issues

#### Issue: Web app not loading
**Symptoms:**
- Blank white screen
- JavaScript errors in console
- "Failed to load" messages

**Solutions:**
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- Add error handling -->
  <script>
    window.addEventListener('error', function(e) {
      console.error('Global error:', e.error);
    });
  </script>
</head>
<body>
  <!-- Loading indicator -->
  <div id="loading">
    <div>Loading Campus Lost & Found...</div>
  </div>
  
  <script>
    window.addEventListener('load', function(ev) {
      // Hide loading indicator
      document.getElementById('loading').style.display = 'none';
      
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      }).catch(function(error) {
        console.error('Flutter initialization error:', error);
        document.body.innerHTML = '<h1>Failed to load application</h1><p>' + error + '</p>';
      });
    });
  </script>
</body>
</html>
```

#### Issue: CORS errors on web
**Symptoms:**
- "CORS policy" errors in console
- API requests fail on web but work on mobile

**Solutions:**
```dart
// 1. Configure Firebase for web
// web/index.html
<script type="module">
  import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js';
  import { getFirestore } from 'https://www.gstatic.com/firebasejs/9.0.0/firebase-firestore.js';
  
  const firebaseConfig = {
    // Your config
  };
  
  const app = initializeApp(firebaseConfig);
  window.firebaseApp = app;
</script>

// 2. Use Firebase Hosting for deployment
// firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "Cross-Origin-Embedder-Policy",
            "value": "require-corp"
          },
          {
            "key": "Cross-Origin-Opener-Policy",
            "value": "same-origin"
          }
        ]
      }
    ]
  }
}
```

---

## Development Environment Issues

### Flutter Doctor Issues

#### Issue: Flutter doctor shows errors
**Symptoms:**
- Red X marks in flutter doctor output
- Build tools not found
- License issues

**Solutions:**
```bash
# 1. Run flutter doctor for detailed info
flutter doctor -v

# 2. Fix Android issues
flutter doctor --android-licenses
sdkmanager "platforms;android-33" "build-tools;33.0.0"

# 3. Fix iOS issues (macOS only)
sudo xcode-select --install
sudo xcodebuild -license accept

# 4. Fix VS Code/Android Studio issues
# Install Flutter and Dart plugins
# Restart IDE after installation
```

### IDE Issues

#### Issue: Code completion not working
**Symptoms:**
- No autocomplete suggestions
- Import statements not working
- Syntax highlighting missing

**Solutions:**
```bash
# 1. Restart Dart Analysis Server
# VS Code: Ctrl+Shift+P > "Dart: Restart Analysis Server"
# Android Studio: File > Invalidate Caches and Restart

# 2. Check Flutter and Dart SDK paths
# VS Code: Settings > Extensions > Dart & Flutter
# Android Studio: File > Settings > Languages & Frameworks > Flutter

# 3. Clear pub cache
flutter pub cache repair
flutter clean
flutter pub get

# 4. Check .dart_tool folder
# Delete .dart_tool folder and run flutter pub get
```

#### Issue: Hot reload not working
**Symptoms:**
- Changes don't appear when saving
- Need to restart app for changes
- "Hot reload failed" messages

**Solutions:**
```dart
// 1. Check for syntax errors
// Hot reload fails if there are compilation errors

// 2. Avoid stateless to stateful widget changes
// These require hot restart instead of hot reload

// 3. Check if running in debug mode
flutter run --debug  // Enables hot reload
flutter run --release  // Disables hot reload

// 4. Use hot restart for major changes
// Press 'R' in terminal or use IDE button

// 5. Check file watchers
// Some IDEs have file watcher limits
// Increase limit or exclude unnecessary directories
```

---

## Deployment Problems

### Build Issues

#### Issue: Release build fails
**Symptoms:**
- Debug builds work but release fails
- "Build failed" errors
- Missing dependencies in release

**Solutions:**
```bash
# 1. Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release --verbose

# 2. Check for debug-only dependencies
# Remove or wrap debug-only code
if (kDebugMode) {
  // Debug-only code here
}

# 3. Check ProGuard rules (Android)
# android/app/proguard-rules.pro
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 4. Check for missing assets
# Ensure all assets are listed in pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

### Firebase Deployment Issues

#### Issue: Firebase deployment fails
**Symptoms:**
- "Deployment failed" errors
- Functions not updating
- Rules deployment rejected

**Solutions:**
```bash
# 1. Check Firebase CLI version
npm install -g firebase-tools@latest

# 2. Login and select correct project
firebase login
firebase use --add
firebase projects:list

# 3. Deploy specific components
firebase deploy --only hosting
firebase deploy --only functions
firebase deploy --only firestore:rules

# 4. Check deployment logs
firebase functions:log
firebase hosting:channel:list

# 5. Validate rules before deployment
firebase firestore:rules:test
```

---

## Frequently Asked Questions

### General Questions

**Q: How do I reset my password?**
A: Go to the login screen and tap "Forgot Password". Enter your email address and check your inbox for reset instructions.

**Q: Can I use the app without an internet connection?**
A: The app requires an internet connection for most features. However, you can view previously loaded content offline.

**Q: How do I delete my account?**
A: Go to Settings > Account > Delete Account. Note that this action is irreversible.

**Q: Why can't I see my reported items?**
A: Check that you're logged in with the correct account. Your reports appear in the "My Reports" section.

### Technical Questions

**Q: The app is running slowly. What can I do?**
A: Try these steps:
1. Close and restart the app
2. Clear app cache (Android: Settings > Apps > Campus LF > Storage > Clear Cache)
3. Update to the latest version
4. Restart your device

**Q: Images won't upload. What's wrong?**
A: Common causes:
- File too large (max 10MB)
- Unsupported format (use JPG, PNG, or GIF)
- Poor internet connection
- Storage permissions not granted

**Q: Push notifications aren't working. How do I fix this?**
A: Check these settings:
1. App notifications enabled in device settings
2. Notification preferences in app settings
3. App has permission to send notifications
4. Device is connected to internet

### Feature Questions

**Q: How do I search for specific items?**
A: Use the search bar on the home screen. You can search by:
- Item name
- Description keywords
- Location
- Category

**Q: Can I edit a report after posting?**
A: Yes, go to "My Reports", select the report, and tap "Edit". You can update description, status, and add more images.

**Q: How do I contact someone who found my item?**
A: Tap on the found item report and use the "Contact" button to send a message through the app.

**Q: What happens when I mark an item as recovered?**
A: The report is updated to show it's been recovered and is removed from active search results.

---

## Error Codes Reference

### Authentication Errors
- `AUTH_001`: Invalid email format
- `AUTH_002`: Password too weak
- `AUTH_003`: Email already in use
- `AUTH_004`: User not found
- `AUTH_005`: Wrong password
- `AUTH_006`: Email not verified
- `AUTH_007`: Account disabled
- `AUTH_008`: Too many failed attempts

### Network Errors
- `NET_001`: No internet connection
- `NET_002`: Request timeout
- `NET_003`: Server unreachable
- `NET_004`: Rate limit exceeded
- `NET_005`: Service unavailable

### Database Errors
- `DB_001`: Permission denied
- `DB_002`: Document not found
- `DB_003`: Query limit exceeded
- `DB_004`: Invalid query
- `DB_005`: Transaction failed

### File Upload Errors
- `FILE_001`: File too large
- `FILE_002`: Invalid file format
- `FILE_003`: Upload failed
- `FILE_004`: Storage quota exceeded
- `FILE_005`: Permission denied

### Validation Errors
- `VAL_001`: Required field missing
- `VAL_002`: Invalid input format
- `VAL_003`: Value out of range
- `VAL_004`: Duplicate entry
- `VAL_005`: Invalid characters

---

## Getting Help

### Self-Help Resources
1. **Check this troubleshooting guide**
2. **Visit our FAQ section**
3. **Check system status**: https://status.campus-lf.edu
4. **Search community forums**: https://community.campus-lf.edu

### Contact Support

#### Email Support
- **General Support**: support@campus-lf.edu
- **Technical Issues**: tech@campus-lf.edu
- **Bug Reports**: bugs@campus-lf.edu
- **Feature Requests**: features@campus-lf.edu

#### Response Times
- **Critical Issues**: 2-4 hours
- **General Support**: 24-48 hours
- **Feature Requests**: 1-2 weeks

#### What to Include in Support Requests
1. **Device Information**:
   - Device model and OS version
   - App version
   - Flutter version (for developers)

2. **Problem Description**:
   - What you were trying to do
   - What happened instead
   - Error messages (exact text)
   - Screenshots if applicable

3. **Steps to Reproduce**:
   - Detailed steps to recreate the issue
   - Frequency of occurrence
   - Workarounds attempted

#### Emergency Contact
For critical security issues or data breaches:
- **Emergency Hotline**: +1-800-CAMPUS-LF
- **Security Email**: security@campus-lf.edu

### Community Support
- **Discord Server**: https://discord.gg/campus-lf
- **Reddit Community**: r/CampusLostFound
- **Stack Overflow**: Tag questions with `campus-lost-found`

### Developer Resources
- **GitHub Repository**: https://github.com/campus-lf/app
- **API Documentation**: https://docs.campus-lf.edu
- **Developer Portal**: https://developers.campus-lf.edu

---

*This troubleshooting guide is regularly updated based on user feedback and common issues. If you can't find a solution to your problem, please contact our support team.*

**Last Updated**: January 2024  
**Version**: 1.0  
**Next Review**: April 2024