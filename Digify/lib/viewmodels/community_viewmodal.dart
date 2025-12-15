import 'package:flutter/foundation.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/repositories/community_repository.dart';
import 'package:digify/repositories/channel_repository.dart';
import 'package:digify/modal_classes/channels.dart';
import 'package:uuid/uuid.dart';

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
    print("VM: assignRole called");
    _setLoading(true);
    _setError(null);

    final result = await _repository.assignRole(communityId, userId, role);

    _setLoading(false);

    if (result.error != null) {
      print("VM: assignRole failed: ${result.error}");
      _setError(result.error);
      return false;
    }
    // Ideally we re-fetch community here to update state
    print("VM: assignRole success, fetching community...");
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

  // Create a new role and associated channel
  Future<bool> createRoleAndChannel(
      String communityId, String roleName, String firstUserId) async {
    _setLoading(true);
    _setError(null);

    try {
      // 1. Add Role to Community
      final roleResult = await _repository.addRole(communityId, roleName);
      if (roleResult.error != null) {
        _setError(roleResult.error);
        _setLoading(false);
        return false;
      }

      // 2. Create Channel for the Role
      final ChannelRepository channelRepo = ChannelRepository();
      final String channelId = const Uuid().v1();
      final newChannel = ChannelModel(
        uid: channelId,
        communityId: communityId,
        name: roleName, // Channel name same as role
        users: [
          firstUserId
        ], // Add the user to the channel immediately (as requested)
        canTalk: true, // Defaulting to true
        createdat: DateTime.now(),
      );

      final channelResult = await channelRepo.createChannel(newChannel);
      if (channelResult.error != null) {
        // If channel creation fails, we might want to revert the role addition?
        // For now, let's just error out.
        _setError(
            "Role created but channel creation failed: ${channelResult.error}");
        _setLoading(false);
        return false;
      }

      // 3. Assign Role to User
      final assignResult =
          await _repository.assignRole(communityId, firstUserId, roleName);
      if (assignResult.error != null) {
        _setError(
            "Role & Channel created but assignment failed: ${assignResult.error}");
        _setLoading(false);
        return false;
      }

      // 4. Update the admins list if needed?
      // The requirement doesn't explicitly say "Make them admin", just assign the role.
      // But if the role implies specific permissions, that's separate.
      // We'll stick to just assigning the text role.

      // Success
      await fetchCommunity(communityId); // Refresh local state
      _setLoading(false);
      return true;
    } catch (e) {
      _setError("Unexpected error: $e");
      _setLoading(false);
      return false;
    }
  }
}
