import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/user_data.dart';

class UserRepository {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  // Create or update user
  Future<void> saveUser(UserData user) async {
    await users.doc(user.userId).set(user.toMap());
  }

  // Get user by ID
  Future<UserData?> getUser(String userId) async {
    final doc = await users.doc(userId).get();
    if (doc.exists) {
      return UserData.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await users.doc(userId).delete();
  }
}
