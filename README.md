# Campus Lost & Found — Monorepo

This repository contains two Flutter applications:

- `campuslf/` — User-facing app (Android, Web)
- `campuslf_admin/` — Admin portal (Web)

Both apps are independently runnable. Use the commands below based on the app you’re working on.

## Quick Start

- Prerequisites
  - Flutter SDK installed and on PATH
  - Firebase CLI (optional, for deploy) — `npm i -g firebase-tools`

### Run (development)
- User app (campuslf):
  - Web: `flutter run -d chrome` (inside `campuslf/`)
  - Android: `flutter run -d android` (device/emulator required)
- Admin app (campuslf_admin):
  - Web: `flutter run -d chrome` (inside `campuslf_admin/`)

## Build

- User app (campuslf):
  - Web: `flutter build web --release`
  - Android APK: `flutter build apk --release`
  - Android App Bundle: `flutter build appbundle --release`
- Admin app (campuslf_admin):
  - Web: `flutter build web --release`

Build outputs:
- `campuslf/build/web/` — user app web build
- `campuslf/build/app/outputs/flutter-apk/app-release.apk` — user app APK
- `campuslf_admin/build/web/` — admin app web build

## Deploy (Firebase Hosting)

Ensure the Firebase projects exist and are configured:
- User app project: `wsucampuslf`
- Admin app project: `wsulostfound`

User app (web):
1. `cd campuslf`
2. `flutter build web --release`
3. `firebase deploy --only hosting --project wsucampuslf`

Admin app (web):
1. `cd campuslf_admin`
2. `flutter build web --release`
3. `firebase deploy --only hosting --project wsulostfound`

Notes:
- Add authorized domains in Firebase Auth for each project (e.g., `*.web.app`, `*.firebaseapp.com`).
- Storage rules need enabling the first time you use Firebase Storage (Console → Storage → Get Started).

## CI/CD (GitHub Actions)

Two workflows are provided under `.github/workflows/`:
- `build.yml` — builds campuslf web/APK and campuslf_admin web on push; uploads artifacts
- `deploy.yml` — optionally builds and deploys Hosting for both apps

### Secrets required for deploy
- `FIREBASE_TOKEN` — create via `firebase login` then `firebase login:ci`
  - In GitHub → Repo → Settings → Secrets and variables → Actions → New repository secret → add `FIREBASE_TOKEN`

The deploy workflow will skip deploy if `FIREBASE_TOKEN` isn’t set.

## Repository layout

- `campuslf/` — user app
- `campuslf_admin/` — admin app
- `.github/workflows/` — CI/CD pipelines
- `.gitignore` — global ignore rules for build artifacts and local caches
- `README_MONOREPO.md` — high-level notes on the monorepo

## Common issues (Windows)
- Flutter plugins use junctions; keep project and Flutter SDK on the same drive to avoid symlink errors.
- Low disk space during Android build can crash Gradle; free 3–5 GB or move Gradle cache via `GRADLE_USER_HOME`.

## Support
If you want me to enable auto-deploy on tags or add per-ABI APK builds, let me know and I’ll update the workflows.