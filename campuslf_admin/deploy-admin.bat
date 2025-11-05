@echo off
echo Building WSU Admin Panel for Web...

REM Clean previous build
if exist build\web rmdir /s /q build\web

REM Build for web
flutter build web --release --web-renderer html

REM Check if build was successful
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Build completed successfully!
echo.
echo To deploy to Firebase Hosting:
echo 1. Make sure you're logged in: firebase login
echo 2. Deploy: firebase deploy --only hosting
echo.
echo To serve locally:
echo firebase serve --only hosting
echo.
pause