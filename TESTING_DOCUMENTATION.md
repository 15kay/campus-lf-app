# Testing Documentation
## Campus Lost & Found Application

### Table of Contents
1. [Testing Overview](#testing-overview)
2. [Testing Strategy](#testing-strategy)
3. [Test Environment Setup](#test-environment-setup)
4. [Unit Testing](#unit-testing)
5. [Widget Testing](#widget-testing)
6. [Integration Testing](#integration-testing)
7. [End-to-End Testing](#end-to-end-testing)
8. [Performance Testing](#performance-testing)
9. [Security Testing](#security-testing)
10. [Accessibility Testing](#accessibility-testing)
11. [Cross-Platform Testing](#cross-platform-testing)
12. [QA Procedures](#qa-procedures)
13. [Test Data Management](#test-data-management)
14. [Continuous Integration Testing](#continuous-integration-testing)
15. [Bug Tracking and Reporting](#bug-tracking-and-reporting)

---

## Testing Overview

### Testing Philosophy
The Campus Lost & Found application follows a comprehensive testing approach that ensures:
- **Reliability**: All features work as expected
- **Performance**: Application meets performance requirements
- **Security**: User data and system integrity are protected
- **Accessibility**: Application is usable by all users
- **Cross-Platform Compatibility**: Consistent experience across platforms

### Testing Pyramid
```
    /\
   /  \     E2E Tests (10%)
  /____\    
 /      \   Integration Tests (20%)
/________\  Unit Tests (70%)
```

### Test Coverage Goals
- **Unit Tests**: 90% code coverage
- **Widget Tests**: 80% UI component coverage
- **Integration Tests**: 100% critical user flows
- **E2E Tests**: 100% main user journeys

---

## Testing Strategy

### Test Types and Scope

#### 1. Unit Tests
- **Scope**: Individual functions, methods, and classes
- **Tools**: Flutter Test, Mockito
- **Coverage**: Business logic, utilities, models
- **Frequency**: Run on every commit

#### 2. Widget Tests
- **Scope**: Individual UI components and widgets
- **Tools**: Flutter Test, flutter_test
- **Coverage**: UI components, user interactions
- **Frequency**: Run on every commit

#### 3. Integration Tests
- **Scope**: Feature-level testing with real dependencies
- **Tools**: Flutter Integration Test
- **Coverage**: User flows, API interactions
- **Frequency**: Run on pull requests

#### 4. End-to-End Tests
- **Scope**: Complete user journeys across the application
- **Tools**: Flutter Driver, Appium
- **Coverage**: Critical business flows
- **Frequency**: Run on releases

### Testing Environment Strategy
```dart
enum TestEnvironment {
  unit,      // Isolated testing with mocks
  widget,    // UI testing with test widgets
  integration, // Feature testing with test backend
  staging,   // E2E testing with staging environment
  production // Smoke testing in production
}

class TestConfig {
  static Map<TestEnvironment, Map<String, String>> configs = {
    TestEnvironment.unit: {
      'firebase_project': 'mock',
      'api_base_url': 'mock://api',
    },
    TestEnvironment.integration: {
      'firebase_project': 'campus-lf-test',
      'api_base_url': 'https://test-api.campus-lf.edu',
    },
    TestEnvironment.staging: {
      'firebase_project': 'campus-lf-staging',
      'api_base_url': 'https://staging-api.campus-lf.edu',
    },
  };
}
```

---

## Test Environment Setup

### Prerequisites
```bash
# Install Flutter and dependencies
flutter doctor

# Install test dependencies
flutter pub get

# Install additional testing tools
dart pub global activate coverage
dart pub global activate junitreport
```

### Test Configuration
```yaml
# pubspec.yaml - dev_dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  fake_cloud_firestore: ^2.4.1+1
  firebase_auth_mocks: ^0.12.0
  network_image_mock: ^2.1.1
  golden_toolkit: ^0.15.0
```

### Test Environment Variables
```dart
// test/test_config.dart
class TestConfig {
  static const String testFirebaseProject = 'campus-lf-test';
  static const String testApiKey = 'test-api-key';
  static const String testDatabaseUrl = 'https://campus-lf-test.firebaseio.com';
  
  static void setupTestEnvironment() {
    // Set up test-specific configurations
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock Firebase
    setupFirebaseAuthMocks();
    setupFirestoreMocks();
  }
}
```

---

## Unit Testing

### Test Structure
```dart
// test/unit/models/report_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/models.dart';

void main() {
  group('Report Model Tests', () {
    late Report testReport;
    
    setUp(() {
      testReport = Report(
        reportId: 'test-id',
        uid: 'user-123',
        itemName: 'Test Item',
        status: 'lost',
        description: 'Test description',
        location: 'Library',
        date: DateTime.now(),
        category: 'Electronics',
        timestamp: DateTime.now(),
      );
    });
    
    test('should create Report from JSON', () {
      final json = {
        'reportId': 'test-id',
        'uid': 'user-123',
        'itemName': 'Test Item',
        'status': 'lost',
        'description': 'Test description',
        'location': 'Library',
        'date': DateTime.now().toIso8601String(),
        'category': 'Electronics',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final report = Report.fromJson(json);
      
      expect(report.reportId, equals('test-id'));
      expect(report.itemName, equals('Test Item'));
      expect(report.status, equals('lost'));
    });
    
    test('should convert Report to JSON', () {
      final json = testReport.toJson();
      
      expect(json['reportId'], equals('test-id'));
      expect(json['itemName'], equals('Test Item'));
      expect(json['status'], equals('lost'));
    });
    
    test('should validate required fields', () {
      expect(() => Report(
        reportId: '',
        uid: 'user-123',
        itemName: '',
        status: 'lost',
        description: 'Test',
        location: 'Library',
        date: DateTime.now(),
        category: 'Electronics',
        timestamp: DateTime.now(),
      ), throwsA(isA<ValidationException>()));
    });
  });
}
```

### Service Layer Testing
```dart
// test/unit/services/report_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:campus_lf_app/services/report_service.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference {}
class MockDocumentReference extends Mock implements DocumentReference {}

void main() {
  group('ReportService Tests', () {
    late ReportService reportService;
    late MockFirestore mockFirestore;
    late MockCollectionReference mockCollection;
    
    setUp(() {
      mockFirestore = MockFirestore();
      mockCollection = MockCollectionReference();
      reportService = ReportService(firestore: mockFirestore);
      
      when(mockFirestore.collection('reports')).thenReturn(mockCollection);
    });
    
    test('should create report successfully', () async {
      final report = Report(
        reportId: 'test-id',
        uid: 'user-123',
        itemName: 'Test Item',
        status: 'lost',
        description: 'Test description',
        location: 'Library',
        date: DateTime.now(),
        category: 'Electronics',
        timestamp: DateTime.now(),
      );
      
      final mockDoc = MockDocumentReference();
      when(mockCollection.add(any)).thenAnswer((_) async => mockDoc);
      when(mockDoc.id).thenReturn('generated-id');
      
      final result = await reportService.createReport(report);
      
      expect(result, isNotNull);
      verify(mockCollection.add(any)).called(1);
    });
    
    test('should handle create report failure', () async {
      final report = Report(
        reportId: 'test-id',
        uid: 'user-123',
        itemName: 'Test Item',
        status: 'lost',
        description: 'Test description',
        location: 'Library',
        date: DateTime.now(),
        category: 'Electronics',
        timestamp: DateTime.now(),
      );
      
      when(mockCollection.add(any)).thenThrow(Exception('Network error'));
      
      expect(() => reportService.createReport(report), 
             throwsA(isA<ServiceException>()));
    });
  });
}
```

### Utility Function Testing
```dart
// test/unit/utils/validation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/utils/validation.dart';

void main() {
  group('Validation Utils Tests', () {
    test('should validate email addresses correctly', () {
      expect(ValidationUtils.isValidEmail('test@example.com'), isTrue);
      expect(ValidationUtils.isValidEmail('user@university.edu'), isTrue);
      expect(ValidationUtils.isValidEmail('invalid-email'), isFalse);
      expect(ValidationUtils.isValidEmail(''), isFalse);
      expect(ValidationUtils.isValidEmail('test@'), isFalse);
    });
    
    test('should validate phone numbers correctly', () {
      expect(ValidationUtils.isValidPhoneNumber('+1234567890'), isTrue);
      expect(ValidationUtils.isValidPhoneNumber('1234567890'), isTrue);
      expect(ValidationUtils.isValidPhoneNumber('123'), isFalse);
      expect(ValidationUtils.isValidPhoneNumber('abc123'), isFalse);
    });
    
    test('should sanitize input correctly', () {
      expect(ValidationUtils.sanitizeInput('<script>alert("xss")</script>'), 
             equals('scriptalert("xss")/script'));
      expect(ValidationUtils.sanitizeInput('Normal text'), 
             equals('Normal text'));
      expect(ValidationUtils.sanitizeInput(''), equals(''));
    });
  });
}
```

---

## Widget Testing

### Basic Widget Tests
```dart
// test/widget/pages/home_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/pages/home_page.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('should display welcome message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );
      
      expect(find.text('Welcome to Campus Lost & Found'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
    
    testWidgets('should navigate to report page when FAB is tapped', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
          routes: {
            '/report': (context) => Scaffold(body: Text('Report Page')),
          },
        ),
      );
      
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      
      await tester.tap(fab);
      await tester.pumpAndSettle();
      
      expect(find.text('Report Page'), findsOneWidget);
    });
    
    testWidgets('should display recent reports list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );
      
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Recent Reports'), findsOneWidget);
    });
  });
}
```

### Form Widget Testing
```dart
// test/widget/pages/report_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/pages/report_page.dart';

void main() {
  group('ReportPage Widget Tests', () {
    testWidgets('should display all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReportPage(onSubmit: (report) {}),
        ),
      );
      
      expect(find.byKey(Key('item_name_field')), findsOneWidget);
      expect(find.byKey(Key('description_field')), findsOneWidget);
      expect(find.byKey(Key('location_dropdown')), findsOneWidget);
      expect(find.byKey(Key('category_dropdown')), findsOneWidget);
      expect(find.byKey(Key('status_toggle')), findsOneWidget);
    });
    
    testWidgets('should validate required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReportPage(onSubmit: (report) {}),
        ),
      );
      
      // Try to submit without filling required fields
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pump();
      
      expect(find.text('Item name is required'), findsOneWidget);
      expect(find.text('Please select a location'), findsOneWidget);
    });
    
    testWidgets('should submit form with valid data', (WidgetTester tester) async {
      Report? submittedReport;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ReportPage(onSubmit: (report) {
            submittedReport = report;
          }),
        ),
      );
      
      // Fill form fields
      await tester.enterText(find.byKey(Key('item_name_field')), 'Test Item');
      await tester.enterText(find.byKey(Key('description_field')), 'Test description');
      
      // Select location
      await tester.tap(find.byKey(Key('location_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      
      // Submit form
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pump();
      
      expect(submittedReport, isNotNull);
      expect(submittedReport!.itemName, equals('Test Item'));
      expect(submittedReport!.location, equals('Library'));
    });
  });
}
```

### Custom Widget Testing
```dart
// test/widget/components/report_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/components/report_card.dart';
import 'package:campus_lf_app/models.dart';

void main() {
  group('ReportCard Widget Tests', () {
    late Report testReport;
    
    setUp(() {
      testReport = Report(
        reportId: 'test-id',
        uid: 'user-123',
        itemName: 'Test Item',
        status: 'lost',
        description: 'Test description',
        location: 'Library',
        date: DateTime.now(),
        category: 'Electronics',
        timestamp: DateTime.now(),
      );
    });
    
    testWidgets('should display report information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(report: testReport),
          ),
        ),
      );
      
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.text('Lost'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
    });
    
    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              report: testReport,
              onTap: () { tapped = true; },
            ),
          ),
        ),
      );
      
      await tester.tap(find.byType(ReportCard));
      expect(tapped, isTrue);
    });
  });
}
```

---

## Integration Testing

### Feature Integration Tests
```dart
// integration_test/report_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Report Flow Integration Tests', () {
    testWidgets('complete report creation flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to login if not authenticated
      if (find.text('Login').evaluate().isNotEmpty) {
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        
        // Login with test credentials
        await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(Key('password_field')), 'testpassword');
        await tester.tap(find.byKey(Key('login_button')));
        await tester.pumpAndSettle();
      }
      
      // Navigate to report page
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      // Fill report form
      await tester.enterText(find.byKey(Key('item_name_field')), 'Lost Laptop');
      await tester.enterText(find.byKey(Key('description_field')), 'MacBook Pro 13-inch');
      
      // Select location
      await tester.tap(find.byKey(Key('location_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      
      // Select category
      await tester.tap(find.byKey(Key('category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Electronics'));
      await tester.pumpAndSettle();
      
      // Submit report
      await tester.tap(find.byKey(Key('submit_button')));
      await tester.pumpAndSettle();
      
      // Verify success
      expect(find.text('Report submitted successfully'), findsOneWidget);
      
      // Verify report appears in list
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      expect(find.text('Lost Laptop'), findsOneWidget);
    });
    
    testWidgets('search and filter reports', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to search page
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      // Search for specific item
      await tester.enterText(find.byKey(Key('search_field')), 'laptop');
      await tester.pump();
      
      // Apply filters
      await tester.tap(find.byKey(Key('filter_button')));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Electronics'));
      await tester.tap(find.text('Library'));
      await tester.tap(find.byKey(Key('apply_filters')));
      await tester.pumpAndSettle();
      
      // Verify filtered results
      expect(find.text('Lost Laptop'), findsOneWidget);
    });
  });
}
```

### Authentication Integration Tests
```dart
// integration_test/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Authentication Flow Tests', () {
    testWidgets('user registration flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to registration
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      // Fill registration form
      await tester.enterText(find.byKey(Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(Key('email_field')), 'newuser@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'SecurePassword123!');
      await tester.enterText(find.byKey(Key('confirm_password_field')), 'SecurePassword123!');
      
      // Submit registration
      await tester.tap(find.byKey(Key('register_button')));
      await tester.pumpAndSettle();
      
      // Verify email verification prompt
      expect(find.text('Please verify your email'), findsOneWidget);
    });
    
    testWidgets('user login flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Enter credentials
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(Key('password_field')), 'testpassword');
      
      // Submit login
      await tester.tap(find.byKey(Key('login_button')));
      await tester.pumpAndSettle();
      
      // Verify successful login
      expect(find.text('Welcome to Campus Lost & Found'), findsOneWidget);
    });
    
    testWidgets('password reset flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Tap forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      
      // Enter email
      await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
      
      // Submit reset request
      await tester.tap(find.byKey(Key('reset_button')));
      await tester.pumpAndSettle();
      
      // Verify success message
      expect(find.text('Password reset email sent'), findsOneWidget);
    });
  });
}
```

---

## End-to-End Testing

### Critical User Journey Tests
```dart
// integration_test/e2e_user_journeys_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('End-to-End User Journey Tests', () {
    testWidgets('complete lost item reporting and recovery journey', 
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // User A reports lost item
      await _loginUser(tester, 'user1@example.com', 'password123');
      await _reportLostItem(tester, 'iPhone 13', 'Black iPhone with blue case');
      await _logout(tester);
      
      // User B reports found item
      await _loginUser(tester, 'user2@example.com', 'password123');
      await _reportFoundItem(tester, 'iPhone 13', 'Found in library');
      
      // User B searches for lost items and contacts User A
      await _searchForItem(tester, 'iPhone');
      await _contactItemOwner(tester);
      await _logout(tester);
      
      // User A receives message and responds
      await _loginUser(tester, 'user1@example.com', 'password123');
      await _checkMessages(tester);
      await _respondToMessage(tester, 'Yes, that\'s my phone!');
      
      // Users arrange meetup and mark item as recovered
      await _markItemAsRecovered(tester);
      
      // Verify item is no longer in active reports
      await _verifyItemRecovered(tester, 'iPhone 13');
    });
    
    testWidgets('user profile management journey', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      await _loginUser(tester, 'test@example.com', 'password123');
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Edit profile information
      await tester.tap(find.byKey(Key('edit_profile_button')));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byKey(Key('name_field')), 'Updated Name');
      await tester.enterText(find.byKey(Key('phone_field')), '+1234567890');
      
      // Save changes
      await tester.tap(find.byKey(Key('save_button')));
      await tester.pumpAndSettle();
      
      // Verify changes saved
      expect(find.text('Profile updated successfully'), findsOneWidget);
      expect(find.text('Updated Name'), findsOneWidget);
    });
  });
}

// Helper functions for E2E tests
Future<void> _loginUser(WidgetTester tester, String email, String password) async {
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byKey(Key('email_field')), email);
  await tester.enterText(find.byKey(Key('password_field')), password);
  await tester.tap(find.byKey(Key('login_button')));
  await tester.pumpAndSettle();
}

Future<void> _reportLostItem(WidgetTester tester, String itemName, String description) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byKey(Key('item_name_field')), itemName);
  await tester.enterText(find.byKey(Key('description_field')), description);
  
  // Select "Lost" status
  await tester.tap(find.byKey(Key('status_lost')));
  
  // Select location
  await tester.tap(find.byKey(Key('location_dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Library'));
  await tester.pumpAndSettle();
  
  await tester.tap(find.byKey(Key('submit_button')));
  await tester.pumpAndSettle();
}

Future<void> _logout(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Logout'));
  await tester.pumpAndSettle();
}
```

---

## Performance Testing

### Performance Test Suite
```dart
// test/performance/performance_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Performance Tests', () {
    testWidgets('app startup performance', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      
      app.main();
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should start within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      print('App startup time: ${stopwatch.elapsedMilliseconds}ms');
    });
    
    testWidgets('list scrolling performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to reports list
      await tester.tap(find.text('All Reports'));
      await tester.pumpAndSettle();
      
      final stopwatch = Stopwatch()..start();
      
      // Scroll through list
      final listFinder = find.byType(ListView);
      await tester.fling(listFinder, Offset(0, -500), 1000);
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // Scrolling should be smooth (< 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      print('List scroll time: ${stopwatch.elapsedMilliseconds}ms');
    });
    
    testWidgets('search performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      
      final stopwatch = Stopwatch()..start();
      
      // Perform search
      await tester.enterText(find.byKey(Key('search_field')), 'laptop');
      await tester.pump();
      
      stopwatch.stop();
      
      // Search should be fast (< 500ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      print('Search time: ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}
```

### Memory Usage Testing
```dart
// test/performance/memory_test.dart
import 'dart:developer';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Memory Usage Tests', () {
    testWidgets('memory usage during navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Get initial memory usage
      final initialMemory = await _getMemoryUsage();
      
      // Navigate through different pages
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();
      }
      
      // Get final memory usage
      final finalMemory = await _getMemoryUsage();
      
      // Memory increase should be reasonable (< 50MB)
      final memoryIncrease = finalMemory - initialMemory;
      expect(memoryIncrease, lessThan(50 * 1024 * 1024)); // 50MB
      
      print('Memory increase: ${memoryIncrease / 1024 / 1024}MB');
    });
  });
}

Future<int> _getMemoryUsage() async {
  final info = await Service.getInfo();
  return info.heapUsage ?? 0;
}
```

---

## Security Testing

### Security Test Cases
```dart
// test/security/security_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/utils/validation.dart';
import 'package:campus_lf_app/services/auth_service.dart';

void main() {
  group('Security Tests', () {
    test('input sanitization prevents XSS', () {
      final maliciousInputs = [
        '<script>alert("xss")</script>',
        'javascript:alert("xss")',
        '<img src="x" onerror="alert(\'xss\')">',
        '"><script>alert("xss")</script>',
      ];
      
      for (final input in maliciousInputs) {
        final sanitized = ValidationUtils.sanitizeInput(input);
        expect(sanitized, isNot(contains('<script>')));
        expect(sanitized, isNot(contains('javascript:')));
        expect(sanitized, isNot(contains('onerror')));
      }
    });
    
    test('password validation enforces security requirements', () {
      final weakPasswords = [
        'password',
        '123456',
        'qwerty',
        'abc123',
        'Password', // Missing number and special char
        'password123', // Missing uppercase and special char
      ];
      
      for (final password in weakPasswords) {
        final result = ValidationUtils.validatePassword(password);
        expect(result.isValid, isFalse);
      }
      
      // Strong password should pass
      final strongPassword = 'SecureP@ssw0rd123!';
      final result = ValidationUtils.validatePassword(strongPassword);
      expect(result.isValid, isTrue);
    });
    
    test('authentication tokens are properly validated', () async {
      // Test with invalid token
      expect(() => AuthService.validateToken('invalid-token'),
             throwsA(isA<AuthenticationException>()));
      
      // Test with expired token
      expect(() => AuthService.validateToken('expired-token'),
             throwsA(isA<TokenExpiredException>()));
    });
    
    test('user permissions are properly enforced', () {
      final studentUser = UserProfile(
        uid: 'student-123',
        name: 'Student User',
        email: 'student@university.edu',
        role: UserRole.student,
      );
      
      final adminUser = UserProfile(
        uid: 'admin-123',
        name: 'Admin User',
        email: 'admin@university.edu',
        role: UserRole.admin,
      );
      
      // Student should not have admin permissions
      expect(PermissionService.canDeleteAnyReport(studentUser), isFalse);
      expect(PermissionService.canViewAnalytics(studentUser), isFalse);
      
      // Admin should have admin permissions
      expect(PermissionService.canDeleteAnyReport(adminUser), isTrue);
      expect(PermissionService.canViewAnalytics(adminUser), isTrue);
    });
  });
}
```

---

## Accessibility Testing

### Accessibility Test Suite
```dart
// test/accessibility/accessibility_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/pages/home_page.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('all interactive elements have semantic labels', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );
      
      // Check that buttons have semantic labels
      final buttons = find.byType(ElevatedButton);
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final button = buttons.at(i);
        final widget = tester.widget<ElevatedButton>(button);
        expect(widget.child, isNotNull);
      }
      
      // Check that form fields have labels
      final textFields = find.byType(TextField);
      for (int i = 0; i < textFields.evaluate().length; i++) {
        final textField = textFields.at(i);
        final widget = tester.widget<TextField>(textField);
        expect(widget.decoration?.labelText ?? widget.decoration?.hintText, 
               isNotNull);
      }
    });
    
    testWidgets('app supports screen reader navigation', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );
      
      // Enable semantics
      final SemanticsHandle handle = tester.ensureSemantics();
      
      // Verify semantic tree structure
      expect(tester.getSemantics(find.byType(AppBar)), 
             matchesSemantics(
               label: 'Campus Lost & Found',
               isHeader: true,
             ));
      
      handle.dispose();
    });
    
    testWidgets('color contrast meets accessibility standards', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(),
        ),
      );
      
      // This would typically use a custom matcher to check color contrast
      // For demonstration, we'll check that colors are defined
      final theme = Theme.of(tester.element(find.byType(HomePage)));
      expect(theme.primaryColor, isNotNull);
      expect(theme.colorScheme.onPrimary, isNotNull);
      
      // In a real implementation, you would calculate contrast ratios
      // and ensure they meet WCAG guidelines (4.5:1 for normal text)
    });
    
    testWidgets('app works with large text sizes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaleFactor: 2.0),
            child: HomePage(),
          ),
        ),
      );
      
      // Verify that UI doesn't break with large text
      expect(find.byType(HomePage), findsOneWidget);
      
      // Check that text doesn't overflow
      final textWidgets = find.byType(Text);
      for (int i = 0; i < textWidgets.evaluate().length; i++) {
        final text = textWidgets.at(i);
        final renderObject = tester.renderObject(text);
        expect(renderObject.hasVisualOverflow, isFalse);
      }
    });
  });
}
```

---

## Cross-Platform Testing

### Platform-Specific Tests
```dart
// test/platform/platform_test.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_lf_app/utils/platform_utils.dart';

void main() {
  group('Cross-Platform Tests', () {
    test('platform detection works correctly', () {
      if (kIsWeb) {
        expect(PlatformUtils.isWeb, isTrue);
        expect(PlatformUtils.isMobile, isFalse);
      } else if (Platform.isAndroid) {
        expect(PlatformUtils.isAndroid, isTrue);
        expect(PlatformUtils.isMobile, isTrue);
      } else if (Platform.isIOS) {
        expect(PlatformUtils.isIOS, isTrue);
        expect(PlatformUtils.isMobile, isTrue);
      }
    });
    
    test('file handling works on all platforms', () async {
      final result = await PlatformUtils.pickImage();
      
      if (PlatformUtils.isWeb) {
        expect(result, isA<Uint8List>());
      } else {
        expect(result, isA<File>());
      }
    });
    
    test('storage works on all platforms', () async {
      await PlatformUtils.saveToStorage('test_key', 'test_value');
      final value = await PlatformUtils.getFromStorage('test_key');
      expect(value, equals('test_value'));
    });
  });
}
```

---

## QA Procedures

### Manual Testing Checklist

#### Pre-Release Testing Checklist
- [ ] **Functionality Testing**
  - [ ] All features work as expected
  - [ ] User flows complete successfully
  - [ ] Error handling works properly
  - [ ] Data validation is effective

- [ ] **UI/UX Testing**
  - [ ] UI elements are properly aligned
  - [ ] Navigation is intuitive
  - [ ] Loading states are shown
  - [ ] Error messages are clear

- [ ] **Performance Testing**
  - [ ] App starts within 3 seconds
  - [ ] Smooth scrolling and animations
  - [ ] No memory leaks
  - [ ] Efficient network usage

- [ ] **Security Testing**
  - [ ] Authentication works properly
  - [ ] Authorization is enforced
  - [ ] Input validation prevents attacks
  - [ ] Data is encrypted

- [ ] **Accessibility Testing**
  - [ ] Screen reader compatibility
  - [ ] Keyboard navigation
  - [ ] Color contrast compliance
  - [ ] Large text support

- [ ] **Cross-Platform Testing**
  - [ ] iOS functionality
  - [ ] Android functionality
  - [ ] Web functionality
  - [ ] Desktop functionality

### Test Execution Process
```dart
class QAProcess {
  static Future<TestReport> executeTestSuite() async {
    final report = TestReport();
    
    // Run automated tests
    report.unitTestResults = await runUnitTests();
    report.widgetTestResults = await runWidgetTests();
    report.integrationTestResults = await runIntegrationTests();
    
    // Run manual tests
    report.manualTestResults = await runManualTests();
    
    // Generate coverage report
    report.coverageReport = await generateCoverageReport();
    
    // Analyze results
    report.summary = analyzeResults(report);
    
    return report;
  }
  
  static TestSummary analyzeResults(TestReport report) {
    final totalTests = report.getTotalTestCount();
    final passedTests = report.getPassedTestCount();
    final failedTests = report.getFailedTestCount();
    
    return TestSummary(
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      passRate: (passedTests / totalTests) * 100,
      coveragePercentage: report.coverageReport.percentage,
      recommendation: _getRecommendation(passedTests, totalTests),
    );
  }
  
  static String _getRecommendation(int passed, int total) {
    final passRate = (passed / total) * 100;
    
    if (passRate >= 95) {
      return 'Ready for release';
    } else if (passRate >= 90) {
      return 'Minor issues to fix before release';
    } else if (passRate >= 80) {
      return 'Major issues to fix before release';
    } else {
      return 'Not ready for release - significant issues';
    }
  }
}
```

---

## Test Data Management

### Test Data Setup
```dart
// test/test_data/test_data_manager.dart
class TestDataManager {
  static Future<void> setupTestData() async {
    await _createTestUsers();
    await _createTestReports();
    await _createTestMessages();
  }
  
  static Future<void> _createTestUsers() async {
    final testUsers = [
      UserProfile(
        uid: 'test-user-1',
        name: 'John Doe',
        email: 'john@example.com',
        role: UserRole.student,
      ),
      UserProfile(
        uid: 'test-user-2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        role: UserRole.staff,
      ),
      UserProfile(
        uid: 'test-admin',
        name: 'Admin User',
        email: 'admin@example.com',
        role: UserRole.admin,
      ),
    ];
    
    for (final user in testUsers) {
      await TestFirestore.collection('users').doc(user.uid).set(user.toJson());
    }
  }
  
  static Future<void> _createTestReports() async {
    final testReports = [
      Report(
        reportId: 'test-report-1',
        uid: 'test-user-1',
        itemName: 'iPhone 13',
        status: 'lost',
        description: 'Black iPhone with blue case',
        location: 'Library',
        date: DateTime.now().subtract(Duration(days: 1)),
        category: 'Electronics',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
      ),
      Report(
        reportId: 'test-report-2',
        uid: 'test-user-2',
        itemName: 'MacBook Pro',
        status: 'found',
        description: '13-inch MacBook Pro',
        location: 'Cafeteria',
        date: DateTime.now().subtract(Duration(hours: 2)),
        category: 'Electronics',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
      ),
    ];
    
    for (final report in testReports) {
      await TestFirestore.collection('reports').doc(report.reportId).set(report.toJson());
    }
  }
  
  static Future<void> cleanupTestData() async {
    // Clean up test users
    final users = await TestFirestore.collection('users').get();
    for (final doc in users.docs) {
      if (doc.id.startsWith('test-')) {
        await doc.reference.delete();
      }
    }
    
    // Clean up test reports
    final reports = await TestFirestore.collection('reports').get();
    for (final doc in reports.docs) {
      if (doc.id.startsWith('test-')) {
        await doc.reference.delete();
      }
    }
  }
}
```

### Test Data Factories
```dart
// test/test_data/factories.dart
class UserFactory {
  static UserProfile createStudent({
    String? uid,
    String? name,
    String? email,
  }) {
    return UserProfile(
      uid: uid ?? 'student-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Student',
      email: email ?? 'student@example.com',
      role: UserRole.student,
    );
  }
  
  static UserProfile createAdmin({
    String? uid,
    String? name,
    String? email,
  }) {
    return UserProfile(
      uid: uid ?? 'admin-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Admin',
      email: email ?? 'admin@example.com',
      role: UserRole.admin,
    );
  }
}

class ReportFactory {
  static Report createLostReport({
    String? reportId,
    String? uid,
    String? itemName,
    String? location,
  }) {
    return Report(
      reportId: reportId ?? 'lost-${DateTime.now().millisecondsSinceEpoch}',
      uid: uid ?? 'test-user',
      itemName: itemName ?? 'Test Item',
      status: 'lost',
      description: 'Test description',
      location: location ?? 'Library',
      date: DateTime.now(),
      category: 'Other',
      timestamp: DateTime.now(),
    );
  }
  
  static Report createFoundReport({
    String? reportId,
    String? uid,
    String? itemName,
    String? location,
  }) {
    return Report(
      reportId: reportId ?? 'found-${DateTime.now().millisecondsSinceEpoch}',
      uid: uid ?? 'test-user',
      itemName: itemName ?? 'Test Item',
      status: 'found',
      description: 'Test description',
      location: location ?? 'Library',
      date: DateTime.now(),
      category: 'Other',
      timestamp: DateTime.now(),
    );
  }
}
```

---

## Continuous Integration Testing

### CI/CD Pipeline Configuration
```yaml
# .github/workflows/test.yml
name: Test Suite

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run unit tests
      run: flutter test --coverage
      
    - name: Run widget tests
      run: flutter test test/widget/
      
    - name: Generate coverage report
      run: |
        dart pub global activate coverage
        dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib
        
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info
        
  integration_test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Run integration tests
      run: flutter test integration_test/
      
  build_test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        platform: [android, web]
        
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build for ${{ matrix.platform }}
      run: |
        if [ "${{ matrix.platform }}" == "android" ]; then
          flutter build apk --debug
        elif [ "${{ matrix.platform }}" == "web" ]; then
          flutter build web
        fi
```

### Test Automation Scripts
```dart
// scripts/run_tests.dart
import 'dart:io';

void main(List<String> arguments) async {
  print('Starting comprehensive test suite...');
  
  // Run unit tests
  print('\n🧪 Running unit tests...');
  final unitTestResult = await Process.run('flutter', ['test', '--coverage']);
  if (unitTestResult.exitCode != 0) {
    print('❌ Unit tests failed');
    exit(1);
  }
  print('✅ Unit tests passed');
  
  // Run widget tests
  print('\n🎨 Running widget tests...');
  final widgetTestResult = await Process.run('flutter', ['test', 'test/widget/']);
  if (widgetTestResult.exitCode != 0) {
    print('❌ Widget tests failed');
    exit(1);
  }
  print('✅ Widget tests passed');
  
  // Run integration tests
  print('\n🔗 Running integration tests...');
  final integrationTestResult = await Process.run('flutter', ['test', 'integration_test/']);
  if (integrationTestResult.exitCode != 0) {
    print('❌ Integration tests failed');
    exit(1);
  }
  print('✅ Integration tests passed');
  
  // Generate coverage report
  print('\n📊 Generating coverage report...');
  await Process.run('dart', ['pub', 'global', 'activate', 'coverage']);
  await Process.run('dart', [
    'pub', 'global', 'run', 'coverage:format_coverage',
    '--lcov', '--in=coverage', '--out=coverage/lcov.info',
    '--packages=.packages', '--report-on=lib'
  ]);
  
  print('✅ All tests completed successfully!');
}
```

---

## Bug Tracking and Reporting

### Bug Report Template
```markdown
## Bug Report

### Environment
- **Platform**: [iOS/Android/Web/Desktop]
- **OS Version**: [e.g., iOS 16.0, Android 13]
- **App Version**: [e.g., 1.2.3]
- **Device**: [e.g., iPhone 14, Samsung Galaxy S23]

### Bug Description
**Summary**: Brief description of the bug

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**: What should happen

**Actual Behavior**: What actually happens

**Screenshots/Videos**: [Attach if applicable]

### Additional Information
- **Frequency**: [Always/Sometimes/Rarely]
- **Severity**: [Critical/High/Medium/Low]
- **User Impact**: [How many users affected]
- **Workaround**: [If any exists]

### Technical Details
- **Error Messages**: [Any error messages shown]
- **Console Logs**: [Relevant log entries]
- **Network Conditions**: [WiFi/Mobile/Offline]
```

### Bug Tracking Workflow
```dart
enum BugSeverity {
  critical,  // App crashes, data loss
  high,      // Major feature broken
  medium,    // Minor feature issue
  low,       // Cosmetic issue
}

enum BugStatus {
  open,
  inProgress,
  testing,
  resolved,
  closed,
  wontFix,
}

class BugReport {
  final String id;
  final String title;
  final String description;
  final BugSeverity severity;
  final BugStatus status;
  final String reportedBy;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<String> steps;
  final List<String> attachments;
  
  BugReport({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.reportedBy,
    this.assignedTo,
    required this.createdAt,
    this.resolvedAt,
    required this.steps,
    required this.attachments,
  });
}

class BugTracker {
  static Future<void> reportBug(BugReport bug) async {
    // Save to bug tracking system
    await BugDatabase.saveBug(bug);
    
    // Notify team based on severity
    if (bug.severity == BugSeverity.critical) {
      await NotificationService.notifyTeamUrgent(bug);
    } else {
      await NotificationService.notifyTeam(bug);
    }
    
    // Auto-assign based on component
    final assignee = await getAssigneeForBug(bug);
    if (assignee != null) {
      await assignBug(bug.id, assignee);
    }
  }
}
```

---

## Test Metrics and Reporting

### Test Metrics Dashboard
```dart
class TestMetrics {
  static Future<TestDashboard> generateDashboard() async {
    final unitTestResults = await getUnitTestResults();
    final integrationTestResults = await getIntegrationTestResults();
    final coverageData = await getCoverageData();
    final performanceMetrics = await getPerformanceMetrics();
    
    return TestDashboard(
      unitTests: TestSummary(
        total: unitTestResults.total,
        passed: unitTestResults.passed,
        failed: unitTestResults.failed,
        skipped: unitTestResults.skipped,
        duration: unitTestResults.duration,
      ),
      integrationTests: TestSummary(
        total: integrationTestResults.total,
        passed: integrationTestResults.passed,
        failed: integrationTestResults.failed,
        skipped: integrationTestResults.skipped,
        duration: integrationTestResults.duration,
      ),
      coverage: CoverageSummary(
        linesCovered: coverageData.linesCovered,
        totalLines: coverageData.totalLines,
        percentage: coverageData.percentage,
        uncoveredFiles: coverageData.uncoveredFiles,
      ),
      performance: PerformanceSummary(
        averageStartupTime: performanceMetrics.averageStartupTime,
        averageResponseTime: performanceMetrics.averageResponseTime,
        memoryUsage: performanceMetrics.memoryUsage,
        crashRate: performanceMetrics.crashRate,
      ),
    );
  }
}
```

---

*This testing documentation provides comprehensive guidelines for ensuring the quality and reliability of the Campus Lost & Found application across all platforms and use cases.*

**Last Updated**: January 2024  
**Version**: 1.0  
**Next Review**: April 2024