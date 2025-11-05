@echo off
echo Starting deployment process...

REM --- Build User App ---
echo Building user application...
cd /d "f:\Cam\campuslf"
call flutter build web
if %errorlevel% neq 0 (
    echo User application build failed.
    exit /b %errorlevel%
)

REM --- Build Admin App ---
echo Building admin application...
cd /d "f:\Cam\campuslf_admin"
call flutter build web
if %errorlevel% neq 0 (
    echo Admin application build failed.
    exit /b %errorlevel%
)

REM --- Deploy to Firebase ---
echo Deploying to Firebase...
cd /d "f:\Cam\campuslf"

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Firebase CLI not found. Please install it using: npm install -g firebase-tools
    exit /b %errorlevel%
)

REM Login to Firebase
firebase login

REM Deploy both hosting targets
firebase deploy --only hosting

echo.
echo Deployment complete!
pause