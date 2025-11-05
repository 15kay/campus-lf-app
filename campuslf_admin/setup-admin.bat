@echo off
echo ========================================
echo WSU Lost & Found Admin Panel Setup
echo ========================================
echo.

echo Step 1: Installing Flutter dependencies...
flutter pub get

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Step 2: Checking Flutter configuration...
flutter doctor

echo.
echo Step 3: Building for web (development)...
flutter build web --debug

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to build web version
    pause
    exit /b 1
)

echo.
echo ========================================
echo Setup completed successfully!
echo ========================================
echo.
echo Next steps:
echo 1. Configure Firebase settings in firebase_options.dart
echo 2. Set up admin authentication in Firebase Console
echo 3. Deploy using: firebase deploy --only hosting
echo.
echo To run locally: flutter run -d chrome
echo To build for production: flutter build web --release
echo.
pause