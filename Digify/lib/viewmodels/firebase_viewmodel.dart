import 'package:digify/repositories/firebase_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseViewModel extends ChangeNotifier {
  final _repository = Firebase_Repository();

  User? get currentUser => _repository.getCurrentUser();

  Future<User?> signIn(String email, String password) {
    return _repository.signIn(email, password);
  }

  Future<User?> signUp(String email, String password) {
    return _repository.signUp(email, password);
  }

  Future<void> updatePassword(String email) {
    return _repository.updatePassword(email);
  }

  User? getCurrentUser() {
    return _repository.getCurrentUser();
  }

  Future<void> signOut() {
    return _repository.signOut();
  }
}
