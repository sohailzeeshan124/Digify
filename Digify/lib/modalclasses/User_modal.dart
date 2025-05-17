class UserData {
  final String userId; // userId should NOT be nullable
  final String username; // username should NOT be nullable
  final String displayName; // displayName should NOT be nullable
  final String phoneNumber; // phoneNumber should NOT be nullable
  final String address; // address should NOT be nullable
  final String aboutyou;

  final String? cnicFrontUrl; // Optional
  final String? cnicBackUrl; // Optional
  final String? profilePicUrl; // Optional
  final String? signaturePicUrl; // Optional

  UserData({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.phoneNumber,
    required this.address,
    required this.aboutyou,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.profilePicUrl,
    this.signaturePicUrl,
  });

  // From Firestore document
  factory UserData.fromFirestore(Map<String, dynamic> data) {
    return UserData(
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      address: data['address'] ?? '',
      aboutyou: data['aboutyou'] ?? '',
      cnicFrontUrl: data['cnicFrontUrl'],
      cnicBackUrl: data['cnicBackUrl'],
      profilePicUrl: data['profilePicUrl'],
      signaturePicUrl: data['signaturePicUrl'],
    );
  }

  // To Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'address': address,
      'aboutyou': aboutyou,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'profilePicUrl': profilePicUrl,
      'signaturePicUrl': signaturePicUrl,
    };
  }

  // copyWith method for updating specific fields
  UserData copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? phoneNumber,
    String? address,
    String? aboutyou,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? profilePicUrl,
    String? signaturePicUrl,
  }) {
    return UserData(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      aboutyou: aboutyou ?? this.aboutyou,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      signaturePicUrl: signaturePicUrl ?? this.signaturePicUrl,
    );
  }
}
