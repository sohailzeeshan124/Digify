// import 'package:digify/repositories/googledrive_repository.dart';
// import 'package:digify/repositories/user_repository.dart';
// import 'package:flutter/foundation.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class GoogleDriveViewModel extends ChangeNotifier {
//   final GoogleDriveRepository _driveRepo;
//   final UserRepository _userRepo;

//   bool _isLinked = false;
//   String? _driveEmail;

//   bool get isLinked => _isLinked;
//   String? get driveEmail => _driveEmail;

//   GoogleDriveViewModel(this._driveRepo, this._userRepo);

//   /// Link Google Drive account
//   Future<void> linkDrive(String uid) async {
//     try {
//       GoogleSignInAccount? account = await _driveRepo.linkGoogleDrive();
//       if (account != null) {
//         _isLinked = true;
//         _driveEmail = account.email;

//         // Save info in Firestore
//         await _userRepo.updateUser(uid, {
//           'isGoogleDriveLinked': true,
//           'googleDriveEmail': account.email,
//         });

//         notifyListeners();
//       }
//     } catch (e) {
//       debugPrint("Error linking Google Drive: $e");
//       rethrow;
//     }
//   }

//   /// Unlink Google Drive account
//   Future<void> unlinkDrive(String uid) async {
//     try {
//       await _driveRepo.unlinkGoogleDrive();

//       _isLinked = false;
//       _driveEmail = null;

//       await _userRepo.updateUser(uid, {
//         'isGoogleDriveLinked': false,
//         'googleDriveEmail': null,
//       });

//       notifyListeners();
//     } catch (e) {
//       debugPrint("Error unlinking Google Drive: $e");
//       rethrow;
//     }
//   }

//   /// Restore current signed in account (if available)
//   Future<void> checkCurrentAccount() async {
//     GoogleSignInAccount? account = await _driveRepo.getCurrentAccount();
//     _isLinked = account != null;
//     _driveEmail = account?.email;
//     notifyListeners();
//   }
// }
