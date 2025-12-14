import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/channels.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class ChannelRepository {
  final _firestore = FirebaseFirestore.instance;

  // Create a new channel
  Future<Result<void>> createChannel(ChannelModel channel) async {
    try {
      await _firestore
          .collection('channels')
          .doc(channel.uid)
          .set(channel.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error creating channel: ${e.toString()}");
    }
  }

  // Get a single channel by UID
  Future<Result<ChannelModel>> getChannel(String uid) async {
    try {
      final doc = await _firestore.collection('channels').doc(uid).get();
      if (doc.exists) {
        return Result.success(ChannelModel.fromMap(doc.data()!));
      } else {
        return Result.failure("Channel not found");
      }
    } catch (e) {
      return Result.failure("Error getting channel: ${e.toString()}");
    }
  }

  // Get all channels for a specific community
  Future<Result<List<ChannelModel>>> getChannels(String communityId) async {
    try {
      final querySnapshot = await _firestore
          .collection('channels')
          .where('communityId', isEqualTo: communityId)
          .get();
      final channels = querySnapshot.docs
          .map((doc) => ChannelModel.fromMap(doc.data()))
          .toList();
      return Result.success(channels);
    } catch (e) {
      return Result.failure("Error getting channels: ${e.toString()}");
    }
  }

  // Update entire channel
  Future<Result<void>> updateChannel(ChannelModel channel) async {
    try {
      await _firestore
          .collection('channels')
          .doc(channel.uid)
          .update(channel.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error updating channel: ${e.toString()}");
    }
  }

  // Change specifically the channel name
  Future<Result<void>> changeChannelName(String uid, String newName) async {
    try {
      await _firestore
          .collection('channels')
          .doc(uid)
          .update({'name': newName});
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error changing channel name: ${e.toString()}");
    }
  }

  // Delete a channel
  Future<Result<void>> deleteChannel(String uid) async {
    try {
      await _firestore.collection('channels').doc(uid).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error deleting channel: ${e.toString()}");
    }
  }
}
