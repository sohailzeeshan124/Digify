class CommunityModel {
  final String uid;
  final String name;
  final String description;
  final String? communityPicture;
  final List<String> admins;
  final DateTime createdAt;
  final List<String> roles;
  final Map<String, String> memberRoles; // userId_role

  CommunityModel({
    required this.uid,
    required this.name,
    required this.description,
    this.communityPicture,
    required this.admins,
    required this.createdAt,
    required this.roles,
    required this.memberRoles,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'description': description,
      'communityPicture': communityPicture,
      'admins': admins,
      'createdAt': createdAt.toIso8601String(),
      'roles': roles,
      'memberRoles': memberRoles,
    };
  }

  factory CommunityModel.fromMap(Map<String, dynamic> map) {
    return CommunityModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      communityPicture: map['communityPicture'],
      admins: List<String>.from(map['admins'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
      roles: List<String>.from(map['roles'] ?? []),
      memberRoles: Map<String, String>.from(map['memberRoles'] ?? {}),
    );
  }
}
