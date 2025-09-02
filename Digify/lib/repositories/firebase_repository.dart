import 'package:firebase_auth/firebase_auth.dart';

class Firebase_Repository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<AuthResult> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return AuthResult(user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Please log in instead.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Please choose a stronger one.';
      } else {
        message = 'Sign up failed. Please try again.';
      }
      return AuthResult(errorMessage: message);
    } catch (e) {
      return AuthResult(errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception("No account found for this email.");
      } else if (e.code == 'wrong-password') {
        throw Exception("Wrong password entered.");
      } else if (e.code == 'invalid-email') {
        throw Exception("Invalid email format.");
      } else {
        throw Exception("Sign in failed: ${e.message}");
      }
    } catch (e) {
      throw Exception("Sign in failed: $e");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent");
    } catch (e) {
      print("Error sending password reset email: $e");
      rethrow;
    }
  }
}

class AuthResult {
  final User? user;
  final String? errorMessage;

  AuthResult({this.user, this.errorMessage});

  bool get isSuccess => user != null;
}
