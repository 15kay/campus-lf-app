# 🏗️ Technical Architecture

## Table of Contents

- [System Overview](#system-overview)
- [Architecture Patterns](#architecture-patterns)
- [Component Architecture](#component-architecture)
- [Data Architecture](#data-architecture)
- [Security Architecture](#security-architecture)
- [Communication Architecture](#communication-architecture)
- [Deployment Architecture](#deployment-architecture)
- [Performance Considerations](#performance-considerations)
- [Scalability Design](#scalability-design)

## System Overview

Campus Lost & Found follows a modern, cloud-native architecture built on Flutter for cross-platform development and Firebase for backend services. The system is designed with modularity, scalability, and maintainability in mind.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Applications                      │
├─────────────────┬─────────────────┬─────────────────────────┤
│   Flutter Web   │  Flutter Mobile │    Flutter Desktop     │
│   (Chrome/Edge) │  (Android/iOS)  │   (Windows/macOS)       │
└─────────────────┴─────────────────┴─────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │   API Layer   │
                    └───────┬───────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Firebase Services                         │
├─────────────────┬─────────────────┬─────────────────────────┤
│  Authentication │   Firestore     │    Storage & CDN        │
│   (Auth/OAuth)  │   (Database)    │   (Files/Images)        │
├─────────────────┼─────────────────┼─────────────────────────┤
│  Cloud Functions│  Realtime DB    │  Cloud Messaging        │
│  (Serverless)   │  (Live Chat)    │  (Push Notifications)   │
└─────────────────┴─────────────────┴─────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                 External Services                          │
├─────────────────┬─────────────────┬─────────────────────────┤
│     WebRTC      │   AI Services   │    Analytics            │
│  (Video/Voice)  │   (Chatbot)     │   (Usage Tracking)      │
└─────────────────┴─────────────────┴─────────────────────────┘
```

## Architecture Patterns

### 1. **Model-View-Controller (MVC)**
- **Models**: Data structures and business logic (`models.dart`)
- **Views**: UI components and pages (`pages/` directory)
- **Controllers**: State management and data flow (`app.dart`)

### 2. **Repository Pattern**
- Abstracts data access logic
- Provides clean separation between UI and data sources
- Enables easy testing and mocking

### 3. **Observer Pattern**
- Real-time data synchronization with Firestore
- Live chat updates and typing indicators
- Push notification handling

### 4. **Singleton Pattern**
- Firebase service instances
- Theme and settings management
- User session management

## Component Architecture

### Frontend Components

```
lib/
├── main.dart                 # Application entry point
├── app.dart                  # Main app configuration & routing
├── models.dart               # Data models and business logic
├── firebase_options.dart     # Firebase configuration
└── pages/
    ├── home_page.dart        # Dashboard and item feed
    ├── report_page.dart      # Item reporting interface
    ├── search_page.dart      # Search and filtering
    ├── my_reports_page.dart  # User's item management
    ├── chat_page.dart        # Messaging interface
    ├── video_call_page.dart  # WebRTC video calling
    ├── profile_page.dart     # User profile management
    ├── settings_page.dart    # App configuration
    ├── about_page.dart       # Information and support
    ├── manual_page.dart      # User documentation
    └── chatbot_page.dart     # AI assistant
```

### Core Components

#### 1. **Authentication System**
```dart
class AuthenticationService {
  // Firebase Auth integration
  // User registration and login
  // Session management
  // Profile verification
}
```

#### 2. **Data Management**
```dart
class DataService {
  // Firestore operations
  // Real-time data synchronization
  // Offline data caching
  // Data validation
}
```

#### 3. **Communication System**
```dart
class CommunicationService {
  // Real-time messaging
  // WebRTC video/voice calls
  // Push notifications
  // Typing indicators
}
```

#### 4. **Media Management**
```dart
class MediaService {
  // Image upload and compression
  // File storage management
  // Media optimization
  // CDN integration
}
```

## Data Architecture

### Database Design

#### **Firestore Collections**

##### Users Collection
```json
{
  "users": {
    "userId": {
      "uid": "string",
      "name": "string",
      "studentNumber": "string",
      "email": "string",
      "gender": "string",
      "profileImage": "string",
      "isOnline": "boolean",
      "lastSeen": "timestamp",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

##### Reports Collection
```json
{
  "reports": {
    "reportId": {
      "uid": "string",
      "itemName": "string",
      "status": "Lost|Found",
      "description": "string",
      "location": "string",
      "category": "string",
      "date": "timestamp",
      "imageUrl": "string",
      "isActive": "boolean",
      "views": "number",
      "createdAt": "timestamp",
      "updatedAt": "timestamp"
    }
  }
}
```

##### Conversations Collection
```json
{
  "conversations": {
    "conversationId": {
      "userA": "string",
      "userB": "string",
      "lastMessage": "string",
      "lastMessageTime": "timestamp",
      "unreadCountA": "number",
      "unreadCountB": "number",
      "createdAt": "timestamp"
    }
  }
}
```

##### Messages Collection
```json
{
  "messages": {
    "messageId": {
      "conversationId": "string",
      "senderId": "string",
      "receiverId": "string",
      "content": "string",
      "type": "text|image|file",
      "mediaUrl": "string",
      "deliveryStatus": "sent|delivered|read",
      "timestamp": "timestamp"
    }
  }
}
```

#### **Realtime Database Structure**
```json
{
  "typing": {
    "conversationId": {
      "userId": "boolean"
    }
  },
  "presence": {
    "userId": {
      "isOnline": "boolean",
      "lastSeen": "timestamp"
    }
  },
  "calls": {
    "callId": {
      "callerId": "string",
      "receiverId": "string",
      "type": "video|voice",
      "status": "ringing|active|ended",
      "offer": "object",
      "answer": "object",
      "candidates": "array"
    }
  }
}
```

### Data Flow

```
User Action → UI Component → State Management → Service Layer → Firebase
     ↓                                                              ↓
UI Update ← State Update ← Data Processing ← Response ← Firebase Response
```

## Security Architecture

### Authentication & Authorization

#### **Firebase Authentication**
- Email/password authentication
- Google OAuth integration
- Student email verification
- Session management with JWT tokens

#### **Security Rules**

##### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reports are publicly readable but only writable by owner
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource == null || resource.data.uid == request.auth.uid);
    }
    
    // Conversations accessible only to participants
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        (resource.data.userA == request.auth.uid || 
         resource.data.userB == request.auth.uid);
    }
    
    // Messages accessible only to conversation participants
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        (resource.data.senderId == request.auth.uid || 
         resource.data.receiverId == request.auth.uid);
    }
  }
}
```

##### Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /reports/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### Data Protection

#### **Input Validation**
- Client-side form validation
- Server-side data sanitization
- XSS protection
- SQL injection prevention

#### **Privacy Controls**
- User data anonymization options
- GDPR compliance features
- Data retention policies
- User consent management

## Communication Architecture

### Real-time Messaging

#### **Message Flow**
```
Sender → Flutter App → Firestore → Real-time Listener → Receiver App
                    ↓
              Push Notification → FCM → Device Notification
```

#### **WebRTC Video Calling**
```
Caller → Create Offer → Firebase → Receiver
   ↓                                  ↓
ICE Candidates ← → Firebase ← → ICE Candidates
   ↓                                  ↓
Direct P2P Connection Established
```

### Push Notifications

#### **FCM Integration**
- Message notifications
- Call notifications
- Item match alerts
- System announcements

## Deployment Architecture

### Development Environment
```
Developer Machine → Git Repository → CI/CD Pipeline
                                          ↓
                                   Build & Test
                                          ↓
                                   Deploy to Staging
```

### Production Environment
```
Firebase Hosting (Web) ← CDN ← Users
         ↓
Firebase Services (Backend)
         ↓
Google Cloud Infrastructure
```

### Platform-Specific Deployment

#### **Web Deployment**
- Firebase Hosting
- Progressive Web App (PWA)
- Service Worker for offline functionality
- CDN for global distribution

#### **Mobile Deployment**
- Google Play Store (Android)
- Apple App Store (iOS)
- Over-the-air updates
- Crash reporting and analytics

## Performance Considerations

### Frontend Optimization

#### **Flutter Performance**
- Widget tree optimization
- Lazy loading for large lists
- Image caching and compression
- Memory management

#### **Network Optimization**
- Data pagination
- Offline-first architecture
- Intelligent caching strategies
- Bandwidth-aware media loading

### Backend Optimization

#### **Firestore Performance**
- Compound indexes for complex queries
- Data denormalization for read optimization
- Batch operations for bulk updates
- Connection pooling

#### **Storage Optimization**
- Image compression and resizing
- CDN caching strategies
- Lazy loading for media content
- Progressive image loading

## Scalability Design

### Horizontal Scaling

#### **Firebase Auto-scaling**
- Automatic resource allocation
- Global distribution
- Load balancing
- Regional data replication

### Vertical Scaling

#### **Performance Monitoring**
- Real-time performance metrics
- Error tracking and reporting
- User analytics and insights
- Resource utilization monitoring

### Future Scalability

#### **Microservices Migration**
- Service decomposition strategy
- API gateway implementation
- Container orchestration
- Database sharding

#### **Advanced Features**
- Machine learning integration
- Advanced search capabilities
- Multi-tenant architecture
- Enterprise features

---

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter 3.0+ | Cross-platform UI framework |
| **State Management** | Provider/Riverpod | Application state management |
| **Authentication** | Firebase Auth | User authentication and authorization |
| **Database** | Cloud Firestore | NoSQL document database |
| **Real-time** | Firebase Realtime DB | Live chat and presence |
| **Storage** | Firebase Storage | File and media storage |
| **Hosting** | Firebase Hosting | Web application hosting |
| **Communication** | WebRTC | Peer-to-peer video/voice calls |
| **Notifications** | FCM | Push notifications |
| **Analytics** | Firebase Analytics | Usage tracking and insights |
| **Monitoring** | Firebase Crashlytics | Error tracking and reporting |

This architecture ensures a robust, scalable, and maintainable application that can grow with the university's needs while providing an excellent user experience across all platforms.