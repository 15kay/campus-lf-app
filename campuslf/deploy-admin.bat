@echo off
echo Deploying Admin Web App to Firebase...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Firebase CLI...
    npm install -g firebase-tools
)

REM Login to Firebase (if not already logged in)
echo Logging in to Firebase...
firebase login

REM Initialize Firebase project (if not already initialized)
if not exist .firebaserc (
    echo Initializing Firebase project...
    firebase init hosting
)

REM Deploy to Firebase Hosting
echo Deploying to Firebase Hosting...
firebase deploy --only hosting

echo.
echo Admin web app deployed successfully!
echo Visit your Firebase console to get the hosting URL.
pause