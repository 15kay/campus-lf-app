# Deployment Guide
## Campus Lost & Found Application

### Table of Contents
1. [Deployment Overview](#deployment-overview)
2. [Environment Setup](#environment-setup)
3. [Build Configuration](#build-configuration)
4. [Platform-Specific Deployment](#platform-specific-deployment)
5. [Firebase Deployment](#firebase-deployment)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Production Deployment](#production-deployment)
8. [Monitoring and Logging](#monitoring-and-logging)
9. [Backup and Recovery](#backup-and-recovery)
10. [Maintenance Procedures](#maintenance-procedures)
11. [Rollback Procedures](#rollback-procedures)
12. [Performance Optimization](#performance-optimization)
13. [Security Hardening](#security-hardening)
14. [Troubleshooting](#troubleshooting)

---

## Deployment Overview

### Deployment Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Mobile Apps   │    │   Web App       │    │  Desktop App    │
│  (iOS/Android)  │    │   (Flutter)     │    │   (Flutter)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Load Balancer  │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Firebase Cloud  │
                    │   Functions     │
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Firestore     │    │ Firebase Auth   │    │ Firebase        │
│   Database      │    │                 │    │ Storage         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Deployment Environments
- **Development**: Local development environment
- **Testing**: Automated testing environment
- **Staging**: Pre-production testing environment
- **Production**: Live production environment

### Deployment Strategy
- **Blue-Green Deployment**: Zero-downtime deployments
- **Canary Releases**: Gradual rollout to subset of users
- **Feature Flags**: Control feature availability
- **Automated Rollbacks**: Quick recovery from issues

---

## Environment Setup

### Prerequisites
```bash
# Required Software
- Flutter SDK 3.16.0+
- Dart SDK 3.2.0+
- Firebase CLI 12.0.0+
- Node.js 18.0.0+
- Git 2.40.0+

# Platform-specific tools
- Xcode 15.0+ (for iOS)
- Android Studio 2023.1+ (for Android)
- Chrome 120.0+ (for Web)
```

### Environment Configuration
```yaml
# config/environments.yaml
development:
  firebase_project: campus-lf-dev
  api_base_url: https://dev-api.campus-lf.edu
  debug_mode: true
  analytics_enabled: false
  
testing:
  firebase_project: campus-lf-test
  api_base_url: https://test-api.campus-lf.edu
  debug_mode: true
  analytics_enabled: false
  
staging:
  firebase_project: campus-lf-staging
  api_base_url: https://staging-api.campus-lf.edu
  debug_mode: false
  analytics_enabled: true
  
production:
  firebase_project: campus-lf-prod
  api_base_url: https://api.campus-lf.edu
  debug_mode: false
  analytics_enabled: true
```

### Environment Variables
```bash
# .env.production
FIREBASE_PROJECT_ID=campus-lf-prod
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=campus-lf-prod.firebaseapp.com
FIREBASE_DATABASE_URL=https://campus-lf-prod.firebaseio.com
FIREBASE_STORAGE_BUCKET=campus-lf-prod.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=1:123456789:web:abcdef123456

# Security
ENCRYPTION_KEY=your-encryption-key
JWT_SECRET=your-jwt-secret
API_RATE_LIMIT=1000

# External Services
SENDGRID_API_KEY=your-sendgrid-key
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
```

---

## Build Configuration

### Flutter Build Configuration
```yaml
# pubspec.yaml
name: campus_lf_app
description: Campus Lost & Found Application
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  # ... other dependencies

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
          weight: 700
```

### Build Scripts
```bash
#!/bin/bash
# scripts/build.sh

set -e

echo "🚀 Starting build process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Run tests
echo "🧪 Running tests..."
flutter test

# Build for different platforms
echo "📱 Building for platforms..."

# Android
echo "Building Android APK..."
flutter build apk --release --target-platform android-arm64

echo "Building Android App Bundle..."
flutter build appbundle --release

# iOS
echo "Building iOS..."
flutter build ios --release --no-codesign

# Web
echo "Building Web..."
flutter build web --release --web-renderer canvaskit

# Desktop (if needed)
echo "Building Desktop..."
flutter build windows --release
flutter build macos --release
flutter build linux --release

echo "✅ Build process completed!"
```

### Code Signing Configuration
```bash
# iOS Code Signing
# ios/Runner.xcodeproj/project.pbxproj
DEVELOPMENT_TEAM = YOUR_TEAM_ID;
CODE_SIGN_IDENTITY = "Apple Distribution";
PROVISIONING_PROFILE_SPECIFIER = "Campus LF Distribution";

# Android Signing
# android/key.properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=campus-lf-key
storeFile=../keystore/campus-lf-keystore.jks
```

---

## Platform-Specific Deployment

### Android Deployment

#### Google Play Store Deployment
```bash
# Build signed APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release

# Upload to Google Play Console
# 1. Go to Google Play Console
# 2. Select your app
# 3. Go to Release management > App releases
# 4. Upload the .aab file
# 5. Fill in release notes
# 6. Submit for review
```

#### Android Configuration
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="edu.campus.lf">
    
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    
    <application
        android:label="Campus Lost &amp; Found"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />
              
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### iOS Deployment

#### App Store Deployment
```bash
# Build iOS app
flutter build ios --release

# Open Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Any iOS Device" as target
# 2. Product > Archive
# 3. Upload to App Store Connect
# 4. Submit for review
```

#### iOS Configuration
```xml
<!-- ios/Runner/Info.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>Campus Lost &amp; Found</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>campus_lf_app</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UILaunchStoryboardName</key>
    <string>LaunchScreen</string>
    <key>UIMainStoryboardFile</key>
    <string>Main</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to take photos of lost/found items.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>This app needs microphone access for voice calls.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to select images.</string>
</dict>
</plist>
```

### Web Deployment

#### Firebase Hosting Deployment
```bash
# Build web app
flutter build web --release

# Initialize Firebase Hosting
firebase init hosting

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Custom domain setup
firebase hosting:channel:deploy production --expires 30d
```

#### Web Configuration
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Campus Lost & Found - Find your lost items">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Campus Lost & Found">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>Campus Lost & Found</title>
  <link rel="manifest" href="manifest.json">
  
  <!-- PWA Configuration -->
  <meta name="theme-color" content="#2196F3">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  
  <!-- Security Headers -->
  <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline' https://www.gstatic.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https:;">
</head>
<body>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        }
      }).then(function(engineInitializer) {
        return engineInitializer.initializeEngine();
      }).then(function(appRunner) {
        return appRunner.runApp();
      });
    });
  </script>
</body>
</html>
```

### Desktop Deployment

#### Windows Deployment
```bash
# Build Windows app
flutter build windows --release

# Create installer using Inno Setup or NSIS
# Package the build/windows/runner/Release folder
```

#### macOS Deployment
```bash
# Build macOS app
flutter build macos --release

# Code sign the app
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" build/macos/Build/Products/Release/campus_lf_app.app

# Create DMG installer
hdiutil create -volname "Campus Lost & Found" -srcfolder build/macos/Build/Products/Release/campus_lf_app.app -ov -format UDZO campus_lf_app.dmg
```

---

## Firebase Deployment

### Firebase Project Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase project
firebase init

# Select features:
# - Firestore
# - Functions
# - Hosting
# - Storage
# - Emulators
```

### Firestore Deployment
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Firestore indexes
firebase deploy --only firestore:indexes
```

#### Firestore Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.uid &&
        isValidReport(request.resource.data);
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.uid || 
         hasRole(request.auth.uid, 'moderator'));
      allow delete: if request.auth != null && 
        (request.auth.uid == resource.data.uid || 
         hasRole(request.auth.uid, 'admin'));
    }
    
    // Helper functions
    function isValidReport(data) {
      return data.keys().hasAll(['itemName', 'status', 'location', 'uid']) &&
             data.itemName is string &&
             data.itemName.size() > 0 &&
             data.status in ['lost', 'found'] &&
             data.location in ['Library', 'Cafeteria', 'Gym', 'Classroom', 'Parking', 'Other'];
    }
    
    function hasRole(userId, role) {
      return get(/databases/$(database)/documents/users/$(userId)).data.role == role;
    }
  }
}
```

### Firebase Functions Deployment
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendNotification
```

#### Cloud Functions
```javascript
// functions/index.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Send notification when new report is created
exports.sendReportNotification = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snap, context) => {
    const report = snap.data();
    const reportId = context.params.reportId;
    
    // Send push notification to relevant users
    const message = {
      notification: {
        title: `New ${report.status} item reported`,
        body: `${report.itemName} at ${report.location}`,
      },
      topic: `${report.status}_items`,
    };
    
    try {
      await admin.messaging().send(message);
      console.log('Notification sent successfully');
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });

// Clean up old reports
exports.cleanupOldReports = functions.pubsub
  .schedule('0 2 * * *') // Run daily at 2 AM
  .onRun(async (context) => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 365); // 1 year ago
    
    const oldReports = await admin.firestore()
      .collection('reports')
      .where('timestamp', '<', cutoff)
      .get();
    
    const batch = admin.firestore().batch();
    oldReports.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`Deleted ${oldReports.size} old reports`);
  });
```

### Firebase Storage Deployment
```bash
# Deploy storage rules
firebase deploy --only storage
```

#### Storage Security Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile pictures
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                   request.auth.uid == userId &&
                   request.resource.size < 5 * 1024 * 1024 && // 5MB
                   request.resource.contentType.matches('image/.*');
    }
    
    // Report images
    match /report_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                   request.auth.uid == userId &&
                   request.resource.size < 10 * 1024 * 1024 && // 10MB
                   request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

## CI/CD Pipeline

### GitHub Actions Workflow
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [ main ]
  workflow_dispatch:

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
      
    - name: Run tests
      run: flutter test --coverage
      
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: coverage/lcov.info

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        distribution: 'zulu'
        java-version: '17'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build APK
      run: flutter build apk --release
      
    - name: Build App Bundle
      run: flutter build appbundle --release
      
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: android-builds
        path: |
          build/app/outputs/flutter-apk/app-release.apk
          build/app/outputs/bundle/release/app-release.aab

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build iOS
      run: flutter build ios --release --no-codesign
      
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: ios-build
        path: build/ios/iphoneos/Runner.app

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        
    - name: Install dependencies
      run: flutter pub get
      
    - name: Build Web
      run: flutter build web --release
      
    - name: Deploy to Firebase Hosting
      uses: FirebaseExtended/action-hosting-deploy@v0
      with:
        repoToken: '${{ secrets.GITHUB_TOKEN }}'
        firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
        projectId: campus-lf-prod
        channelId: live

  deploy-functions:
    needs: test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install Firebase CLI
      run: npm install -g firebase-tools
      
    - name: Deploy Firebase Functions
      run: firebase deploy --only functions --project campus-lf-prod
      env:
        FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

### Deployment Scripts
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

ENVIRONMENT=${1:-staging}
VERSION=${2:-$(git rev-parse --short HEAD)}

echo "🚀 Deploying to $ENVIRONMENT (version: $VERSION)"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|production)$ ]]; then
    echo "❌ Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
flutter test

# Build applications
echo "📱 Building applications..."
./scripts/build.sh

# Deploy Firebase components
echo "☁️ Deploying Firebase components..."
firebase use $ENVIRONMENT
firebase deploy --only firestore:rules,firestore:indexes,functions,storage

# Deploy web app
echo "🌐 Deploying web application..."
firebase deploy --only hosting

# Deploy mobile apps (if production)
if [ "$ENVIRONMENT" = "production" ]; then
    echo "📱 Deploying mobile applications..."
    # This would typically involve uploading to app stores
    # or internal distribution systems
fi

# Update version tracking
echo "📝 Updating version tracking..."
git tag "v$VERSION-$ENVIRONMENT"
git push origin "v$VERSION-$ENVIRONMENT"

echo "✅ Deployment completed successfully!"
echo "🔗 Web app: https://$ENVIRONMENT.campus-lf.edu"
```

---

## Production Deployment

### Pre-Deployment Checklist
- [ ] **Code Quality**
  - [ ] All tests passing
  - [ ] Code review completed
  - [ ] Security scan passed
  - [ ] Performance benchmarks met

- [ ] **Configuration**
  - [ ] Environment variables set
  - [ ] Firebase project configured
  - [ ] SSL certificates valid
  - [ ] DNS records updated

- [ ] **Security**
  - [ ] Security rules deployed
  - [ ] API keys rotated
  - [ ] Access controls verified
  - [ ] Backup procedures tested

- [ ] **Monitoring**
  - [ ] Monitoring tools configured
  - [ ] Alerting rules set up
  - [ ] Log aggregation enabled
  - [ ] Performance tracking active

### Production Deployment Process
```bash
#!/bin/bash
# scripts/production-deploy.sh

set -e

echo "🚀 Starting production deployment..."

# Pre-deployment checks
echo "🔍 Running pre-deployment checks..."
./scripts/pre-deployment-checks.sh

# Create deployment backup
echo "💾 Creating deployment backup..."
./scripts/backup.sh production

# Deploy to staging first
echo "🧪 Deploying to staging for final validation..."
./scripts/deploy.sh staging

# Run smoke tests on staging
echo "🔥 Running smoke tests on staging..."
./scripts/smoke-tests.sh staging

# Deploy to production
echo "🎯 Deploying to production..."
./scripts/deploy.sh production

# Run post-deployment verification
echo "✅ Running post-deployment verification..."
./scripts/post-deployment-checks.sh production

# Send deployment notification
echo "📢 Sending deployment notification..."
./scripts/notify-deployment.sh production

echo "🎉 Production deployment completed successfully!"
```

### Blue-Green Deployment
```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

CURRENT_ENV=$(firebase hosting:channel:list --json | jq -r '.[] | select(.name == "live") | .name')
NEW_ENV="green"

if [ "$CURRENT_ENV" = "green" ]; then
    NEW_ENV="blue"
fi

echo "🔄 Deploying to $NEW_ENV environment..."

# Deploy to new environment
firebase hosting:channel:deploy $NEW_ENV --expires 1h

# Run health checks
echo "🏥 Running health checks..."
./scripts/health-check.sh $NEW_ENV

# Switch traffic
echo "🔀 Switching traffic to $NEW_ENV..."
firebase hosting:channel:deploy $NEW_ENV --only hosting

# Monitor for issues
echo "👀 Monitoring for issues..."
sleep 300 # Wait 5 minutes

# Verify deployment success
if ./scripts/verify-deployment.sh $NEW_ENV; then
    echo "✅ Deployment successful!"
    # Clean up old environment
    firebase hosting:channel:delete $CURRENT_ENV
else
    echo "❌ Deployment failed, rolling back..."
    firebase hosting:channel:deploy $CURRENT_ENV --only hosting
    exit 1
fi
```

---

## Monitoring and Logging

### Application Monitoring
```dart
// lib/services/monitoring_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

class MonitoringService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static final FirebasePerformance _performance = FirebasePerformance.instance;
  
  static Future<void> initialize() async {
    // Set up crash reporting
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    
    // Set up performance monitoring
    await _performance.setPerformanceCollectionEnabled(true);
    
    // Set up analytics
    await _analytics.setAnalyticsCollectionEnabled(true);
  }
  
  static Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
  
  static Future<void> logError(dynamic error, StackTrace? stackTrace) async {
    await _crashlytics.recordError(error, stackTrace);
  }
  
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }
  
  static Trace startTrace(String name) {
    return _performance.newTrace(name);
  }
}
```

### Health Check Endpoints
```javascript
// functions/health.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.healthCheck = functions.https.onRequest(async (req, res) => {
  const checks = {
    timestamp: new Date().toISOString(),
    status: 'healthy',
    checks: {}
  };
  
  try {
    // Check Firestore connectivity
    await admin.firestore().collection('health').doc('test').get();
    checks.checks.firestore = 'healthy';
  } catch (error) {
    checks.checks.firestore = 'unhealthy';
    checks.status = 'unhealthy';
  }
  
  try {
    // Check Authentication
    await admin.auth().listUsers(1);
    checks.checks.auth = 'healthy';
  } catch (error) {
    checks.checks.auth = 'unhealthy';
    checks.status = 'unhealthy';
  }
  
  try {
    // Check Storage
    await admin.storage().bucket().getFiles({ maxResults: 1 });
    checks.checks.storage = 'healthy';
  } catch (error) {
    checks.checks.storage = 'unhealthy';
    checks.status = 'unhealthy';
  }
  
  const statusCode = checks.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(checks);
});
```

### Logging Configuration
```yaml
# logging.yaml
version: 1
formatters:
  default:
    format: '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
handlers:
  console:
    class: logging.StreamHandler
    level: INFO
    formatter: default
    stream: ext://sys.stdout
  file:
    class: logging.handlers.RotatingFileHandler
    level: DEBUG
    formatter: default
    filename: logs/app.log
    maxBytes: 10485760  # 10MB
    backupCount: 5
loggers:
  '':
    level: DEBUG
    handlers: [console, file]
    propagate: no
```

---

## Backup and Recovery

### Database Backup Strategy
```bash
#!/bin/bash
# scripts/backup.sh

ENVIRONMENT=${1:-production}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/$ENVIRONMENT/$TIMESTAMP"

echo "💾 Creating backup for $ENVIRONMENT environment..."

# Create backup directory
mkdir -p $BACKUP_DIR

# Export Firestore data
echo "📄 Backing up Firestore data..."
gcloud firestore export gs://campus-lf-$ENVIRONMENT-backups/firestore/$TIMESTAMP \
  --project=campus-lf-$ENVIRONMENT

# Backup Firebase Storage
echo "🗂️ Backing up Firebase Storage..."
gsutil -m cp -r gs://campus-lf-$ENVIRONMENT.appspot.com \
  gs://campus-lf-$ENVIRONMENT-backups/storage/$TIMESTAMP/

# Backup configuration
echo "⚙️ Backing up configuration..."
firebase functions:config:get > $BACKUP_DIR/functions-config.json
cp firestore.rules $BACKUP_DIR/
cp storage.rules $BACKUP_DIR/

# Create backup manifest
echo "📋 Creating backup manifest..."
cat > $BACKUP_DIR/manifest.json << EOF
{
  "timestamp": "$TIMESTAMP",
  "environment": "$ENVIRONMENT",
  "version": "$(git rev-parse HEAD)",
  "components": [
    "firestore",
    "storage",
    "functions-config",
    "security-rules"
  ]
}
EOF

echo "✅ Backup completed: $BACKUP_DIR"
```

### Disaster Recovery Plan
```bash
#!/bin/bash
# scripts/disaster-recovery.sh

BACKUP_TIMESTAMP=${1}
ENVIRONMENT=${2:-production}

if [ -z "$BACKUP_TIMESTAMP" ]; then
    echo "❌ Please provide backup timestamp"
    echo "Usage: $0 <backup_timestamp> [environment]"
    exit 1
fi

echo "🚨 Starting disaster recovery for $ENVIRONMENT..."
echo "📅 Using backup from: $BACKUP_TIMESTAMP"

# Confirm recovery
read -p "⚠️ This will overwrite current data. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Recovery cancelled"
    exit 1
fi

# Restore Firestore
echo "📄 Restoring Firestore data..."
gcloud firestore import gs://campus-lf-$ENVIRONMENT-backups/firestore/$BACKUP_TIMESTAMP \
  --project=campus-lf-$ENVIRONMENT

# Restore Storage
echo "🗂️ Restoring Firebase Storage..."
gsutil -m cp -r gs://campus-lf-$ENVIRONMENT-backups/storage/$BACKUP_TIMESTAMP/* \
  gs://campus-lf-$ENVIRONMENT.appspot.com/

# Restore configuration
echo "⚙️ Restoring configuration..."
firebase functions:config:set --project=campus-lf-$ENVIRONMENT \
  $(cat backups/$ENVIRONMENT/$BACKUP_TIMESTAMP/functions-config.json | jq -r 'to_entries[] | "\(.key)=\(.value)"')

# Deploy security rules
echo "🔒 Restoring security rules..."
firebase deploy --only firestore:rules,storage --project=campus-lf-$ENVIRONMENT

# Verify recovery
echo "✅ Running post-recovery verification..."
./scripts/health-check.sh $ENVIRONMENT

echo "🎉 Disaster recovery completed!"
```

### Automated Backup Schedule
```yaml
# .github/workflows/backup.yml
name: Automated Backup

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Google Cloud SDK
      uses: google-github-actions/setup-gcloud@v1
      with:
        service_account_key: ${{ secrets.GCP_SA_KEY }}
        project_id: campus-lf-production
        
    - name: Create backup
      run: ./scripts/backup.sh production
      
    - name: Verify backup
      run: ./scripts/verify-backup.sh production
      
    - name: Cleanup old backups
      run: ./scripts/cleanup-backups.sh production 30  # Keep 30 days
```

---

## Maintenance Procedures

### Regular Maintenance Tasks
```bash
#!/bin/bash
# scripts/maintenance.sh

ENVIRONMENT=${1:-production}

echo "🔧 Starting maintenance for $ENVIRONMENT..."

# Update dependencies
echo "📦 Checking for dependency updates..."
flutter pub outdated

# Clean up old data
echo "🧹 Cleaning up old data..."
firebase functions:shell --project=campus-lf-$ENVIRONMENT << EOF
cleanupOldReports()
EOF

# Optimize database
echo "🗄️ Optimizing database..."
# Run database optimization queries

# Update security rules if needed
echo "🔒 Checking security rules..."
firebase deploy --only firestore:rules,storage --project=campus-lf-$ENVIRONMENT

# Generate maintenance report
echo "📊 Generating maintenance report..."
./scripts/generate-maintenance-report.sh $ENVIRONMENT

echo "✅ Maintenance completed!"
```

### Database Maintenance
```javascript
// functions/maintenance.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.scheduledMaintenance = functions.pubsub
  .schedule('0 3 * * 0') // Weekly on Sunday at 3 AM
  .onRun(async (context) => {
    console.log('Starting scheduled maintenance...');
    
    // Clean up expired sessions
    await cleanupExpiredSessions();
    
    // Archive old reports
    await archiveOldReports();
    
    // Optimize indexes
    await optimizeIndexes();
    
    // Generate maintenance report
    await generateMaintenanceReport();
    
    console.log('Scheduled maintenance completed');
  });

async function cleanupExpiredSessions() {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 30); // 30 days ago
  
  const expiredSessions = await admin.firestore()
    .collection('sessions')
    .where('lastActivity', '<', cutoff)
    .get();
  
  const batch = admin.firestore().batch();
  expiredSessions.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`Cleaned up ${expiredSessions.size} expired sessions`);
}

async function archiveOldReports() {
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - 365); // 1 year ago
  
  const oldReports = await admin.firestore()
    .collection('reports')
    .where('timestamp', '<', cutoff)
    .where('status', '!=', 'recovered')
    .get();
  
  const batch = admin.firestore().batch();
  
  // Move to archive collection
  oldReports.docs.forEach(doc => {
    const archiveRef = admin.firestore().collection('archived_reports').doc(doc.id);
    batch.set(archiveRef, { ...doc.data(), archivedAt: new Date() });
    batch.delete(doc.ref);
  });
  
  await batch.commit();
  console.log(`Archived ${oldReports.size} old reports`);
}
```

### Performance Optimization
```bash
#!/bin/bash
# scripts/optimize-performance.sh

ENVIRONMENT=${1:-production}

echo "⚡ Optimizing performance for $ENVIRONMENT..."

# Analyze bundle size
echo "📊 Analyzing bundle size..."
flutter build web --analyze-size

# Optimize images
echo "🖼️ Optimizing images..."
find assets/images -name "*.png" -exec pngquant --force --ext .png {} \;
find assets/images -name "*.jpg" -exec jpegoptim --max=85 {} \;

# Update CDN cache
echo "🌐 Updating CDN cache..."
# Invalidate CDN cache for static assets

# Optimize database queries
echo "🗄️ Optimizing database queries..."
# Run query optimization analysis

# Update performance monitoring
echo "📈 Updating performance monitoring..."
firebase deploy --only functions:performanceMonitoring --project=campus-lf-$ENVIRONMENT

echo "✅ Performance optimization completed!"
```

---

## Rollback Procedures

### Automated Rollback
```bash
#!/bin/bash
# scripts/rollback.sh

ENVIRONMENT=${1:-production}
TARGET_VERSION=${2}

if [ -z "$TARGET_VERSION" ]; then
    echo "❌ Please provide target version"
    echo "Usage: $0 <environment> <target_version>"
    exit 1
fi

echo "🔄 Rolling back $ENVIRONMENT to version $TARGET_VERSION..."

# Confirm rollback
read -p "⚠️ This will rollback to $TARGET_VERSION. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Rollback cancelled"
    exit 1
fi

# Rollback web application
echo "🌐 Rolling back web application..."
firebase hosting:channel:deploy $TARGET_VERSION --project=campus-lf-$ENVIRONMENT

# Rollback Firebase Functions
echo "☁️ Rolling back Firebase Functions..."
git checkout $TARGET_VERSION -- functions/
firebase deploy --only functions --project=campus-lf-$ENVIRONMENT

# Rollback security rules if needed
echo "🔒 Rolling back security rules..."
git checkout $TARGET_VERSION -- firestore.rules storage.rules
firebase deploy --only firestore:rules,storage --project=campus-lf-$ENVIRONMENT

# Verify rollback
echo "✅ Verifying rollback..."
./scripts/health-check.sh $ENVIRONMENT

# Send rollback notification
echo "📢 Sending rollback notification..."
./scripts/notify-rollback.sh $ENVIRONMENT $TARGET_VERSION

echo "🎉 Rollback completed successfully!"
```

### Emergency Rollback
```bash
#!/bin/bash
# scripts/emergency-rollback.sh

ENVIRONMENT=${1:-production}

echo "🚨 EMERGENCY ROLLBACK for $ENVIRONMENT"

# Get last known good version
LAST_GOOD_VERSION=$(git tag --sort=-version:refname | grep "$ENVIRONMENT" | head -1)

if [ -z "$LAST_GOOD_VERSION" ]; then
    echo "❌ No previous version found"
    exit 1
fi

echo "📅 Rolling back to: $LAST_GOOD_VERSION"

# Immediate rollback without confirmation
echo "⚡ Performing immediate rollback..."

# Rollback web app
firebase hosting:channel:deploy $LAST_GOOD_VERSION --project=campus-lf-$ENVIRONMENT

# Rollback functions
git checkout $LAST_GOOD_VERSION -- functions/
firebase deploy --only functions --project=campus-lf-$ENVIRONMENT

# Send emergency notification
./scripts/notify-emergency.sh $ENVIRONMENT $LAST_GOOD_VERSION

echo "🎉 Emergency rollback completed!"
```

---

## Security Hardening

### Production Security Checklist
- [ ] **Network Security**
  - [ ] HTTPS enforced
  - [ ] Security headers configured
  - [ ] CORS properly configured
  - [ ] Rate limiting enabled

- [ ] **Authentication & Authorization**
  - [ ] Strong password policies
  - [ ] Multi-factor authentication
  - [ ] Session management secure
  - [ ] Role-based access control

- [ ] **Data Protection**
  - [ ] Data encryption at rest
  - [ ] Data encryption in transit
  - [ ] Secure key management
  - [ ] Data backup encrypted

- [ ] **Application Security**
  - [ ] Input validation enabled
  - [ ] XSS protection active
  - [ ] SQL injection prevention
  - [ ] Security scanning automated

### Security Configuration
```javascript
// functions/security.js
const functions = require('firebase-functions');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');

// Rate limiting middleware
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP',
});

// Security headers middleware
const securityHeaders = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "https:"],
      scriptSrc: ["'self'"],
      connectSrc: ["'self'", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
});

exports.secureApi = functions.https.onRequest((req, res) => {
  // Apply security middleware
  limiter(req, res, () => {
    securityHeaders(req, res, () => {
      // API logic here
      res.json({ message: 'Secure API endpoint' });
    });
  });
});
```

---

## Troubleshooting

### Common Deployment Issues

#### Build Failures
```bash
# Issue: Flutter build fails
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter build <platform> --verbose

# Issue: Dependency conflicts
# Solution: Update dependencies
flutter pub upgrade
flutter pub deps
```

#### Firebase Deployment Issues
```bash
# Issue: Firebase deployment fails
# Solution: Check authentication and project
firebase login
firebase projects:list
firebase use <project-id>

# Issue: Security rules deployment fails
# Solution: Validate rules syntax
firebase firestore:rules:get
firebase firestore:rules:test
```

#### Performance Issues
```bash
# Issue: Slow app startup
# Solution: Analyze and optimize
flutter build web --analyze-size
flutter build apk --analyze-size

# Issue: Memory leaks
# Solution: Profile memory usage
flutter run --profile
# Use DevTools to analyze memory
```

### Debugging Tools
```dart
// lib/utils/debug_utils.dart
class DebugUtils {
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  static void logDebug(String message) {
    if (isDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    print('[ERROR] $message');
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
  
  static void logPerformance(String operation, Duration duration) {
    if (isDebugMode) {
      print('[PERF] $operation took ${duration.inMilliseconds}ms');
    }
  }
}
```

### Log Analysis
```bash
#!/bin/bash
# scripts/analyze-logs.sh

ENVIRONMENT=${1:-production}
TIME_RANGE=${2:-1h}

echo "📊 Analyzing logs for $ENVIRONMENT (last $TIME_RANGE)..."

# Analyze Firebase Functions logs
firebase functions:log --project=campus-lf-$ENVIRONMENT --limit=1000

# Analyze error patterns
echo "🔍 Error patterns:"
firebase functions:log --project=campus-lf-$ENVIRONMENT | grep -i error | sort | uniq -c | sort -nr

# Analyze performance metrics
echo "⚡ Performance metrics:"
firebase functions:log --project=campus-lf-$ENVIRONMENT | grep -i "execution took" | awk '{print $NF}' | sort -n

# Generate summary report
echo "📋 Generating summary report..."
./scripts/generate-log-report.sh $ENVIRONMENT $TIME_RANGE
```

---

*This deployment guide provides comprehensive procedures for deploying, maintaining, and troubleshooting the Campus Lost & Found application across all environments and platforms.*

**Last Updated**: January 2024  
**Version**: 1.0  
**Next Review**: April 2024