# Security Documentation
## Campus Lost & Found Application

### Table of Contents
1. [Security Overview](#security-overview)
2. [Authentication & Authorization](#authentication--authorization)
3. [Data Security](#data-security)
4. [Privacy Protection](#privacy-protection)
5. [Network Security](#network-security)
6. [Application Security](#application-security)
7. [Firebase Security](#firebase-security)
8. [Compliance Guidelines](#compliance-guidelines)
9. [Security Policies](#security-policies)
10. [Incident Response](#incident-response)
11. [Security Testing](#security-testing)
12. [Security Monitoring](#security-monitoring)

---

## Security Overview

### Security Architecture
The Campus Lost & Found application implements a multi-layered security approach:

- **Authentication Layer**: Firebase Authentication with multi-factor support
- **Authorization Layer**: Role-based access control (RBAC)
- **Data Layer**: End-to-end encryption for sensitive data
- **Network Layer**: HTTPS/TLS encryption for all communications
- **Application Layer**: Input validation and sanitization
- **Infrastructure Layer**: Firebase security rules and monitoring

### Security Principles
- **Principle of Least Privilege**: Users have minimal necessary permissions
- **Defense in Depth**: Multiple security layers
- **Zero Trust**: Verify every request and user
- **Data Minimization**: Collect only necessary information
- **Privacy by Design**: Built-in privacy protection

---

## Authentication & Authorization

### Authentication Methods

#### Primary Authentication
```javascript
// Firebase Authentication Configuration
const authConfig = {
  providers: [
    'email/password',
    'google.com',
    'microsoft.com'
  ],
  mfa: {
    enabled: true,
    methods: ['sms', 'totp']
  },
  passwordPolicy: {
    minLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireNumbers: true,
    requireSpecialChars: true
  }
};
```

#### Multi-Factor Authentication (MFA)
- **SMS Verification**: Phone number verification
- **TOTP**: Time-based one-time passwords
- **Email Verification**: Required for account activation

#### Session Management
```dart
class SessionManager {
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration refreshThreshold = Duration(minutes: 5);
  
  static Future<void> refreshToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.getIdToken(true);
    }
  }
  
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await clearLocalStorage();
  }
}
```

### Authorization Framework

#### Role-Based Access Control
```dart
enum UserRole {
  student,
  staff,
  admin,
  moderator
}

class PermissionManager {
  static bool canCreateReport(UserRole role) {
    return [UserRole.student, UserRole.staff, UserRole.admin].contains(role);
  }
  
  static bool canModerateContent(UserRole role) {
    return [UserRole.moderator, UserRole.admin].contains(role);
  }
  
  static bool canAccessAnalytics(UserRole role) {
    return [UserRole.admin].contains(role);
  }
}
```

#### Resource-Level Permissions
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports are readable by all authenticated users
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.auth.uid == resource.data.uid;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.uid || 
         hasRole(request.auth.uid, 'moderator'));
    }
  }
}
```

---

## Data Security

### Data Classification
- **Public**: General application information
- **Internal**: User profiles, reports metadata
- **Confidential**: Personal messages, contact information
- **Restricted**: Authentication tokens, admin data

### Encryption Standards

#### Data at Rest
```dart
class EncryptionService {
  static const String algorithm = 'AES-256-GCM';
  
  static Future<String> encryptSensitiveData(String data) async {
    final key = await getEncryptionKey();
    final encrypted = await encrypt(data, key, algorithm);
    return encrypted;
  }
  
  static Future<String> decryptSensitiveData(String encryptedData) async {
    final key = await getEncryptionKey();
    final decrypted = await decrypt(encryptedData, key, algorithm);
    return decrypted;
  }
}
```

#### Data in Transit
- **TLS 1.3**: All network communications
- **Certificate Pinning**: Prevent man-in-the-middle attacks
- **HSTS**: HTTP Strict Transport Security

#### Key Management
```dart
class KeyManager {
  static Future<String> getEncryptionKey() async {
    // Use Flutter Secure Storage for key storage
    const storage = FlutterSecureStorage();
    String? key = await storage.read(key: 'encryption_key');
    
    if (key == null) {
      key = generateSecureKey();
      await storage.write(key: 'encryption_key', value: key);
    }
    
    return key;
  }
  
  static String generateSecureKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
```

### Data Sanitization
```dart
class DataSanitizer {
  static String sanitizeInput(String input) {
    // Remove potentially harmful characters
    String sanitized = input.replaceAll(RegExp(r'[<>"\']'), '');
    
    // Limit length
    if (sanitized.length > 1000) {
      sanitized = sanitized.substring(0, 1000);
    }
    
    // Trim whitespace
    return sanitized.trim();
  }
  
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }
}
```

---

## Privacy Protection

### Data Collection Principles
- **Minimal Collection**: Only collect necessary data
- **Purpose Limitation**: Use data only for stated purposes
- **Consent Management**: Clear user consent mechanisms
- **Right to Deletion**: Users can delete their data

### Privacy Controls
```dart
class PrivacyManager {
  static Future<void> updatePrivacySettings(String userId, Map<String, bool> settings) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'privacy': {
        'showProfile': settings['showProfile'] ?? false,
        'allowMessages': settings['allowMessages'] ?? true,
        'shareLocation': settings['shareLocation'] ?? false,
        'analyticsOptIn': settings['analyticsOptIn'] ?? false,
      }
    });
  }
  
  static Future<void> deleteUserData(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    
    // Delete user profile
    batch.delete(FirebaseFirestore.instance.collection('users').doc(userId));
    
    // Delete user reports
    final reports = await FirebaseFirestore.instance
        .collection('reports')
        .where('uid', isEqualTo: userId)
        .get();
    
    for (final doc in reports.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}
```

### GDPR Compliance
```dart
class GDPRCompliance {
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    final userData = <String, dynamic>{};
    
    // Export profile data
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    userData['profile'] = profile.data();
    
    // Export reports
    final reports = await FirebaseFirestore.instance
        .collection('reports')
        .where('uid', isEqualTo: userId)
        .get();
    userData['reports'] = reports.docs.map((doc) => doc.data()).toList();
    
    return userData;
  }
  
  static Future<void> anonymizeUserData(String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'name': 'Anonymous User',
      'email': 'deleted@example.com',
      'phone': null,
      'profilePicture': null,
    });
  }
}
```

---

## Network Security

### HTTPS Configuration
```dart
class NetworkSecurity {
  static HttpClient createSecureClient() {
    final client = HttpClient();
    
    // Enable certificate pinning
    client.badCertificateCallback = (cert, host, port) {
      return validateCertificate(cert, host);
    };
    
    return client;
  }
  
  static bool validateCertificate(X509Certificate cert, String host) {
    // Implement certificate pinning logic
    final expectedFingerprints = [
      'SHA256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
      'SHA256:BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB='
    ];
    
    final certFingerprint = sha256.convert(cert.der).toString();
    return expectedFingerprints.contains(certFingerprint);
  }
}
```

### API Security
```dart
class APISecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add security headers
    options.headers['X-Content-Type-Options'] = 'nosniff';
    options.headers['X-Frame-Options'] = 'DENY';
    options.headers['X-XSS-Protection'] = '1; mode=block';
    
    // Add authentication token
    final token = AuthService.getCurrentToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    super.onRequest(options, handler);
  }
  
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // Log security-related errors
    if (err.response?.statusCode == 401) {
      SecurityLogger.logUnauthorizedAccess(err);
    }
    
    super.onError(err, handler);
  }
}
```

---

## Application Security

### Input Validation
```dart
class InputValidator {
  static ValidationResult validateReportInput(Map<String, dynamic> data) {
    final errors = <String>[];
    
    // Validate item name
    if (data['itemName'] == null || data['itemName'].toString().trim().isEmpty) {
      errors.add('Item name is required');
    } else if (data['itemName'].toString().length > 100) {
      errors.add('Item name must be less than 100 characters');
    }
    
    // Validate description
    if (data['description'] != null && data['description'].toString().length > 1000) {
      errors.add('Description must be less than 1000 characters');
    }
    
    // Validate location
    final validLocations = ['Library', 'Cafeteria', 'Gym', 'Classroom', 'Parking', 'Other'];
    if (!validLocations.contains(data['location'])) {
      errors.add('Invalid location');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  ValidationResult({required this.isValid, required this.errors});
}
```

### XSS Prevention
```dart
class XSSProtection {
  static String sanitizeHTML(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;');
  }
  
  static String sanitizeForJSON(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
```

### SQL Injection Prevention
```dart
class DatabaseSecurity {
  // Using parameterized queries with Firestore
  static Future<List<Report>> searchReports(String query) async {
    // Sanitize search query
    final sanitizedQuery = DataSanitizer.sanitizeInput(query);
    
    // Use Firestore's built-in security
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('itemName', isGreaterThanOrEqualTo: sanitizedQuery)
        .where('itemName', isLessThan: sanitizedQuery + '\uf8ff')
        .limit(50)
        .get();
    
    return snapshot.docs.map((doc) => Report.fromJson(doc.data())).toList();
  }
}
```

---

## Firebase Security

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function hasRole(userId, role) {
      return get(/databases/$(database)/documents/users/$(userId)).data.role == role;
    }
    
    function isValidReport() {
      return request.resource.data.keys().hasAll(['itemName', 'status', 'location', 'uid']) &&
             request.resource.data.itemName is string &&
             request.resource.data.itemName.size() <= 100 &&
             request.resource.data.status in ['lost', 'found'] &&
             request.resource.data.location in ['Library', 'Cafeteria', 'Gym', 'Classroom', 'Parking', 'Other'];
    }
    
    // User documents
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId) && isValidUserData();
    }
    
    // Report documents
    match /reports/{reportId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isValidReport() && isOwner(request.resource.data.uid);
      allow update: if isAuthenticated() && (isOwner(resource.data.uid) || hasRole(request.auth.uid, 'moderator'));
      allow delete: if isAuthenticated() && (isOwner(resource.data.uid) || hasRole(request.auth.uid, 'admin'));
    }
    
    // Message documents
    match /conversations/{conversationId}/messages/{messageId} {
      allow read, write: if isAuthenticated() && 
        (request.auth.uid in resource.data.participants || 
         request.auth.uid in request.resource.data.participants);
    }
  }
}
```

### Firebase Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                   request.auth.uid == userId &&
                   request.resource.size < 5 * 1024 * 1024 && // 5MB limit
                   request.resource.contentType.matches('image/.*');
    }
    
    // Report images
    match /report_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                   request.auth.uid == userId &&
                   request.resource.size < 10 * 1024 * 1024 && // 10MB limit
                   request.resource.contentType.matches('image/.*');
    }
  }
}
```

### Firebase Functions Security
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Verify authentication middleware
const verifyAuth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split('Bearer ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

// Rate limiting
const rateLimit = require('express-rate-limit');
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

exports.secureFunction = functions.https.onRequest((req, res) => {
  limiter(req, res, () => {
    verifyAuth(req, res, () => {
      // Function logic here
    });
  });
});
```

---

## Compliance Guidelines

### GDPR Compliance Checklist
- [ ] **Lawful Basis**: Clear legal basis for data processing
- [ ] **Consent Management**: Granular consent mechanisms
- [ ] **Data Minimization**: Collect only necessary data
- [ ] **Purpose Limitation**: Use data only for stated purposes
- [ ] **Data Accuracy**: Keep data accurate and up-to-date
- [ ] **Storage Limitation**: Delete data when no longer needed
- [ ] **Security**: Implement appropriate security measures
- [ ] **Accountability**: Document compliance measures

### COPPA Compliance (if applicable)
- [ ] **Parental Consent**: Obtain verifiable parental consent for users under 13
- [ ] **Data Collection Limits**: Limit data collection from children
- [ ] **Disclosure Restrictions**: Restrict disclosure of children's data
- [ ] **Access Rights**: Provide parents access to their child's data

### FERPA Compliance (Educational Records)
- [ ] **Educational Records Protection**: Protect student educational records
- [ ] **Consent Requirements**: Obtain consent for disclosure
- [ ] **Access Rights**: Provide students access to their records
- [ ] **Amendment Rights**: Allow students to request amendments

---

## Security Policies

### Password Policy
```dart
class PasswordPolicy {
  static const int minLength = 8;
  static const int maxLength = 128;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;
  static const List<String> commonPasswords = [
    'password', '123456', 'qwerty', 'admin'
  ];
  
  static ValidationResult validatePassword(String password) {
    final errors = <String>[];
    
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters');
    }
    
    if (password.length > maxLength) {
      errors.add('Password must be less than $maxLength characters');
    }
    
    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }
    
    if (requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }
    
    if (requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }
    
    if (requireSpecialChars && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }
    
    if (commonPasswords.contains(password.toLowerCase())) {
      errors.add('Password is too common');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
```

### Data Retention Policy
```dart
class DataRetentionPolicy {
  static const Duration userDataRetention = Duration(days: 2555); // 7 years
  static const Duration reportDataRetention = Duration(days: 1095); // 3 years
  static const Duration messageDataRetention = Duration(days: 365); // 1 year
  static const Duration logDataRetention = Duration(days: 90); // 3 months
  
  static Future<void> cleanupExpiredData() async {
    final now = DateTime.now();
    
    // Clean up old reports
    final expiredReports = await FirebaseFirestore.instance
        .collection('reports')
        .where('timestamp', isLessThan: now.subtract(reportDataRetention))
        .get();
    
    for (final doc in expiredReports.docs) {
      await doc.reference.delete();
    }
    
    // Clean up old messages
    final expiredMessages = await FirebaseFirestore.instance
        .collectionGroup('messages')
        .where('timestamp', isLessThan: now.subtract(messageDataRetention))
        .get();
    
    for (final doc in expiredMessages.docs) {
      await doc.reference.delete();
    }
  }
}
```

### Access Control Policy
```dart
class AccessControlPolicy {
  static const Map<UserRole, List<String>> rolePermissions = {
    UserRole.student: [
      'create_report',
      'view_reports',
      'send_messages',
      'update_profile'
    ],
    UserRole.staff: [
      'create_report',
      'view_reports',
      'send_messages',
      'update_profile',
      'view_analytics_basic'
    ],
    UserRole.moderator: [
      'create_report',
      'view_reports',
      'send_messages',
      'update_profile',
      'moderate_content',
      'view_analytics_basic'
    ],
    UserRole.admin: [
      'create_report',
      'view_reports',
      'send_messages',
      'update_profile',
      'moderate_content',
      'view_analytics_full',
      'manage_users',
      'system_configuration'
    ]
  };
  
  static bool hasPermission(UserRole role, String permission) {
    return rolePermissions[role]?.contains(permission) ?? false;
  }
}
```

---

## Incident Response

### Security Incident Response Plan

#### 1. Incident Classification
- **Critical**: Data breach, system compromise
- **High**: Unauthorized access, service disruption
- **Medium**: Security policy violation, suspicious activity
- **Low**: Minor security issue, false positive

#### 2. Response Team
- **Incident Commander**: Overall response coordination
- **Technical Lead**: Technical investigation and remediation
- **Communications Lead**: Internal and external communications
- **Legal Counsel**: Legal and compliance guidance

#### 3. Response Procedures
```dart
class IncidentResponse {
  static Future<void> reportSecurityIncident(SecurityIncident incident) async {
    // Log the incident
    await SecurityLogger.logIncident(incident);
    
    // Notify response team
    await NotificationService.notifySecurityTeam(incident);
    
    // Implement immediate containment if critical
    if (incident.severity == IncidentSeverity.critical) {
      await implementEmergencyContainment(incident);
    }
    
    // Start investigation
    await startInvestigation(incident);
  }
  
  static Future<void> implementEmergencyContainment(SecurityIncident incident) async {
    switch (incident.type) {
      case IncidentType.dataBreach:
        await disableAffectedAccounts();
        await revokeCompromisedTokens();
        break;
      case IncidentType.systemCompromise:
        await isolateAffectedSystems();
        await enableEmergencyMode();
        break;
    }
  }
}
```

#### 4. Communication Templates
```dart
class IncidentCommunication {
  static String generateUserNotification(SecurityIncident incident) {
    return '''
    Security Notice
    
    We have detected a security incident that may have affected your account.
    
    What happened: ${incident.description}
    What we're doing: ${incident.responseActions}
    What you should do: ${incident.userActions}
    
    We take your security seriously and are working to resolve this issue.
    
    For questions, contact: security@campus-lf.edu
    ''';
  }
  
  static String generateRegulatoryNotification(SecurityIncident incident) {
    return '''
    Security Incident Report
    
    Incident ID: ${incident.id}
    Date/Time: ${incident.timestamp}
    Severity: ${incident.severity}
    Affected Users: ${incident.affectedUserCount}
    Data Types: ${incident.affectedDataTypes}
    
    Description: ${incident.detailedDescription}
    Root Cause: ${incident.rootCause}
    Remediation: ${incident.remediationSteps}
    
    Contact: security@campus-lf.edu
    ''';
  }
}
```

---

## Security Testing

### Security Test Plan
```dart
class SecurityTestSuite {
  static Future<void> runSecurityTests() async {
    await testAuthentication();
    await testAuthorization();
    await testInputValidation();
    await testDataEncryption();
    await testNetworkSecurity();
  }
  
  static Future<void> testAuthentication() async {
    // Test invalid credentials
    expect(await AuthService.login('invalid@email.com', 'wrongpassword'), 
           throwsA(isA<AuthenticationException>()));
    
    // Test session timeout
    await AuthService.login('test@email.com', 'password');
    await Future.delayed(Duration(hours: 25));
    expect(await AuthService.getCurrentUser(), isNull);
  }
  
  static Future<void> testAuthorization() async {
    // Test unauthorized access
    final studentUser = await createTestUser(UserRole.student);
    expect(await AdminService.deleteUser('someUserId', studentUser.token),
           throwsA(isA<UnauthorizedException>()));
  }
  
  static Future<void> testInputValidation() async {
    // Test XSS prevention
    final maliciousInput = '<script>alert("xss")</script>';
    final sanitized = DataSanitizer.sanitizeInput(maliciousInput);
    expect(sanitized, isNot(contains('<script>')));
    
    // Test SQL injection prevention
    final sqlInjection = "'; DROP TABLE users; --";
    expect(() => DatabaseSecurity.searchReports(sqlInjection), 
           returnsNormally);
  }
}
```

### Penetration Testing Checklist
- [ ] **Authentication Testing**
  - [ ] Brute force attacks
  - [ ] Session management
  - [ ] Password policy enforcement
  - [ ] Multi-factor authentication bypass

- [ ] **Authorization Testing**
  - [ ] Privilege escalation
  - [ ] Role-based access control
  - [ ] Resource-level permissions
  - [ ] API endpoint authorization

- [ ] **Input Validation Testing**
  - [ ] Cross-site scripting (XSS)
  - [ ] SQL injection
  - [ ] Command injection
  - [ ] File upload vulnerabilities

- [ ] **Data Security Testing**
  - [ ] Data encryption at rest
  - [ ] Data encryption in transit
  - [ ] Key management
  - [ ] Data leakage

---

## Security Monitoring

### Security Logging
```dart
class SecurityLogger {
  static Future<void> logSecurityEvent(SecurityEvent event) async {
    final logEntry = {
      'timestamp': DateTime.now().toIso8601String(),
      'eventType': event.type.toString(),
      'severity': event.severity.toString(),
      'userId': event.userId,
      'ipAddress': event.ipAddress,
      'userAgent': event.userAgent,
      'details': event.details,
    };
    
    // Log to Firebase Analytics
    await FirebaseAnalytics.instance.logEvent(
      name: 'security_event',
      parameters: logEntry,
    );
    
    // Log to external SIEM if configured
    if (event.severity == SecuritySeverity.high || 
        event.severity == SecuritySeverity.critical) {
      await SIEMIntegration.sendLog(logEntry);
    }
  }
  
  static Future<void> logFailedLogin(String email, String ipAddress) async {
    await logSecurityEvent(SecurityEvent(
      type: SecurityEventType.failedLogin,
      severity: SecuritySeverity.medium,
      userId: email,
      ipAddress: ipAddress,
      details: 'Failed login attempt',
    ));
  }
  
  static Future<void> logUnauthorizedAccess(String userId, String resource) async {
    await logSecurityEvent(SecurityEvent(
      type: SecurityEventType.unauthorizedAccess,
      severity: SecuritySeverity.high,
      userId: userId,
      details: 'Attempted to access: $resource',
    ));
  }
}
```

### Security Metrics
```dart
class SecurityMetrics {
  static Future<Map<String, dynamic>> getSecurityDashboard() async {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));
    
    return {
      'failedLogins': await getFailedLoginCount(last24Hours),
      'unauthorizedAccess': await getUnauthorizedAccessCount(last24Hours),
      'activeUsers': await getActiveUserCount(last24Hours),
      'suspiciousActivity': await getSuspiciousActivityCount(last24Hours),
      'securityAlerts': await getActiveSecurityAlerts(),
    };
  }
  
  static Future<void> generateSecurityReport() async {
    final metrics = await getSecurityDashboard();
    final report = SecurityReport(
      timestamp: DateTime.now(),
      metrics: metrics,
      recommendations: await generateSecurityRecommendations(metrics),
    );
    
    await SecurityReportService.saveReport(report);
    await NotificationService.notifySecurityTeam(report);
  }
}
```

### Automated Security Monitoring
```dart
class SecurityMonitor {
  static Timer? _monitoringTimer;
  
  static void startMonitoring() {
    _monitoringTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      performSecurityChecks();
    });
  }
  
  static Future<void> performSecurityChecks() async {
    // Check for suspicious login patterns
    await checkSuspiciousLogins();
    
    // Check for unusual data access patterns
    await checkDataAccessPatterns();
    
    // Check for potential security vulnerabilities
    await checkSecurityVulnerabilities();
    
    // Check system health
    await checkSystemHealth();
  }
  
  static Future<void> checkSuspiciousLogins() async {
    final recentLogins = await getRecentLogins(Duration(minutes: 5));
    
    for (final login in recentLogins) {
      // Check for multiple failed attempts
      if (login.failedAttempts > 5) {
        await SecurityLogger.logSecurityEvent(SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          severity: SecuritySeverity.high,
          userId: login.userId,
          details: 'Multiple failed login attempts: ${login.failedAttempts}',
        ));
      }
      
      // Check for unusual location
      if (await isUnusualLocation(login.userId, login.location)) {
        await SecurityLogger.logSecurityEvent(SecurityEvent(
          type: SecurityEventType.suspiciousActivity,
          severity: SecuritySeverity.medium,
          userId: login.userId,
          details: 'Login from unusual location: ${login.location}',
        ));
      }
    }
  }
}
```

---

## Security Contact Information

### Security Team
- **Security Officer**: security@campus-lf.edu
- **Emergency Contact**: +1-555-SECURITY
- **Incident Reporting**: incidents@campus-lf.edu

### Vulnerability Disclosure
- **Email**: security@campus-lf.edu
- **PGP Key**: Available at https://campus-lf.edu/.well-known/security.txt
- **Response Time**: 48 hours for acknowledgment, 30 days for resolution

### Security Resources
- **Security Policy**: https://campus-lf.edu/security-policy
- **Privacy Policy**: https://campus-lf.edu/privacy-policy
- **Terms of Service**: https://campus-lf.edu/terms-of-service
- **Security Updates**: https://campus-lf.edu/security-updates

---

*This security documentation is reviewed quarterly and updated as needed to reflect current security practices and threats.*

**Last Updated**: January 2024  
**Version**: 1.0  
**Next Review**: April 2024