# Driftly Social Features Implementation Plan

## Overview

This document outlines the implementation plan for the new social features in Driftly, based on the cruise timeline progression.

---

## Timeline Overview

```
Day -30: User joins sailing, starts onboarding
Day -25: Tribe matching (existing)
Day -15: Countdown to tribe merge begins (5 days before merge)
Day -10: TRIBE MERGE - Two tribes of 4 become one tribe of 8
Day  0:  DEPARTURE - Cruise begins
Day  3:  DM UNLOCKING - Users can now DM each other 1:1
Day  7+: Cruise-wide BeReal moments
Day  N:  END OF CRUISE - Memories, photo exchange, farewell
```

---

## Feature 1: DM Unlocking (Day 3 of Cruise)

### Description
DMs between tribe members unlock on Day 3 of the cruise (3 days after departure). This encourages group bonding first before 1:1 conversations.

### Data Model Changes

**`/sailings/{sailingId}` - Add fields:**
```dart
dmUnlockDate: Timestamp  // departureDate + 3 days
```

**`/users/{userId}` - Add field:**
```dart
dmUnlockedAt: Timestamp?  // When DMs were unlocked for this user
```

**New collection: `/directMessages/{conversationId}`**
```dart
class DirectMessage {
  String id;
  String sailingId;
  List<String> participantIds;  // [userId1, userId2]
  String lastMessage;
  DateTime lastMessageAt;
  Map<String, int> unreadCounts;  // {userId: count}
  DateTime createdAt;
}
```

**New collection: `/directMessages/{conversationId}/messages/{messageId}`**
```dart
class DMMessage {
  String id;
  String senderId;
  String senderName;
  String text;
  String? imageUrl;
  DateTime timestamp;
  bool isRead;
}
```

### Implementation Files

1. **`lib/models/direct_message.dart`** - New file
   - DirectMessage model
   - DMMessage model

2. **`lib/services/dm_service.dart`** - New file
   - `isDMUnlocked(sailingId, userId)` - Check if DMs are available
   - `getOrCreateConversation(userId1, userId2)`
   - `sendDirectMessage(conversationId, message)`
   - `streamConversations(userId)`
   - `streamMessages(conversationId)`
   - `markAsRead(conversationId, userId)`

3. **`lib/providers/dm_provider.dart`** - New file
   - State management for DM feature
   - Unlock countdown state

4. **`lib/screens/dm/dm_list_screen.dart`** - New file
   - List of DM conversations
   - Shows "Unlocks in X days" countdown if locked

5. **`lib/screens/dm/dm_chat_screen.dart`** - New file
   - 1:1 chat interface

6. **`lib/widgets/dm_unlock_countdown.dart`** - New file
   - Countdown widget showing days/hours until DM unlock
   - "DMs unlock in 2 days 4 hours!"

### UI Flow

1. Before Day 3: Show locked DM button with countdown
2. Day 3: Push notification "DMs are now unlocked! Start chatting 1:1"
3. After Day 3: Full DM functionality available

---

## Feature 2: Tribe Merging (Day -10 / 10 Days Before Departure)

### Description
10 days before departure, two compatible tribes of 4 merge into one super-tribe of 8. This expands social circles before boarding.

### Data Model Changes

**`/sailings/{sailingId}/tribes/{tribeId}` - Add fields:**
```dart
isMerged: bool              // True after merge
mergedWithTribeId: String?  // ID of tribe merged with
superTribeId: String?       // ID of the combined tribe
mergedAt: Timestamp?
```

**New collection: `/sailings/{sailingId}/superTribes/{superTribeId}`**
```dart
class SuperTribe {
  String id;
  String sailingId;
  String name;                    // New combined name
  String ageBand;
  List<String> originalTribeIds;  // [tribeId1, tribeId2]
  List<String> memberIds;         // All 8 members
  List<String> commonInterests;
  DateTime mergedAt;
  DateTime? lastActivityAt;
}
```

### Implementation Files

1. **`lib/models/super_tribe.dart`** - New file
   - SuperTribe model

