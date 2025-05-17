import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final DateTime timestamp;
  final String channelId;
  final List<String>? attachments;
  final Map<String, dynamic>? reactions;
  final bool isEdited;
  final String? replyToMessageId;
  final List<String>? mentions;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.timestamp,
    required this.channelId,
    this.attachments,
    this.reactions,
    this.isEdited = false,
    this.replyToMessageId,
    this.mentions,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      content: data['content'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatar: data['senderAvatar'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      channelId: data['channelId'] ?? '',
      attachments: List<String>.from(data['attachments'] ?? []),
      reactions: data['reactions'],
      isEdited: data['isEdited'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      mentions: List<String>.from(data['mentions'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'timestamp': Timestamp.fromDate(timestamp),
      'channelId': channelId,
      'attachments': attachments,
      'reactions': reactions,
      'isEdited': isEdited,
      'replyToMessageId': replyToMessageId,
      'mentions': mentions,
    };
  }
}
