/// DailyPrompt Model
///
/// Represents a daily conversation prompt for pods
/// Prompts are category-based and rotate daily
class DailyPrompt {
  final String id;
  final String podCategory; // Maps to pod type/interest
  final String prompt;
  final String emoji;
  final int dayIndex; // 0-6 for weekly rotation

  const DailyPrompt({
    required this.id,
    required this.podCategory,
    required this.prompt,
    required this.emoji,
    required this.dayIndex,
  });

  @override
  String toString() {
    return 'DailyPrompt(category: $podCategory, prompt: $prompt)';
  }
}

/// Daily prompts organized by pod category
class DailyPrompts {
  DailyPrompts._();

  /// Get today's prompt for a specific pod category
  static DailyPrompt? getTodaysPrompt(String podName) {
    final category = _mapPodToCategory(podName);
    final prompts = _promptsByCategory[category];
    if (prompts == null || prompts.isEmpty) return null;

    // Use day of year for rotation
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final index = dayOfYear % prompts.length;
    return prompts[index];
  }

  /// Map pod name to a prompt category
  static String _mapPodToCategory(String podName) {
    final name = podName.toLowerCase();

    if (name.contains('gym') || name.contains('fitness')) {
      return 'fitness';
    } else if (name.contains('night') || name.contains('party')) {
      return 'nightlife';
    } else if (name.contains('drink') || name.contains('bar') || name.contains('chill')) {
      return 'drinks';
    } else if (name.contains('excursion') || name.contains('explorer') || name.contains('adventure')) {
      return 'excursions';
    } else if (name.contains('sport') || name.contains('game')) {
      return 'sports';
    }

    return 'general';
  }

