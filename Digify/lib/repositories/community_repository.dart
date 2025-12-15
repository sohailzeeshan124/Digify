import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/community.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class CommunityRepository {
  final _firestore = FirebaseFirestore.instance;

  // Create a new community
  Future<Result<void>> createCommunity(CommunityModel community) async {
    try {
      await _firestore
          .collection('communities')
          .doc(community.uid)
          .set(community.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error creating community: ${e.toString()}");
    }
  }

  // Get a community by UID
  Future<Result<CommunityModel>> getCommunity(String uid) async {
    try {
      final doc = await _firestore.collection('communities').doc(uid).get();
      if (doc.exists) {
        return Result.success(CommunityModel.fromMap(doc.data()!));
      } else {
        return Result.failure("Community not found");
      }
    } catch (e) {
      return Result.failure("Error getting community: ${e.toString()}");
    }
  }

  // Update a community
  Future<Result<void>> updateCommunity(CommunityModel community) async {
    try {
      await _firestore
          .collection('communities')
          .doc(community.uid)
          .update(community.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error updating community: ${e.toString()}");
    }
  }

  // Delete a community
  Future<Result<void>> deleteCommunity(String uid) async {
    try {
      await _firestore.collection('communities').doc(uid).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error deleting community: ${e.toString()}");
    }
  }

  // Assign a role to a user
  Future<Result<void>> assignRole(
      String communityId, String userId, String role) async {
    try {
      print(
          "REPO: Assigning role '$role' to user '$userId' in community '$communityId'");
      await _firestore.collection('communities').doc(communityId).update({
        'memberRoles.$userId': role,
      });
      print("REPO: Role assigned successfully");
      return Result.success(null);
    } catch (e) {
      print("REPO: Error assigning role: $e");
      return Result.failure("Error assigning role: ${e.toString()}");
    }
  }

  // Remove a user from the community (remove role mapping)
  Future<Result<void>> removeUser(String communityId, String userId) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'memberRoles.$userId': FieldValue.delete(),
        'admins': FieldValue.arrayRemove([userId]), // verify if admin too
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error removing user: ${e.toString()}");
    }
  }

  // Add an admin
  Future<Result<void>> addAdmin(String communityId, String userId) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'admins': FieldValue.arrayUnion([userId]),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error adding admin: ${e.toString()}");
    }
  }

  // Remove an admin
  Future<Result<void>> removeAdmin(String communityId, String userId) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'admins': FieldValue.arrayRemove([userId]),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error removing admin: ${e.toString()}");
    }
  }

  // Add a new role to the community
  Future<Result<void>> addRole(String communityId, String roleName) async {
    try {
      await _firestore.collection('communities').doc(communityId).update({
        'roles': FieldValue.arrayUnion([roleName]),
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error adding role: ${e.toString()}");
    }
  }
}
