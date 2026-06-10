import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isUserExist => _currentUser != null;
  bool get isInitialized => _isInitialized;

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Load user profile from database
  Future<void> loadUserProfile() async {
    if (_isLoading || _isInitialized) return;
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      _currentUser = await _userRepository.getUser();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Save user (for onboarding)
  Future<bool> saveUser(User user) async {
    if (_isLoading) return false;
    
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final id = await _userRepository.saveUser(user);
      if (id > 0) {
        _currentUser = user.copyWith(id: id);
        _isInitialized = true;
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? storeName,
    String? profileImage,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        storeName: storeName ?? _currentUser!.storeName,
        profileImage: profileImage,
        updatedAt: DateTime.now().toIso8601String(),
      );

      final result = await _userRepository.updateUser(updatedUser);
      if (result > 0) {
        _currentUser = updatedUser;
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Logout / reset user (optional)
  Future<void> resetUser() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      await _userRepository.deleteUser();
      _currentUser = null;
      _isInitialized = false;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }
}