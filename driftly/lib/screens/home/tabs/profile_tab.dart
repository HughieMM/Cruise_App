import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/badge_service.dart';
import '../../../models/pod.dart';
import '../../../models/sailing.dart';
import '../../../models/achievement_badge.dart';
import '../../../utils/constants.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/badges_display.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/avatar_progress_ring.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/small_caps_label.dart';
import '../../settings/notification_preferences_screen.dart';

/// Helper to get cruise line background image path
String _getCruiseLineBackground(String? cruiseLineId) {
  if (cruiseLineId == null) return 'assets/images/background.png';

  final id = cruiseLineId.toLowerCase();
  if (id.contains('royal') || id.contains('caribbean')) {
    return 'assets/images/royal_caribbean_bg.png';
  } else if (id.contains('carnival')) {
    return 'assets/images/carnival_bg.png';
  } else if (id.contains('ncl') || id.contains('norwegian')) {
    return 'assets/images/ncl_bg.png';
  }
  return 'assets/images/background.png';
}

/// Helper to get a short cruise line badge (shown as a watermark behind
/// the profile avatar). Returns null for an unrecognized/no cruise line.
String? _getCruiseLineAbbreviation(String? cruiseLineId) {
  if (cruiseLineId == null) return null;

  final id = cruiseLineId.toLowerCase();
  if (id.contains('royal') || id.contains('caribbean')) return 'RCL';
  if (id.contains('carnival')) return 'CCL';
  if (id.contains('ncl') || id.contains('norwegian')) return 'NCL';
  return null;
}

/// Cruise-line-branded fallback for the Edit Profile cover-photo box when
/// no custom cover photo has been set — (label, color) or null if the
/// cruise line is unrecognized/not yet chosen.
(String, Color)? _getCruiseLineAccent(String? cruiseLineId) {
  if (cruiseLineId == null) return null;

  final id = cruiseLineId.toLowerCase();
  if (id.contains('carnival')) return ('CRVL', AppColors.carnivalRed);
  if (id.contains('ncl') || id.contains('norwegian')) return ('NCL', AppColors.norwegianGreen);
  if (id.contains('royal') || id.contains('caribbean')) return ('RCL', AppColors.royalBlue);
  return null;
}

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

enum _CoverPhotoSource { camera, gallery }

