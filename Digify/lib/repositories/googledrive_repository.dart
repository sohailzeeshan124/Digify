// import 'dart:io';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:googleapis/drive/v3.dart' as drive;
// import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';

// class GoogleDriveRepository {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       drive.DriveApi.driveFileScope, // Needed for uploading files
//     ],
//   );

//   /// 🔹 Sign in and link Google Drive
//   Future<GoogleSignInAccount?> linkGoogleDrive() async {
//     try {
//       final account = await _googleSignIn.signIn();
//       if (account == null) {
//         print("⚠️ User cancelled sign-in");
//         return null;
//       }
//       print("✅ Signed in as: ${account.email}");
//       return account;
//     } catch (e) {
//       print("❌ Error in linkGoogleDrive: $e");
//       return null;
//     }
//   }

//   /// 🔹 Disconnect Google Drive
//   Future<void> unlinkGoogleDrive() async {
//     try {
//       await _googleSignIn.disconnect();
//       print("✅ Disconnected from Google Drive");
//     } catch (e) {
//       print("❌ Error in unlinkGoogleDrive: $e");
//     }
//   }

//   /// 🔹 Get currently signed-in account
//   Future<GoogleSignInAccount?> getCurrentAccount() async {
//     try {
//       return await _googleSignIn.signInSilently();
//     } catch (e) {
//       print("❌ Error in getCurrentAccount: $e");
//       return null;
//     }
//   }

//   /// 🔹 Upload file to Google Drive
//   Future<String?> uploadFileToDrive(File file, String fileName) async {
//     try {
//       final account = await _googleSignIn.signInSilently();
//       if (account == null) {
//         throw Exception("⚠️ Google Drive not linked. Please sign in first.");
//       }

//       // Get authentication headers
//       final authHeaders = await account.authHeaders;
//       final authenticateClient = GoogleAuthClient(authHeaders);

//       final driveApi = drive.DriveApi(authenticateClient);

//       final driveFile = drive.File()
//         ..name = fileName
//         ..parents = ["root"]; // You can change this to a folder ID

//       final uploadedFile = await driveApi.files.create(
//         driveFile,
//         uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
//       );

//       print("✅ File uploaded successfully. Drive File ID: ${uploadedFile.id}");
//       return uploadedFile.id;
//     } catch (e) {
//       print("❌ Error in uploadFileToDrive: $e");
//       return null;
//     }
//   }
// }

// /// 🔹 Helper client for authenticated Google API requests
// class GoogleAuthClient extends http.BaseClient {
//   final Map<String, String> _headers;
//   final http.Client _client = IOClient();

//   GoogleAuthClient(this._headers);

//   @override
//   Future<http.StreamedResponse> send(http.BaseRequest request) {
//     request.headers.addAll(_headers);
//     return _client.send(request);
//   }
// }
