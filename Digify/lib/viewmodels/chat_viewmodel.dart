import 'package:digify/modal_classes/chat.dart';
import 'package:digify/repositories/chat_repository.dart';
import 'package:flutter/material.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repo = ChatRepository();

  bool isLoading = false;
  String? errorMessage;

  Future<void> uploadChat(ChatModel chat) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.uploadChat(chat);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }

  Future<void> updateChat(ChatModel chat) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.updateChat(chat);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }

  Future<void> deleteChat(String uid) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.deleteChat(uid);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }

  Future<List<ChatModel>> getRecentChats(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.getMessages(userId);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
      notifyListeners();
      return [];
    }

    final messages = result.data ?? [];
    final Map<String, ChatModel> recentChats = {};

    for (var msg in messages) {
      final otherId = msg.senderId == userId ? msg.receiverId : msg.senderId;
      if (!recentChats.containsKey(otherId)) {
        recentChats[otherId] = msg;
      }
    }

    notifyListeners();
    return recentChats.values.toList();
  }
}
