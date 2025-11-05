# WSU Campus Lost & Found System Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLIENT LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │   Flutter Web   │  │  Flutter Mobile │  │  Flutter Desktop│            │
│  │   (Chrome/Edge) │  │   (Android/iOS) │  │   (Windows/Mac) │            │
│  │                 │  │                 │  │                 │            │
│  │ • User App      │  │ • User App      │  │ • User App      │            │
│  │ • Admin Portal  │  │ • Admin Portal  │  │ • Admin Portal  │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS/WSS
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FIREBASE BACKEND                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │ Firebase Auth   │  │ Cloud Firestore │  │ Firebase Storage│            │
│  │                 │  │                 │  │                 │            │
│  │ • WSU Email     │  │ • Real-time DB  │  │ • Image Storage │            │
│  │ • JWT Tokens    │  │ • Collections   │  │ • File Upload   │            │
│  │ • User Sessions │  │ • Security Rules│  │ • CDN Delivery  │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │ Firebase Hosting│  │ Cloud Functions │  │ Firebase Analytics│          │
│  │                 │  │                 │  │                 │            │
│  │ • Static Assets │  │ • Server Logic  │  │ • User Tracking │            │
│  │ • CDN           │  │ • Triggers      │  │ • Performance   │            │
│  │ • SSL/HTTPS     │  │ • Notifications │  │ • Crash Reports │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Internal APIs
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL SERVICES                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │ Email Service   │  │ Push Notifications│ │ Image Processing│            │
│  │ (SMTP/SendGrid) │  │ (FCM)           │  │ (Cloud Vision)  │            │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘            │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Application Layer Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER APPLICATION                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        PRESENTATION LAYER                           │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │ Auth Screen │ │ Home Screen │ │ Item Detail │ │ Messages    │   │   │
│  │  │             │ │             │ │ Screen      │ │ Screen      │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │ Report      │ │ Forum       │ │ Profile     │ │ Admin       │   │   │
│  │  │ Screen      │ │ Screen      │ │ Screen      │ │ Dashboard   │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         SERVICE LAYER                               │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │ Auth        │ │ Realtime    │ │ Storage     │ │ Error       │   │   │
│  │  │ Service     │ │ Service     │ │ Service     │ │ Handler     │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │ Input       │ │ Two Factor  │ │ Mock        │ │ Firebase    │   │   │
│  │  │ Validator   │ │ Service     │ │ Service     │ │ Storage     │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                       │
│                                    ▼                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         MODEL LAYER                                 │   │
│  │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │  │ Item Model  │ │ User Model  │ │ Message     │ │ Comment     │   │   │
│  │  │             │ │             │ │ Model       │ │ Model       │   │   │
│  │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Database Design (Firestore Collections)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FIRESTORE DATABASE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         USERS COLLECTION                            │   │
│  │  Document ID: {userId}                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • email: string (WSU email)                                 │   │   │
│  │  │ • name: string                                              │   │   │
│  │  │ • studentId: string (optional)                              │   │   │
│  │  │ • phone: string (10 digits)                                 │   │   │
│  │  │ • role: string (student/staff/admin)                        │   │   │
│  │  │ • createdAt: timestamp                                      │   │   │
│  │  │ • lastLogin: timestamp                                      │   │   │
│  │  │ • isActive: boolean                                         │   │   │
│  │  │ • karma: number                                             │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         ITEMS COLLECTION                            │   │
│  │  Document ID: {itemId}                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • title: string                                             │   │   │
│  │  │ • description: string                                       │   │   │
│  │  │ • category: string (electronics/clothing/books/etc)         │   │   │
│  │  │ • location: string                                          │   │   │
│  │  │ • isLost: boolean                                           │   │   │
│  │  │ • contactInfo: string (email)                               │   │   │
│  │  │ • userId: string (owner)                                    │   │   │
│  │  │ • userEmail: string                                         │   │   │
│  │  │ • userName: string                                          │   │   │
│  │  │ • imagePath: string (main image)                            │   │   │
│  │  │ • imagePaths: array<string> (all images)                    │   │   │
│  │  │ • dateTime: timestamp (when lost/found)                     │   │   │
│  │  │ • createdAt: timestamp                                      │   │   │
│  │  │ • updatedAt: timestamp                                      │   │   │
│  │  │ • status: string (active/resolved/expired)                  │   │   │
│  │  │ • likes: array<string> (user IDs)                           │   │   │
│  │  │ • comments: array<object>                                   │   │   │
│  │  │   ├─ id: string                                             │   │   │
│  │  │   ├─ userId: string                                         │   │   │
│  │  │   ├─ userName: string                                       │   │   │
│  │  │   ├─ text: string                                           │   │   │
│  │  │   └─ dateTime: timestamp                                    │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                       MESSAGES COLLECTION                           │   │
│  │  Document ID: {messageId}                                           │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • senderId: string                                          │   │   │
│  │  │ • senderName: string                                        │   │   │
│  │  │ • senderEmail: string                                       │   │   │
│  │  │ • receiverEmail: string                                     │   │   │
│  │  │ • content: string                                           │   │   │
│  │  │ • itemTitle: string (optional)                              │   │   │
│  │  │ • itemId: string (optional)                                 │   │   │
│  │  │ • isRead: boolean                                           │   │   │
│  │  │ • createdAt: timestamp                                      │   │   │
│  │  │ • messageType: string (inquiry/response/general)            │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     FORUM_POSTS COLLECTION                         │   │
│  │  Document ID: {postId}                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • title: string                                             │   │   │
│  │  │ • content: string                                           │   │   │
│  │  │ • category: string (General/Tips/Success Stories)           │   │   │
│  │  │ • userId: string                                            │   │   │
│  │  │ • userEmail: string                                         │   │   │
│  │  │ • userName: string                                          │   │   │
│  │  │ • likes: number                                             │   │   │
│  │  │ • createdAt: timestamp                                      │   │   │
│  │  │ • updatedAt: timestamp                                      │   │   │
│  │  │ • isActive: boolean                                         │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    SUBCOLLECTION: comments                  │   │   │
│  │  │  Document ID: {commentId}                                   │   │   │
│  │  │  ┌─────────────────────────────────────────────────────┐   │   │   │
│  │  │  │ • content: string                                   │   │   │   │
│  │  │  │ • userId: string                                    │   │   │   │
│  │  │  │ • userName: string                                  │   │   │   │
│  │  │  │ • createdAt: timestamp                              │   │   │   │
│  │  │  └─────────────────────────────────────────────────────┘   │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SECURITY LAYERS                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AUTHENTICATION LAYER                            │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • Firebase Auth with WSU Email Validation                   │   │   │
│  │  │ • JWT Token-based Sessions                                  │   │   │
│  │  │ • Two-Factor Authentication (Optional)                      │   │   │
│  │  │ • Guest Mode (Limited Access)                               │   │   │
│  │  │ • Password Reset via Email                                  │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AUTHORIZATION LAYER                             │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • Firestore Security Rules                                  │   │   │
│  │  │ • User Ownership Validation                                 │   │   │
│  │  │ • Email Domain Restrictions                                 │   │   │
│  │  │ • Role-based Access Control                                 │   │   │
│  │  │ • Resource-level Permissions                                │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      DATA PROTECTION                               │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • Input Validation & Sanitization                           │   │   │
│  │  │ • XSS Protection                                            │   │   │
│  │  │ • CSRF Protection                                           │   │   │
│  │  │ • File Upload Restrictions                                  │   │   │
│  │  │ • Rate Limiting                                             │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    TRANSPORT SECURITY                              │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ • HTTPS/TLS 1.3 Encryption                                  │   │   │
│  │  │ • Firebase Hosting SSL                                      │   │   │
│  │  │ • Secure WebSocket Connections                              │   │   │
│  │  │ • API Key Environment Variables                             │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DATA FLOW DIAGRAM                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  USER ACTIONS                    SYSTEM PROCESSING                         │
│                                                                             │
│  ┌─────────────┐                 ┌─────────────────────────────────────┐   │
│  │ User Login  │────────────────▶│ 1. Validate WSU Email               │   │
│  └─────────────┘                 │ 2. Authenticate with Firebase       │   │
│                                  │ 3. Create/Update User Profile       │   │
│                                  │ 4. Generate JWT Token               │   │
│                                  └─────────────────────────────────────┘   │
│                                                    │                       │
│                                                    ▼                       │
│  ┌─────────────┐                 ┌─────────────────────────────────────┐   │
│  │ Report Item │────────────────▶│ 1. Validate Input Data              │   │
│  └─────────────┘                 │ 2. Upload Images to Storage         │   │
│                                  │ 3. Create Item Document             │   │
│                                  │ 4. Trigger Real-time Updates        │   │
│                                  └─────────────────────────────────────┘   │
│                                                    │                       │
│                                                    ▼                       │
│  ┌─────────────┐                 ┌─────────────────────────────────────┐   │
│  │ Send Message│────────────────▶│ 1. Validate Recipient Email         │   │
│  └─────────────┘                 │ 2. Check Self-messaging Prevention  │   │
│                                  │ 3. Create Message Document          │   │
│                                  │ 4. Update Unread Count              │   │
│                                  └─────────────────────────────────────┘   │
│                                                    │                       │
│                                                    ▼                       │
│  ┌─────────────┐                 ┌─────────────────────────────────────┐   │
│  │ View Items  │────────────────▶│ 1. Query Items Collection           │   │
│  └─────────────┘                 │ 2. Apply Security Rules             │   │
│                                  │ 3. Stream Real-time Updates         │   │
│                                  │ 4. Update UI Components             │   │
│                                  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEPLOYMENT ARCHITECTURE                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      PRODUCTION ENVIRONMENT                         │   │
│  │                                                                     │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│  │  │ Firebase Hosting│  │ Cloud Firestore │  │ Firebase Storage│     │   │
│  │  │                 │  │                 │  │                 │     │   │
│  │  │ • wsucampuslf   │  │ • Production DB │  │ • Image CDN     │     │   │
│  │  │   .web.app      │  │ • Security Rules│  │ • File Storage  │     │   │
│  │  │ • SSL/HTTPS     │  │ • Indexes       │  │ • 5MB Limit     │     │   │
│  │  │ • CDN           │  │ • Backups       │  │ • Auto-scaling  │     │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │   │
│  │                                                                     │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│  │  │ Firebase Auth   │  │ Cloud Functions │  │ Monitoring      │     │   │
│  │  │                 │  │                 │  │                 │     │   │
│  │  │ • User Sessions │  │ • Triggers      │  │ • Analytics     │     │   │
│  │  │ • JWT Tokens    │  │ • Notifications │  │ • Error Tracking│     │   │
│  │  │ • 2FA Support   │  │ • Cleanup Jobs  │  │ • Performance   │     │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      ADMIN ENVIRONMENT                             │   │
│  │                                                                     │   │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │   │
│  │  │ Admin Portal    │  │ Admin Dashboard │  │ User Management │     │   │
│  │  │                 │  │                 │  │                 │     │   │
│  │  │ • wsulostfound  │  │ • Real-time     │  │ • User Roles    │     │   │
│  │  │   .web.app      │  │   Statistics    │  │ • Permissions   │     │   │
│  │  │ • Admin Auth    │  │ • Item Analytics│  │ • Activity Logs │     │   │
│  │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Key Features Summary

### Core Functionality
- **Item Management**: Report, browse, and manage lost/found items
- **Real-time Messaging**: Direct communication between users
- **Smart Matching**: AI-powered item matching system
- **Forum System**: Community discussions and tips
- **User Profiles**: Karma system and activity tracking

### Security Features
- **WSU Email Authentication**: Restricted to university emails
- **Role-based Access**: Student, staff, and admin roles
- **Data Validation**: Input sanitization and validation
- **Secure File Upload**: Image size and type restrictions
- **Privacy Protection**: User data encryption and secure transmission

### Technical Features
- **Real-time Updates**: Live data synchronization
- **Offline Support**: Local data caching
- **Multi-platform**: Web, mobile, and desktop support
- **Responsive Design**: Adaptive UI for all screen sizes
- **Performance Optimization**: Lazy loading and caching

This architecture ensures scalability, security, and maintainability while providing a seamless user experience across all platforms.