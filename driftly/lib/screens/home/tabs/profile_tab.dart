import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/pod.dart';
import '../../../models/sailing.dart';
import '../../../utils/constants.dart';

/// Profile Tab
///
/// Features:
/// - User profile info (name, age band, interests)
/// - Selfie/profile photo
/// - Sailing details (cruise line, ship, date)
/// - Joined pods
/// - Settings with sign out
/// - Edit profile functionality
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Pod>? _userPods;
  Sailing? _sailing;
  bool _isLoadingExtras = true;

  @override
  void initState() {
    super.initState();
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (user == null || user.currentSailingId == null) {
      setState(() => _isLoadingExtras = false);
      return;
    }

    try {
      final sailing = await _firestoreService.getSailing(user.currentSailingId!);
      final pods = await _firestoreService.getUserPodsForSailing(
        sailingId: user.currentSailingId!,
        userId: user.uid,
      );

      if (mounted) {
        setState(() {
          _sailing = sailing;
          _userPods = pods;
          _isLoadingExtras = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExtras = false);
      }
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatCruiseLineId(String id) {
    // Convert cruise_line_id to display name
    return id.split('_').map((word) =>
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  String _formatShipId(String id) {
    // Convert ship_id to display name
    return id.split('_').map((word) =>
      word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : ''
    ).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.appUser;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsSheet(context),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await authProvider.refreshUserData();
              await _loadExtras();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  _buildProfileHeader(context, user, authProvider),
                  const SizedBox(height: 16),

                  // Interests
                  _buildInterestsCard(user.interests),
                  const SizedBox(height: 16),

                  // Sailing Info
                  _buildSailingCard(),
                  const SizedBox(height: 16),

                  // My Pods
                  _buildPodsCard(),
                  const SizedBox(height: 24),

                  // Sign Out Button
                  _buildSignOutButton(context, authProvider),
                  const SizedBox(height: 16),

                  // App Version
                  Center(
                    child: Text(
                      'Driftly v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: user.selfieUrl != null
                  ? NetworkImage(user.selfieUrl!)
                  : null,
              child: user.selfieUrl == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Age: ${user.ageBand}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (user.selfieVerified) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showEditProfileDialog(context, user, authProvider),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestsCard(List<String> interests) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            interests.isEmpty
                ? Text(
                    'No interests selected',
                    style: TextStyle(color: Colors.grey[600]),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests
                        .map((interest) => Chip(
                              label: Text(interest),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            ))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSailingCard() {
    if (_isLoadingExtras) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Sailing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_sailing == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Sailing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No sailing selected',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final dateStr = DateFormat('dd MMM yyyy').format(_sailing!.departureDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Sailing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.directions_boat,
              'Cruise Line',
              _formatCruiseLineId(_sailing!.cruiseLineId),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.sailing, 'Ship', _formatShipId(_sailing!.shipId)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Sailing Date', dateStr),
          ],
        ),
      ),
    );
  }

  Widget _buildPodsCard() {
    if (_isLoadingExtras) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Pods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Pods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_userPods == null || _userPods!.isEmpty)
              Text(
                'No pods joined yet',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ..._userPods!.map((pod) {
                final color = _parseColor(pod.color);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPodBadge(pod.name, color),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context, AuthProvider authProvider) {
    return OutlinedButton.icon(
      onPressed: () => _showSignOutDialog(context, authProvider),
      icon: const Icon(Icons.logout),
      label: const Text('Sign Out'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.groups, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showNotificationsSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showPrivacySheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showHelpSupportSheet(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                _showSignOutDialog(context, authProvider);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.sailing,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Driftly',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with fellow cruisers, join interest-based pods, create spontaneous hangouts, and make your cruise experience unforgettable!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Terms of Service coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Privacy Policy coming soon')),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Made with ❤️ in Bermuda',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user, AuthProvider authProvider) {
    final nameController = TextEditingController(text: user.name);
    String? selectedAgeBand = user.ageBand;
    Set<String> selectedInterests = Set.from(user.interests);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Age Band (Read-only - verified during signup)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Age Band',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Text(
                          selectedAgeBand ?? 'Not set',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.lock, size: 16, color: Colors.grey[500]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age band cannot be changed after verification',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${selectedInterests.length}/5 selected',
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedInterests.length >= 3 ? Colors.green : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.availableInterests.map((interest) {
                      final isSelected = selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              if (selectedInterests.length < 5) {
                                selectedInterests.add(interest);
                              }
                            } else {
                              selectedInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name cannot be empty')),
                        );
                        return;
                      }

                      if (selectedAgeBand == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select an age band')),
                        );
                        return;
                      }

                      if (selectedInterests.length < 3) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select at least 3 interests')),
                        );
                        return;
                      }

                      final success = await authProvider.updateProfile({
                        'name': nameController.text.trim(),
                        'ageBand': selectedAgeBand,
                        'interests': selectedInterests.toList(),
                        'updatedAt': DateTime.now().toIso8601String(),
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authProvider.errorMessage ?? 'Failed to update profile'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    // These would normally be stored in user preferences/Firestore
    bool pushEnabled = true;
    bool chatNotifications = true;
    bool hangoutNotifications = true;
    bool podActivityNotifications = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Enable all push notifications'),
                  value: pushEnabled,
                  onChanged: (value) {
                    setModalState(() => pushEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Notification Types',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Chat Messages'),
                  subtitle: const Text('New messages in pod chats'),
                  value: chatNotifications && pushEnabled,
                  onChanged: pushEnabled
                      ? (value) => setModalState(() => chatNotifications = value)
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Hangouts'),
                  subtitle: const Text('New hangouts in your age group'),
                  value: hangoutNotifications && pushEnabled,
                  onChanged: pushEnabled
                      ? (value) => setModalState(() => hangoutNotifications = value)
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Pod Activity'),
                  subtitle: const Text('New members joining your pods'),
                  value: podActivityNotifications && pushEnabled,
                  onChanged: pushEnabled
                      ? (value) => setModalState(() => podActivityNotifications = value)
                      : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    bool showAgeBand = true;
    bool showInterests = true;
    bool allowMessages = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Privacy',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Profile Visibility',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Show Age Band'),
                  subtitle: const Text('Others can see your age group'),
                  value: showAgeBand,
                  onChanged: (value) => setModalState(() => showAgeBand = value),
                ),
                SwitchListTile(
                  title: const Text('Show Interests'),
                  subtitle: const Text('Others can see your interests'),
                  value: showInterests,
                  onChanged: (value) => setModalState(() => showInterests = value),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Communication',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Allow Direct Messages'),
                  subtitle: const Text('Let others message you directly'),
                  value: allowMessages,
                  onChanged: (value) => setModalState(() => allowMessages = value),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Permanently delete your account and data'),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteAccountDialog(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data, including your profile, messages, and hangouts will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion will be available soon'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Help & Support',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.question_answer_outlined),
                title: const Text('FAQs'),
                subtitle: const Text('Frequently asked questions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showFAQSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Contact Support'),
                subtitle: const Text('Get help from our team'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showContactSupportDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Report a Bug'),
                subtitle: const Text('Help us improve Driftly'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showReportBugDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('Suggest a Feature'),
                subtitle: const Text('Tell us what you\'d like to see'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showSuggestFeatureDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFAQSheet(BuildContext context) {
    final faqs = [
      {
        'question': 'What is Driftly?',
        'answer': 'Driftly is a social app for cruise passengers to connect with others on the same sailing. Join pods, create hangouts, and find your cruise crew!',
      },
      {
        'question': 'What are Pods?',
        'answer': 'Pods are interest-based groups where you can chat with other cruisers who share your interests like fitness, nightlife, or excursions.',
      },
      {
        'question': 'What are Hangouts?',
        'answer': 'Hangouts are spontaneous meetups you can create or join. They last 45 minutes and help you find people at specific locations on the ship.',
      },
      {
        'question': 'What are Hot Zones?',
        'answer': 'Hot Zones show you the current vibe at different locations around the ship, voted on by fellow cruisers in real-time.',
      },
      {
        'question': 'Why can I only see people in my age group?',
        'answer': 'To ensure a comfortable experience, hangouts are filtered by age group so you can connect with people in a similar life stage.',
      },
      {
        'question': 'Is my information private?',
        'answer': 'Yes! Only people on your same sailing can see your profile. You can also adjust privacy settings to control what others see.',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'FAQs',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final faq = faqs[index];
                    return ExpansionTile(
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            faq['answer']!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Reach out to us:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text('support@driftlyapp.com'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                const Text('Response within 24 hours'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReportBugDialog(BuildContext context) {
    final bugController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Describe the issue you encountered:'),
            const SizedBox(height: 16),
            TextField(
              controller: bugController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What went wrong?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (bugController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Bug report submitted.'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showSuggestFeatureDialog(BuildContext context) {
    final featureController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggest a Feature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What feature would you like to see?'),
            const SizedBox(height: 16),
            TextField(
              controller: featureController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your idea...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (featureController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Feature suggestion submitted.'),
                  ),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
