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
}
