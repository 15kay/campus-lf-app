# 🚀 Deployment Guide

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Firebase Configuration](#firebase-configuration)
- [Development Deployment](#development-deployment)
- [Production Deployment](#production-deployment)
- [Platform-Specific Deployment](#platform-specific-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Maintenance](#monitoring--maintenance)
- [Troubleshooting](#troubleshooting)

## Overview

This guide covers the complete deployment process for the Campus Lost & Found application across all supported platforms: Web, Android, iOS, Windows, macOS, and Linux.

### Deployment Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Development   │    │     Staging     │    │   Production    │
│   Environment   │───▶│   Environment   │───▶│   Environment   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Firebase Dev    │    │ Firebase Stage  │    │ Firebase Prod   │
│ Project         │    │ Project         │    │ Project         │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Prerequisites

### System Requirements

#### **Development Machine**
- **OS**: Windows 10+, macOS 10.14+, or Ubuntu 18.04+
- **RAM**: Minimum 8GB, Recommended 16GB
- **Storage**: 10GB free space
- **Internet**: Stable broadband connection

#### **Software Dependencies**
- **Flutter SDK**: 3.16.0 or later
- **Dart SDK**: 3.2.0 or later
- **Git**: Latest version
- **Node.js**: 18.0.0 or later (for Firebase CLI)
- **Firebase CLI**: Latest version

#### **Platform-Specific Requirements**

**Android Development:**
- Android Studio 2022.3.1 or later
- Android SDK 33 or later
- Java JDK 11 or later

**iOS Development:**
- Xcode 15.0 or later
- iOS 12.0+ deployment target
- Apple Developer Account (for distribution)

**Web Development:**
- Modern web browser
- Web server (for hosting)

**Desktop Development:**
- Visual Studio 2022 (Windows)
- Xcode Command Line Tools (macOS)
- Build essentials (Linux)

### Account Requirements

- **Firebase Account**: Google account with Firebase access
- **Google Play Console**: For Android app distribution
- **Apple Developer Account**: For iOS app distribution
- **Domain & Hosting**: For web deployment

## Environment Setup

### 1. Install Flutter

#### **Windows**
```powershell
# Download Flutter SDK
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip" -OutFile "flutter.zip"

# Extract to C:\flutter
Expand-Archive -Path "flutter.zip" -DestinationPath "C:\"

# Add to PATH
$env:PATH += ";C:\flutter\bin"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, [EnvironmentVariableTarget]::User)

# Verify installation
flutter doctor
```

#### **macOS**
```bash
# Using Homebrew
brew install flutter

# Or download manually
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.16.0-stable.zip
unzip flutter_macos_3.16.0-stable.zip
sudo mv flutter /usr/local/

# Add to PATH
echo 'export PATH="$PATH:/usr/local/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify installation
flutter doctor
```

#### **Linux**
```bash
# Download Flutter
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz

# Extract
tar xf flutter_linux_3.16.0-stable.tar.xz
sudo mv flutter /opt/

# Add to PATH
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter doctor
```

### 2. Install Firebase CLI

```bash
# Install via npm
npm install -g firebase-tools

# Login to Firebase
firebase login

# Verify installation
firebase --version
```

### 3. Configure Development Environment

```bash
# Clone the repository
git clone https://github.com/your-org/campus_lf_app.git
cd campus_lf_app

# Install dependencies
flutter pub get

# Run Flutter doctor to check setup
flutter doctor

# Enable required platforms
flutter config --enable-web
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

## Firebase Configuration

### 1. Create Firebase Projects

#### **Development Project**
```bash
# Create new Firebase project
firebase projects:create campus-lf-dev --display-name "Campus L&F Development"

# Set as default project
firebase use campus-lf-dev
```

#### **Production Project**
```bash
# Create production project
firebase projects:create campus-lf-prod --display-name "Campus L&F Production"
```

### 2. Configure Firebase Services

#### **Authentication Setup**
```bash
# Enable Authentication
firebase auth:enable

# Configure sign-in methods
firebase auth:config --enable-email-password
firebase auth:config --enable-google
```

#### **Firestore Setup**
```bash
# Initialize Firestore
firebase firestore:init

# Deploy security rules
firebase deploy --only firestore:rules

# Deploy indexes
firebase deploy --only firestore:indexes
```

#### **Storage Setup**
```bash
# Initialize Storage
firebase storage:init

# Deploy storage rules
firebase deploy --only storage
```

#### **Hosting Setup**
```bash
# Initialize hosting
firebase hosting:init

# Configure hosting
# Select build/web as public directory
# Configure as single-page app: Yes
# Set up automatic builds: No (for now)
```

### 3. Generate Configuration Files

#### **Android Configuration**
```bash
# Download google-services.json
firebase apps:sdkconfig android --out android/app/google-services.json

# Verify file placement
ls android/app/google-services.json
```

#### **iOS Configuration**
```bash
# Download GoogleService-Info.plist
firebase apps:sdkconfig ios --out ios/Runner/GoogleService-Info.plist

# Add to Xcode project manually
```

#### **Web Configuration**
```bash
# Generate web config
firebase apps:sdkconfig web --out web/firebase-config.js

# Update index.html with config
```

### 4. Environment Configuration

Create environment-specific configuration files:

#### **Development Environment**
```dart
// lib/config/dev_config.dart
class DevConfig {
  static const String environment = 'development';
  static const String apiUrl = 'https://campus-lf-dev.firebaseapp.com';
  static const bool enableLogging = true;
  static const bool enableAnalytics = false;
  
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: 'your-dev-api-key',
    authDomain: 'campus-lf-dev.firebaseapp.com',
    projectId: 'campus-lf-dev',
    storageBucket: 'campus-lf-dev.appspot.com',
    messagingSenderId: 'your-sender-id',
    appId: 'your-dev-app-id',
  );
}
```

#### **Production Environment**
```dart
// lib/config/prod_config.dart
class ProdConfig {
  static const String environment = 'production';
  static const String apiUrl = 'https://campus-lf-prod.firebaseapp.com';
  static const bool enableLogging = false;
  static const bool enableAnalytics = true;
  
  static const FirebaseOptions firebaseOptions = FirebaseOptions(
    apiKey: 'your-prod-api-key',
    authDomain: 'campus-lf-prod.firebaseapp.com',
    projectId: 'campus-lf-prod',
    storageBucket: 'campus-lf-prod.appspot.com',
    messagingSenderId: 'your-sender-id',
    appId: 'your-prod-app-id',
  );
}
```

## Development Deployment

### 1. Local Development Server

```bash
# Start development server
flutter run -d chrome --web-port 3000

# Or for specific platform
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### 2. Development Web Deployment

```bash
# Build for web
flutter build web --dart-define=ENVIRONMENT=development

# Deploy to Firebase Hosting
firebase deploy --only hosting --project campus-lf-dev

# Access at: https://campus-lf-dev.web.app
```

### 3. Development Mobile Testing

#### **Android Debug Build**
```bash
# Build debug APK
flutter build apk --debug --dart-define=ENVIRONMENT=development

# Install on device
flutter install

# Or build and install in one step
flutter run --dart-define=ENVIRONMENT=development
```

#### **iOS Debug Build**
```bash
# Build for iOS simulator
flutter build ios --debug --dart-define=ENVIRONMENT=development --simulator

# Build for device
flutter build ios --debug --dart-define=ENVIRONMENT=development
```

## Production Deployment

### 1. Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Code review completed
- [ ] Security audit completed
- [ ] Performance testing completed
- [ ] Firebase security rules reviewed
- [ ] Environment variables configured
- [ ] SSL certificates valid
- [ ] Backup procedures in place

### 2. Production Build Configuration

#### **Update Version Numbers**
```yaml
# pubspec.yaml
version: 1.0.0+1  # Update version and build number
```

#### **Configure Release Settings**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with production config
  await Firebase.initializeApp(
    options: ProdConfig.firebaseOptions,
  );
  
  // Disable debug features in production
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  
  runApp(MyApp());
}
```

### 3. Web Production Deployment

#### **Build for Production**
```bash
# Clean previous builds
flutter clean
flutter pub get

# Build optimized web version
flutter build web \
  --release \
  --dart-define=ENVIRONMENT=production \
  --web-renderer canvaskit \
  --base-href /

# Optimize build
cd build/web
# Compress assets
gzip -9 -k *.js *.css *.html
```

#### **Deploy to Firebase Hosting**
```bash
# Switch to production project
firebase use campus-lf-prod

# Deploy to hosting
firebase deploy --only hosting

# Verify deployment
firebase hosting:sites:list
```

#### **Custom Domain Setup**
```bash
# Add custom domain
firebase hosting:sites:create your-domain.com

# Configure DNS
# Add A records pointing to Firebase hosting IPs
# Add TXT record for domain verification

# Connect domain
firebase hosting:sites:update your-domain.com --add-domain your-domain.com
```

### 4. Android Production Deployment

#### **Generate Signing Key**
```bash
# Create keystore
keytool -genkey -v -keystore ~/campus-lf-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias campus-lf

# Create key.properties
echo "storePassword=your-store-password" > android/key.properties
echo "keyPassword=your-key-password" >> android/key.properties
echo "keyAlias=campus-lf" >> android/key.properties
echo "storeFile=../campus-lf-key.jks" >> android/key.properties
```

#### **Configure Gradle for Release**
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
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

#### **Build Release APK/AAB**
```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle \
  --release \
  --dart-define=ENVIRONMENT=production \
  --obfuscate \
  --split-debug-info=build/debug-info

# Or build APK
flutter build apk \
  --release \
  --dart-define=ENVIRONMENT=production \
  --split-per-abi
```

#### **Upload to Google Play Console**
1. Login to Google Play Console
2. Create new app or select existing
3. Upload AAB file to Internal Testing
4. Complete store listing
5. Submit for review
6. Promote to Production after approval

### 5. iOS Production Deployment

#### **Configure Xcode Project**
```bash
# Open iOS project
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select Runner target
# 2. Update Bundle Identifier
# 3. Set Team and Provisioning Profile
# 4. Configure App Store Connect
```

#### **Build for App Store**
```bash
# Build iOS release
flutter build ios \
  --release \
  --dart-define=ENVIRONMENT=production \
  --obfuscate \
  --split-debug-info=build/debug-info

# Archive in Xcode
# Product > Archive
# Upload to App Store Connect
```

#### **App Store Submission**
1. Complete app metadata in App Store Connect
2. Upload screenshots and app preview
3. Set pricing and availability
4. Submit for review
5. Release after approval

### 6. Desktop Production Deployment

#### **Windows**
```bash
# Build Windows executable
flutter build windows --release --dart-define=ENVIRONMENT=production

# Create installer using Inno Setup or similar
# Package with dependencies
```

#### **macOS**
```bash
# Build macOS app
flutter build macos --release --dart-define=ENVIRONMENT=production

# Code sign and notarize
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" build/macos/Build/Products/Release/campus_lf_app.app

# Create DMG installer
hdiutil create -volname "Campus L&F" -srcfolder build/macos/Build/Products/Release/campus_lf_app.app -ov -format UDZO campus_lf_installer.dmg
```

#### **Linux**
```bash
# Build Linux executable
flutter build linux --release --dart-define=ENVIRONMENT=production

# Create AppImage or Snap package
# Package with dependencies
```

## Platform-Specific Deployment

### Web Deployment Options

#### **Firebase Hosting (Recommended)**
```bash
# Configure firebase.json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [{
      "source": "**",
      "destination": "/index.html"
    }],
    "headers": [{
      "source": "**/*.@(js|css)",
      "headers": [{
        "key": "Cache-Control",
        "value": "max-age=31536000"
      }]
    }]
  }
}

