import 'package:digify/modalclasses/User_modal.dart';
import 'package:digify/repositories/User_repository.dart';
import 'package:flutter/material.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  UserData? _userData;

  UserData? get userData => _userData;

  // Save user data
  Future<bool> saveUserData(UserData userData) async {
    try {
      await _userRepository.saveUserData(userData);
      _userData = userData;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error saving user data in ViewModel: $e');
      return false;
    }
  }

  // Fetch user data
  Future<UserData?> fetchUserData(String userId) async {
    try {
      _userData = await _userRepository.getUserData(userId);
      notifyListeners();
      return _userData;
    } catch (e) {
      print('Error fetching user data in ViewModel: $e');
    }
    return null;
  }

  // Update user data (could be used to update profile)
  Future<bool> updateUserData(UserData userData) async {
    try {
      await _userRepository.saveUserData(userData);
      _userData = userData;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating user data in ViewModel: $e');
      return false;
    }
  }
}
