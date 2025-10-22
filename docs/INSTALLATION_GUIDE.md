# Campus Lost & Found - Installation Guide

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Environment Setup](#development-environment-setup)
3. [Project Setup](#project-setup)
4. [Firebase Configuration](#firebase-configuration)
5. [Platform-Specific Setup](#platform-specific-setup)
6. [Running the Application](#running-the-application)
7. [Troubleshooting](#troubleshooting)
8. [Production Deployment](#production-deployment)

---

## 🔧 Prerequisites

### System Requirements

#### Minimum Requirements
```yaml
Operating System:
  - Windows 10 (64-bit) or later
  - macOS 10.14 (Mojave) or later
  - Ubuntu 18.04 LTS or later

Hardware:
  - RAM: 8GB minimum, 16GB recommended
  - Storage: 10GB free space
  - Processor: Intel i5 or AMD equivalent
  - Internet: Stable broadband connection
```

#### Required Software

##### 1. Flutter SDK
```bash
# Minimum Flutter version: 3.16.0
# Recommended: Latest stable version
```

##### 2. Dart SDK
```bash
# Included with Flutter SDK
# Minimum Dart version: 3.2.0
```

##### 3. Development Tools
```yaml
Required IDEs (choose one):
  - Visual Studio Code (recommended)
  - Android Studio
  - IntelliJ IDEA

Required Extensions/Plugins:
  - Flutter extension
  - Dart extension
  - Firebase extension (optional but recommended)
```

##### 4. Platform-Specific Requirements

**For Android Development:**
```yaml
Android Studio: Latest stable version
Android SDK: API level 21 (Android 5.0) or higher
Java Development Kit: JDK 11 or later
```

**For iOS Development (macOS only):**
```yaml
Xcode: 14.0 or later
iOS SDK: iOS 12.0 or later
CocoaPods: Latest version
```

**For Web Development:**
```yaml
Chrome Browser: Latest version (for debugging)
Web Server: Any HTTP server for deployment
```

**For Desktop Development:**
```yaml
Windows: Visual Studio 2019 or later
macOS: Xcode command line tools
Linux: GTK development libraries
```

---

## 🛠️ Development Environment Setup

### Step 1: Install Flutter SDK

#### Windows Installation
```powershell
# Method 1: Using Git
git clone https://github.com/flutter/flutter.git -b stable
# Add Flutter to PATH: C:\path\to\flutter\bin

# Method 2: Download ZIP
# Download from https://flutter.dev/docs/get-started/install/windows
# Extract and add to PATH

# Verify installation
flutter doctor
```

#### macOS Installation
```bash
# Method 1: Using Git
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Method 2: Using Homebrew
brew install flutter

# Verify installation
flutter doctor
```

#### Linux Installation
```bash
# Download Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz

# Add to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### Step 2: Configure Development Environment

#### Visual Studio Code Setup
```json
// .vscode/settings.json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

#### Required VS Code Extensions
```bash
# Install Flutter extension
code --install-extension Dart-Code.flutter

# Install additional helpful extensions
code --install-extension Dart-Code.dart-code
code --install-extension ms-vscode.vscode-json
code --install-extension bradlc.vscode-tailwindcss
```

### Step 3: Platform Setup

#### Android Setup
```bash
# Install Android Studio
# Download from: https://developer.android.com/studio

# Accept Android licenses
flutter doctor --android-licenses

# Create Android Virtual Device (AVD)
# Open Android Studio > AVD Manager > Create Virtual Device
```

#### iOS Setup (macOS only)
```bash
# Install Xcode from App Store
# Install Xcode command line tools
sudo xcode-select --install

# Install CocoaPods
sudo gem install cocoapods

# Setup iOS Simulator
open -a Simulator
```

#### Web Setup
```bash
# Enable web support
flutter config --enable-web

# Install Chrome for debugging
# Chrome should be in PATH for flutter web debugging
```

---

## 📦 Project Setup

### Step 1: Clone Repository
```bash
# Clone the project repository
git clone https://github.com/your-org/campus_lf_app.git
cd campus_lf_app

# Or download and extract ZIP file
```

### Step 2: Install Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# For iOS (macOS only)
cd ios && pod install && cd ..

# Verify installation
flutter doctor
flutter pub deps
```

### Step 3: Project Structure Verification
```
campus_lf_app/
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── lib/                     # Dart source code
│   ├── main.dart           # Application entry point
│   ├── app.dart            # Main app configuration
│   ├── models/             # Data models
│   ├── pages/              # UI pages/screens
│   ├── services/           # Business logic services
│   └── widgets/            # Reusable UI components
├── web/                     # Web-specific files
├── test/                    # Test files
├── docs/                    # Documentation
├── pubspec.yaml            # Dependencies configuration
└── README.md               # Project overview
```

---

## 🔥 Firebase Configuration

### Step 1: Create Firebase Project

#### Firebase Console Setup
```bash
# 1. Go to https://console.firebase.google.com/
# 2. Click "Create a project"
# 3. Enter project name: "campus-lost-found"
# 4. Enable Google Analytics (optional)
# 5. Create project
```

#### Enable Required Services
```yaml
Required Firebase Services:
  - Authentication (Email/Password, Google Sign-In)
  - Cloud Firestore (Database)
  - Cloud Storage (File uploads)
  - Cloud Functions (Optional, for advanced features)
  - Firebase Hosting (For web deployment)
```

### Step 2: Install Firebase CLI
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init
```

### Step 3: Configure Firebase for Flutter

#### Install FlutterFire CLI
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure
```

#### Manual Configuration (Alternative)

**Android Configuration:**
```bash
# Download google-services.json from Firebase Console
# Place in: android/app/google-services.json

# Add to android/build.gradle
classpath 'com.google.gms:google-services:4.3.15'

# Add to android/app/build.gradle
apply plugin: 'com.google.gms.google-services'
```

**iOS Configuration:**
```bash
# Download GoogleService-Info.plist from Firebase Console
# Add to ios/Runner/ in Xcode project

# Update ios/Runner/Info.plist with URL schemes
```

**Web Configuration:**
```html
<!-- Add to web/index.html -->
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-firestore.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-auth.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-storage.js"></script>
```

### Step 4: Firebase Security Rules

#### Firestore Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports are readable by authenticated users
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.userId == request.auth.uid);
    }
    
    // Messages are readable by participants
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
  }
}
```

#### Storage Security Rules
```javascript
// storage.rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /reports/{reportId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.auth.uid == resource.metadata.uploadedBy;
    }
    
    match /profiles/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📱 Platform-Specific Setup

### Android Setup

#### Gradle Configuration
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId "com.campus.lostfound"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        multiDexEnabled true
    }
}
```

#### Permissions
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

#### Signing Configuration
```gradle
// android/app/build.gradle
android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### iOS Setup

#### Info.plist Configuration
```xml
<!-- ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos of lost/found items</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to help find nearby lost items</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice calls</string>
```

#### Podfile Configuration
```ruby
# ios/Podfile
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

### Web Setup

#### Index.html Configuration
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <base href="$FLUTTER_BASE_HREF">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Campus Lost & Found Application">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Campus Lost & Found">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <link rel="icon" type="image/png" href="favicon.png"/>
  <title>Campus Lost & Found</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script>
    var serviceWorkerVersion = null;
    var scriptLoaded = false;
    function loadMainDartJs() {
      if (scriptLoaded) {
        return;
      }
      scriptLoaded = true;
      var scriptTag = document.createElement('script');
      scriptTag.src = 'main.dart.js';
      scriptTag.type = 'application/javascript';
      document.body.append(scriptTag);
    }

    if ('serviceWorker' in navigator) {
      window.addEventListener('load', function () {
        navigator.serviceWorker.register('flutter_service_worker.js');
      });
    }
    loadMainDartJs();
  </script>
</body>
</html>
```

#### Web Manifest
```json
{
  "name": "Campus Lost & Found",
  "short_name": "Campus L&F",
  "start_url": ".",
  "display": "standalone",
  "background_color": "#0175C2",
  "theme_color": "#0175C2",
  "description": "Find and report lost items on campus",
  "orientation": "portrait-primary",
  "prefer_related_applications": false,
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

---

## 🚀 Running the Application

### Development Mode

#### Run on Different Platforms
```bash
# Run on Android device/emulator
flutter run -d android

# Run on iOS device/simulator (macOS only)
flutter run -d ios

# Run on web browser
flutter run -d chrome

# Run on desktop (Windows/macOS/Linux)
flutter run -d windows
flutter run -d macos
flutter run -d linux

# List available devices
flutter devices
```

#### Hot Reload and Hot Restart
```bash
# During development, use:
# r - Hot reload (preserves state)
# R - Hot restart (resets state)
# q - Quit
# h - Help
```

#### Debug Mode Features
```bash
# Run with verbose logging
flutter run --verbose

# Run with specific flavor
flutter run --flavor development

# Run with custom entry point
flutter run --target lib/main_dev.dart
```

### Build for Production

#### Android APK/AAB
```bash
# Build APK (for testing)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Build with specific flavor
flutter build apk --flavor production --release
```

#### iOS IPA
```bash
# Build for iOS (requires macOS and Xcode)
flutter build ios --release

# Build for App Store
flutter build ipa --release
```

#### Web Build
```bash
# Build for web
flutter build web --release

# Build with specific base href
flutter build web --base-href /campus-lf/
```

#### Desktop Builds
```bash
# Build for Windows
flutter build windows --release

# Build for macOS
flutter build macos --release

# Build for Linux
flutter build linux --release
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Flutter Doctor Issues
```bash
# Issue: Android licenses not accepted
Solution: flutter doctor --android-licenses

# Issue: Xcode not properly configured
Solution: sudo xcode-select --install

# Issue: CocoaPods not installed
Solution: sudo gem install cocoapods

# Issue: Flutter not in PATH
Solution: Add Flutter bin directory to system PATH
```

#### Build Issues

##### Android Build Errors
```bash
# Issue: Gradle build failed
Solution:
1. cd android && ./gradlew clean
2. flutter clean && flutter pub get
3. flutter build apk

# Issue: Multidex error
Solution: Add multiDexEnabled true in build.gradle

# Issue: Kotlin version conflict
Solution: Update kotlin_version in android/build.gradle
```

##### iOS Build Errors
```bash
# Issue: Pod install failed
Solution:
1. cd ios && rm -rf Pods Podfile.lock
2. pod install
3. flutter clean && flutter pub get

# Issue: Signing certificate issues
Solution: Configure signing in Xcode project settings

# Issue: Simulator not found
Solution: xcrun simctl list devices
```

##### Web Build Errors
```bash
# Issue: CORS errors in development
Solution: Use flutter run -d chrome --web-renderer html

# Issue: Firebase not initialized
Solution: Check firebase_options.dart configuration

# Issue: Service worker caching issues
Solution: Clear browser cache and rebuild
```

#### Runtime Issues

##### Firebase Connection Issues
```dart
// Debug Firebase connection
void debugFirebase() async {
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
}
```

##### Network Issues
```dart
// Check network connectivity
import 'package:connectivity_plus/connectivity_plus.dart';

void checkConnectivity() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    print('No internet connection');
  }
}
```

##### Performance Issues
```bash
# Profile app performance
flutter run --profile

# Analyze app size
flutter build apk --analyze-size

# Check for memory leaks
flutter run --enable-software-rendering
```

### Debug Tools

#### Flutter Inspector
```bash
# Open Flutter Inspector in VS Code
# Ctrl+Shift+P -> "Flutter: Open Flutter Inspector"

# Or in browser
flutter run -d chrome --debug
# Open DevTools in browser
```

#### Logging and Debugging
```dart
// Enable debug logging
import 'dart:developer' as developer;

void debugLog(String message) {
  developer.log(message, name: 'CampusLF');
}

// Firebase debug logging
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

#### Performance Monitoring
```dart
// Add performance monitoring
import 'package:firebase_performance/firebase_performance.dart';

void trackPerformance() async {
  final trace = FirebasePerformance.instance.newTrace('app_startup');
  await trace.start();
  // App initialization code
  await trace.stop();
}
```

---

## 🌐 Production Deployment

### Web Deployment

#### Firebase Hosting
```bash
# Initialize Firebase Hosting
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### Custom Web Server
```bash
# Build for production
flutter build web --release

# Copy build files to web server
cp -r build/web/* /var/www/html/

# Configure web server (nginx example)
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Mobile App Deployment

#### Google Play Store (Android)
```bash
# Build App Bundle
flutter build appbundle --release

# Upload to Google Play Console
# Follow Google Play Store guidelines
```

#### Apple App Store (iOS)
```bash
# Build for App Store
flutter build ipa --release

# Upload using Xcode or Application Loader
# Follow App Store Review Guidelines
```

### Environment Configuration

#### Environment Variables
```dart
// lib/config/environment.dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.campus-lf.com',
  );
  
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
```

#### Build Flavors
```yaml
# pubspec.yaml
flutter:
  flavors:
    development:
      applicationId: com.campus.lostfound.dev
    staging:
      applicationId: com.campus.lostfound.staging
    production:
      applicationId: com.campus.lostfound
```

### Monitoring and Analytics

#### Firebase Analytics
```dart
// Initialize analytics
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

// Track events
await analytics.logEvent(
  name: 'item_reported',
  parameters: {
    'item_type': 'phone',
    'location': 'library',
  },
);
```

#### Crashlytics
```dart
// Initialize Crashlytics
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  
  runApp(MyApp());
}
```

---

## 📚 Additional Resources

### Documentation Links
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)

### Community Resources
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)
- [GitHub - Flutter](https://github.com/flutter/flutter)

### Development Tools
- [Flutter DevTools](https://flutter.dev/docs/development/tools/devtools)
- [VS Code Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Android Studio Flutter Plugin](https://plugins.jetbrains.com/plugin/9212-flutter)

---

## 📞 Support

### Getting Help
- **Documentation Issues**: Check this guide and official Flutter docs
- **Technical Issues**: Create issue on project repository
- **Firebase Issues**: Check Firebase Console and documentation
- **Platform Issues**: Consult platform-specific documentation

### Contact Information
- **Development Team**: dev@campus-lf.com
- **Technical Support**: support@campus-lf.com
- **Project Repository**: https://github.com/your-org/campus_lf_app

---

*Last Updated: January 2025*  
*Version: 1.0.0*  
*Document Status: Complete*