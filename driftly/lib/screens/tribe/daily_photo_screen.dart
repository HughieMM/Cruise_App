import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tribe_provider.dart';
import '../../services/storage_service.dart';

/// Daily Photo Screen (BeReal-style)
///
/// Users take a photo in response to the daily prompt.
/// Features:
/// - Random daily prompt time (10am-10pm during cruise)
/// - Shows response time after submission
/// - View tribe members' daily photos
class DailyPhotoScreen extends StatefulWidget {
  final DateTime promptedAt;

  const DailyPhotoScreen({
    super.key,
    required this.promptedAt,
  });

  @override
  State<DailyPhotoScreen> createState() => _DailyPhotoScreenState();
}

class _DailyPhotoScreenState extends State<DailyPhotoScreen> {
  final StorageService _storageService = StorageService();
  File? _photo;
  bool _isUploading = false;
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final photo = await _storageService.takePhoto();
    if (photo != null) {
      setState(() => _photo = photo);
    }
  }

  Future<void> _submitPhoto() async {
    if (_photo == null) return;

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final tribeProvider = Provider.of<TribeProvider>(context, listen: false);
      final user = authProvider.appUser;

      if (user == null || user.currentSailingId == null) {
        throw Exception('User or sailing not found');
      }

      // Upload photo
      final photoUrl = await _storageService.uploadDailyPhoto(
        userId: user.uid,
        sailingId: user.currentSailingId!,
        photo: _photo!,
      );

      // Submit to tribe
      final success = await tribeProvider.submitDailyPhoto(
        sailingId: user.currentSailingId!,
        userId: user.uid,
        userName: user.name,
        userPhotoUrl: user.facePhotoUrl,
        photoUrl: photoUrl,
        caption: _captionController.text.trim().isNotEmpty
            ? _captionController.text.trim()
            : null,
        promptedAt: widget.promptedAt,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(_getResponseTimeMessage()),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tribeProvider.errorMessage ?? 'Failed to submit photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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

  String _getResponseTimeMessage() {
    final responseTime = DateTime.now().difference(widget.promptedAt);
    if (responseTime.inSeconds < 60) {
      return 'Photo posted in ${responseTime.inSeconds}s! Lightning fast!';
    } else if (responseTime.inMinutes < 5) {
      return 'Photo posted in ${responseTime.inMinutes}m! Quick response!';
    } else if (responseTime.inMinutes < 30) {
      return 'Photo posted in ${responseTime.inMinutes}m!';
    } else {
      return 'Photo posted! Better late than never!';
    }
  }

  String _getElapsedTime() {
    final elapsed = DateTime.now().difference(widget.promptedAt);
    if (elapsed.inSeconds < 60) {
      return '${elapsed.inSeconds}s';
    } else if (elapsed.inMinutes < 60) {
      return '${elapsed.inMinutes}m ${elapsed.inSeconds % 60}s';
    } else {
      return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          children: [
            const Text(
              'Daily Pic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _getElapsedTime(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.blue.withOpacity(0.2),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Show your tribe what you\'re up to!',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),

            // Photo area
            Expanded(
              child: _photo == null
                  ? _buildCameraPrompt()
                  : _buildPhotoPreview(),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.all(24),
              child: _photo == null
                  ? _buildTakePhotoButton()
                  : _buildSubmitControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 3),
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 48,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Time for your daily pic!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to take a photo',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _photo!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Caption field
          TextField(
            controller: _captionController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Add a caption (optional)',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLength: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildTakePhotoButton() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitControls() {
    return Row(
      children: [
        // Retake button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _takePhoto,
            icon: const Icon(Icons.refresh),
            label: const Text('Retake'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Submit button
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _submitPhoto,
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(_isUploading ? 'Posting...' : 'Post to Tribe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
