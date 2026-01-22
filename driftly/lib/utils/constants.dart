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

  // ==================== Age Bands ====================

  static const List<String> ageBands = ['21-23', '24-27', '28-30'];

  static const String ageBand2123 = '21-23';
  static const String ageBand2427 = '24-27';
  static const String ageBand2830 = '28-30';

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

  // ==================== Micro Hangout Vibes ====================

  static const List<String> hangoutVibes = [
    'chill',
    'lively',
    'party',
  ];

  // ==================== Validation ====================

  /// Regex pattern for email validation
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Regex pattern for name validation (letters, spaces, hyphens, apostrophes)
  static final RegExp nameRegex = RegExp(
    r'^[a-zA-Z\s\-\']+$',
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