2. **`lib/services/tribe_service.dart`** - Update existing
   - Add `runTribeMerging(sailingId)` - Algorithm to merge compatible tribes
   - Add `getSuperTribe(sailingId, superTribeId)`
   - Add `streamSuperTribe(sailingId, superTribeId)`

3. **`lib/screens/tribe/tribe_merge_reveal_screen.dart`** - New file
   - Exciting reveal animation when tribes merge
   - "Meet your new tribemates!" with profile cards

4. **Update `lib/screens/home/tabs/tribe_tab.dart`**
   - Handle both regular tribes and super tribes
   - Show "Tribes merge in X days" countdown before merge
   - Celebration UI on merge day

### Merge Algorithm

```dart
Future<void> runTribeMerging(String sailingId) async {
  // 1. Get all full tribes (4 members) that haven't merged
  // 2. Group by age band
  // 3. Within each age band, find pairs with:
  //    - At least 1 shared interest
  //    - Compatible gender ratios (aim for 4M/4F)
  // 4. Create SuperTribe for each matched pair
  // 5. Update original tribes with superTribeId
  // 6. Send notifications to all members
}
```

---

## Feature 3: Pre-Merge Countdown & Voting Polls (Day -15 to Day -10)

### Description
5 days before the tribe merge, start a fun countdown with daily icebreaker voting polls. These help break the ice before meeting the other tribe.

### Data Model Changes

**New collection: `/sailings/{sailingId}/tribeMergePolls/{pollId}`**
```dart
class TribeMergePoll {
  String id;
  String sailingId;
  String tribeId;              // Which tribe this is for
  String partnerTribeId;       // The tribe they'll merge with
  String question;             // Fun icebreaker question
  List<String> options;        // Answer choices
  Map<String, String> votes;   // {userId: selectedOption}
  int dayNumber;               // 1-5 countdown
  DateTime createdAt;
  DateTime expiresAt;          // 24 hours from creation
}
```

### Sample Poll Questions (One per day)

**Day 5 before merge:**
- "What's everyone's go-to cruise drink? 🍹"
  - Options: Cocktails, Beer/Wine, Mocktails, Coffee all day

**Day 4 before merge:**
- "First thing you're doing when you board? 🚢"
  - Options: Pool deck, Buffet, Explore the ship, Find my cabin

**Day 3 before merge:**
- "What's your cruise personality? 🎭"
  - Options: Early bird, Night owl, Spontaneous, Planner

**Day 2 before merge:**
- "Pick a shore excursion vibe 🏝️"
  - Options: Adventure/active, Beach relax, Local culture, Shopping

**Day 1 before merge:**
- "How should we celebrate meeting IRL? 🎉"
  - Options: Group dinner, Pool party, Bar crawl, Casino night

### Implementation Files

1. **`lib/models/tribe_merge_poll.dart`** - New file
   - TribeMergePoll model

2. **`lib/services/poll_service.dart`** - New file
   - `createDailyPoll(sailingId, tribeId, dayNumber)`
   - `vote(pollId, userId, option)`
   - `streamPoll(pollId)`
   - `getPollResults(pollId)`

3. **`lib/providers/poll_provider.dart`** - New file
   - Poll state management

4. **`lib/screens/tribe/merge_countdown_screen.dart`** - New file
   - Shows countdown to merge (5, 4, 3, 2, 1 days)
   - Displays current poll
   - Shows voting results from both tribes

5. **`lib/widgets/poll_card.dart`** - New file
   - Interactive voting card with options
   - Shows results after voting

### UI Flow

1. Day 15 before departure: Banner appears "5 days until tribe merge!"
2. Daily poll notification: "Today's icebreaker is ready! Vote now 🗳️"
3. Show both tribes' results to build anticipation
4. Day 10: Merge happens with fanfare

---

## Feature 4: End of Cruise Features

### Description
When the cruise ends (after returnDate), transition to memories mode with photo sharing, contact exchange, and farewell features.

### Data Model Changes

**`/sailings/{sailingId}` - Add fields:**
```dart
isEnded: bool
endedAt: Timestamp?
```

