class UserData {
  final String userId;
  final String username;
  final String displayName;
  final String phoneNumber;
  final String address;

  UserData({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.phoneNumber,
    required this.address,
  });

  // Convert UserData -> Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  // Convert Firestore Map -> UserData
  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
    );
  }
}