  /// Prompts organized by category
  static const Map<String, List<DailyPrompt>> _promptsByCategory = {
    'fitness': [
      DailyPrompt(
        id: 'fit_1',
        podCategory: 'fitness',
        prompt: 'What\'s your go-to workout to stay active on vacation?',
        emoji: '💪',
        dayIndex: 0,
      ),
      DailyPrompt(
        id: 'fit_2',
        podCategory: 'fitness',
        prompt: 'Early bird gym session or sunset workout - which are you?',
        emoji: '🌅',
        dayIndex: 1,
      ),
      DailyPrompt(
        id: 'fit_3',
        podCategory: 'fitness',
        prompt: 'Best workout playlist song? Drop your recommendation!',
        emoji: '🎵',
        dayIndex: 2,
      ),
      DailyPrompt(
        id: 'fit_4',
        podCategory: 'fitness',
        prompt: 'What\'s your fitness goal for this cruise?',
        emoji: '🎯',
        dayIndex: 3,
      ),
      DailyPrompt(
        id: 'fit_5',
        podCategory: 'fitness',
        prompt: 'Favorite post-workout meal on the ship?',
        emoji: '🍌',
        dayIndex: 4,
      ),
      DailyPrompt(
        id: 'fit_6',
        podCategory: 'fitness',
        prompt: 'Anyone up for a group workout challenge today?',
        emoji: '🏋️',
        dayIndex: 5,
      ),
      DailyPrompt(
        id: 'fit_7',
        podCategory: 'fitness',
        prompt: 'Cardio or weights - what\'s your preference?',
        emoji: '⚡',
        dayIndex: 6,
      ),
    ],
    'nightlife': [
      DailyPrompt(
        id: 'night_1',
        podCategory: 'nightlife',
        prompt: 'What\'s everyone wearing tonight?',
        emoji: '👗',
        dayIndex: 0,
      ),
      DailyPrompt(
        id: 'night_2',
        podCategory: 'nightlife',
        prompt: 'Best song to get the party started?',
        emoji: '🎶',
        dayIndex: 1,
      ),
      DailyPrompt(
        id: 'night_3',
        podCategory: 'nightlife',
        prompt: 'Club or lounge vibes tonight?',
        emoji: '🎵',
        dayIndex: 2,
      ),
      DailyPrompt(
        id: 'night_4',
        podCategory: 'nightlife',
        prompt: 'What time are we hitting the dance floor?',
        emoji: '💃',
        dayIndex: 3,
      ),
      DailyPrompt(
        id: 'night_5',
        podCategory: 'nightlife',
        prompt: 'Best party memory from this trip so far?',
        emoji: '🎉',
        dayIndex: 4,
      ),
      DailyPrompt(
        id: 'night_6',
        podCategory: 'nightlife',
        prompt: 'Pre-game plans before hitting the club?',
        emoji: '🪩',
        dayIndex: 5,
      ),
      DailyPrompt(
        id: 'night_7',
        podCategory: 'nightlife',
        prompt: 'What\'s your signature dance move?',
        emoji: '🕺',
        dayIndex: 6,
      ),
    ],
    'drinks': [
      DailyPrompt(
        id: 'drink_1',
        podCategory: 'drinks',
        prompt: 'What\'s your signature drink order?',
        emoji: '🍹',
        dayIndex: 0,
      ),
      DailyPrompt(
        id: 'drink_2',
        podCategory: 'drinks',
        prompt: 'Poolside drinks or sunset bar - which spot today?',
        emoji: '🌴',
        dayIndex: 1,
      ),
      DailyPrompt(
        id: 'drink_3',
        podCategory: 'drinks',
        prompt: 'Best drink you\'ve discovered on the ship?',
        emoji: '🥂',
        dayIndex: 2,
      ),
      DailyPrompt(
        id: 'drink_4',
        podCategory: 'drinks',
        prompt: 'Frozen or on the rocks?',
        emoji: '🧊',
        dayIndex: 3,
      ),
      DailyPrompt(
        id: 'drink_5',
        podCategory: 'drinks',
        prompt: 'Coffee cocktail or tropical fruity drink?',
        emoji: '☕',
        dayIndex: 4,
      ),
      DailyPrompt(
        id: 'drink_6',
        podCategory: 'drinks',
        prompt: 'What\'s the vibe at your favorite bar right now?',
        emoji: '🍸',
        dayIndex: 5,
      ),
      DailyPrompt(
        id: 'drink_7',
        podCategory: 'drinks',
        prompt: 'Anyone found a hidden gem bar on the ship?',
        emoji: '💎',
        dayIndex: 6,
      ),
    ],
    'excursions': [
      DailyPrompt(
        id: 'exc_1',
        podCategory: 'excursions',
        prompt: 'What excursion are you most excited about?',
        emoji: '🏝️',
        dayIndex: 0,
      ),
      DailyPrompt(
        id: 'exc_2',
        podCategory: 'excursions',
        prompt: 'Beach day or adventure tour - what\'s your pick?',
        emoji: '⛱️',
        dayIndex: 1,
      ),
      DailyPrompt(
        id: 'exc_3',
        podCategory: 'excursions',
        prompt: 'Best photo spot you\'ve found on shore?',
        emoji: '📸',
        dayIndex: 2,
      ),
      DailyPrompt(
        id: 'exc_4',
        podCategory: 'excursions',
        prompt: 'Anyone want to explore together at the next port?',
        emoji: '🗺️',
        dayIndex: 3,
      ),
      DailyPrompt(
        id: 'exc_5',
        podCategory: 'excursions',
        prompt: 'Best local food you\'ve tried on shore?',
        emoji: '🍽️',
        dayIndex: 4,
      ),
      DailyPrompt(
        id: 'exc_6',
        podCategory: 'excursions',
        prompt: 'Water sports or land activities?',
        emoji: '🚤',
        dayIndex: 5,
      ),
      DailyPrompt(
        id: 'exc_7',
        podCategory: 'excursions',
        prompt: 'Share your top shore day tip!',
        emoji: '💡',
        dayIndex: 6,
      ),
    ],
    'sports': [
      DailyPrompt(
        id: 'sport_1',
        podCategory: 'sports',
        prompt: 'Who\'s up for a game today?',
        emoji: '🏀',
        dayIndex: 0,
      ),
      DailyPrompt(
        id: 'sport_2',
        podCategory: 'sports',
        prompt: 'Basketball, volleyball, or mini golf?',
        emoji: '⛳',
        dayIndex: 1,
      ),
      DailyPrompt(
        id: 'sport_3',
        podCategory: 'sports',
        prompt: 'Anyone want to organize a tournament?',
        emoji: '🏆',
        dayIndex: 2,
      ),
      DailyPrompt(
        id: 'sport_4',
        podCategory: 'sports',
        prompt: 'What sport would you add to a cruise ship?',
        emoji: '🎯',
        dayIndex: 3,
      ),
      DailyPrompt(
        id: 'sport_5',
        podCategory: 'sports',
        prompt: 'Morning or evening game session?',
        emoji: '🌙',
        dayIndex: 4,
      ),
      DailyPrompt(
        id: 'sport_6',
        podCategory: 'sports',
        prompt: 'What\'s your best sports deck moment so far?',
        emoji: '🙌',
        dayIndex: 5,
      ),
      DailyPrompt(
        id: 'sport_7',
        podCategory: 'sports',
        prompt: 'Team sports or 1v1 competition?',
        emoji: '🤝',
        dayIndex: 6,
      ),
    ],
    'general': [
      DailyPrompt(
        id: 'gen_1',
        podCategory: 'general',
        prompt: 'What\'s your favorite thing about cruising?',
        emoji: '🚢',
        dayIndex: 0,
      ),
      DailyPrompt(
        id: 'gen_2',
        podCategory: 'general',
        prompt: 'What are you looking forward to today?',
        emoji: '✨',
        dayIndex: 1,
      ),
      DailyPrompt(
        id: 'gen_3',
        podCategory: 'general',
        prompt: 'Share your best cruise tip!',
        emoji: '💡',
        dayIndex: 2,
      ),
      DailyPrompt(
        id: 'gen_4',
        podCategory: 'general',
        prompt: 'What\'s the highlight of your trip so far?',
        emoji: '🌟',
        dayIndex: 3,
      ),
      DailyPrompt(
        id: 'gen_5',
        podCategory: 'general',
        prompt: 'Where would you love to cruise next?',
        emoji: '🗺️',
        dayIndex: 4,
      ),
      DailyPrompt(
        id: 'gen_6',
        podCategory: 'general',
        prompt: 'What\'s surprised you most about this cruise?',
        emoji: '😮',
        dayIndex: 5,
      ),
      DailyPrompt(
        id: 'gen_7',
        podCategory: 'general',
        prompt: 'Best way to meet new people on a cruise?',
        emoji: '👋',
        dayIndex: 6,
      ),
    ],
  };

  /// Get all prompts for a category
  static List<DailyPrompt> getPromptsForCategory(String category) {
    return _promptsByCategory[category] ?? _promptsByCategory['general']!;
  }
}
