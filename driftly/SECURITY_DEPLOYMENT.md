# Security & Deployment Guide

## Firestore Security Rules

The app includes comprehensive Firestore security rules in `firestore.rules`. These rules must be deployed before going to production.

### Deploying Security Rules

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project (if not done)
firebase init firestore

# Deploy security rules
firebase deploy --only firestore:rules
```

### Key Security Features

1. **Authentication Required**: All operations require user authentication
2. **User Ownership**: Users can only modify their own documents
3. **Input Validation**: Server-side validation for:
   - String lengths (names, messages, locations)
   - Enum values (vibes, age bands, locations)
   - Timestamp validity
4. **Immutable Fields**: Critical fields like uid and email cannot be modified
5. **Vote Restrictions**: Hot zone votes are immutable once created
6. **Message Security**: Users can only delete their own messages

### Security Rules Summary

| Collection | Create | Read | Update | Delete |
|-----------|--------|------|--------|--------|
| /users/{userId} | Own only | Own only | Own only (except uid/email) | Own only |
| /sailings/{sailingId} | Auth | Auth | Auth | Disabled |
| /sailings/{id}/pods/{podId} | Auth | Auth | Auth | Disabled |
| /pods/{id}/members/{userId} | Own only | Auth | Disabled | Own only |
| /pods/{id}/messages/{msgId} | Auth (validated) | Auth | Disabled | Own only |
| /sailings/{id}/hangouts/{hId} | Auth (validated) | Auth | Join/Leave only | Disabled |
| /sailings/{id}/hotZoneVotes/{vId} | Auth (validated) | Auth | Disabled | Disabled |

## Input Sanitization

The app implements client-side input sanitization to prevent XSS and injection attacks:

### Implemented in `lib/utils/input_validator.dart`

- **XSS Prevention**: Removes script tags and javascript: protocols
- **Null Byte Removal**: Prevents null byte injection
- **Length Limits**: Enforces maximum lengths for all user inputs
- **Pattern Validation**: Validates emails, names, age bands, etc.

### Applied in FirestoreService

All user input is sanitized before being written to Firestore:
- Messages: Sanitized and truncated to 500 characters
- Locations: Sanitized and truncated to 100 characters
- Vibes: Validated against allowed enums
- Age Bands: Validated against allowed values

## Production Checklist

Before deploying to production:

### Firebase Configuration

- [ ] Deploy Firestore security rules: `firebase deploy --only firestore:rules`
- [ ] Set up Firebase Authentication email templates
- [ ] Configure authorized domains in Firebase Console
- [ ] Enable Firebase App Check for abuse prevention
- [ ] Set up Firebase Performance Monitoring
- [ ] Configure Cloud Firestore indexes (check console for warnings)

### Security

- [ ] Review and test all Firestore security rules
- [ ] Implement rate limiting (Cloud Functions or App Check)
- [ ] Set up monitoring and alerts for suspicious activity
- [ ] Enable audit logging
- [ ] Review all API keys and ensure they're restricted properly
- [ ] Implement custom authentication claims for admin roles

### Performance

- [ ] Create composite indexes for complex queries:
  - Hangouts: `sailingId` + `ageBand` + `expiresAt`
  - Hot Zone Votes: `sailingId` + `location` + `timestamp`
- [ ] Enable persistence for offline support
- [ ] Implement pagination for large message lists
- [ ] Consider implementing Cloud Functions for vote aggregation

### Monitoring

- [ ] Set up Firebase Crashlytics
- [ ] Implement analytics event tracking
- [ ] Set up performance monitoring
- [ ] Configure alerts for error rates and performance degradation

### Testing

- [ ] Test all security rules with Firebase Emulator Suite
- [ ] Perform security audit and penetration testing
- [ ] Test offline functionality
- [ ] Load test with realistic user volumes
- [ ] Test edge cases (expired hangouts, duplicate votes, etc.)

## Recommended Cloud Functions

Consider implementing these Cloud Functions for better security and performance:

### 1. Vote Aggregation (Hot Zones)
Instead of client-side aggregation, use a Cloud Function triggered on vote creation to maintain pre-aggregated vote counts.

### 2. Cleanup Functions
- Auto-expire old hangouts and votes
- Clean up orphaned data

### 3. Notifications
- Notify users when someone joins their hangout
- Send reminders before hangout expires

### 4. Rate Limiting
- Prevent spam by limiting vote/message creation frequency per user

## Environment Variables

Create a `.env` file (DO NOT commit to git):

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id
```

Add `.env` to `.gitignore`

## Monitoring Queries

Useful Firestore queries for monitoring:

```javascript
// Find users with suspicious activity
db.collection('hotZoneVotes')
  .where('userId', '==', 'suspicious_user_id')
  .where('timestamp', '>', Date.now() - 3600000)
  .get()

// Check for abnormal vote patterns
db.collection('hotZoneVotes')
  .where('location', '==', 'Pool')
  .where('timestamp', '>', Date.now() - 3600000)
  .get()
```

## Support & Maintenance

For security issues or questions, contact: [your-email@example.com]

Last updated: 2026-01-19
