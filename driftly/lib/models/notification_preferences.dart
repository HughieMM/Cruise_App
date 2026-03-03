/// NotificationPreferences Model
///
/// User preferences for push notifications
class NotificationPreferences {
  final bool dailyPhotoReminders;
  final bool podMessages;
  final bool hangoutUpdates;
  final bool tribeActivity;
  final bool hotZoneAlerts;
  final bool badgeEarned;

  const NotificationPreferences({
    this.dailyPhotoReminders = true,
    this.podMessages = true,
    this.hangoutUpdates = true,
    this.tribeActivity = true,
    this.hotZoneAlerts = true,
    this.badgeEarned = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();

    return NotificationPreferences(
      dailyPhotoReminders: map['dailyPhotoReminders'] as bool? ?? true,
      podMessages: map['podMessages'] as bool? ?? true,
      hangoutUpdates: map['hangoutUpdates'] as bool? ?? true,
      tribeActivity: map['tribeActivity'] as bool? ?? true,
      hotZoneAlerts: map['hotZoneAlerts'] as bool? ?? true,
      badgeEarned: map['badgeEarned'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyPhotoReminders': dailyPhotoReminders,
      'podMessages': podMessages,
      'hangoutUpdates': hangoutUpdates,
      'tribeActivity': tribeActivity,
      'hotZoneAlerts': hotZoneAlerts,
      'badgeEarned': badgeEarned,
    };
  }

  NotificationPreferences copyWith({
    bool? dailyPhotoReminders,
    bool? podMessages,
    bool? hangoutUpdates,
    bool? tribeActivity,
    bool? hotZoneAlerts,
    bool? badgeEarned,
  }) {
    return NotificationPreferences(
      dailyPhotoReminders: dailyPhotoReminders ?? this.dailyPhotoReminders,
      podMessages: podMessages ?? this.podMessages,
      hangoutUpdates: hangoutUpdates ?? this.hangoutUpdates,
      tribeActivity: tribeActivity ?? this.tribeActivity,
      hotZoneAlerts: hotZoneAlerts ?? this.hotZoneAlerts,
      badgeEarned: badgeEarned ?? this.badgeEarned,
    );
  }

  @override
  String toString() {
    return 'NotificationPreferences(dailyPhotoReminders: $dailyPhotoReminders, podMessages: $podMessages, hangoutUpdates: $hangoutUpdates)';
  }
}
