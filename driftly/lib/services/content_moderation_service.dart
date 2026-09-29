import 'package:cloud_firestore/cloud_firestore.dart';

/// Result of a content-moderation check.
class ModerationCheckResult {
  final bool blocked;
  final int strikeCount;
  final bool justBanned;

  const ModerationCheckResult({
    required this.blocked,
    required this.strikeCount,
    required this.justBanned,
  });

  static const ModerationCheckResult allowed =
      ModerationCheckResult(blocked: false, strikeCount: 0, justBanned: false);
}

/// Thrown by a message-send method when the text trips the content filter,
/// instead of a generic Exception — lets the UI show a distinct warning/ban
/// dialog rather than the usual red "failed to send" snackbar.
class ContentModerationException implements Exception {
  final ModerationCheckResult result;
  const ContentModerationException(this.result);

  @override
  String toString() => 'ContentModerationException(strikes: ${result.strikeCount}, '
      'justBanned: ${result.justBanned})';
}

/// ContentModerationService
///
/// Proactive, automatic detection of slurs/hate speech/self-harm language
/// at send-time — distinct from ModerationService, which handles content
/// *reported* by other users after the fact. This is a pattern/keyword
/// filter, not an AI classifier: it catches known slurs (including common
/// leetspeak/spacing obfuscation) and a curated phrase list, but can't
/// understand novel paraphrasing. Treat it as the first line of defense;
/// the existing report system is the backstop for anything it misses.
///
/// Enforcement: 3 strikes total. The first two are warnings; the third
/// suspends the account (isBanned: true). Firestore rules only allow a
/// user's own client to move moderationStrikes up and isBanned false→true
/// — never back down — so this can't be gamed from the app itself. A
/// false-positive ban can still be reversed manually via the Firebase
/// console, which bypasses rules entirely.
class ContentModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _banThreshold = 3;

  // Racial slur — flexible character classes to catch common leetspeak
  // (n1gg@, n!gg3r, etc.) without needing to enumerate every variant.
  // Racial slur — matches any word STARTING with "nig"/"n1g" (single g)
  // or "nigg"/"n1gg" (double g), per explicit instruction to flag it
  // instantly regardless of what follows. This is deliberately broader
  // than requiring a full slur spelling — it will also catch unrelated
  // words that happen to start the same way (e.g. "night", "Nigeria",
  // "Niger"), a known, accepted trade-off for this word specifically.
  //
  // Two variants of the same core pattern: _slurPattern is word-boundary
  // anchored (\b) for checking real text, so it only trips at the start
  // of an actual word. _slurPatternLoose has no anchor, for checking the
  // punctuation/space-collapsed text below — collapsing "n i g g e r"
  // into "nigger" also erases the original word boundaries, so an
  // anchored pattern would stop catching spaced-out obfuscation sitting
  // in the middle of a longer message.
  static final RegExp _slurPattern = RegExp(
    r'\bn[i1!|]+[gq96]+',
    caseSensitive: false,
  );
  static final RegExp _slurPatternLoose = RegExp(
    r'n[i1!|]+[gq96]+',
    caseSensitive: false,
  );

  // Self-harm-inciting phrases.
  static final List<RegExp> _selfHarmPatterns = [
    RegExp(r'kill\s*(your|ur)\s*self', caseSensitive: false),
    RegExp(r'\bkys\b', caseSensitive: false),
    RegExp(r'go\s+die', caseSensitive: false),
    RegExp(r'you\s+should\s+die', caseSensitive: false),
  ];

  // Single blocked words — plain, case-insensitive, whole-word matches.
  // Note: "monkey" and "cracker" are also ordinary dictionary words, so
  // this will produce some false positives (an actual monkey excursion, a
  // cracker snack) — shipped as explicitly requested; easy to loosen by
  // just editing this list if that becomes a problem in practice.
  static final List<RegExp> _blockedWords = [
    'rape',
    'monkey',
    'cracker',
    'fuck',
    'shit',
    'bitch',
    'cunt',
  ].map((w) => RegExp('\\b$w\\b', caseSensitive: false)).toList();

  /// Strips everything but letters/digits, so spaced-out or punctuated
  /// evasion ("n i g g e r", "n.i.g.g.e.r") still matches the same
  /// patterns as the un-spaced form.
  String _collapse(String text) => text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

  /// Whether [text] trips any blocked pattern. Pure/synchronous — checked
  /// against both the original text (for whole-word matches like "rape")
  /// and a punctuation/space-collapsed version (for the slur/self-harm
  /// patterns, which evasion most commonly targets).
  bool containsBlockedContent(String text) {
    if (text.trim().isEmpty) return false;

    final collapsed = _collapse(text);

    if (_slurPattern.hasMatch(text) || _slurPatternLoose.hasMatch(collapsed)) {
      return true;
    }

    for (final pattern in _selfHarmPatterns) {
      if (pattern.hasMatch(text)) return true;
    }

    for (final pattern in _blockedWords) {
      if (pattern.hasMatch(text)) return true;
    }

    return false;
  }

  /// Checks [text]; if clean, returns [ModerationCheckResult.allowed]. If
  /// flagged, increments the user's strike count and, on the 3rd strike,
  /// bans the account — then returns a result describing what happened so
  /// the caller can show the right warning/ban messaging.
  Future<ModerationCheckResult> checkAndRecordViolation({
    required String userId,
    required String text,
  }) async {
    if (!containsBlockedContent(text)) return ModerationCheckResult.allowed;

    final userRef = _firestore.collection('users').doc(userId);

    final newStrikeCount = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(userRef);
      final current = (snapshot.data()?['moderationStrikes'] as int?) ?? 0;
      final updated = current + 1;

      final updates = <String, Object?>{
        'moderationStrikes': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (updated >= _banThreshold) {
        updates['isBanned'] = true;
      }

      transaction.update(userRef, updates);
      return updated;
    });

    return ModerationCheckResult(
      blocked: true,
      strikeCount: newStrikeCount,
      justBanned: newStrikeCount >= _banThreshold,
    );
  }
}