class _ProfileTabState extends State<ProfileTab> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  List<Pod>? _userPods;
  Sailing? _sailing;
  bool _isLoadingExtras = true;
  bool _isUploadingCoverPhoto = false;

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

  Future<void> _changeCoverPhoto(BuildContext context, AuthProvider authProvider) async {
    final source = await showModalBottomSheet<_CoverPhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Cover Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, _CoverPhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, _CoverPhotoSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    File? photo;
    try {
      photo = source == _CoverPhotoSource.camera
          ? await _storageService.takePhoto()
          : await _storageService.pickImageFromGallery();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get photo: $e')),
        );
      }
      return;
    }

    if (photo == null) return;

    setState(() => _isUploadingCoverPhoto = true);
    try {
      final url = await _storageService.uploadProfilePhoto(
        userId: authProvider.appUser!.uid,
        file: photo,
        photoType: 'cover',
      );
      final success = await authProvider.updateProfile({'coverPhotoUrl': url});
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update cover photo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update cover photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCoverPhoto = false);
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

        final backgroundImage = _getCruiseLineBackground(_sailing?.cruiseLineId);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showSettingsSheet(context),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Cruise-line photo once the real asset exists; falls back to
              // a themed gradient (rather than a blank/broken page) until
              // then, or for an unrecognized cruise line.
              Image.asset(
                backgroundImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.3),
                      radius: 1.3,
                      colors: [Color(0xFF12293D), AppColors.background],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
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

                        // Achievement Badges
                        _buildBadgesCard(user.uid),
                        const SizedBox(height: 16),

                        // Interests
                        _buildInterestsCard(user.interests, () => _showEditProfileDialog(context, user, authProvider)),
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
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user, AuthProvider authProvider) {
    final backgroundImage = _getCruiseLineBackground(_sailing?.cruiseLineId);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Banner — the user's own cover photo once set, otherwise
              // falls back to the cruise-line background/gradient.
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (user.coverPhotoUrl != null)
                      Image.network(
                        user.coverPhotoUrl as String,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          backgroundImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF12293D), AppColors.background],
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Image.asset(
                        backgroundImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF12293D), AppColors.background],
                            ),
                          ),
                        ),
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                    if (_isUploadingCoverPhoto)
                      const ColoredBox(
                        color: Colors.black45,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    else
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: () => _changeCoverPhoto(context, authProvider),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.45),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Profile content
              Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_getCruiseLineAbbreviation(_sailing?.cruiseLineId) != null)
                          Container(
                            width: 152,
                            height: 152,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.teal.withValues(alpha: 0.22),
                                  AppColors.teal.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _getCruiseLineAbbreviation(_sailing?.cruiseLineId)!,
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                            ),
                          ),
                        AvatarWithProgressRing(
                          imageUrl: user.selfieUrl,
                          fallbackInitial:
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          percent: user.profileCompletionPercent as double,
                          size: 108,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: ${user.ageBand}',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                    if (user.selfieVerified) ...[
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: AppColors.teal),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Social Links
                    if (user.socialLinks != null && (user.socialLinks as Map).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: (user.socialLinks as Map<String, String>).entries.map((entry) {
                          return _SocialLinkButton(
                            platform: entry.key,
                            handle: entry.value,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: PillButton(
                        label: 'Edit Profile',
                        icon: Icons.edit,
                        variant: PillVariant.outlined,
                        color: Colors.white,
                        onPressed: () => _showEditProfileDialog(context, user, authProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterestsCard(List<String> interests, VoidCallback onEditInterests) {
    return GlassCard(
      borderColor: AppColors.tealBorder,
      tintColor: AppColors.tealTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...interests.map((interest) => Chip(
                    label: Text(interest),
                    labelStyle: const TextStyle(color: AppColors.teal),
                    backgroundColor: AppColors.tealTint,
                    side: const BorderSide(color: AppColors.teal),
                  )),
              ActionChip(
                label: const Text('+ Add more'),
                labelStyle: TextStyle(color: Colors.grey[400]),
                backgroundColor: Colors.transparent,
                side: BorderSide(color: Colors.grey[600]!, style: BorderStyle.solid),
                onPressed: onEditInterests,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesCard(String userId) {
    return GlassCard(
      borderColor: AppColors.pinkBorder,
      tintColor: AppColors.pinkTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Achievement Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => _showAllBadgesDialog(userId),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BadgesRow(
            userId: userId,
            onViewAll: () => _showAllBadgesDialog(userId),
          ),
        ],
      ),
    );
  }

  void _showAllBadgesDialog(String userId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pinkTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.pinkBorder),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'All Badges',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keep participating to unlock more badges!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      child: BadgesDisplay(
                        userId: userId,
                        showAll: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSailingCard() {
    if (_isLoadingExtras) {
      return GlassCard(
        borderColor: AppColors.pinkBorder,
        tintColor: AppColors.pinkTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Sailing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
      );
    }

    if (_sailing == null) {
      return GlassCard(
        borderColor: AppColors.pinkBorder,
        tintColor: AppColors.pinkTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Sailing',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No sailing selected',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final dateStr = DateFormat('dd MMM yyyy').format(_sailing!.departureDate);

    return GlassCard(
      borderColor: AppColors.pinkBorder,
      tintColor: AppColors.pinkTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Sailing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
    );
  }

  Widget _buildPodsCard() {
    if (_isLoadingExtras) {
      return GlassCard(
        borderColor: AppColors.tealBorder,
        tintColor: AppColors.tealTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Pods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
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
      );
    }

    return GlassCard(
      borderColor: AppColors.tealBorder,
      tintColor: AppColors.tealTint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Pods',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (_userPods == null || _userPods!.isEmpty)
            Text(
              'No pods joined yet',
              style: TextStyle(color: Colors.grey[400]),
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
        Icon(icon, size: 20, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        child: SingleChildScrollView(
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
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect with fellow cruisers, join interest-based pods, create spontaneous hangouts, and make your cruise experience unforgettable!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[300]),
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/terms-of-service');
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/privacy-policy');
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
    bool isUploadingCover = false;

    // Social links controllers
    final socialLinks = Map<String, String>.from(user.socialLinks ?? {});
    final Map<String, TextEditingController> socialControllers = {};
    for (final platform in AppConstants.socialPlatforms) {
      socialControllers[platform] = TextEditingController(text: socialLinks[platform] ?? '');
    }

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

                  // Cover Photo
                  const Text(
                    'Cover Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: isUploadingCover
                        ? null
                        : () async {
                            setModalState(() => isUploadingCover = true);
                            await _changeCoverPhoto(context, authProvider);
                            setModalState(() => isUploadingCover = false);
                          },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Builder(builder: (context) {
                          if (isUploadingCover) {
                            return const ColoredBox(
                              color: Colors.black45,
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            );
                          }

                          final coverPhotoUrl = authProvider.appUser?.coverPhotoUrl;
                          if (coverPhotoUrl != null) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(coverPhotoUrl, fit: BoxFit.cover),
                                const _CoverPhotoEditBadge(),
                              ],
                            );
                          }

                          final accent = _getCruiseLineAccent(_sailing?.cruiseLineId);
                          if (accent != null) {
                            final (label, color) = accent;
                            return Container(
                              color: color,
                              alignment: Alignment.center,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Center(
                                    child: Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const _CoverPhotoEditBadge(),
                                ],
                              ),
                            );
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(color: Colors.grey[700]!),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: Icon(Icons.add_a_photo, color: Colors.grey[500]),
                                ),
                                const _CoverPhotoEditBadge(),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
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
                          color: AppColors.tealTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: AppColors.teal, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: AppColors.teal,
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
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cake, color: Colors.grey[400]),
                        const SizedBox(width: 12),
                        Text(
                          selectedAgeBand ?? 'Not set',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
                          color: selectedInterests.length >= 3 ? AppColors.teal : Colors.grey[400],
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

                  // Social Links Section
                  const Text(
                    'Social Links',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your social handles so others can connect with you',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...AppConstants.socialPlatforms.map((platform) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: socialControllers[platform],
                        decoration: InputDecoration(
                          labelText: platform,
                          hintText: 'Your $platform username',
                          prefixIcon: Icon(_getSocialIcon(platform)),
                          prefixIconColor: _getSocialColor(platform),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

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

                      // Collect non-empty social links
                      final updatedSocialLinks = <String, String>{};
                      for (final platform in AppConstants.socialPlatforms) {
                        final handle = socialControllers[platform]?.text.trim() ?? '';
                        if (handle.isNotEmpty) {
                          // Remove @ symbol if user included it
                          updatedSocialLinks[platform] = handle.startsWith('@')
                              ? handle.substring(1)
                              : handle;
                        }
                      }

                      final success = await authProvider.updateProfile({
                        'name': nameController.text.trim(),
                        'ageBand': selectedAgeBand,
                        'interests': selectedInterests.toList(),
                        'socialLinks': updatedSocialLinks,
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
    // Navigate to full notification preferences screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isDeleting = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Delete Account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action cannot be undone. Your profile, photos, and pod memberships will be permanently deleted.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !isDeleting,
                  decoration: InputDecoration(
                    labelText: 'Confirm your password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        if (passwordController.text.isEmpty) {
                          setDialogState(() => errorText = 'Please enter your password');
                          return;
                        }
                        setDialogState(() {
                          isDeleting = true;
                          errorText = null;
                        });

                        final success = await authProvider.deleteAccount(passwordController.text);

                        if (!dialogContext.mounted) return;

                        if (success) {
                          Navigator.pop(dialogContext);
                          if (context.mounted) {
                            context.go('/auth');
                          }
                        } else {
                          setDialogState(() {
                            isDeleting = false;
                            errorText = authProvider.errorMessage ?? 'Failed to delete account';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete Account'),
              ),
            ],
          );
        },
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
        'question': 'What are Vibes / Hot Zones?',
        'answer': 'Vibes shows you the current vibe at different locations around the ship, voted on by fellow cruisers in real-time.',
      },
      {
        'question': 'Why can I only see people in my age group?',
        'answer': 'To ensure a comfortable experience, Tribes and Pods are matched within your age group so you can connect with people in a similar life stage.',
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
                            style: TextStyle(color: Colors.grey[300]),
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
                Icon(Icons.email, color: Colors.grey[400], size: 20),
                const SizedBox(width: 8),
                const Text('support@driftlyapp.com'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[400], size: 20),
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
    _showFeedbackDialog(
      context,
      type: 'bug',
      title: 'Report a Bug',
      prompt: 'Describe the issue you encountered:',
      hintText: 'What went wrong?',
      thanksMessage: 'Thank you! Bug report submitted.',
    );
  }

  void _showSuggestFeatureDialog(BuildContext context) {
    _showFeedbackDialog(
      context,
      type: 'feature',
      title: 'Suggest a Feature',
      prompt: 'What feature would you like to see?',
      hintText: 'Describe your idea...',
      thanksMessage: 'Thank you! Feature suggestion submitted.',
    );
  }

  void _showFeedbackDialog(
    BuildContext context, {
    required String type,
    required String title,
    required String prompt,
    required String hintText,
    required String thanksMessage,
  }) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messageController = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prompt),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  enabled: !isSubmitting,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                  ),
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final message = messageController.text.trim();
                        if (message.isEmpty) {
                          setDialogState(() => errorText = 'Please enter a description');
                          return;
                        }

                        final user = authProvider.appUser;
                        if (user == null) return;

                        setDialogState(() {
                          isSubmitting = true;
                          errorText = null;
                        });

                        try {
                          await _firestoreService.submitFeedback(
                            userId: user.uid,
                            userName: user.name,
                            type: type,
                            message: message,
                          );

                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(thanksMessage)),
                          );
                        } catch (e) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() {
                            isSubmitting = false;
                            errorText = 'Failed to submit: $e';
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'snapchat':
        return Icons.chat_bubble;
      case 'tiktok':
        return Icons.music_note;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return Icons.link;
    }
  }

  Color _getSocialColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'tiktok':
        return const Color(0xFF00F2EA);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return Colors.blue;
    }
  }
}

/// Small camera badge overlaid on the Edit Profile cover-photo preview box,
/// hinting that it's tappable.
class _CoverPhotoEditBadge extends StatelessWidget {
  const _CoverPhotoEditBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
      ),
    );
  }
}

/// Social link button for profile display
class _SocialLinkButton extends StatelessWidget {
  final String platform;
  final String handle;

  const _SocialLinkButton({
    required this.platform,
    required this.handle,
  });

  IconData _getIcon() {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'snapchat':
        return Icons.chat_bubble;
      case 'tiktok':
        return Icons.music_note;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return Icons.link;
    }
  }

  Color _getColor() {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'tiktok':
        return const Color(0xFF00F2EA);
      case 'twitter':
        return const Color(0xFF1DA1F2);
      default:
        return Colors.blue;
    }
  }

  Future<void> _openSocialLink() async {
    String? url;
    switch (platform.toLowerCase()) {
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'snapchat':
        url = 'https://snapchat.com/add/$handle';
        break;
      case 'tiktok':
        url = 'https://tiktok.com/@$handle';
        break;
      case 'twitter':
        url = 'https://twitter.com/$handle';
        break;
    }
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return GestureDetector(
      onTap: _openSocialLink,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIcon(), size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '@$handle',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
