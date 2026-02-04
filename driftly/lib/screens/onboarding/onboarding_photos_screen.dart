import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

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
    if (source == ImageSourceChoice.camera) {
      photo = await _storageService.takePhoto();
    } else {
      photo = await _storageService.pickImageFromGallery();
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
    final photo = await _storageService.takePhoto();
    if (photo != null) {
      setState(() {
        _verificationPhoto = photo;
        _verificationStep = 2; // Completed
      });
    }
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
      appBar: AppBar(
        title: Text(_showVerification ? 'Verify Your Face' : 'Add Your Photos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _showVerification
            ? _buildVerificationView()
            : _buildPhotoUploadView(),
      ),
    );
  }

  Widget _buildPhotoUploadView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: 2 / 4, // Step 2 of 4
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 32),

          // Header
          const Text(
            'Show us who you are!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload 3 photos to help others get to know you',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
                color: _allPhotosSelected ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _allPhotosSelected
                    ? 'All photos added!'
                    : '${[_facePhoto, _funPhoto, _wildcardPhoto].where((p) => p != null).length}/3 photos added',
                style: TextStyle(
                  color: _allPhotosSelected ? Colors.green : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Continue Button
          ElevatedButton(
            onPressed: _allPhotosSelected && !_isUploading
                ? _handleContinue
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Continue to Verification',
              style: TextStyle(fontSize: 16),
            ),
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
          // Progress Indicator
          LinearProgressIndicator(
            value: 2.5 / 4,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 32),

          // Header
          const Text(
            'Quick Face Verification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us make sure you\'re a real person',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Face photo reference
          if (_facePhoto != null) ...[
            const Text(
              'Your profile photo:',
              style: TextStyle(fontWeight: FontWeight.w500),
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
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
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
                    color: _isVerified
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isVerified ? 'Verified!' : _currentPose,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _isVerified
                          ? Colors.green
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!_isVerified) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Take a selfie doing this pose',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Verification photo or button
          if (_verificationPhoto != null) ...[
            const Text(
              'Your verification selfie:',
              style: TextStyle(fontWeight: FontWeight.w500),
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
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
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
              icon: const Icon(Icons.refresh),
              label: const Text('Retake Photo'),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _takeVerificationPhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Verification Selfie'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Continue Button
          ElevatedButton(
            onPressed: _isVerified && !_isUploading ? _handleContinue : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            child: _isUploading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Complete Setup',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
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
            child: const Text('Back to Photos'),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo preview or placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: photo != null
                      ? null
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  image: photo != null
                      ? DecorationImage(
                          image: FileImage(photo),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photo == null
                    ? Icon(
                        icon,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
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
                          ),
                        ),
                        if (isRequired) ...[
                          const SizedBox(width: 4),
                          const Text(
                            '*',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Status icon
              Icon(
                photo != null ? Icons.check_circle : Icons.add_a_photo,
                color: photo != null ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ImageSourceChoice { camera, gallery }
