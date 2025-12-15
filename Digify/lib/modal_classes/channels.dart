import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelModel {
  final String uid;
  final String communityId;
  final String name;
  final List<String> users;
  final bool canTalk;
  final DateTime createdat;

  ChannelModel({
    required this.uid,
    required this.communityId,
    required this.name,
    required this.users,
    required this.canTalk,
    required this.createdat,
  });

  ChannelModel copyWith({
    String? uid,
    String? communityId,
    String? name,
    List<String>? users,
    bool? canTalk,
    DateTime? createdat,
  }) {
    return ChannelModel(
      uid: uid ?? this.uid,
      communityId: communityId ?? this.communityId,
      name: name ?? this.name,
      users: users ?? this.users,
      canTalk: canTalk ?? this.canTalk,
      createdat: createdat ?? this.createdat,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'communityId': communityId,
      'name': name,
      'users': users,
      'canTalk': canTalk,
      'createdat': createdat,
    };
  }

  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    return ChannelModel(
      uid: map['uid'] ?? '',
      communityId: map['communityId'] ?? '',
      name: map['name'] ?? '',
      users: List<String>.from(map['users'] ?? []),
      canTalk: map['canTalk'] ?? false,
      createdat: map['createdat'] is Timestamp
          ? (map['createdat'] as Timestamp).toDate()
          : DateTime.parse(map['createdat'].toString()),
    );
  }
}
