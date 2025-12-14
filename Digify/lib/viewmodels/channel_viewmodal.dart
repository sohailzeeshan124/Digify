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
  Future<bool> deleteChannel(String uid) async {
    _setLoading(true);
    _setError(null);

    final result = await _repository.deleteChannel(uid);

    _setLoading(false);

    if (result.error != null) {
      _setError(result.error);
      return false;
    }
    return true;
  }
}