# Deploy
firebase deploy --only hosting
```

#### **Netlify Deployment**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Build and deploy
flutter build web --release
netlify deploy --prod --dir=build/web
```

#### **Vercel Deployment**
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
flutter build web --release
vercel --prod build/web
```

### Mobile App Store Deployment

#### **Google Play Store Process**
1. **Prepare Release**
   - Update version numbers
   - Generate signed AAB
   - Test thoroughly

2. **Store Listing**
   - App title and description
   - Screenshots (phone, tablet, TV)
   - Feature graphic
   - Privacy policy URL

3. **Release Management**
   - Internal testing → Closed testing → Open testing → Production
   - Staged rollout (recommended)
   - Monitor crash reports

#### **Apple App Store Process**
1. **Prepare Release**
   - Update version numbers
   - Archive and upload
   - Test with TestFlight

2. **App Store Connect**
   - App metadata
   - Screenshots for all device sizes
   - App preview videos
   - Privacy information

3. **Review Process**
   - Submit for review
   - Respond to reviewer feedback
   - Release manually or automatically

### Desktop Distribution

#### **Windows Distribution**
- **Microsoft Store**: Package as MSIX
- **Direct Download**: Installer with auto-updater
- **Chocolatey**: Package manager distribution

#### **macOS Distribution**
- **Mac App Store**: Sandbox requirements
- **Direct Download**: Notarized DMG
- **Homebrew**: Package manager distribution

#### **Linux Distribution**
- **Snap Store**: Universal packages
- **AppImage**: Portable applications
- **Flatpak**: Sandboxed applications
- **Distribution repositories**: DEB, RPM packages

## CI/CD Pipeline

### GitHub Actions Workflow

```yaml
# .github/workflows/deploy.yml
name: Deploy Campus L&F

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze

  build-web:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build web --release --dart-define=ENVIRONMENT=production
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: campus-lf-prod

  build-android:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '11'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: echo '${{ secrets.KEYSTORE_BASE64 }}' | base64 -d > android/app/keystore.jks
      - run: echo '${{ secrets.KEY_PROPERTIES }}' > android/key.properties
      - run: flutter build appbundle --release --dart-define=ENVIRONMENT=production
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.campus.lostfound
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal

  build-ios:
    needs: test
    runs-on: macos-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build ios --release --dart-define=ENVIRONMENT=production --no-codesign
      - uses: apple-actions/import-codesign-certs@v1
        with:
          p12-file-base64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
          p12-password: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
      - uses: apple-actions/download-provisioning-profiles@v1
        with:
          bundle-id: com.campus.lostfound
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
      - run: xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/Runner.xcarchive
      - run: xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportOptionsPlist ios/ExportOptions.plist -exportPath build/
      - uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: build/Runner.ipa
          issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
          api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

