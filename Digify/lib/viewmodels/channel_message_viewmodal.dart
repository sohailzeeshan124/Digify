import 'package:flutter/foundation.dart';
import 'package:digify/modal_classes/channel_messages.dart';
import 'package:digify/repositories/channel_message_repository.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'dart:io';
import 'package:digify/modal_classes/user_data.dart';
import 'package:uuid/uuid.dart';

class ChannelMessageViewModel extends ChangeNotifier {
  final ChannelMessageRepository _repository = ChannelMessageRepository();
  final CloudinaryRepository _cloudinaryRepo = CloudinaryRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ChannelMessageModel> _messages = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChannelMessageModel> get messages => _messages;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Send a message
  Future<bool> sendMessage(ChannelMessageModel message) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.uploadChat(message);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Send a file message
  Future<bool> sendFileMessage({
    required File file,
    required String type, // 'image', 'video', 'document'
    required UserModel currentUser,
    required String channelId,
    String? fileName,
  }) async {
    _setLoading(true);
    _setError(null);

    String? uploadedUrl;

    // Upload to Cloudinary
    final response = await _cloudinaryRepo.uploadFile(file.path,
        folder: "digify/channels/$channelId");

    if (response != null) {
      uploadedUrl = response.secureUrl;
    } else {
      _setError("Failed to upload file");
      _setLoading(false);
      return false;
    }

    final message = ChannelMessageModel(
      uid: const Uuid().v1(),
      channelId: channelId,
      senderId: currentUser.uid,
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

    return await sendMessage(message);
  }

  // Fetch messages for a channel
  Future<void> fetchMessages(String channelId) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.getMessages(channelId);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
    } else if (result.data != null) {
      _messages = result.data!;
      notifyListeners();
    }
  }

  // Update a message
  Future<bool> updateMessage(ChannelMessageModel message) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.updateChat(message);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Delete a message
  Future<bool> deleteMessage(String uid) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.deleteChat(uid);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Get chat stream
  Stream<List<ChannelMessageModel>> getChatStream(String channelId) {
    return _repository.getChatStream(channelId);
  }
}
