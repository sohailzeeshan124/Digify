import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;

  final DateTime dateOfBirth;

  String aboutme;

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

  // Usage metrics / history
  int pdfCreatedCount;
  List<DateTime> pdfCreatedAt;

  int documentsSignedCount;
  List<DateTime> documentsSignedAt;

  int certificatesCreatedCount;
  List<DateTime> certificatesCreatedAt;

  int imagesToTextCount;
  List<DateTime> imagesToTextAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.fullName,
    required this.dateOfBirth,
    this.aboutme = '',
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
    this.pdfCreatedCount = 0,
    this.pdfCreatedAt = const [],
    this.documentsSignedCount = 0,
    this.documentsSignedAt = const [],
    this.certificatesCreatedCount = 0,
    this.certificatesCreatedAt = const [],
    this.imagesToTextCount = 0,
    this.imagesToTextAt = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    List<DateTime> _parseDateList(dynamic raw) {
      final List<DateTime> out = [];
      if (raw is List) {
        for (final item in raw) {
          if (item is Timestamp) {
            out.add(item.toDate());
          } else if (item is DateTime) {
            out.add(item);
          } else if (item is String) {
            final dt = DateTime.tryParse(item);
            if (dt != null) out.add(dt);
          }
        }
      }
      return out;
    }

    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      fullName: data['fullName'] ?? '',
      aboutme: data['aboutme'] ?? '',
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
      pdfCreatedCount: (data['pdfCreatedCount'] ?? 0) is int
          ? data['pdfCreatedCount'] as int
          : int.tryParse('${data['pdfCreatedCount'] ?? 0}') ?? 0,
      pdfCreatedAt: _parseDateList(data['pdfCreatedAt']),
      documentsSignedCount: (data['documentsSignedCount'] ?? 0) is int
          ? data['documentsSignedCount'] as int
          : int.tryParse('${data['documentsSignedCount'] ?? 0}') ?? 0,
      documentsSignedAt: _parseDateList(data['documentsSignedAt']),
      certificatesCreatedCount: (data['certificatesCreatedCount'] ?? 0) is int
          ? data['certificatesCreatedCount'] as int
          : int.tryParse('${data['certificatesCreatedCount'] ?? 0}') ?? 0,
      certificatesCreatedAt: _parseDateList(data['certificatesCreatedAt']),
      imagesToTextCount: (data['imagesToTextCount'] ?? 0) is int
          ? data['imagesToTextCount'] as int
          : int.tryParse('${data['imagesToTextCount'] ?? 0}') ?? 0,
      imagesToTextAt: _parseDateList(data['imagesToTextAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'aboutme': aboutme,
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
      // usage metrics
      'pdfCreatedCount': pdfCreatedCount,
      'pdfCreatedAt': pdfCreatedAt,
      'documentsSignedCount': documentsSignedCount,
      'documentsSignedAt': documentsSignedAt,
      'certificatesCreatedCount': certificatesCreatedCount,
      'certificatesCreatedAt': certificatesCreatedAt,
      'imagesToTextCount': imagesToTextCount,
      'imagesToTextAt': imagesToTextAt,
    };
  }
}
