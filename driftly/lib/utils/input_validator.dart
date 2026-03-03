import 'constants.dart';

/// Input validation and sanitization utilities
/// Prevents XSS, injection attacks, and ensures data integrity
class InputValidator {
  // Prevent instantiation
  InputValidator._();

  // ==================== Sanitization ====================

  /// Sanitize text input by removing potentially harmful characters
  /// Prevents XSS and script injection
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;

    // Remove null bytes
    String sanitized = input.replaceAll('\u0000', '');

    // Remove script tags and common XSS patterns
    sanitized = sanitized.replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'javascript:', caseSensitive: false), '');
    sanitized = sanitized.replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');

    // Trim whitespace
    sanitized = sanitized.trim();

    return sanitized;
  }

  /// Sanitize and truncate text to maximum length
  static String sanitizeAndTruncate(String input, int maxLength) {
    final sanitized = sanitizeText(input);
    if (sanitized.length <= maxLength) return sanitized;
    return sanitized.substring(0, maxLength);
  }

  // ==================== Validation ====================

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return AppConstants.emailRegex.hasMatch(email.trim());
  }

  /// Validate name (letters, spaces, hyphens, apostrophes only)
  static bool isValidName(String name) {
    if (name.isEmpty || name.length > AppConstants.maxNameLength) return false;
    return AppConstants.nameRegex.hasMatch(name.trim());
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }

  /// Validate message text
  static String? validateMessage(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    if (text.length > AppConstants.maxMessageLength) {
      return 'Message is too long (max ${AppConstants.maxMessageLength} characters)';
    }
    return null;
  }

  /// Validate location name
  static String? validateLocation(String? location) {
    if (location == null || location.trim().isEmpty) {
      return 'Location cannot be empty';
    }
    if (location.length > AppConstants.maxLocationLength) {
      return 'Location name is too long';
    }
    return null;
  }

  /// Validate user name
  static String? validateUserName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    if (!isValidName(name)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    if (name.length > AppConstants.maxNameLength) {
      return 'Name is too long (max ${AppConstants.maxNameLength} characters)';
    }
    return null;
  }

  /// Validate email
  static String? validateEmailField(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? validatePasswordField(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password cannot be empty';
    }
    if (!isValidPassword(password)) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    return null;
  }

  // ==================== Age Band Validation ====================

  /// Validate age is within cruise requirements (16+)
  static bool isValidAge(int age) {
    return age >= 16;
  }

  /// Get age band from age
  static String? getAgeBand(int age) {
    if (!isValidAge(age)) return null;
    if (age >= 16 && age <= 17) return AppConstants.ageBand1617;
    if (age >= 18 && age <= 20) return AppConstants.ageBand1820;
    if (age >= 21 && age <= 30) return AppConstants.ageBand2130;
    if (age >= 31 && age <= 39) return AppConstants.ageBand3139;
    if (age > 39) return AppConstants.ageBand39Plus;
    return null;
  }

  /// Validate age band string
  static bool isValidAgeBand(String? ageBand) {
    if (ageBand == null) return false;
    return AppConstants.ageBands.contains(ageBand);
  }

  // ==================== Hot Zones Validation ====================

  /// Validate hot zone location
  static bool isValidHotZoneLocation(String? location) {
    if (location == null) return false;
    return AppConstants.hotZoneLocations.contains(location);
  }

  /// Validate vibe option
  static bool isValidVibe(String? vibe) {
    if (vibe == null) return false;
    return AppConstants.vibeOptions.contains(vibe);
  }

  /// Validate hangout vibe
  static bool isValidHangoutVibe(String? vibe) {
    if (vibe == null) return false;
    return AppConstants.hangoutVibes.contains(vibe);
  }
}
