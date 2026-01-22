# Driftly Firestore Schema

## Collections Overview

```
/users/{userId}
/cruiseLines/{cruiseLineId}
/ships/{shipId}
/sailings/{sailingId}
/sailings/{sailingId}/pods/{podId}
/sailings/{sailingId}/pods/{podId}/members/{userId}
/sailings/{sailingId}/pods/{podId}/messages/{messageId}
/sailings/{sailingId}/hangouts/{hangoutId}
/sailings/{sailingId}/hotZoneVotes/{voteId}
```

---

## 1. Users Collection

**Path:** `/users/{userId}`

**Fields:**
- `uid` (string) - Firebase Auth UID
- `email` (string) - User email
- `name` (string) - Full name
- `ageBand` (string) - "21-25" or "26-30"
- `interests` (array<string>) - ["Nightlife", "Fitness", etc.]
- `selfieVerified` (boolean) - Whether selfie uploaded
- `selfieUrl` (string, optional) - Profile photo URL
- `currentSailingId` (string, nullable) - Reference to current sailing
- `createdAt` (timestamp) - Account creation date
- `updatedAt` (timestamp) - Last profile update

**Example Document:**
```json
{
  "uid": "abc123xyz",
  "email": "alex@example.com",
  "name": "Alex Johnson",
  "ageBand": "21-25",
  "interests": ["Nightlife", "Fitness", "Excursions"],
  "selfieVerified": true,
  "selfieUrl": "https://storage.googleapis.com/...",
  "currentSailingId": "sailing_001",
  "createdAt": {"seconds": 1704067200, "nanoseconds": 0},
  "updatedAt": {"seconds": 1704067200, "nanoseconds": 0}
}
```

---

## 2. Cruise Lines Collection

**Path:** `/cruiseLines/{cruiseLineId}`

**Fields:**
- `id` (string) - Cruise line ID
- `name` (string) - Cruise line name
- `logoUrl` (string, optional) - Logo image URL
- `createdAt` (timestamp) - When added to database

**Example Document:**
```json
{
  "id": "royal_caribbean",
  "name": "Royal Caribbean",
  "logoUrl": "https://example.com/logos/royal.png",
  "createdAt": {"seconds": 1704067200, "nanoseconds": 0}
}
```

---

## 3. Ships Collection

**Path:** `/ships/{shipId}`

**Fields:**
- `id` (string) - Ship ID
- `name` (string) - Ship name
- `cruiseLineId` (string) - Reference to cruise line
- `capacity` (number, optional) - Passenger capacity
- `imageUrl` (string, optional) - Ship image
- `createdAt` (timestamp) - When added to database

**Example Document:**
```json
{
  "id": "harmony_of_seas",
  "name": "Harmony of the Seas",
  "cruiseLineId": "royal_caribbean",
  "capacity": 6780,
  "imageUrl": "https://example.com/ships/harmony.jpg",
  "createdAt": {"seconds": 1704067200, "nanoseconds": 0}
}
```

---

## 4. Sailings Collection

**Path:** `/sailings/{sailingId}`

**Fields:**
- `id` (string) - Sailing ID
- `shipId` (string) - Reference to ship
- `cruiseLineId` (string) - Reference to cruise line (denormalized for queries)
- `departureDate` (timestamp) - Sailing departure date
- `returnDate` (timestamp, optional) - Sailing return date
- `memberCount` (number) - Total users on this sailing
- `active` (boolean) - Whether sailing is active (30-day window logic)
- `createdAt` (timestamp) - When sailing was created

**Example Document:**
```json
{
  "id": "sailing_20260215_harmony",
  "shipId": "harmony_of_seas",
  "cruiseLineId": "royal_caribbean",
  "departureDate": {"seconds": 1739577600, "nanoseconds": 0},
  "returnDate": {"seconds": 1740182400, "nanoseconds": 0},
  "memberCount": 127,
  "active": true,
  "createdAt": {"seconds": 1704067200, "nanoseconds": 0}
}
```

---

## 5. Pods Subcollection

**Path:** `/sailings/{sailingId}/pods/{podId}`

**Fields:**
- `id` (string) - Pod ID
- `sailingId` (string) - Parent sailing ID (denormalized)
- `name` (string) - Pod name ("Gym Crew", "Nightlife Crew", etc.)
- `description` (string) - Pod description
- `icon` (string) - Icon name for UI
- `color` (string) - Hex color code for UI
- `memberCount` (number) - Current member count
- `lastMessageAt` (timestamp, nullable) - Last message timestamp
- `createdAt` (timestamp) - Pod creation date

**Example Document:**
```json
{
  "id": "pod_nightlife_001",
  "sailingId": "sailing_20260215_harmony",
  "name": "Nightlife Crew",
  "description": "Late nights, dancing, and parties",
  "icon": "nightlife",
  "color": "#9C27B0",
  "memberCount": 24,
  "lastMessageAt": {"seconds": 1739577600, "nanoseconds": 0},
  "createdAt": {"seconds": 1704067200, "nanoseconds": 0}
}
```

---

## 6. Pod Members Subcollection

