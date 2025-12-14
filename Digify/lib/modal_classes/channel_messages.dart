import 'package:digify/modal_classes/chat.dart';

class ChannelMessageModel {
  final String uid;
  final String channelId;
  final String senderId;
  final String message;
  final DateTime sentAt;

  final String type; // 'text', 'image', 'video', 'document'
  final String? attachmentUrl;
  final String? fileName;

  ChannelMessageModel({
    required this.uid,
    required this.channelId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    this.type = 'text',
    this.attachmentUrl,
    this.fileName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'channelId': channelId,
      'senderId': senderId,
      'message': message,
      'sentAt': sentAt.toIso8601String(),
      'type': type,
      'attachmentUrl': attachmentUrl,
      'fileName': fileName,
    };
  }

  factory ChannelMessageModel.fromMap(Map<String, dynamic> map) {
    return ChannelMessageModel(
      uid: map['uid'] ?? '',
      channelId: map['channelId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      sentAt: DateTime.parse(map['sentAt']),
      type: map['type'] ?? 'text',
      attachmentUrl: map['attachmentUrl'],
      fileName: map['fileName'],
    );
  }
}
