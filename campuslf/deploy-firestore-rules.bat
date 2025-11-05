@echo off
REM Deploy Firestore security rules using Firebase CLI
REM Requirements: Node.js, Firebase CLI installed (npm i -g firebase-tools) and logged in (firebase login)

setlocal

REM Use default project from .firebaserc (wsucampuslf). Override by passing project id as first argument.
set PROJECT=%1
if "%PROJECT%"=="" (
  set PROJECT=wsucampuslf
)

echo Deploying Firestore rules to project %PROJECT% ...
firebase deploy --only firestore:rules --project %PROJECT%

if %ERRORLEVEL% neq 0 (
  echo Deployment failed. Ensure you are logged in: firebase login
  exit /b %ERRORLEVEL%
)

echo Firestore rules deployed successfully.
endlocal