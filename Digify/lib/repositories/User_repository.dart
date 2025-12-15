import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/user_data.dart';

class UserRepository {
  final _firestore = FirebaseFirestore.instance;
  final String collection = "users";

  Future<void> createUser(UserModel user) async {
    await _firestore.collection(collection).doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(collection).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection(collection).doc(uid).delete();
  }

  Future<String> generateUniqueUsername(String displayName) async {
    String username = "";
    bool exists = true;

    while (exists) {
      int tag = Random().nextInt(90000) + 10000; // random 5-digit
      username = "$displayName#$tag";

      final query = await _firestore
          .collection(collection)
          .where("username", isEqualTo: username)
          .get();

      exists = query.docs.isNotEmpty;
    }

    return username;
  }

  Future<List<UserModel>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];
    // Firestore 'where in' supports up to 10 items. For more, we need to batch or loop.
    // For simplicity, assuming < 10 friends for now or we can split.
    // Actually, getting by document ID with whereIn is FieldPath.documentId

    List<UserModel> users = [];

    // Split into chunks of 10
    for (var i = 0; i < uids.length; i += 10) {
      var end = (i + 10 < uids.length) ? i + 10 : uids.length;
      var chunk = uids.sublist(i, end);

      final query = await _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      users.addAll(
          query.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)));
    }

    return users;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final query = await _firestore
        .collection(collection)
        .where('username', isEqualTo: username)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  Future<void> addFriend(String currentUserId, String friendId) async {
    // Add friend to current user's friend list
    await _firestore.collection(collection).doc(currentUserId).update({
      'friends': FieldValue.arrayUnion([friendId])
    });

    // Add current user to friend's friend list (Two-way friendship)
    await _firestore.collection(collection).doc(friendId).update({
      'friends': FieldValue.arrayUnion([currentUserId])
    });
  }

  Future<void> removeFriend(String currentUserId, String friendId) async {
    // Remove friend from current user's friend list
    await _firestore.collection(collection).doc(currentUserId).update({
      'friends': FieldValue.arrayRemove([friendId])
    });

    // Remove current user from friend's friend list
    await _firestore.collection(collection).doc(friendId).update({
      'friends': FieldValue.arrayRemove([currentUserId])
    });
  }

  Future<void> addServerJoined(String userId, String communityId) async {
    print(
        "REPO: Adding community '$communityId' to user '$userId' serversJoined");
    try {
      await _firestore.collection(collection).doc(userId).update({
        'serversJoined': FieldValue.arrayUnion([communityId])
      });
      print("REPO: Added to serversJoined successfully");
    } catch (e) {
      print("REPO: Error adding to serversJoined: $e");
      rethrow;
    }
  }

  Future<void> removeServerJoined(String userId, String communityId) async {
    print(
        "REPO: Removing community '$communityId' from user '$userId' serversJoined");
    try {
      await _firestore.collection(collection).doc(userId).update({
        'serversJoined': FieldValue.arrayRemove([communityId])
      });
      print("REPO: Removed from serversJoined successfully");
    } catch (e) {
      print("REPO: Error removing from serversJoined: $e");
      rethrow;
    }
  }
}