### Environment Secrets

Configure the following secrets in your CI/CD platform:

```bash
# Firebase
FIREBASE_SERVICE_ACCOUNT=<service-account-json>

# Android
KEYSTORE_BASE64=<base64-encoded-keystore>
KEY_PROPERTIES=<key-properties-content>
GOOGLE_PLAY_SERVICE_ACCOUNT=<service-account-json>

# iOS
IOS_CERTIFICATE_BASE64=<base64-encoded-p12>
IOS_CERTIFICATE_PASSWORD=<certificate-password>
APPSTORE_ISSUER_ID=<app-store-connect-issuer-id>
APPSTORE_KEY_ID=<app-store-connect-key-id>
APPSTORE_PRIVATE_KEY=<app-store-connect-private-key>
```

## Monitoring & Maintenance

### Application Monitoring

#### **Firebase Analytics**
```dart
// Track app usage
await FirebaseAnalytics.instance.logEvent(
  name: 'report_created',
  parameters: {
    'item_category': category,
    'report_type': type,
  },
);
```

#### **Crashlytics Setup**
```dart
// Initialize Crashlytics
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

// Log custom errors
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Custom error description',
);
```

#### **Performance Monitoring**
```dart
// Track custom traces
final trace = FirebasePerformance.instance.newTrace('report_creation');
await trace.start();
// ... perform operation
await trace.stop();
```

