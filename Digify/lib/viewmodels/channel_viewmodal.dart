import 'package:digify/repositories/channel_message_repository.dart';
import 'package:digify/repositories/community_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:digify/modal_classes/channels.dart';
import 'package:digify/repositories/channel_repository.dart';

class ChannelViewModel extends ChangeNotifier {
  final ChannelRepository _repository = ChannelRepository();

  bool _isLoading = false;
  String? _errorMessage;
  List<ChannelModel> _channels = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChannelModel> get channels => _channels;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Create a new channel
  Future<bool> createChannel(ChannelModel channel) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.createChannel(channel);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Fetch channels for a community
  Future<void> fetchChannels(String communityId) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.getChannels(communityId);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
    } else if (result.data != null) {
      _channels = result.data!;
      notifyListeners();
    }
  }

  // Update a channel
  Future<bool> updateChannel(ChannelModel channel) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.updateChannel(channel);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Change channel name
  Future<bool> changeChannelName(String uid, String newName) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.changeChannelName(uid, newName);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }

  // Delete a channel
  Future<bool> deleteChannel(ChannelModel channel) async {
    _setLoading(true);
    _setError(null);

    // 1. Delete associated messages
    final ChannelMessageRepository messageRepository =
        ChannelMessageRepository();
    await messageRepository.deleteMessagesByChannel(channel.uid);

    // 2. Downgrade users to 'Member' (as per requirement)
    final CommunityRepository communityRepository = CommunityRepository();
    for (final userId in channel.users) {
      // Set role to 'Member'
      await communityRepository.assignRole(
          channel.communityId, userId, 'Member');
      // Ensure removed from admins if they were one
      await communityRepository.removeAdmin(channel.communityId, userId);
    }

    // 3. Delete the channel itself
    final result = await _repository.deleteChannel(channel.uid);

    if (result.error != null) {
      _setLoading(false);
      _setError(result.error);
      return false;
    }

    // 4. Update local state
    _channels.removeWhere((c) => c.uid == channel.uid);
    notifyListeners();

    _setLoading(false);
    return true;
  }
}
