/// App-wide constants and configuration values
/// Centralizes magic numbers, strings, and timing values for maintainability
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== Timing Constants ====================

  /// Duration for micro hangout visibility (45 minutes)
  static const Duration hangoutDuration = Duration(minutes: 45);

  /// Duration for hot zone vote validity (1 hour)
  static const Duration voteValidityDuration = Duration(hours: 1);

  /// Duration for sailing access window (30 days)
  static const Duration sailingAccessWindow = Duration(days: 30);

  /// Duration for end of cruise period (72 hours post-cruise access)
  static const Duration endOfCruiseDuration = Duration(hours: 72);

  // ==================== BeReal / Daily Photo ====================

  /// BeReal prompts per day per cruise (strictly once)
  static const int beRealPromptsPerDay = 1;

  /// BeReal is tribe-only for now (not cruise-wide)
  static const bool beRealTribeOnly = true;

  /// BeReal prompt window - random time between these hours (10am-10pm)
  static const int beRealStartHour = 10;
  static const int beRealEndHour = 22;

  /// Default timeout for network requests
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Debounce duration for search inputs
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // ==================== Pagination & Limits ====================

  /// Maximum messages to load in chat
  static const int messageLimit = 50;

  /// Maximum characters for message text
  static const int maxMessageLength = 500;

  /// Maximum characters for hangout location
  static const int maxLocationLength = 100;

  /// Maximum characters for user name
  static const int maxNameLength = 50;

  /// Maximum characters for user bio
  static const int maxBioLength = 300;

  // ==================== Tribe Configuration ====================

  /// Minimum members for a valid tribe
  static const int minTribeSize = 3;

  /// Maximum members for a tribe
  static const int maxTribeSize = 5;

  /// Ideal tribe sizes (prefer these over min/max edges)
  static const List<int> idealTribeSizes = [4, 5, 3];

  // ==================== Age Bands ====================

  static const List<String> ageBands = ['16-17', '18-20', '21-30', '31-39', '39+'];

  static const String ageBand1617 = '16-17';
  static const String ageBand1820 = '18-20';
  static const String ageBand2130 = '21-30';
  static const String ageBand3139 = '31-39';
  static const String ageBand39Plus = '39+';

  /// Age band that has restrictions (no alcohol, no gambling)
  static const String restrictedAgeBand = '16-17';

  // ==================== Age Mixing Safety Rules ====================

  /// Age bands that can NEVER mix with other age groups (safety protection)
  /// - 16-17: Minors must stay with minors (predator protection)
  /// - 39+: Older users stay with their age group (community preference)
  static const List<String> noMixingAgeBands = ['16-17', '39+'];

  /// Age bands that CAN mix when user opts-in (for small cruise numbers)
  /// Only 18-39 age ranges can mix together
  static const List<String> mixableAgeBands = ['18-20', '21-30', '31-39'];

  /// Check if an age band can potentially mix with others
  static bool canAgeBandMix(String ageBand) => mixableAgeBands.contains(ageBand);

  /// Check if an age band is protected (never mixes)
  static bool isProtectedAgeBand(String ageBand) => noMixingAgeBands.contains(ageBand);

  // ==================== Interests ====================

  static const List<String> availableInterests = [
    'Nightlife',
    'Fitness',
    'Excursions',
    'Relaxation',
    'Food & Dining',
    'Sports',
    'Photography',
    'Music',
    'Casino',
    'On Island Hangout',
  ];

  /// Interests restricted for 16-17 age group
  static const List<String> restrictedInterests = [
    'Casino',
    'Nightlife', // Often involves alcohol
  ];

  /// Interests available for 16-17 age group
  static List<String> get underageInterests =>
      availableInterests.where((i) => !restrictedInterests.contains(i)).toList();

  // ==================== Hot Zones ====================

  /// Fixed location names for Hot Zones
  static const List<String> hotZoneLocations = [
    'Pool',
    'Casino',
    'Nightclub',
    'Sports Deck',
    'Buffet',
    'Theatre',
  ];

  /// Vibe options for Hot Zones voting
  static const List<String> vibeOptions = [
    'active',
    'quiet',
    'overcrowded',
    'good_vibes',
  ];

  // ==================== Micro Hangout Vibes & Colors ====================

  static const List<String> hangoutVibes = [
    'chill',
    'lively',
    'party',
    'adventurous',
    'social',
  ];

  /// Mood colors for hangouts (hex colors)
  static const Map<String, String> hangoutMoodColors = {
    'chill': '#4A90A4',      // Calm blue
    'lively': '#FF9500',     // Energetic orange
    'party': '#FF2D55',      // Hot pink/red
    'adventurous': '#34C759', // Green
    'social': '#AF52DE',     // Purple
  };

  /// Hangout category colors
  static const Map<String, String> hangoutCategoryColors = {
    'Pool': '#00CED1',       // Turquoise
    'Bar': '#8B0000',        // Dark red
    'Restaurant': '#FF8C00', // Dark orange
    'Deck': '#87CEEB',       // Sky blue
    'Casino': '#FFD700',     // Gold
    'Spa': '#DDA0DD',        // Plum
    'Gym': '#32CD32',        // Lime green
    'Theatre': '#9370DB',    // Medium purple
    'Shore Excursion': '#20B2AA', // Light sea green
    'Other': '#708090',      // Slate gray
  };

  // ==================== Message Settings ====================

  /// Duration before messages expire in pod chats
  static const Duration messageExpiryDuration = Duration(hours: 10);

  // ==================== Validation ====================

  /// Regex pattern for email validation
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Regex pattern for name validation (letters, spaces, hyphens, apostrophes)
  static final RegExp nameRegex = RegExp(
    r"^[a-zA-Z\s\-']+$",
  );

  /// Minimum password length
  static const int minPasswordLength = 6;

  // ==================== Error Messages ====================

  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String noSailingSelected = 'Please select a sailing first';
  static const String authError = 'Authentication error. Please sign in again.';
  static const String permissionDenied = 'Permission denied. Please check your access.';

  // ==================== Empty State Messages ====================

  static const String noHangoutsMessage = 'No active hangouts right now.\nBe the first to create one!';
  static const String noMessagesMessage = 'No messages yet.\nStart the conversation!';
  static const String noPodsMessage = 'No pods available.\nCheck back later!';
  static const String noVotesMessage = 'No votes yet.\nBe the first to vote!';

  // ==================== Social Media Platforms ====================

  static const List<String> socialPlatforms = [
    'Instagram',
    'Snapchat',
    'TikTok',
    'Twitter',
  ];

  /// Social media icons (using material icons names)
  static const Map<String, String> socialIcons = {
    'Instagram': 'camera_alt',
    'Snapchat': 'chat_bubble',
    'TikTok': 'music_note',
    'Twitter': 'alternate_email',
  };

  // ==================== Pod Colors ====================

  static const Map<String, String> podColors = {
    'Nightlife': '#6B2D5C',     // Deep purple
    'Fitness': '#2E7D32',       // Forest green
    'Excursions': '#1565C0',    // Ocean blue
    'Relaxation': '#00ACC1',    // Cyan
    'Food & Dining': '#EF6C00', // Orange
    'Sports': '#C62828',        // Red
    'Photography': '#6A1B9A',   // Purple
    'Music': '#AD1457',         // Pink
    'Casino': '#F9A825',        // Gold
    'On Island Hangout': '#00897B', // Teal
  };

  // ==================== Firestore Collection Names ====================

  static const String usersCollection = 'users';
  static const String sailingsCollection = 'sailings';
  static const String podsCollection = 'pods';
  static const String membersCollection = 'members';
  static const String messagesCollection = 'messages';
  static const String hangoutsCollection = 'hangouts';
  static const String hotZoneVotesCollection = 'hotZoneVotes';

  // ==================== UI Constants ====================

  /// Default border radius for cards
  static const double cardBorderRadius = 12.0;

  /// Default padding for screens
  static const double screenPadding = 16.0;

  /// Default spacing between elements
  static const double defaultSpacing = 16.0;

  /// Small spacing between elements
  static const double smallSpacing = 8.0;

  /// Large spacing between sections
  static const double largeSpacing = 24.0;

  // ==================== Animation Durations ====================

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
