# Campus Lost & Found App - Testing Guide

## Overview
This guide provides comprehensive testing instructions for the Campus Lost & Found application, focusing on Firebase real-time features and the admin dashboard.

## Prerequisites
- Web application running at: http://localhost:3000
- Android App Bundle (AAB) generated at: `build/app/outputs/bundle/release/app-release.aab`
- Firebase project configured with Firestore, Authentication, and Storage

## Testing Scenarios

### 1. Firebase Real-Time Features Testing

#### A. Multi-User Report Visibility
**Objective**: Verify that reports made by other users are visible to the current user in real-time.

**Steps**:
1. Open two browser windows/tabs at http://localhost:3000
2. Sign in with different user accounts in each window
3. In Window 1: Create a new report (Lost or Found item)
4. In Window 2: Navigate to Home page and verify the new report appears immediately
5. In Window 1: Update the report status or description
6. In Window 2: Verify changes appear in real-time without page refresh

**Expected Results**:
- Reports appear instantly across all user sessions
- Updates to reports are reflected in real-time
- No page refresh required for updates

#### B. Real-Time Messaging
**Steps**:
1. Use two different user accounts
2. Start a chat between the users
3. Send messages from both accounts
4. Verify messages appear instantly in both chat windows

#### C. Report Status Updates
**Steps**:
1. Create a report with status "Pending"
2. From another user account, verify the report is visible
3. Update the report status to "Found" or "Resolved"
4. Verify the status change is reflected immediately for all users

### 2. Admin Dashboard Testing

#### A. Admin Access Control
**Steps**:
1. Sign in with a regular user account
2. Check that "Admin Dashboard" option is NOT visible in the menu
3. Sign in with an admin account (set `isAdmin: true` in Firestore)
4. Verify "Admin Dashboard" option appears in the popup menu
5. Click "Admin Dashboard" and verify access is granted

#### B. User Management
**Steps**:
1. Access Admin Dashboard → Users tab
2. Verify all registered users are displayed
3. Test promoting a user to admin status
4. Test demoting an admin to regular user
5. Verify changes are reflected immediately

#### C. Report Management
**Steps**:
1. Access Admin Dashboard → Reports tab
2. Verify all reports from all users are displayed
3. Test filtering reports by status (Pending, Found, Resolved)
4. Test updating report status as admin
5. Test deleting reports as admin
6. Verify changes are reflected in real-time

#### D. Statistics Dashboard
**Steps**:
1. Access Admin Dashboard → Overview tab
2. Verify statistics are displayed:
   - Total number of reports
   - Reports by status (Pending, Found, Resolved)
   - Reports by category
3. Create new reports and verify statistics update in real-time

### 3. Cross-Platform Testing

#### A. Web Application
- Test all features in Chrome, Firefox, and Edge browsers
- Verify responsive design on different screen sizes
- Test offline functionality (if implemented)

#### B. Android Application
- Install the generated AAB on Android devices
- Test all Firebase features work identically to web version
- Verify push notifications (if implemented)
- Test offline synchronization

### 4. Performance Testing

#### A. Real-Time Updates
- Test with multiple users (5-10) simultaneously
- Verify performance doesn't degrade with concurrent users
- Monitor Firebase usage and costs

#### B. Large Dataset Testing
- Create 50+ reports
- Test search functionality performance
- Verify pagination works correctly
- Test admin dashboard with large datasets

### 5. Security Testing

#### A. Authentication
- Verify unauthenticated users cannot access protected features
- Test session timeout and re-authentication
- Verify admin-only features are properly protected

#### B. Data Access
- Verify users can only edit their own reports
- Test that admin privileges are properly enforced
- Verify Firebase security rules are working correctly

## Test Data Setup

### Creating Test Users
1. Register multiple test accounts with different roles:
   - `admin@test.com` (set `isAdmin: true` in Firestore)
   - `user1@test.com` (regular user)
   - `user2@test.com` (regular user)

### Creating Test Reports
1. Create reports with different categories:
   - Electronics (phones, laptops)
   - Personal Items (keys, wallets)
   - Clothing (jackets, bags)
   - Documents (ID cards, books)

2. Create reports with different statuses:
   - Pending
   - Found
   - Resolved

## Troubleshooting

### Common Issues
1. **Reports not appearing in real-time**:
   - Check Firebase console for connection issues
   - Verify Firestore security rules
   - Check browser console for errors

2. **Admin dashboard not accessible**:
   - Verify user has `isAdmin: true` in Firestore
   - Check authentication status
   - Verify imports in admin_dashboard.dart

3. **Build issues**:
   - Run `flutter clean` and `flutter pub get`
   - Check for missing dependencies
   - Verify Firebase configuration

## Success Criteria

✅ **All Firebase real-time features working**:
- Reports appear instantly across all users
- Real-time updates without page refresh
- Messaging works in real-time

✅ **Admin dashboard fully functional**:
- Role-based access control working
- User management capabilities
- Report oversight and statistics
- Real-time data updates

✅ **Android App Bundle generated successfully**:
- AAB file created without errors
- Ready for Google Play Store deployment

✅ **Cross-platform compatibility**:
- Web and mobile versions work identically
- Responsive design on all screen sizes

## Next Steps

After successful testing:
1. Deploy to production Firebase environment
2. Submit Android App Bundle to Google Play Store
3. Set up monitoring and analytics
4. Plan for user onboarding and training

## Contact

For technical issues or questions about testing, refer to the development team or check the project documentation.