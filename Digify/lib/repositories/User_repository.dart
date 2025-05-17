import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modalclasses/User_modal.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user data to Firestore
  Future<bool> saveUserData(UserData userData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userData.userId)
          .set(userData.toMap());
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Fetch user data from Firestore
  Future<UserData?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserData.fromFirestore(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // 🔥 Delete user data from Firestore
  Future<bool> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      return true;
      // ignore: dead_code
      print('User data deleted successfully.');
    } catch (e) {
      return false;
      // ignore: dead_code
      print('Error deleting user data: $e');
    }
  }
}
