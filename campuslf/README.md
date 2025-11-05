# WSU Campus Lost & Found System

A comprehensive Flutter-based lost and found management system for Walter Sisulu University.

## 🌐 Live Applications

### User App
**URL:** https://wsucampuslf.web.app
- Report lost items
- Browse found items
- Real-time notifications
- Smart matching system
- **Secure:** WSU email authentication required

### Admin Portal
**URL:** https://wsulostfound.web.app
- **Login:** admin@wsu.ac.za / admin123
- Real-time dashboard
- Items management
- User analytics
- System settings

## 🚀 Features

### User Features
- **Item Reporting:** Easy lost/found item submission
- **Smart Search:** Advanced filtering and categorization
- **Real-time Updates:** Live notifications and updates
- **Secure Authentication:** User login and profile management
- **Mobile Responsive:** Works on all devices

### Admin Features
- **Live Dashboard:** Real-time statistics and monitoring
- **Items Management:** Full CRUD operations for items
- **User Management:** Admin user controls
- **Analytics:** Performance insights and reports
- **Modern UI:** Dark theme with glassmorphism design

## 🛠️ Technology Stack

- **Frontend:** Flutter (Web)
- **Backend:** Firebase
- **Database:** Firestore
- **Authentication:** Firebase Auth
- **Hosting:** Firebase Hosting
- **Storage:** Firebase Storage

## 📱 Installation & Setup

### Prerequisites
- Flutter SDK
- Firebase CLI
- Git

### Local Development
```bash
# Clone repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Run user app
cd campuslf
flutter run -d chrome

# Run admin app
cd campuslf_admin
flutter run -d chrome
```

### Deployment
```bash
# Build and deploy user app
cd campuslf
flutter build web --release
firebase deploy --only hosting

# Build and deploy admin app
cd campuslf_admin
flutter build web --release
firebase deploy --only hosting
```

## 🔧 Configuration

### Firebase Setup
- Project ID: wsucampuslf (User App)
- Project ID: wsulostfound (Admin Portal)
- Authentication enabled
- Firestore database configured
- Storage bucket active

### Admin Access
- Email: admin@wsu.ac.za
- Password: admin123
- Full system access and management

## 📊 System Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   User App      │    │  Admin Portal   │
│ wsucampuslf     │    │ wsulostfound    │
└─────────────────┘    └─────────────────┘
         │                       │
         └───────────┬───────────┘
                     │
         ┌─────────────────┐
         │   Firebase      │
         │   Backend       │
         └─────────────────┘
```

## 🎯 Usage

### For Students
1. Visit https://wsucampuslf.web.app
2. Create account or login
3. Report lost items or browse found items
4. Receive notifications for matches

### For Administrators
1. Visit https://wsulostfound.web.app
2. Login with admin credentials
3. Monitor system activity
4. Manage items and users
5. View analytics and reports

## 📈 Key Metrics

- Real-time user tracking
- Item success rate monitoring
- Response time analytics
- Campus coverage statistics

## 🔒 Security

- Firebase Authentication
- Secure admin access
- Data encryption
- Role-based permissions

## 📞 Support

For technical support or questions:
- Admin Portal: https://wsulostfound.web.app
- System Administrator: admin@wsu.ac.za

---

**Walter Sisulu University - Digital Services & Innovation Team**