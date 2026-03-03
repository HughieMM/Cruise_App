import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_preferences.dart';

/// Notification Preferences Screen
///
/// Allows users to customize which notifications they receive
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (user != null) {
      try {
        final userData = await _firestoreService.getUser(user.uid);
        if (userData != null && mounted) {
          setState(() {
            // Load from user's notificationPreferences field
            _preferences = NotificationPreferences.fromMap(
              userData.toMap()['notificationPreferences'] as Map<String, dynamic>?,
            );
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      await _firestoreService.updateUser(
        user.uid,
        {'notificationPreferences': _preferences.toMap()},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updatePreference(NotificationPreferences newPrefs) {
    setState(() {
      _preferences = newPrefs;
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, color: Colors.blue[400]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Choose which notifications you want to receive',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Memories Section
                _buildSectionHeader('Memories'),
                _buildSwitchTile(
                  icon: Icons.camera_alt,
                  title: 'Daily Photo Reminders',
                  subtitle: 'Get reminded to capture cruise moments',
                  value: _preferences.dailyPhotoReminders,
                  onChanged: (value) {
                    _updatePreference(
                      _preferences.copyWith(dailyPhotoReminders: value),
                    );
                  },
                ),
                const Divider(),

                // Social Section
                _buildSectionHeader('Social'),
                _buildSwitchTile(
                  icon: Icons.chat_bubble,
                  title: 'Pod Messages',
                  subtitle: 'New messages in your pods',
                  value: _preferences.podMessages,
                  onChanged: (value) {
                    _updatePreference(
                      _preferences.copyWith(podMessages: value),
                    );
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.location_on,
                  title: 'Hangout Updates',
                  subtitle: 'When people join hangouts near you',
                  value: _preferences.hangoutUpdates,
                  onChanged: (value) {
                    _updatePreference(
                      _preferences.copyWith(hangoutUpdates: value),
                    );
                  },
                ),
                _buildSwitchTile(
                  icon: Icons.groups,
                  title: 'Tribe Activity',
                  subtitle: 'Updates from your cruise tribe',
                  value: _preferences.tribeActivity,
                  onChanged: (value) {
                    _updatePreference(
                      _preferences.copyWith(tribeActivity: value),
                    );
                  },
                ),
                const Divider(),

                // Discover Section
                _buildSectionHeader('Discover'),
                _buildSwitchTile(
                  icon: Icons.whatshot,
                  title: 'Hot Zone Alerts',
                  subtitle: 'When locations get popular',
                  value: _preferences.hotZoneAlerts,
                  onChanged: (value) {
                    _updatePreference(
                      _preferences.copyWith(hotZoneAlerts: value),
                    );
                  },
                ),
                const Divider(),

                // Achievements Section
                _buildSectionHeader('Achievements'),
                _buildSwitchTile(
                  icon: Icons.emoji_events,
                  title: 'Badge Earned',
                  subtitle: 'When you earn a new badge',
                  value: _preferences.badgeEarned,
                  onChanged: (value) {
                    _updatePreference(
                      _preferences.copyWith(badgeEarned: value),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Saving indicator
                if (_isSaving)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[400],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }
}
