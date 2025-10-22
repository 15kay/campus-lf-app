# 🤝 Contributing to Campus Lost & Found

## Table of Contents

- [Welcome](#welcome)
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation Standards](#documentation-standards)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Security Guidelines](#security-guidelines)
- [Performance Guidelines](#performance-guidelines)
- [Accessibility Guidelines](#accessibility-guidelines)

## Welcome

Thank you for your interest in contributing to Campus Lost & Found! This document provides guidelines and standards for contributing to our project. Whether you're fixing bugs, adding features, improving documentation, or helping with testing, your contributions are valuable and appreciated.

### Types of Contributions

We welcome various types of contributions:

- 🐛 **Bug fixes**
- ✨ **New features**
- 📚 **Documentation improvements**
- 🧪 **Test coverage**
- 🎨 **UI/UX improvements**
- 🔧 **Performance optimizations**
- 🌐 **Internationalization**
- ♿ **Accessibility improvements**

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of background, experience level, gender identity, sexual orientation, disability, personal appearance, body size, race, ethnicity, age, religion, or nationality.

### Expected Behavior

- **Be respectful** and considerate in all interactions
- **Be collaborative** and help others learn and grow
- **Be constructive** when providing feedback
- **Be patient** with newcomers and those learning
- **Be inclusive** and welcoming to all community members

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Personal attacks or trolling
- Publishing private information without consent
- Spam or irrelevant promotional content
- Any behavior that would be inappropriate in a professional setting

### Enforcement

Instances of unacceptable behavior may be reported to the project maintainers. All complaints will be reviewed and investigated promptly and fairly.

## Getting Started

### Prerequisites

Before contributing, ensure you have:

- **Flutter SDK** 3.16.0 or later
- **Dart SDK** 3.2.0 or later
- **Git** for version control
- **Firebase CLI** for backend services
- **Code editor** (VS Code, Android Studio, or IntelliJ recommended)

### Development Environment Setup

1. **Fork the Repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/campus_lf_app.git
   cd campus_lf_app
   ```

2. **Set Up Upstream Remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/campus_lf_app.git
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Configure Development Environment**
   ```bash
   # Copy environment template
   cp .env.example .env.development
   
   # Configure Firebase (see DEPLOYMENT.md)
   firebase use --add
   ```

5. **Verify Setup**
   ```bash
   flutter doctor
   flutter test
   flutter analyze
   ```

### Project Structure

```
campus_lf_app/
├── lib/
│   ├── config/          # Configuration files
│   ├── models/          # Data models
│   ├── services/        # Business logic and API calls
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable UI components
│   ├── utils/           # Utility functions
│   └── main.dart        # App entry point
├── test/                # Unit and widget tests
├── integration_test/    # Integration tests
├── android/             # Android-specific code
├── ios/                 # iOS-specific code
├── web/                 # Web-specific code
├── docs/                # Documentation
└── assets/              # Static assets
```

## Development Workflow

### Branch Strategy

We use **Git Flow** with the following branch structure:

- **`main`**: Production-ready code
- **`develop`**: Integration branch for features
- **`feature/*`**: New features
- **`bugfix/*`**: Bug fixes
- **`hotfix/*`**: Critical production fixes
- **`release/*`**: Release preparation

### Creating a Feature Branch

```bash
# Update develop branch
git checkout develop
git pull upstream develop

# Create feature branch
git checkout -b feature/your-feature-name

# Work on your feature
# ... make changes ...

# Commit changes
git add .
git commit -m "feat: add new feature description"

# Push to your fork
git push origin feature/your-feature-name
```

### Commit Message Convention

We follow the **Conventional Commits** specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks
- **perf**: Performance improvements
- **ci**: CI/CD changes

#### Examples

```bash
# Feature
git commit -m "feat(auth): add biometric authentication"

# Bug fix
git commit -m "fix(chat): resolve message ordering issue"

# Documentation
git commit -m "docs: update API documentation"

# Breaking change
git commit -m "feat!: change user model structure

BREAKING CHANGE: User model now requires studentId field"
```

## Coding Standards

### Dart/Flutter Conventions

#### **File Naming**
- Use **snake_case** for file names
- Use **PascalCase** for class names
- Use **camelCase** for variables and functions

```dart
// ✅ Good
class UserProfile {}
String userName = 'john_doe';
void getUserData() {}

// ❌ Bad
class userProfile {}
String user_name = 'john_doe';
void get_user_data() {}
```

#### **Code Organization**

```dart
// File structure order:
// 1. Imports (dart: first, then package:, then relative)
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

// 2. Class definition
class UserProfileScreen extends StatefulWidget {
  // 3. Constructor
  const UserProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  // 4. Properties
  final String userId;

  // 5. Methods
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}
```

#### **Widget Structure**

```dart
class _UserProfileScreenState extends State<UserProfileScreen> {
  // 1. State variables
  bool _isLoading = false;
  User? _user;

  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  // 3. Private methods
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      _user = await UserService.getUser(widget.userId);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // 4. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // 5. Widget builders
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('User Profile'),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text('User not found'));
    }

    return _buildUserProfile();
  }

  Widget _buildUserProfile() {
    return Column(
      children: [
        _buildProfileHeader(),
        _buildProfileDetails(),
      ],
    );
  }
}
```

#### **Error Handling**

```dart
// ✅ Good - Specific error handling
Future<User> getUser(String id) async {
  try {
    final response = await _apiService.get('/users/$id');
    return User.fromJson(response.data);
  } on NetworkException catch (e) {
    throw UserServiceException('Network error: ${e.message}');
  } on FormatException catch (e) {
    throw UserServiceException('Invalid data format: ${e.message}');
  } catch (e) {
    throw UserServiceException('Unexpected error: $e');
  }
}

// ❌ Bad - Generic error handling
Future<User> getUser(String id) async {
  try {
    final response = await _apiService.get('/users/$id');
    return User.fromJson(response.data);
  } catch (e) {
    print('Error: $e');
    return null;
  }
}
```

#### **Null Safety**

```dart
// ✅ Good - Proper null safety
class User {
  final String id;
  final String name;
  final String? email; // Nullable
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.createdAt,
  });

  // Safe null checking
  String get displayName => name.isNotEmpty ? name : 'Unknown User';
  bool get hasEmail => email?.isNotEmpty ?? false;
}

// ❌ Bad - Unsafe null handling
class User {
  String id;
  String name;
  String email;
  DateTime createdAt;

  String get displayName => name != null ? name : 'Unknown User';
}
```

### State Management

#### **Provider Pattern**

```dart
// ✅ Good - Proper provider structure
class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Methods
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await AuthService.signIn(email, password);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void signOut() {
    _user = null;
    _clearError();
    notifyListeners();
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
```

### UI/UX Guidelines

#### **Material Design 3**

```dart
// ✅ Good - Consistent Material 3 usage
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        margin: EdgeInsets.all(8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
```

#### **Responsive Design**

```dart
// ✅ Good - Responsive layout
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 600) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
```

#### **Accessibility**

```dart
// ✅ Good - Accessible widgets
Widget _buildSearchButton() {
  return FloatingActionButton(
    onPressed: _performSearch,
    tooltip: 'Search for items',
    child: const Icon(
      Icons.search,
      semanticLabel: 'Search',
    ),
  );
}

Widget _buildItemCard(Item item) {
  return Card(
    child: ListTile(
      title: Text(item.name),
      subtitle: Text(item.description),
      onTap: () => _viewItemDetails(item),
      // Accessibility
      semanticsLabel: 'Item: ${item.name}, ${item.description}',
      accessibilityTraits: [AccessibilityTrait.button],
    ),
  );
}
```

## Testing Guidelines

### Test Structure

```
test/
├── unit/
│   ├── models/
│   ├── services/
│   └── utils/
├── widget/
│   ├── screens/
│   └── widgets/
└── integration/
    ├── auth_flow_test.dart
    └── report_flow_test.dart
```

### Unit Tests

```dart
// test/unit/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:campus_lf_app/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth);
    });

    group('signIn', () {
      test('should return user when credentials are valid', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'password123';
        final mockUser = MockUser();
        final mockCredential = MockUserCredential();
        
        when(mockCredential.user).thenReturn(mockUser);
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await authService.signIn(email, password);

        // Assert
        expect(result, equals(mockUser));
        verify(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).called(1);
      });

      test('should throw AuthException when credentials are invalid', () async {
        // Arrange
        const email = 'test@example.com';
        const password = 'wrongpassword';
        
        when(mockAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).thenThrow(FirebaseAuthException(
          code: 'wrong-password',
          message: 'Wrong password',
        ));

        // Act & Assert
        expect(
          () => authService.signIn(email, password),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
```

### Widget Tests

```dart
// test/widget/screens/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:campus_lf_app/screens/login_screen.dart';
import 'package:campus_lf_app/providers/auth_provider.dart';

void main() {
  group('LoginScreen', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('should display email and password fields', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should call signIn when login button is pressed', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Act
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      // Assert
      verify(mockAuthProvider.signIn('test@example.com', 'password123'))
          .called(1);
    });
  });
}
```

### Integration Tests

```dart
// integration_test/auth_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:campus_lf_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('complete sign up and sign in flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to sign up
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Fill sign up form
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('student_id_field')), 'ST12345');

      // Submit sign up
      await tester.tap(find.byKey(const Key('signup_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation to home screen
      expect(find.text('Welcome to Campus L&F'), findsOneWidget);
    });
  });
}
```

### Test Coverage

Maintain minimum test coverage:
- **Unit tests**: 80% coverage
- **Widget tests**: 70% coverage
- **Integration tests**: Critical user flows

```bash
# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# View coverage
open coverage/html/index.html
```

## Documentation Standards

### Code Documentation

#### **Class Documentation**

```dart
/// Service for managing user authentication and profile operations.
/// 
/// This service provides methods for user registration, login, logout,
/// and profile management. It integrates with Firebase Authentication
/// and Firestore for data persistence.
/// 
/// Example usage:
/// ```dart
/// final authService = AuthService();
/// final user = await authService.signIn('email@example.com', 'password');
/// ```
class AuthService {
  /// Creates a new instance of [AuthService].
  /// 
  /// The [firebaseAuth] parameter is optional and defaults to
  /// [FirebaseAuth.instance] if not provided.
  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Signs in a user with email and password.
  /// 
  /// Returns the authenticated [User] on success.
  /// Throws [AuthException] if authentication fails.
  /// 
  /// Parameters:
  /// - [email]: The user's email address
  /// - [password]: The user's password
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final user = await authService.signIn('user@example.com', 'password');
  ///   print('Signed in: ${user.email}');
  /// } catch (e) {
  ///   print('Sign in failed: $e');
  /// }
  /// ```
  Future<User> signIn(String email, String password) async {
    // Implementation...
  }
}
```

#### **Method Documentation**

```dart
/// Uploads an image file to Firebase Storage.
/// 
/// This method compresses the image before upload to optimize storage
/// and bandwidth usage. The uploaded image URL is returned on success.
/// 
/// Parameters:
/// - [imageFile]: The image file to upload
/// - [path]: The storage path where the image will be saved
/// - [quality]: Compression quality (0-100), defaults to 85
/// 
/// Returns:
/// A [Future] that completes with the download URL of the uploaded image.
/// 
/// Throws:
/// - [StorageException] if the upload fails
/// - [ArgumentError] if the file is not a valid image
/// 
/// Example:
/// ```dart
/// final file = File('path/to/image.jpg');
/// final url = await uploadImage(file, 'users/profile_images');
/// print('Image uploaded: $url');
/// ```
Future<String> uploadImage(
  File imageFile,
  String path, {
  int quality = 85,
}) async {
  // Implementation...
}
```

### README Updates

When adding new features, update the README.md:

1. **Features section**: Add new functionality
2. **Installation**: Update if new dependencies are added
3. **Usage**: Add examples for new features
4. **Configuration**: Document new environment variables

### API Documentation

Update API documentation when:
- Adding new endpoints
- Changing request/response formats
- Modifying authentication requirements
- Adding new error codes

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout feature/your-feature
   git rebase develop
   ```

2. **Run quality checks**
   ```bash
   # Format code
   dart format .
   
   # Analyze code
   flutter analyze
   
   # Run tests
   flutter test
   
   # Check test coverage
   flutter test --coverage
   ```

3. **Update documentation**
   - Update relevant documentation files
   - Add/update code comments
   - Update CHANGELOG.md if applicable

### Pull Request Template

```markdown
## Description
Brief description of the changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Checklist
- [ ] My code follows the project's coding standards
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
```

### Review Process

1. **Automated checks**: CI/CD pipeline runs automatically
2. **Code review**: At least one maintainer reviews the code
3. **Testing**: Reviewers test the changes manually if needed
4. **Approval**: Changes are approved by maintainers
5. **Merge**: Changes are merged into the target branch

### Review Criteria

Reviewers will check for:
- **Code quality**: Follows coding standards
- **Functionality**: Works as intended
- **Performance**: No significant performance regressions
- **Security**: No security vulnerabilities introduced
- **Testing**: Adequate test coverage
- **Documentation**: Proper documentation updates

## Issue Reporting

### Bug Reports

Use the bug report template:

```markdown
**Bug Description**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected Behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
- Device: [e.g. iPhone 12, Samsung Galaxy S21]
- OS: [e.g. iOS 15.0, Android 12]
- App Version: [e.g. 1.2.0]
- Flutter Version: [e.g. 3.16.0]

**Additional Context**
Add any other context about the problem here.
```

### Feature Requests

Use the feature request template:

```markdown
**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is.

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
```

## Security Guidelines

### Secure Coding Practices

1. **Input Validation**
   ```dart
   // ✅ Good - Validate all inputs
   String sanitizeInput(String input) {
     if (input.isEmpty) {
       throw ArgumentError('Input cannot be empty');
     }
     
     // Remove potentially dangerous characters
     return input.replaceAll(RegExp(r'[<>"\']'), '');
   }
   ```

2. **Authentication**
   ```dart
   // ✅ Good - Proper authentication checks
   Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
     final currentUser = FirebaseAuth.instance.currentUser;
     
     if (currentUser == null || currentUser.uid != userId) {
       throw UnauthorizedException('User not authorized');
     }
     
     await FirebaseFirestore.instance
         .collection('users')
         .doc(userId)
         .update(data);
   }
   ```

3. **Data Protection**
   ```dart
   // ✅ Good - Encrypt sensitive data
   class SecureStorage {
     static const _storage = FlutterSecureStorage();
     
     static Future<void> storeToken(String token) async {
       await _storage.write(key: 'auth_token', value: token);
     }
     
     static Future<String?> getToken() async {
       return await _storage.read(key: 'auth_token');
     }
   }
   ```

### Security Checklist

- [ ] All user inputs are validated and sanitized
- [ ] Authentication is required for protected operations
- [ ] Sensitive data is encrypted at rest and in transit
- [ ] API keys and secrets are not hardcoded
- [ ] Firebase security rules are properly configured
- [ ] HTTPS is used for all network communications
- [ ] User permissions are checked before data access

## Performance Guidelines

### Optimization Best Practices

1. **Widget Optimization**
   ```dart
   // ✅ Good - Use const constructors
   class ItemCard extends StatelessWidget {
     const ItemCard({
       Key? key,
       required this.item,
     }) : super(key: key);
     
     final Item item;
     
     @override
     Widget build(BuildContext context) {
       return const Card(
         child: ListTile(
           title: Text('Item Name'),
         ),
       );
     }
   }
   ```

2. **List Performance**
   ```dart
   // ✅ Good - Use ListView.builder for large lists
   Widget _buildItemList() {
     return ListView.builder(
       itemCount: items.length,
       itemBuilder: (context, index) {
         return ItemCard(item: items[index]);
       },
     );
   }
   ```

3. **Image Optimization**
   ```dart
   // ✅ Good - Optimize images
   Widget _buildItemImage(String imageUrl) {
     return CachedNetworkImage(
       imageUrl: imageUrl,
       placeholder: (context, url) => const CircularProgressIndicator(),
       errorWidget: (context, url, error) => const Icon(Icons.error),
       width: 200,
       height: 200,
       fit: BoxFit.cover,
     );
   }
   ```

### Performance Checklist

- [ ] Use const constructors where possible
- [ ] Implement lazy loading for large datasets
- [ ] Optimize images (size, format, caching)
- [ ] Minimize widget rebuilds
- [ ] Use efficient data structures
- [ ] Profile app performance regularly

## Accessibility Guidelines

### Accessibility Best Practices

1. **Semantic Labels**
   ```dart
   // ✅ Good - Provide semantic labels
   FloatingActionButton(
     onPressed: _addItem,
     tooltip: 'Add new item',
     child: const Icon(
       Icons.add,
       semanticLabel: 'Add item',
     ),
   )
   ```

2. **Focus Management**
   ```dart
   // ✅ Good - Manage focus properly
   class LoginForm extends StatefulWidget {
     @override
     _LoginFormState createState() => _LoginFormState();
   }
   
   class _LoginFormState extends State<LoginForm> {
     final _emailFocusNode = FocusNode();
     final _passwordFocusNode = FocusNode();
     
     @override
     Widget build(BuildContext context) {
       return Column(
         children: [
           TextFormField(
             focusNode: _emailFocusNode,
             textInputAction: TextInputAction.next,
             onFieldSubmitted: (_) {
               FocusScope.of(context).requestFocus(_passwordFocusNode);
             },
           ),
           TextFormField(
             focusNode: _passwordFocusNode,
             textInputAction: TextInputAction.done,
           ),
         ],
       );
     }
   }
   ```

3. **Color Contrast**
   ```dart
   // ✅ Good - Ensure sufficient color contrast
   class AppColors {
     static const primary = Color(0xFF1976D2);
     static const onPrimary = Color(0xFFFFFFFF); // High contrast
     static const error = Color(0xFFD32F2F);
     static const onError = Color(0xFFFFFFFF); // High contrast
   }
   ```

### Accessibility Checklist

- [ ] All interactive elements have semantic labels
- [ ] Color is not the only way to convey information
- [ ] Text has sufficient color contrast (4.5:1 minimum)
- [ ] Focus management is implemented properly
- [ ] Screen reader support is tested
- [ ] Touch targets are at least 44x44 pixels

---

## Getting Help

### Resources

- **Documentation**: Check the `/docs` folder for detailed guides
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Code Review**: Request reviews from maintainers

### Contact

- **Project Maintainers**: @maintainer1, @maintainer2
- **Email**: dev-team@campus.edu
- **Discord**: [Campus L&F Dev Community](https://discord.gg/campus-lf)

### Office Hours

The maintainers hold virtual office hours:
- **When**: Every Tuesday, 2:00 PM - 3:00 PM EST
- **Where**: Discord voice channel
- **What**: Q&A, code reviews, architecture discussions

---

Thank you for contributing to Campus Lost & Found! Your efforts help make the campus community more connected and helpful. 🎓✨