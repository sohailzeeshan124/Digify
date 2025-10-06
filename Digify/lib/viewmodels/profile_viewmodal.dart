// lib/viewmodels/profile_viewmodel.dart
import 'dart:io';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileViewModel {
  final _repo = UserRepository();

  final cloudinary_repo = CloudinaryRepository();

  Future<void> completeProfile({
    required String uid,
    required String legalName,
    required String displayName,
    //   required String phone,
    required DateTime dob,
    File? cnicFront,
    File? cnicBack,
    File? signatureFile,
  }) async {
    // 1) upload files (if any)
    String? frontUrl, backUrl, sigUrl;
    if (cnicFront != null) {
      final f = await cloudinary_repo.uploadImage(cnicFront.path,
          folder: "digify/cnic");
      if (f != null && f.secureUrl != null) {
        frontUrl = f.secureUrl; // use secureUrl instead of ['url']
      }
    }
    if (cnicBack != null) {
      final b = await cloudinary_repo.uploadImage(cnicBack.path,
          folder: "digify/cnic");

      if (b != null && b.secureUrl != null) {
        backUrl = b.secureUrl; // use secureUrl instead of ['url']
      }
    }
    if (signatureFile != null) {
      final s = await cloudinary_repo.uploadSignature(signatureFile.path);

      if (s != null && s.secureUrl != null) {
        sigUrl = s.secureUrl; // use secureUrl instead of ['url']
      }
    }

    String uniqueUsername = await _repo.generateUniqueUsername(displayName);

    final user = UserModel(
      uid: uid,
      fullName: legalName,
      username: uniqueUsername,
      dateOfBirth: dob,
      cnicFrontUrl: frontUrl,
      cnicBackUrl: backUrl,
      signatureUrl: sigUrl,
      signatureLocalPath: signatureFile?.path,
      email: FirebaseAuth.instance.currentUser!.email.toString(),
      createdAt: getCurrentDate(),
      isGoogleDriveLinked: false,
    );

    await _repo.createUser(user);
  }

  DateTime getCurrentDate() {
    return DateTime.now();
  }
}
