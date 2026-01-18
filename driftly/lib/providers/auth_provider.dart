import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// AuthProvider
///
/// Manages authentication state and user profile data
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _firebaseUser;
  AppUser? _appUser;
  bool _isLoading = true;
  String? _errorMessage;

  /// Getters
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSignedIn => _firebaseUser != null;
  bool get hasProfile => _appUser != null;
  bool get isProfileComplete => _appUser?.isProfileComplete ?? false;

  AuthProvider() {
    _initAuthListener();
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // User signed in, load profile
        await _loadUserProfile(user.uid);
      } else {
        // User signed out
        _appUser = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      _appUser = await _firestoreService.getUser(uid);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load profile: $e';
      debugPrint(_errorMessage);
    }
    notifyListeners();
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      // User creation happens in auth state listener
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      // Profile loading happens in auth state listener
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      _appUser = null;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create user profile after sign-up
  Future<bool> createUserProfile({
    required String name,
    required String ageBand,
    required List<String> interests,
    bool selfieVerified = false,
  }) async {
    try {
      if (_firebaseUser == null) {
        throw Exception('No authenticated user');
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = AppUser(
        uid: _firebaseUser!.uid,
        email: _firebaseUser!.email ?? '',
        name: name,
        ageBand: ageBand,
        interests: interests,
        selfieVerified: selfieVerified,
        currentSailingId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestoreService.createUser(user);
      _appUser = user;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_firebaseUser == null) {
        throw Exception('No authenticated user');
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firestoreService.updateUser(_firebaseUser!.uid, data);
      await _loadUserProfile(_firebaseUser!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update current sailing
  Future<void> updateCurrentSailing(String sailingId) async {
    try {
      if (_firebaseUser == null) return;

      await _firestoreService.updateCurrentSailing(
        _firebaseUser!.uid,
        sailingId,
      );
      await _loadUserProfile(_firebaseUser!.uid);
    } catch (e) {
      _errorMessage = 'Failed to update sailing: $e';
      notifyListeners();
    }
  }

  /// Refresh user data from Firestore
  Future<void> refreshUserData() async {
    try {
      if (_firebaseUser == null) return;
      await _loadUserProfile(_firebaseUser!.uid);
    } catch (e) {
      _errorMessage = 'Failed to refresh user data: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
