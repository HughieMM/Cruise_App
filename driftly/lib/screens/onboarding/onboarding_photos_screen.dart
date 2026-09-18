import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/pill_button.dart';
import 'widgets/onboarding_step_header.dart';

/// Onboarding Photos Screen
///
/// Requires users to upload 3 photos:
/// 1. Face photo (main profile) - used for verification
/// 2. Fun/personality photo
/// 3. Wildcard photo
///
/// Then performs face verification with a random pose prompt
class OnboardingPhotosScreen extends StatefulWidget {
  const OnboardingPhotosScreen({super.key});

  @override
  State<OnboardingPhotosScreen> createState() => _OnboardingPhotosScreenState();
}

class _OnboardingPhotosScreenState extends State<OnboardingPhotosScreen> {
  final StorageService _storageService = StorageService();

  File? _facePhoto;
  File? _funPhoto;
  File? _wildcardPhoto;
  File? _verificationPhoto;

  bool _isUploading = false;
  bool _showVerification = false;
  String _currentPose = '';
  int _verificationStep = 0;

  final List<Map<String, dynamic>> _posePrompts = [
    {'text': 'Smile for the camera!', 'icon': Icons.sentiment_very_satisfied},
    {'text': 'Turn your head slightly left', 'icon': Icons.turn_left},
    {'text': 'Give us a thumbs up!', 'icon': Icons.thumb_up},
    {'text': 'Look surprised!', 'icon': Icons.sentiment_satisfied},
    {'text': 'Wink at the camera', 'icon': Icons.remove_red_eye},
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomPose();
  }

  void _selectRandomPose() {
    final random = Random();
    final pose = _posePrompts[random.nextInt(_posePrompts.length)];
    setState(() {
      _currentPose = pose['text'] as String;
    });
  }

  Future<void> _pickPhoto(String type) async {
    final source = await showModalBottomSheet<ImageSourceChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Photo Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSourceChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSourceChoice.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    File? photo;
    try {
      if (source == ImageSourceChoice.camera) {
        photo = await _storageService.takePhoto();
      } else {
        photo = await _storageService.pickImageFromGallery();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get photo: $e')),
        );
      }
      return;
    }

    if (photo == null) return;

