import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/repositories/user_repository.dart';

class UserViewModel {
  final UserRepository _repository = UserRepository();

  // Save user
  Future<void> saveUser(UserData user) async {
    await _repository.saveUser(user);
  }

  // Get user
  Future<UserData?> getUser(String userId) async {
    return await _repository.getUser(userId);
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _repository.deleteUser(userId);
  }
}