**Update `/sailings/{sailingId}/cruiseMemories/{memoryId}`** (existing collection)
Add fields:
```dart
category: String         // 'group_photo', 'moment', 'highlight', 'farewell'
contributors: [String]   // All users in the photo/memory
isSharedToAll: bool      // Shared with entire sailing?
```

**New collection: `/users/{userId}/contacts/{contactId}`**
```dart
class CruiseContact {
  String id;
  String sailingId;
  String contactUserId;
  String name;
  String? photoUrl;
  String? phoneNumber;      // Exchanged at end
  String? instagramHandle;
  String? snapchatHandle;
  String tribeNote;         // "Wave Riders tribe"
  DateTime addedAt;
}
```

### Implementation Files

1. **`lib/models/cruise_contact.dart`** - New file
   - CruiseContact model

2. **`lib/services/end_of_cruise_service.dart`** - New file
   - `transitionToEndMode(sailingId)`
   - `exchangeContacts(userId1, userId2, contactInfo)`
   - `getEndOfCruiseMemories(sailingId)`
   - `generateTribePhotoAlbum(tribeId)`

3. **`lib/screens/end_cruise/end_of_cruise_home.dart`** - New file
   - Main end-of-cruise experience
   - "Cruise Complete!" celebration header
   - Stats: X new friends, X photos, X memories

4. **`lib/screens/end_cruise/contact_exchange_screen.dart`** - New file
   - QR code to exchange contact info
   - Choose what to share (phone, Instagram, Snapchat)
   - Tribe contact list

5. **`lib/screens/end_cruise/tribe_album_screen.dart`** - New file
   - Shared photo album with tribe
   - All BeReal photos, group shots
   - Download/share album

6. **`lib/screens/end_cruise/farewell_message_screen.dart`** - New file
   - Write farewell message to tribe
   - "Until next cruise!" sentiment

### UI Flow

1. Return date: App detects cruise ended
2. Transition notification: "Your cruise has ended! Let's preserve the memories"
3. End of cruise home shows:
   - Trip stats
   - Exchange contacts CTA
   - View memories/album
   - Write farewell messages
4. Stays accessible as "Past Cruises" after

---

## Feature 5: Cruise-Wide BeReal Moments

### Description
Ship-wide "BeReal" style photo prompts at random times during the cruise. Everyone on the ship gets notified at the same time to capture their moment.

### Data Model Changes

**New collection: `/sailings/{sailingId}/shipWideMoments/{momentId}`**
```dart
class ShipWideMoment {
  String id;
  String sailingId;
  String promptText;          // "What are you doing RIGHT NOW?"
  DateTime promptedAt;        // When notification sent
  DateTime expiresAt;         // 2-hour window to respond
  int participantCount;
  List<String> participantIds;
  String? featuredPhotoId;    // Best/first photo shown in feed
}
```

**New collection: `/sailings/{sailingId}/shipWideMoments/{momentId}/photos/{photoId}`**
```dart
class MomentPhoto {
  String id;
  String momentId;
  String userId;
  String userName;
  String? userPhotoUrl;
  String photoUrl;
  String? caption;
  String? location;           // "Deck 12 Pool"
  int responseTimeSeconds;
  DateTime takenAt;
  List<String> reactions;     // [userId_emoji, ...]
}
```

### Implementation Files

1. **`lib/models/ship_wide_moment.dart`** - New file
   - ShipWideMoment model
   - MomentPhoto model

2. **`lib/services/moment_service.dart`** - New file
   - `triggerShipWideMoment(sailingId)` - Called by Cloud Function
   - `submitMomentPhoto(momentId, photo, caption)`
   - `streamCurrentMoment(sailingId)`
   - `streamMomentPhotos(momentId)`
   - `addReaction(photoId, userId, emoji)`

3. **`lib/providers/moment_provider.dart`** - New file
   - Current moment state
   - Notification handling

4. **`lib/screens/moments/ship_moment_capture_screen.dart`** - New file
   - Full-screen camera view
   - "Capture your moment!" prompt
   - Timer showing time remaining

