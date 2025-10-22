# Campus Lost & Found – 2025 Project Guidelines

## Context
Campus Lost & Found is a mobile and web Flutter application designed for Walter Sisulu University (WSU) students to report, find, and recover lost items across campus. It reduces time spent searching, improves collaboration among students/staff, and centralizes information for quick recovery.

## Goals & Objectives
- Provide a simple, safe platform for reporting lost and found items.
- Enable fast discovery via search and filters.
- Allow students to manage their own reports (view, edit, delete).
- Offer profile management and app settings (including theme switching).
- Integrate Firebase for authentication, data storage (Cloud Firestore), and image uploads (Firebase Storage). Optional: push notifications via Firebase Cloud Messaging.

## User Manual

### Getting Started
1. Launch the app on Android/iOS or open the web version.
2. From the bottom navigation, access: Home, Report, My Reports, Search, Profile, Settings, About.

### Home Page
- Displays a feed of recent lost and found items.
- Tap a card to view Item Details.

Inline SVG screenshot placeholder:

<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360">
  <rect width="640" height="360" fill="#f5f5f5"/>
  <rect x="20" y="20" width="600" height="50" fill="#1B5E20" rx="8"/>
  <text x="40" y="50" font-size="18" fill="#ffffff">Campus Lost & Found – Home</text>
  <rect x="20" y="90" width="600" height="80" fill="#ffffff" stroke="#ddd" rx="12"/>
  <rect x="20" y="180" width="600" height="80" fill="#ffffff" stroke="#ddd" rx="12"/>
  <rect x="20" y="270" width="600" height="60" fill="#ffffff" stroke="#ddd" rx="12"/>
</svg>

### Report Page
- Add a new item: Item name, Status (Lost/Found), Description, Location, Category, Date, and Image upload.
- Submit to publish your report.

### My Reports Page
- View your submissions.
- Delete a report or edit details (editing UI will be added next; currently placeholder action).

### Search & Filter Page
- Search by item name.
- Filter by Status (Lost/Found) and Location.

### Profile Page
- Update your name, student number, email, gender.
- Change your profile picture.

### Settings Page
- Switch between Light, Dark, or System theme.
- Notifications section (informational until Firebase Cloud Messaging is configured).

### About Page
- Displays app purpose and developer contact. Please provide your name and contact email to finalize.

## Design & UI Guidelines
- Theme: Material 3, modern and minimal; select Cupertino nuances where appropriate.
- Colors: Primary Green #1B5E20, Accent Gold #FFD700, Background White/Light Gray.
- Typography: Poppins (Google Fonts) for headings and text.
- Components: Rounded cards, soft shadows, clear spacing (16–20px), smooth page transitions.

## Data Model (Firestore)

Users
{
  "uid": "uniqueID",
  "name": "John Doe",
  "student_number": "123456",
  "email": "john@example.com",
  "gender": "Male",
  "profile_image": "https://..."
}

Reports
{
  "report_id": "xyz123",
  "uid": "uniqueID",
  "item_name": "Backpack",
  "status": "Lost",
  "description": "Blue backpack left in library",
  "location": "Library",
  "date": "2025-10-01",
  "category": "Bags",
  "image_url": "https://...",
  "timestamp": "2025-10-01T12:30:00"
}

## Coding Appendix

### Tech Stack
- Flutter 3 (Material 3)
- Firebase (Auth, Cloud Firestore, Storage; optional Cloud Messaging)

### Project Structure
- lib/app.dart: App root, theme, navigation, pages wiring.
- lib/models.dart: UserProfile and Report models plus demo data.
- lib/pages/: Home, Report, My Reports, Search, Profile, Settings, About.
- lib/main.dart: Entry point that runs MyApp.

### State & Demo Mode
- The app ships with demo in-memory data to run without Firebase configuration.
- Once Firebase is configured, endpoints will replace demo data access.

### Firebase Setup (to be executed)
1. Create a Firebase project (Android/iOS/Web). Note your app IDs and package name.
2. Add services: Authentication, Firestore, Storage (optional: Cloud Messaging).
3. Run FlutterFire CLI to configure platforms and auto-generate firebase_options.dart.
4. Initialize Firebase in main.dart and replace demo data usage with Firestore queries and Storage uploads.

### Build & Run
- Web: flutter run -d chrome
- Android: flutter run -d android
- iOS (macOS required): flutter run -d ios

### Security & Privacy
- Do not store passwords in Firestore; use Firebase Auth.
- Validate inputs; sanitize text fields.
- Never commit credentials or service keys.

---
This document will be updated as Firebase integration and authentication screens are implemented.