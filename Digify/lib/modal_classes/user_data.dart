import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;

  final DateTime dateOfBirth;

  String username; // fullname + random 4 digits at first
  String fullName;
  // String? phoneNumber;

  String? cnicFrontUrl;
  String? cnicBackUrl;

  String? signatureUrl;
  String? signatureLocalPath;

  String? stampUrl;
  String? stampLocalPath;

  String? profilePicUrl;

  String status; // online/offline/busy etc
  bool isDisabled;
  bool isEmailVerified;

  List<String> friends; // UIDs
  List<String> serversJoined; // serverIds

  DateTime createdAt;
  DateTime? lastLogin;

  List<Map<String, dynamic>> sessions;
  // Example: [{ "device": "Pixel 7", "ip": "192.168.1.2", "loggedInAt": "..."}]

  // Role inside each server will be defined in ServerModel
  Map<String, String> serverRoles;
  // { "serverId1": "member", "serverId2": "admin" }

  final bool isGoogleDriveLinked;
  final String? googleDriveEmail; // to show connected account

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.fullName,
    required this.dateOfBirth,
    //   this.phoneNumber,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.signatureUrl,
    this.signatureLocalPath,
    this.stampUrl,
    this.stampLocalPath,
    this.profilePicUrl,
    this.status = "offline",
    this.isDisabled = false,
    this.isEmailVerified = false,
    this.friends = const [],
    this.serversJoined = const [],
    this.sessions = const [],
    this.serverRoles = const {},
    required this.createdAt,
    this.lastLogin,
    required this.isGoogleDriveLinked,
    this.googleDriveEmail,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      dateOfBirth: DateTime.parse(data['dateOfBirth']),
      //     phoneNumber: data['phoneNumber'],
      cnicFrontUrl: data['cnicFrontUrl'],
      cnicBackUrl: data['cnicBackUrl'],
      signatureUrl: data['signatureUrl'],
      signatureLocalPath: data['signatureLocalPath'],
      stampUrl: data['stampUrl'],
      stampLocalPath: data['stampLocalPath'],
      profilePicUrl: data['profilePicUrl'],
      status: data['status'] ?? "offline",
      isDisabled: data['isDisabled'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      friends: List<String>.from(data['friends'] ?? []),
      serversJoined: List<String>.from(data['serversJoined'] ?? []),
      sessions: List<Map<String, dynamic>>.from(data['sessions'] ?? []),
      serverRoles: Map<String, String>.from(data['serverRoles'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
      isGoogleDriveLinked: data['isGoogleDriveLinked'] ?? false,
      googleDriveEmail: data['googleDriveEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      //     'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'signatureUrl': signatureUrl,
      'signatureLocalPath': signatureLocalPath,
      'stampUrl': stampUrl,
      'stampLocalPath': stampLocalPath,
      'profilePicUrl': profilePicUrl,
      'status': status,
      'isDisabled': isDisabled,
      'isEmailVerified': isEmailVerified,
      'friends': friends,
      'serversJoined': serversJoined,
      'sessions': sessions,
      'serverRoles': serverRoles,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'isGoogleDriveLinked': isGoogleDriveLinked,
      'googleDriveEmail': googleDriveEmail,
    };
  }
}