5. **`lib/screens/moments/ship_moment_feed_screen.dart`** - New file
   - Grid/feed of everyone's photos from current moment
   - Can react with emojis
   - Filter by deck/location

6. **`lib/widgets/moment_notification_banner.dart`** - New file
   - Floating banner: "Ship-wide moment! Capture now!"
   - Shows countdown to expiry

### Cloud Function (Firebase)

```typescript
// Scheduled function: triggers moment at random time during cruise
export const triggerShipMoment = functions.pubsub
  .schedule('0 */3 * * *')  // Every 3 hours
  .onRun(async () => {
    // Random delay 0-60 minutes to add unpredictability
    // Only during active cruise hours (10am - 10pm ship time)
    // Create moment document
    // Send FCM to all users on sailing
  });
```

### UI Flow

1. Random time during cruise: Push notification "Ship-wide moment NOW!"
2. Open app to camera screen
3. Capture photo within 2-hour window
4. After submitting, see everyone else's photos
5. React/comment on photos
6. Later: Browse past moments in gallery

---

## Implementation Order (Recommended)

### Phase 1: Foundation (Week 1)
1. Direct Message models & service
2. DM provider & UI screens
3. DM unlock logic

### Phase 2: Tribe Evolution (Week 2)
1. SuperTribe model
2. Tribe merging algorithm
3. Merge reveal UI

### Phase 3: Engagement Features (Week 3)
1. Pre-merge polls model & service
2. Poll UI components
3. Countdown widgets

### Phase 4: Cruise-Wide Social (Week 4)
1. Ship-wide moment models & service
2. Moment capture & feed screens
3. Cloud function for triggers

### Phase 5: End Experience (Week 5)
1. End of cruise models
2. Contact exchange feature
3. Memories & album screens
4. Farewell messages

---

## Testing Checklist

- [ ] DM unlock respects 3-day delay
- [ ] Tribe merge at Day -10 works correctly
- [ ] Polls appear 5 days before merge
- [ ] Ship-wide moments notify all users
- [ ] End of cruise transition is smooth
- [ ] Contact exchange QR codes work
- [ ] All notifications fire at correct times

---

## Firestore Security Rules Updates

```javascript
// DMs: Only participants can read/write
match /directMessages/{conversationId} {
  allow read, write: if request.auth.uid in resource.data.participantIds;
}

// Ship moments: All users on same sailing can participate
match /sailings/{sailingId}/shipWideMoments/{momentId} {
  allow read: if userIsOnSailing(sailingId);
  allow write: if userIsOnSailing(sailingId) &&
               request.time < resource.data.expiresAt;
}

// Tribe merge polls: Only tribe members
match /sailings/{sailingId}/tribeMergePolls/{pollId} {
  allow read, write: if userIsInTribe(sailingId, resource.data.tribeId) ||
                       userIsInTribe(sailingId, resource.data.partnerTribeId);
}
```

---

## Notifications Summary

| Event | When | Message |
|-------|------|---------|
| DM Unlock | Day 3 of cruise | "DMs are now unlocked! Start chatting 1:1 with your tribe" |
| Pre-merge countdown | 5 days before merge | "5 days until tribe merge! Today's icebreaker poll is ready" |
| Daily poll | Each day of countdown | "Vote in today's tribe icebreaker!" |
| Tribe merge | Day -10 | "Your tribes have merged! Meet your 4 new tribemates" |
| Ship-wide moment | Random during cruise | "Ship-wide moment NOW! Show us what you're doing!" |
| End of cruise | Return date | "Cruise complete! Preserve memories & exchange contacts" |

---

## Open Questions

1. **Tribe merge mismatches**: What if there's an odd number of tribes? Create a 12-person super tribe with 3 tribes?

2. **Ship-wide moment frequency**: 2-3 per day? Or random per day (1-4)?

3. **DM unlock scope**: Only tribe members can DM, or anyone on the sailing?

4. **End of cruise timeline**: How long do features stay active post-cruise?

---

*Plan created: March 2026*
*Ready for implementation*
