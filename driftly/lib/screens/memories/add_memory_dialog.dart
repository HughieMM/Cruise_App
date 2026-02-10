import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/cruise_memory.dart';
import '../../models/sailing.dart';

/// Dialog for adding a new cruise memory photo
class AddMemoryDialog extends StatefulWidget {
  final MemoryMilestone milestone;
  final Sailing sailing;
  final VoidCallback onMemoryAdded;

  const AddMemoryDialog({
    super.key,
    required this.milestone,
    required this.sailing,
    required this.onMemoryAdded,
  });

  @override
  State<AddMemoryDialog> createState() => _AddMemoryDialogState();
}

class _AddMemoryDialogState extends State<AddMemoryDialog> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadMemory() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;

      if (user == null) throw Exception('User not found');

      // Upload photo to Firebase Storage
      final photoUrl = await _storageService.uploadMemoryPhoto(
        userId: user.uid,
        sailingId: widget.sailing.id,
        milestone: widget.milestone.name,
        imageFile: _selectedImage!,
      );

      // Calculate day number
      final dayNumber = DateTime.now().difference(widget.sailing.departureDate).inDays + 1;

      // Create memory in Firestore
      await _firestoreService.addCruiseMemory(
        sailingId: widget.sailing.id,
        userId: user.uid,
        milestone: widget.milestone,
        photoUrl: photoUrl,
        caption: _captionController.text.trim().isEmpty 
            ? null 
            : _captionController.text.trim(),
        dayNumber: dayNumber,
      );

      if (!mounted) return;

      Navigator.pop(context);
      widget.onMemoryAdded();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.milestone.displayName} memory saved!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save memory: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(
                  widget.milestone.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.milestone.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.milestone.promptMessage,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Photo preview/picker
            GestureDetector(
              onTap: _isUploading ? null : _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[700]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setState(() => _selectedImage = null);
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to add photo',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Caption field
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                hintText: 'Add a caption (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              maxLines: 2,
              maxLength: 200,
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isUploading ? null : _uploadMemory,
                  child: _isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Memory'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