### Health Checks

#### **Application Health Endpoint**
```dart
// lib/services/health_service.dart
class HealthService {
  static Future<Map<String, dynamic>> getHealthStatus() async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': await _getAppVersion(),
      'firebase': await _checkFirebaseConnection(),
      'storage': await _checkStorageAccess(),
    };
  }
}
```

#### **Monitoring Dashboard**
Set up monitoring dashboards for:
- Application uptime
- Response times
- Error rates
- User engagement metrics
- Resource usage

### Backup Procedures

#### **Firestore Backup**
```bash
# Schedule daily backups
gcloud firestore export gs://campus-lf-backups/$(date +%Y-%m-%d) --project=campus-lf-prod

# Restore from backup
gcloud firestore import gs://campus-lf-backups/2024-01-15 --project=campus-lf-prod
```

#### **Storage Backup**
```bash
# Backup Firebase Storage
gsutil -m cp -r gs://campus-lf-prod.appspot.com gs://campus-lf-backups/storage/$(date +%Y-%m-%d)
```

### Update Procedures

#### **Application Updates**
1. **Prepare Update**
   - Test thoroughly in staging
   - Prepare rollback plan
   - Update documentation

2. **Deploy Update**
   - Deploy to staging first
   - Gradual rollout to production
   - Monitor for issues