    setState(() {
      switch (type) {
        case 'face':
          _facePhoto = photo;
          break;
        case 'fun':
          _funPhoto = photo;
          break;
        case 'wildcard':
          _wildcardPhoto = photo;
          break;
      }
    });
  }

  Future<void> _takeVerificationPhoto() async {
    try {
      final photo = await _storageService.takePhoto();
      if (photo != null) {
        setState(() {
          _verificationPhoto = photo;
          _verificationStep = 2; // Completed
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not take photo: $e')),
        );
      }
    }
  }

  /// Debug-only bypass for verification, since the Simulator has no real
  /// camera. Never available in release builds.
  void _skipVerificationForDebug() {
    setState(() {
      _verificationPhoto = _facePhoto;
      _verificationStep = 2;
    });
  }

  bool get _allPhotosSelected =>
      _facePhoto != null && _funPhoto != null && _wildcardPhoto != null;

  bool get _isVerified => _verificationPhoto != null;

  Future<void> _handleContinue() async {
    if (!_allPhotosSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all 3 photos')),
      );
      return;
    }

    if (!_showVerification) {
      // Move to verification step
      setState(() {
        _showVerification = true;
        _verificationStep = 1;
      });
      return;
    }

    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete face verification')),
      );
      return;
    }

    // Upload all photos
    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.firebaseUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload photos
      final urls = await _storageService.uploadMultiplePhotos(
        userId: userId,
        photos: {
          'face': _facePhoto!,
          'fun': _funPhoto!,
          'wildcard': _wildcardPhoto!,
          'verification': _verificationPhoto!,
        },
      );

      // Update user profile with photo URLs
      final success = await authProvider.updateProfile({
        'facePhotoUrl': urls['face'],
        'funPhotoUrl': urls['fun'],
        'wildcardPhotoUrl': urls['wildcard'],
        'verificationPhotoUrl': urls['verification'],
        'selfieVerified': true,
        'selfieUrl': urls['face'], // Use face photo as main profile pic
      });

      if (!mounted) return;

      if (success) {
        context.go('/onboarding/sailing');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Failed to save photos'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        variant: BackgroundVariant.starfield,
        child: SafeArea(
          child: _showVerification
              ? _buildVerificationView()
              : _buildPhotoUploadView(),
        ),
      ),
    );
  }

  Widget _buildPhotoUploadView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(
            step: 2,
            title: 'Show us who you are',
            onBack: () => context.pop(),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload 3 photos to help others get to know you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),

          // Photo Cards
          _buildPhotoCard(
            title: 'Face Photo',
            subtitle: 'Clear shot of your face (used for verification)',
            icon: Icons.face,
            photo: _facePhoto,
            onTap: () => _pickPhoto('face'),
            isRequired: true,
          ),
          const SizedBox(height: 16),

          _buildPhotoCard(
            title: 'Fun Photo',
            subtitle: 'Show your personality! Something goofy or fun',
            icon: Icons.celebration,
            photo: _funPhoto,
            onTap: () => _pickPhoto('fun'),
            isRequired: true,
          ),
          const SizedBox(height: 16),

          _buildPhotoCard(
            title: 'Wildcard Photo',
            subtitle: 'Anything you want - hobby, travel, pet, etc.',
            icon: Icons.auto_awesome,
            photo: _wildcardPhoto,
            onTap: () => _pickPhoto('wildcard'),
            isRequired: true,
          ),
          const SizedBox(height: 32),

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _allPhotosSelected ? Icons.check_circle : Icons.circle_outlined,
                color: _allPhotosSelected ? AppColors.teal : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _allPhotosSelected
                    ? 'All photos added!'
                    : '${[_facePhoto, _funPhoto, _wildcardPhoto].where((p) => p != null).length}/3 photos added',
                style: TextStyle(
                  color: _allPhotosSelected ? AppColors.teal : Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Continue Button
          PillButton(
            label: 'Continue to Verification',
            color: AppColors.teal,
            onPressed: _allPhotosSelected && !_isUploading
                ? _handleContinue
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepHeader(
            step: 2,
            title: 'Verify Your Face',
            onBack: () => setState(() {
              _showVerification = false;
              _verificationPhoto = null;
              _verificationStep = 0;
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Quick Face Verification',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This helps us make sure you\'re a real person',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 32),

          // Face photo reference
          if (_facePhoto != null) ...[
            const Text(
              'Your profile photo:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _facePhoto!,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Verification prompt
          GlassCard(
            borderColor: _isVerified ? AppColors.teal : AppColors.tealBorder,
            tintColor: AppColors.tealTint,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  _isVerified
                      ? Icons.check_circle
                      : _posePrompts.firstWhere(
                          (p) => p['text'] == _currentPose,
                          orElse: () => {'icon': Icons.camera_alt},
                        )['icon'] as IconData,
                  size: 48,
                  color: AppColors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  _isVerified ? 'Verified!' : _currentPose,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!_isVerified) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Take a selfie doing this pose',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Verification photo or button
          if (_verificationPhoto != null) ...[
            const Text(
              'Your verification selfie:',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _verificationPhoto!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _selectRandomPose();
                setState(() {
                  _verificationPhoto = null;
                  _verificationStep = 1;
                });
              },
              icon: const Icon(Icons.refresh, color: AppColors.teal),
              label: const Text('Retake Photo', style: TextStyle(color: AppColors.teal)),
            ),
          ] else ...[
            PillButton(
              label: 'Take Verification Selfie',
              icon: Icons.camera_alt,
              color: AppColors.teal,
              onPressed: _takeVerificationPhoto,
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _skipVerificationForDebug,
                child: const Text('Skip Verification (Debug Only)'),
              ),
            ],
          ],
          const SizedBox(height: 32),

          // Continue Button
          PillButton(
            label: _isUploading ? '...' : 'Complete Setup',
            color: AppColors.teal,
            onPressed: _isVerified && !_isUploading ? _handleContinue : null,
          ),

          // Back button
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _showVerification = false;
                _verificationPhoto = null;
                _verificationStep = 0;
              });
            },
            child: const Text('Back to Photos', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? photo,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      showBlur: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo preview or placeholder
              photo != null
                  ? Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(photo),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : IconBadge(icon: icon, size: 80, borderRadius: 12),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: AppColors.coral),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),

              // Status icon
              Icon(
                photo != null ? Icons.check_circle : Icons.add_a_photo,
                color: photo != null ? AppColors.teal : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ImageSourceChoice { camera, gallery }
