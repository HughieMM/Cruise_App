import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/tribe.dart';
import '../services/tribe_service.dart';

/// TribeProvider
///
/// Manages tribe state, sibling requests, and Sea Ya photos
class TribeProvider extends ChangeNotifier {
  final TribeService _tribeService = TribeService();

  Tribe? _currentTribe;
  List<TribeMember> _tribeMembers = [];
  List<SiblingRequest> _pendingRequests = [];
  List<SeaYaPhoto> _seaYaPhotos = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSubmittedSeaYa = false;

  StreamSubscription? _tribeSubscription;
  StreamSubscription? _membersSubscription;
  StreamSubscription? _photosSubscription;

  /// Getters
  Tribe? get currentTribe => _currentTribe;
  List<TribeMember> get tribeMembers => _tribeMembers;
  List<SiblingRequest> get pendingRequests => _pendingRequests;
  List<SeaYaPhoto> get seaYaPhotos => _seaYaPhotos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasTribe => _currentTribe != null;
  bool get hasSubmittedSeaYa => _hasSubmittedSeaYa;
  int get memberCount => _tribeMembers.length;

  @override
  void dispose() {
    _tribeSubscription?.cancel();
    _membersSubscription?.cancel();
    _photosSubscription?.cancel();
    super.dispose();
  }

  /// Initialize tribe data for a user
  Future<void> initializeTribe({
    required String sailingId,
    required String? tribeId,
    required String userId,
  }) async {
    if (tribeId == null) {
      _currentTribe = null;
      _tribeMembers = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load tribe
      _currentTribe = await _tribeService.getTribe(sailingId, tribeId);

      if (_currentTribe != null) {
        // Stream tribe updates
        _tribeSubscription?.cancel();
        _tribeSubscription = _tribeService
            .streamUserTribe(sailingId, tribeId)
            .listen((tribe) {
          _currentTribe = tribe;
          notifyListeners();
        });

        // Stream members
        _membersSubscription?.cancel();
        _membersSubscription = _tribeService
            .streamTribeMembers(sailingId, tribeId)
            .listen((members) {
          _tribeMembers = members;
          notifyListeners();
        });

        // Stream Sea Ya photos
        _photosSubscription?.cancel();
        _photosSubscription = _tribeService
            .streamTribeSeaYaPhotos(sailingId: sailingId, tribeId: tribeId)
            .listen((photos) {
          _seaYaPhotos = photos;
          notifyListeners();
        });

        // Check if user has submitted Sea Ya photo today
        _hasSubmittedSeaYa = await _tribeService.hasSubmittedSeaYaPhoto(
          sailingId: sailingId,
          userId: userId,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load tribe: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load pending sibling requests for user
  Future<void> loadPendingRequests({
    required String sailingId,
    required String email,
  }) async {
    try {
      _pendingRequests = await _tribeService.getPendingRequestsForEmail(
        sailingId,
        email,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load pending requests: $e');
    }
  }

  /// Create a sibling/friend request
  Future<bool> createSiblingRequest({
    required String sailingId,
    required String requesterId,
    required String requesterName,
    required String targetEmail,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _tribeService.createSiblingRequest(
        sailingId: sailingId,
        requesterId: requesterId,
        requesterName: requesterName,
        targetEmail: targetEmail,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Accept a sibling request
  Future<bool> acceptSiblingRequest({
    required String sailingId,
    required String requestId,
    required String targetId,
    required String targetName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _tribeService.acceptSiblingRequest(
        sailingId: sailingId,
        requestId: requestId,
        targetId: targetId,
        targetName: targetName,
      );

      // Remove from pending list
      _pendingRequests.removeWhere((r) => r.id == requestId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Decline a sibling request
  Future<bool> declineSiblingRequest({
    required String sailingId,
    required String requestId,
  }) async {
    try {
      await _tribeService.declineSiblingRequest(sailingId, requestId);

      // Remove from pending list
      _pendingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Submit Sea Ya photo
  Future<bool> submitSeaYaPhoto({
    required String sailingId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String photoUrl,
    String? caption,
    required DateTime promptedAt,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _tribeService.submitSeaYaPhoto(
        sailingId: sailingId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        tribeId: _currentTribe?.id,
        photoUrl: photoUrl,
        caption: caption,
        promptedAt: promptedAt,
      );

      _hasSubmittedSeaYa = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get sibling request status
  Future<SiblingRequest?> getSiblingRequest({
    required String sailingId,
    required String requestId,
  }) async {
    try {
      return await _tribeService.getSiblingRequest(sailingId, requestId);
    } catch (e) {
      debugPrint('Failed to get sibling request: $e');
      return null;
    }
  }

  /// Clear tribe data (on logout)
  void clearTribe() {
    _tribeSubscription?.cancel();
    _membersSubscription?.cancel();
    _photosSubscription?.cancel();
    _currentTribe = null;
    _tribeMembers = [];
    _pendingRequests = [];
    _seaYaPhotos = [];
    _hasSubmittedSeaYa = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
