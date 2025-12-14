import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/channel_messages.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class ChannelMessageRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<Result<void>> uploadChat(ChannelMessageModel chat) async {
    try {
      await _firestore
          .collection('channel_messages')
          .doc(chat.uid)
          .set(chat.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error uploading chat: ${e.toString()}");
    }
  }

  Future<Result<void>> updateChat(ChannelMessageModel chat) async {
    try {
      await _firestore
          .collection('channel_messages')
          .doc(chat.uid)
          .update(chat.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error updating chat: ${e.toString()}");
    }
  }

  Future<Result<void>> deleteChat(String uid) async {
    try {
      await _firestore.collection('channel_messages').doc(uid).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error deleting chat: ${e.toString()}");
    }
  }

  Future<Result<List<ChannelMessageModel>>> getMessages(
      String channelid) async {
    try {
      final querySnapshot = await _firestore
          .collection('channel_messages')
          .where('channelId', isEqualTo: channelid)
          .get();

      final messages = querySnapshot.docs
          .map((doc) => ChannelMessageModel.fromMap(doc.data()))
          .toList();

      // Sort by time
      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      return Result.success(messages);
    } catch (e) {
      return Result.failure("Error fetching messages: ${e.toString()}");
    }
  }

  Stream<List<ChannelMessageModel>> getChatStream(String channelId) {
    return _firestore
        .collection('channel_messages')
        .where('channelId', isEqualTo: channelId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChannelMessageModel.fromMap(doc.data()))
          .toList();

      messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      return messages;
    });
  }
}
