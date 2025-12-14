import 'package:flutter/foundation.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/repositories/community_repository.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityRepository _repository = CommunityRepository();

  bool _isLoading = false;
  String? _errorMessage;
  CommunityModel? _currentCommunity;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CommunityModel? get currentCommunity => _currentCommunity;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Create a new community
  Future<bool> createCommunity(CommunityModel community) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.createCommunity(community);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Fetch a specific community
  Future<void> fetchCommunity(String uid) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.getCommunity(uid);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
    } else if (result.data != null) {
      _currentCommunity = result.data;
      notifyListeners();
    }
  }

  // Update a community
  Future<bool> updateCommunity(CommunityModel community) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.updateCommunity(community);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }

    // Update local state if it matches the current community
    if (_currentCommunity?.uid == community.uid) {
      _currentCommunity = community;
      notifyListeners();
    }
    return true;
  }

  // Delete a community
  Future<bool> deleteCommunity(String uid) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.deleteCommunity(uid);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }

    if (_currentCommunity?.uid == uid) {
      _currentCommunity = null;
      notifyListeners();
    }
    return true;
  }

  // Assign a role to a user
  Future<bool> assignRole(
      String communityId, String userId, String role) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.assignRole(communityId, userId, role);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    // Ideally we re-fetch community here to update state
    await fetchCommunity(communityId);
    return true;
  }

  // Remove a user from community
  Future<bool> removeUser(String communityId, String userId) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.removeUser(communityId, userId);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    await fetchCommunity(communityId);
    return true;
  }

  // Add an admin
  Future<bool> addAdmin(String communityId, String userId) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.addAdmin(communityId, userId);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    await fetchCommunity(communityId);
    return true;
  }

  // Remove an admin
  Future<bool> removeAdmin(String communityId, String userId) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.removeAdmin(communityId, userId);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    await fetchCommunity(communityId);
    return true;
  }
}
