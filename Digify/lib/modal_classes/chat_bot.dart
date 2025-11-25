class ChatBotModel {
  final String id;
  final String userId;
  final String text;
  final DateTime timestamp;

  ChatBotModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatBotModel.fromMap(Map<String, dynamic> map) {
    return ChatBotModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
