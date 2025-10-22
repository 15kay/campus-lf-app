# 🔧 Build Android App Instructions

## Problem: Gradle Cache Corruption
The build fails due to corrupted Gradle cache files. Here's how to fix it:

## Solution Steps:

### 1. Clear All Gradle Caches
```powershell
# Stop any running Gradle processes
taskkill /f /im java.exe 2>$null

# Remove entire Gradle cache directory
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle" -ErrorAction SilentlyContinue

# Clean Flutter project
flutter clean

# Remove Android build directory
Remove-Item -Recurse -Force "android\build" -ErrorAction SilentlyContinue
```

### 2. Rebuild Dependencies
```powershell
# Get Flutter dependencies
flutter pub get

# Build debug APK
flutter build apk --debug
```

### 3. If Still Failing - Alternative Method
```powershell
# Try building with verbose output
flutter build apk --debug --verbose

# Or try release build (requires keystore)
flutter build apk --release
```

## 📱 APK Location
Once built successfully, find your APK at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

## 🚀 Install APK
1. Copy APK to your Android device
2. Enable "Install from unknown sources" in Settings
3. Tap the APK file to install

## ⚠️ Note
If build issues persist, the web app version works identically to the native app and can be "installed" from the browser.

## 🌐 Web App Alternative
Visit: https://campus-lf-app.web.app/
- Add to home screen for app-like experience
- Works offline
- All features available