**Path:** `/sailings/{sailingId}/pods/{podId}/members/{userId}`

**Fields:**
- `userId` (string) - User ID
- `userName` (string) - User name (denormalized for quick access)
- `podId` (string) - Pod ID (denormalized)
- `joinedAt` (timestamp) - When user joined pod
- `role` (string, optional) - "member" or "admin" (future feature)

**Example Document:**
```json
{
  "userId": "abc123xyz",
  "userName": "Alex Johnson",
  "podId": "pod_nightlife_001",
  "joinedAt": {"seconds": 1704067200, "nanoseconds": 0},
  "role": "member"
}
```

---

## 7. Messages Subcollection

**Path:** `/sailings/{sailingId}/pods/{podId}/messages/{messageId}`

**Fields:**
- `id` (string) - Message ID
- `podId` (string) - Pod ID (denormalized)
- `userId` (string) - Sender user ID
- `userName` (string) - Sender name (denormalized)
- `userPhotoUrl` (string, optional) - Sender photo (denormalized)
- `text` (string) - Message text
- `timestamp` (timestamp) - Message sent time
- `imageUrl` (string, optional) - Attached image (future feature)
- `reactions` (map<string, array>, optional) - Emoji reactions (future feature)

**Example Document:**
```json
{
  "id": "msg_001",
  "podId": "pod_nightlife_001",
  "userId": "abc123xyz",
  "userName": "Alex Johnson",
  "userPhotoUrl": "https://storage.googleapis.com/...",
  "text": "Anyone up for the club tonight?",
  "timestamp": {"seconds": 1739577600, "nanoseconds": 0},
  "imageUrl": null,
  "reactions": {}
}
```

---

## 8. Micro Hangouts Subcollection

**Path:** `/sailings/{sailingId}/hangouts/{hangoutId}`

**Fields:**
- `id` (string) - Hangout ID
- `sailingId` (string) - Parent sailing ID (denormalized)
- `location` (string) - Location name ("Deck 12 Pool", "Casino", etc.)
- `deck` (string, optional) - Deck number for filtering
- `createdBy` (string) - User ID who created hangout
- `createdByName` (string) - User name (denormalized)
- `attendeeIds` (array<string>) - Array of user IDs who joined
- `attendeeCount` (number) - Number of attendees
- `vibe` (string) - "chill", "lively", or "party"
- `startTime` (timestamp) - Hangout start time
- `expiresAt` (timestamp) - Expiration time (startTime + 45 minutes)
- `active` (boolean) - Whether hangout is still active

**Example Document:**
```json
{
  "id": "hangout_001",
  "sailingId": "sailing_20260215_harmony",
  "location": "Deck 12 Pool",
  "deck": "12",
  "createdBy": "abc123xyz",
  "createdByName": "Alex Johnson",
  "attendeeIds": ["abc123xyz", "def456uvw", "ghi789rst"],
  "attendeeCount": 3,
  "vibe": "chill",
  "startTime": {"seconds": 1739577600, "nanoseconds": 0},
  "expiresAt": {"seconds": 1739580300, "nanoseconds": 0},
  "active": true
}
```

---

## 9. Hot Zone Votes Subcollection

**Path:** `/sailings/{sailingId}/hotZoneVotes/{voteId}`

**Fields:**
- `id` (string) - Vote ID
- `sailingId` (string) - Parent sailing ID (denormalized)
- `location` (string) - Location name
- `deck` (string, optional) - Deck number
- `userId` (string) - Voter user ID
- `crowdLevel` (string) - "empty", "moderate", or "packed"
- `vibe` (string) - "chill", "lively", or "party"
- `timestamp` (timestamp) - Vote timestamp
- `expiresAt` (timestamp) - Vote expiration (timestamp + 1 hour)

**Example Document:**
```json
{
  "id": "vote_001",
  "sailingId": "sailing_20260215_harmony",
  "location": "Casino",
  "deck": "5",
  "userId": "abc123xyz",
  "crowdLevel": "moderate",
  "vibe": "lively",
  "timestamp": {"seconds": 1739577600, "nanoseconds": 0},
  "expiresAt": {"seconds": 1739581200, "nanoseconds": 0}
}
```

---

## Query Patterns

### Get user's pods:
```
/sailings/{sailingId}/pods/{podId}/members
WHERE userId == currentUserId
```

### Get pod messages (real-time):
```
/sailings/{sailingId}/pods/{podId}/messages
ORDER BY timestamp DESC
LIMIT 50
```

### Get active hangouts:
```
/sailings/{sailingId}/hangouts
WHERE active == true
WHERE expiresAt > now()
ORDER BY startTime DESC
```

### Get recent hot zone votes:
```
/sailings/{sailingId}/hotZoneVotes
WHERE timestamp > (now - 1 hour)
WHERE location == "Casino"
ORDER BY timestamp DESC
```

---

## Security Rules (Future Implementation)

- Users can only read/write their own user document
- Users can only join pods if they're part of the sailing
- Only pod members can read messages
- Users can only create one vote per location per hour
- Hangouts automatically expire after 45 minutes
