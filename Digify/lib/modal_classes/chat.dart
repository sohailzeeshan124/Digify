class ChatModel {
  final String uid;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime sentAt;

  ChatModel({
    required this.uid,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.sentAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      uid: map['uid'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      sentAt: DateTime.parse(map['sentAt']),
    );
  }
}
