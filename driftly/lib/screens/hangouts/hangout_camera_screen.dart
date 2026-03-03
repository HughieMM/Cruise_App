import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../services/badge_service.dart';

/// Camera-only photo capture for hangouts
///
/// Designed to capture authentic, in-the-moment photos
/// No camera roll access - only live camera capture
class HangoutCameraScreen extends StatefulWidget {
  final String hangoutId;
  final String sailingId;
  final String location;

  const HangoutCameraScreen({
    super.key,
    required this.hangoutId,
    required this.sailingId,
    required this.location,
  });

  @override
  State<HangoutCameraScreen> createState() => _HangoutCameraScreenState();
}

class _HangoutCameraScreenState extends State<HangoutCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  final BadgeService _badgeService = BadgeService();

  File? _capturedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Automatically open camera on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCamera();
    });
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, // Camera ONLY - no gallery
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85, // Good quality but reasonable file size
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      } else {
        // User cancelled - go back
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _uploadPhoto() async {
    if (_capturedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      if (user == null) throw Exception('User not found');

      // Upload to Firebase Storage
      final photoUrl = await _storageService.uploadHangoutPhoto(
        sailingId: widget.sailingId,
        hangoutId: widget.hangoutId,
        userId: user.uid,
        imageFile: _capturedImage!,
      );

      // Track badge progress for photo sharing
      final newBadge = await _badgeService.incrementStat(
        userId: user.uid,
        statName: 'photos_shared',
      );

      if (!mounted) return;

      // Show badge notification if earned
      if (newBadge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(newBadge.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Badge Earned!', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(newBadge.name),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      Navigator.of(context).pop(photoUrl);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isUploading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            const Text(
              'Share a Moment',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              widget.location,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _capturedImage == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Opening camera...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Photo preview
                Image.file(
                  _capturedImage!,
                  fit: BoxFit.contain,
                ),

                // Bottom action bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Retake button
                          _ActionButton(
                            icon: Icons.refresh,
                            label: 'Retake',
                            onPressed: _isUploading ? null : _openCamera,
                          ),

                          // Upload button
                          _ActionButton(
                            icon: Icons.check_circle,
                            label: 'Share',
                            isPrimary: true,
                            isLoading: _isUploading,
                            onPressed: _isUploading ? null : _uploadPhoto,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Info banner
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Camera only for authentic moments',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isPrimary ? Colors.blue : Colors.white24,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
