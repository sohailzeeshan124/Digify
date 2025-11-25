import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/chat.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class ChatRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<Result<void>> uploadChat(ChatModel chat) async {
    try {
      await _firestore.collection('chats').doc(chat.uid).set(chat.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error uploading chat: ${e.toString()}");
    }
  }

  Future<Result<void>> updateChat(ChatModel chat) async {
    try {
      await _firestore.collection('chats').doc(chat.uid).update(chat.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error updating chat: ${e.toString()}");
    }
  }

  Future<Result<void>> deleteChat(String uid) async {
    try {
      await _firestore.collection('chats').doc(uid).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error deleting chat: ${e.toString()}");
    }
  }

  Future<Result<List<ChatModel>>> getMessages(String userId) async {
    try {
      // Fetch messages where user is sender
      final senderQuery = await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: userId)
          .get();

      // Fetch messages where user is receiver
      final receiverQuery = await _firestore
          .collection('chats')
          .where('receiverId', isEqualTo: userId)
          .get();

      final messages = [
        ...senderQuery.docs.map((doc) => ChatModel.fromMap(doc.data())),
        ...receiverQuery.docs.map((doc) => ChatModel.fromMap(doc.data()))
      ];

      // Sort by time
      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return Result.success(messages);
    } catch (e) {
      return Result.failure("Error fetching messages: ${e.toString()}");
    }
  }
}
