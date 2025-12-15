import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/repositories/user_repository.dart';
import 'package:flutter/foundation.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repo = UserRepository();

  Future<void> createUser(UserModel user) async {
    await _repo.createUser(user);
  }

  Future<UserModel?> getUser(String uid) async {
    return await _repo.getUser(uid);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _repo.updateUser(uid, data);
  }

  Future<void> deleteUser(String uid) async {
    await _repo.deleteUser(uid);
  }

  Future<List<UserModel>> getUsers(List<String> uids) async {
    return await _repo.getUsers(uids);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    return await _repo.getUserByUsername(username);
  }

  Future<void> addFriend(String currentUserId, String friendId) async {
    await _repo.addFriend(currentUserId, friendId);
  }

  Future<void> removeFriend(String currentUserId, String friendId) async {
    await _repo.removeFriend(currentUserId, friendId);
  }

  Future<void> addServerJoined(String userId, String communityId) async {
    await _repo.addServerJoined(userId, communityId);
  }

  Future<void> removeServerJoined(String userId, String communityId) async {
    await _repo.removeServerJoined(userId, communityId);
  }
}
