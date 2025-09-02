import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/repositories/user_repository.dart';

class UserViewModel {
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
}
