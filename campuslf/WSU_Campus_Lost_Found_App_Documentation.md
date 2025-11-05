# WSU Campus Lost & Found Mobile Application
## Complete Project Documentation

---

### Table of Contents
1. [Project Overview](#project-overview)
2. [Technical Specifications](#technical-specifications)
3. [Application Features](#application-features)
4. [User Interface Design](#user-interface-design)
5. [Code Architecture](#code-architecture)
6. [Installation Guide](#installation-guide)
7. [User Manual](#user-manual)
8. [Technical Implementation](#technical-implementation)
9. [Security & Privacy](#security-privacy)
10. [Future Enhancements](#future-enhancements)
11. [Appendices](#appendices)

---

## 1. Project Overview

### 1.1 Project Title
**WSU Campus Lost & Found Mobile Application**

### 1.2 Project Description
A comprehensive mobile application designed specifically for Walter Sisulu University (WSU) to facilitate the reporting, tracking, and recovery of lost and found items on campus. The application provides a centralized platform for students, staff, and faculty to report lost items, browse found items, and communicate with other users to facilitate item recovery.

### 1.3 Project Objectives
- **Primary Goal**: Create an efficient digital solution for managing lost and found items on WSU campus
- **Secondary Goals**:
  - Reduce the time and effort required to recover lost items
  - Provide a secure communication platform between users
  - Implement a karma-based reward system to encourage participation
  - Ensure user privacy and data security
  - Create an intuitive and accessible user interface

### 1.4 Target Audience
- WSU Students (Primary users)
- WSU Faculty and Staff
- Campus Security Personnel
- Administrative Staff

### 1.5 Project Scope
The application covers all WSU campus locations including:
- Academic buildings (Lecture halls, laboratories, libraries)
- Administrative buildings
- Student facilities (cafeteria, gymnasium, student center)
- Outdoor areas (parking lots, sports fields)

---

## 2. Technical Specifications

### 2.1 Development Framework
- **Platform**: Flutter (Cross-platform mobile development)
- **Programming Language**: Dart
- **Target Platforms**: Android and iOS

### 2.2 Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
  image_picker: ^1.0.4
  intl: ^0.18.1
  provider: ^6.1.1
```

### 2.3 System Requirements
**Minimum Requirements:**
- Android 5.0 (API level 21) or iOS 11.0
- 2GB RAM
- 100MB storage space
- Camera access (for photo uploads)
- Internet connectivity (for real-time features)

**Recommended Requirements:**
- Android 8.0+ or iOS 13.0+
- 4GB RAM
- 500MB storage space
- High-resolution camera

### 2.4 Architecture Pattern
- **State Management**: Provider pattern
- **Navigation**: Flutter Navigator 2.0
- **Data Persistence**: SharedPreferences for local storage
- **Image Handling**: image_picker plugin

---

## 3. Application Features

### 3.1 Core Features

#### 3.1.1 Item Reporting System
- **Lost Item Reporting**: Users can report lost items with detailed descriptions
- **Found Item Reporting**: Users can report items they have found
- **Multi-Image Upload**: Support for up to 5 photos per item
- **Location Tracking**: Precise campus location selection
- **Category Classification**: Items organized by categories (Electronics, Books, Clothing, etc.)

#### 3.1.2 Search and Browse
- **Advanced Search**: Filter by category, location, date, and keywords
- **Smart Matching**: AI-powered suggestions for potential matches
- **Real-time Updates**: Live feed of newly reported items
- **Detailed Item Views**: Comprehensive item information with image galleries

#### 3.1.3 Communication System
- **In-App Messaging**: Secure communication between users
- **Contact Information**: WSU email integration
- **Voice/Video Calling**: Integrated calling functionality
- **Privacy Controls**: Users control their contact information visibility

#### 3.1.4 Karma Reward System
- **Point-Based System**: Users earn karma points for helpful actions
- **Activity Tracking**: Points awarded for reporting items, successful recoveries
- **Leaderboards**: Community engagement through friendly competition
- **Premium Features**: Unlock advanced features with higher karma

### 3.2 Advanced Features

#### 3.2.1 User Profile Management
- **WSU Integration**: Automatic WSU email validation
- **Profile Customization**: Personal information and preferences
- **Activity History**: Track of reported and recovered items
- **Statistics Dashboard**: Personal usage analytics

#### 3.2.2 Security Features
- **Data Encryption**: All sensitive data encrypted
- **Privacy Settings**: Granular privacy controls
- **Secure Authentication**: WSU email-based verification
- **Report System**: Ability to report inappropriate content

---

## 4. User Interface Design

### 4.1 Design Philosophy
The application follows a clean, modern design philosophy with emphasis on:
- **Simplicity**: Intuitive navigation and clear visual hierarchy
- **Accessibility**: High contrast colors and readable fonts
- **Consistency**: Uniform design patterns throughout the app
- **Professional Appearance**: Suitable for academic environment

### 4.2 Color Scheme
- **Primary Colors**: Black (#000000), White (#FFFFFF)
- **Accent Colors**: Red (#FF0000) for notifications, Green for success states
- **Text Colors**: Black for primary text, Gray (#8E8E93) for secondary text
- **Background**: Light gray (#F5F5F5) for content areas

### 4.3 Typography
- **Primary Font**: System default (San Francisco on iOS, Roboto on Android)
- **Font Weights**: Regular (400), Medium (500), Semi-bold (600), Bold (700)
- **Font Sizes**: 12px-24px range for optimal readability

### 4.4 Navigation Structure
```
Main Navigator (Bottom Navigation)
├── Home Screen
│   ├── Hero Section
│   ├── Statistics Cards
│   ├── Category Filters
│   └── Items Grid
├── Report Screen
│   ├── Item Type Selection
│   ├── Details Form
│   ├── Image Upload
│   └── Location Selection
├── Messages Screen
│   ├── Conversation List
│   └── Chat Interface
└── Profile Screen
    ├── User Information
    ├── Statistics
    ├── Settings
    └── Account Management
```

---

## 5. Code Architecture

### 5.1 Project Structure
```
lib/
├── main.dart                 # Application entry point
├── models/
│   └── item.dart            # Item data model
├── screens/
│   ├── splash_screen.dart   # App launch screen
│   ├── auth_screen.dart     # Authentication
│   ├── main_navigator.dart  # Bottom navigation
│   ├── home_screen.dart     # Main dashboard
│   ├── report_screen.dart   # Item reporting
│   ├── messages_screen.dart # Messaging system
│   ├── profile_screen.dart  # User profile
│   └── item_detail_screen.dart # Item details
└── services/
    └── message_service.dart # Message handling
```

### 5.2 Key Components

#### 5.2.1 Item Model
```dart
class Item {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final bool isLost;
  final String contactInfo;
  final ItemCategory category;
  final List<String> imagePaths;
}
```

#### 5.2.2 State Management
- **Provider Pattern**: Used for global state management
- **Local State**: StatefulWidget for component-specific state
- **Persistence**: SharedPreferences for user data

### 5.3 Error Handling
- **Try-Catch Blocks**: Comprehensive error handling for async operations
- **Mounted Checks**: Prevent setState calls on disposed widgets
- **Graceful Fallbacks**: Default values when operations fail
- **User Feedback**: Appropriate error messages and loading states

---

## 6. Installation Guide

### 6.1 Development Environment Setup

#### 6.1.1 Prerequisites
1. **Flutter SDK**: Install Flutter 3.0 or later
2. **IDE**: Android Studio, VS Code, or IntelliJ IDEA
3. **Platform Tools**: Android SDK and/or Xcode

#### 6.1.2 Project Setup
```bash
# Clone the repository
git clone [repository-url]
cd campuslf

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### 6.2 Building for Production

#### 6.2.1 Android Build
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

#### 6.2.2 iOS Build
```bash
# Build for iOS
flutter build ios --release
```

---

## 7. User Manual

### 7.1 Getting Started

#### 7.1.1 First Launch
1. **Download and Install**: Install the app from the app store
2. **Account Creation**: Register using your WSU email address
3. **Profile Setup**: Complete your profile information
4. **Permissions**: Grant necessary permissions (camera, storage)

#### 7.1.2 Navigation Basics
- **Bottom Navigation**: Four main sections (Home, Report, Messages, Profile)
- **Back Navigation**: Use back buttons or swipe gestures
- **Search**: Use the search bar on the home screen

### 7.2 Reporting Items

#### 7.2.1 Reporting a Lost Item
1. Navigate to the **Report** tab
2. Select **"I Lost Something"**
3. Fill in item details:
   - Item title and description
   - Location where lost
   - Date and time
   - Category selection
4. Add up to 5 photos
5. Submit the report

#### 7.2.2 Reporting a Found Item
1. Navigate to the **Report** tab
2. Select **"I Found Something"**
3. Provide detailed description
4. Specify where item was found
5. Add clear photos
6. Submit the report

### 7.3 Searching for Items

#### 7.3.1 Browse Items
- **Home Screen**: View recent items in grid layout
- **Category Filters**: Filter by item type
- **Search Bar**: Enter keywords to find specific items

#### 7.3.2 Item Details
- Tap any item to view full details
- View all uploaded photos
- See contact information
- Access messaging options

### 7.4 Communication

#### 7.4.1 Messaging
- **Contact Users**: Message item reporters directly
- **In-App Chat**: Secure messaging within the app
- **Voice/Video Calls**: Make calls through the app

#### 7.4.2 Privacy Settings
- Control who can contact you
- Manage visibility of your contact information
- Block inappropriate users

### 7.5 Profile Management

#### 7.5.1 Account Settings
- Update personal information
- Change contact preferences
- View activity history
- Check karma points

#### 7.5.2 Privacy Controls
- Manage data sharing preferences
- Control notification settings
- Set communication preferences

---

## 8. Technical Implementation

### 8.1 Data Flow Architecture

#### 8.1.1 State Management Flow
```
User Action → Widget → Provider → State Update → UI Rebuild
```

#### 8.1.2 Data Persistence
- **Local Storage**: SharedPreferences for user preferences and karma
- **Image Storage**: Local file system for uploaded images
- **Cache Management**: Automatic cleanup of old data

### 8.2 Key Algorithms

#### 8.2.1 Smart Matching Algorithm
```dart
double calculateSimilarity(Item lost, Item found) {
  double score = 0.0;
  
  // Category match (40% weight)
  if (lost.category == found.category) score += 0.4;
  
  // Location proximity (30% weight)
  score += calculateLocationScore(lost.location, found.location) * 0.3;
  
  // Time proximity (20% weight)
  score += calculateTimeScore(lost.dateTime, found.dateTime) * 0.2;
  
  // Description similarity (10% weight)
  score += calculateTextSimilarity(lost.description, found.description) * 0.1;
  
  return score;
}
```

#### 8.2.2 Karma Point System
```dart
class KarmaSystem {
  static const int REPORT_ITEM = 10;
  static const int SUCCESSFUL_RECOVERY = 50;
  static const int HELPFUL_MESSAGE = 5;
  static const int DAILY_LOGIN = 2;
}
```

### 8.3 Performance Optimizations

#### 8.3.1 Image Optimization
- **Compression**: Automatic image compression before upload
- **Caching**: Efficient image caching system
- **Lazy Loading**: Images loaded on demand

#### 8.3.2 Memory Management
- **Widget Disposal**: Proper cleanup of resources
- **State Management**: Efficient state updates
- **Background Processing**: Non-blocking operations

---

## 9. Security & Privacy

### 9.1 Data Protection

#### 9.1.1 Personal Information
- **WSU Email Validation**: Ensures only WSU community members can access
- **Data Minimization**: Collect only necessary information
- **Encryption**: Sensitive data encrypted at rest and in transit

#### 9.1.2 Communication Security
- **Message Encryption**: All messages encrypted end-to-end
- **Contact Privacy**: Users control visibility of contact information
- **Report System**: Ability to report inappropriate behavior

### 9.2 Privacy Controls

#### 9.2.1 User Consent
- **Explicit Consent**: Clear consent for data collection
- **Granular Controls**: Fine-grained privacy settings
- **Data Portability**: Users can export their data

#### 9.2.2 Compliance
- **POPIA Compliance**: Adherence to South African privacy laws
- **University Policies**: Compliance with WSU data policies
- **Regular Audits**: Periodic security assessments

---

## 10. Future Enhancements

### 10.1 Planned Features

#### 10.1.1 Advanced Technology Integration
- **AI-Powered Matching**: Machine learning for better item matching
- **QR Code Generation**: Unique codes for item tracking
- **Geolocation Services**: GPS-based location tracking
- **Push Notifications**: Real-time alerts for matches

#### 10.1.2 Community Features
- **Rating System**: User reputation management
- **Community Guidelines**: Enhanced moderation tools
- **Success Stories**: Showcase successful recoveries
- **Campus Integration**: Integration with WSU systems

### 10.2 Technical Improvements

#### 10.2.1 Backend Integration
- **Cloud Database**: Scalable cloud storage solution
- **Real-time Sync**: Live data synchronization
- **Analytics Dashboard**: Usage analytics and insights
- **API Development**: RESTful API for third-party integration

#### 10.2.2 Platform Expansion
- **Web Application**: Browser-based version
- **Desktop Application**: Windows/Mac desktop clients
- **API Integration**: Integration with campus security systems
- **Multi-language Support**: Support for additional languages

---

## 11. Appendices

### Appendix A: WSU Email Format Guidelines
- **Students**: `[student_id]@mywsu.ac.za` (e.g., 220123456@mywsu.ac.za)
- **Staff**: `[first_letter][surname]@wsu.ac.za` (e.g., jsmith@wsu.ac.za)

### Appendix B: Campus Location Codes
- **Academic Buildings**: Main Library, Computer Lab A/B, Lecture Halls 1-5
- **Administrative**: Administration Block, Student Center
- **Facilities**: Cafeteria, Gymnasium, Sports Field
- **Outdoor Areas**: Parking Lots A/B, Arts Building, Science Building

### Appendix C: Item Categories
1. **Electronics**: Phones, laptops, tablets, accessories
2. **Books**: Textbooks, notebooks, academic materials
3. **Clothing**: Jackets, bags, accessories
4. **Keys**: Car keys, house keys, access cards
5. **Accessories**: Bags, wallets, jewelry
6. **Other**: Miscellaneous items not fitting other categories

### Appendix D: Technical Specifications Summary
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **Platforms**: Android 5.0+, iOS 11.0+
- **Storage**: Local SharedPreferences
- **Images**: Local file system with compression
- **State Management**: Provider pattern

---

## Contact Information

**Development Team**: WSU Computer Science Department  
**Project Supervisor**: [Supervisor Name]  
**Student Developer**: [Student Name]  
**Email**: [contact_email]@wsu.ac.za  
**Project Repository**: [GitHub URL]  

---

**Document Version**: 1.0  
**Last Updated**: [Current Date]  
**Document Status**: Final Release  

---

*This document serves as the complete technical and user documentation for the WSU Campus Lost & Found Mobile Application. For technical support or feature requests, please contact the development team.*