3. **Post-Deployment**
   - Verify functionality
   - Monitor error rates
   - Gather user feedback

#### **Dependency Updates**
```bash
# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Test after updates
flutter test
flutter analyze
```

## Troubleshooting

### Common Deployment Issues

#### **Build Failures**

**Flutter Build Errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub deps
flutter build <platform>
```

**Gradle Build Errors (Android):**
```bash
# Clean Gradle cache
cd android
./gradlew clean
./gradlew build --refresh-dependencies
```

**Xcode Build Errors (iOS):**
```bash
# Clean Xcode build
cd ios
rm -rf build/
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
```

#### **Firebase Connection Issues**

**Configuration Problems:**
1. Verify Firebase project settings
2. Check API keys and project IDs
3. Ensure services are enabled
4. Validate security rules

**Authentication Issues:**
```bash
# Re-authenticate Firebase CLI
firebase logout
firebase login

# Check project access
firebase projects:list
```

#### **Platform-Specific Issues**

**Web Deployment:**
- Check CORS settings
- Verify hosting configuration
- Test in different browsers
- Check console for JavaScript errors

**Mobile Deployment:**
- Verify signing certificates
- Check app permissions
- Test on different devices
- Validate store metadata

**Desktop Deployment:**
- Check platform dependencies
- Verify code signing
- Test on target OS versions
- Validate installer packages

### Performance Issues

#### **Build Performance**
```bash
# Enable build caching
flutter config --enable-web
flutter config --build-dir=build

# Use build cache
flutter build web --dart-define=FLUTTER_WEB_USE_SKIA=true
```

#### **Runtime Performance**
- Monitor app performance metrics
- Optimize image sizes and formats
- Implement lazy loading
- Use efficient data structures
- Profile memory usage

### Security Considerations

#### **API Security**
- Implement proper authentication
- Use HTTPS everywhere
- Validate all inputs
- Implement rate limiting
- Monitor for suspicious activity

#### **Data Protection**
- Encrypt sensitive data
- Implement proper access controls
- Regular security audits
- Backup encryption
- Compliance with privacy regulations

---

## Support & Resources

### Documentation
- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

### Community Support
- [Flutter Community](https://flutter.dev/community)
- [Firebase Community](https://firebase.google.com/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

### Emergency Contacts
- **DevOps Team**: devops@campus.edu
- **Firebase Support**: Firebase Console → Support
- **Platform Support**: Respective platform support channels

---

*This deployment guide is maintained by the development team and updated regularly. For the latest version, check the project repository.*