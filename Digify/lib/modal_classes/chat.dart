class ChatModel {
  final String uid;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime sentAt;

  final String type; // 'text', 'image', 'video', 'document'
  final String? attachmentUrl;
  final String? fileName;

  ChatModel({
    required this.uid,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.sentAt,
    this.type = 'text',
    this.attachmentUrl,
    this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'type': type,
      'attachmentUrl': attachmentUrl,
      'fileName': fileName,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      uid: map['uid'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      sentAt: DateTime.parse(map['sentAt']),
      type: map['type'] ?? 'text',
      attachmentUrl: map['attachmentUrl'],
      fileName: map['fileName'],
    );
  }
}
