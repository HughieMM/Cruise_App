import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// StorageService
///
/// Handles all Firebase Storage operations for user photos
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Take photo with camera
  Future<File?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Upload user profile photo
  /// Returns the download URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
    required String photoType, // 'face', 'fun', 'wildcard', 'verification'
  }) async {
    try {
      final String fileName = '${photoType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users/$userId/photos/$fileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Upload multiple photos
  /// Returns a map of photo type to download URL
  Future<Map<String, String>> uploadMultiplePhotos({
    required String userId,
    required Map<String, File> photos, // {'face': file, 'fun': file, 'wildcard': file}
  }) async {
    final Map<String, String> urls = {};

    for (final entry in photos.entries) {
      final url = await uploadProfilePhoto(
        userId: userId,
        file: entry.value,
        photoType: entry.key,
      );
      urls[entry.key] = url;
    }

    return urls;
  }

  /// Delete a photo from storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final Reference ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      // Ignore if file doesn't exist
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get all user photos
  Future<List<String>> getUserPhotoUrls(String userId) async {
    try {
      final ListResult result = await _storage.ref().child('users/$userId/photos').listAll();
      final List<String> urls = [];

      for (final Reference ref in result.items) {
        final String url = await ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to get user photos: $e');
    }
  }
}
