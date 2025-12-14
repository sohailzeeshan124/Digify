import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/modal_classes/chat.dart';
import 'package:digify/repositories/chat_repository.dart';
import 'package:flutter/material.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'dart:io';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _repo = ChatRepository();
  final CloudinaryRepository _cloudinaryRepo = CloudinaryRepository();

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

  Future<void> sendFileMessage({
    required File file,
    required String type, // 'image', 'video', 'document'
    required UserModel currentUser,
    required UserModel otherUser,
    String? fileName,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    String? uploadedUrl;

    // Upload to Cloudinary
    final response = await _cloudinaryRepo.uploadFile(file.path,
        folder: "digify/chats/${currentUser.uid}");

    if (response != null) {
      uploadedUrl = response.secureUrl;
    } else {
      errorMessage = "Failed to upload file";
      isLoading = false;
      notifyListeners();
      return;
    }

    final chat = ChatModel(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.uid,
      receiverId: otherUser.uid,
      message: type == 'image'
          ? 'Sent an image'
          : type == 'video'
              ? 'Sent a video'
              : 'Sent a file',
      sentAt: DateTime.now(),
      type: type,
      attachmentUrl: uploadedUrl,
      fileName: fileName,
    );

    await uploadChat(chat);
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

  Stream<List<ChatModel>> getChatStream(
      String currentUserId, String otherUserId) {
    return _repo.getChatStream(currentUserId, otherUserId);
  }
}
