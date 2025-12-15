import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/requestsignature.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class RequestSignatureRepository {
  final _firestore = FirebaseFirestore.instance;
  final String _collection = 'request_signatures';

  Future<Result<void>> createRequest(RequestSignature request) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(request.requestUid)
          .set(request.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error creating request: ${e.toString()}");
    }
  }

  Future<Result<RequestSignature>> getRequest(String requestUid) async {
    try {
      final doc =
          await _firestore.collection(_collection).doc(requestUid).get();
      if (doc.exists && doc.data() != null) {
        return Result.success(RequestSignature.fromMap(doc.data()!));
      } else {
        return Result.failure("Request not found");
      }
    } catch (e) {
      return Result.failure("Error fetching request: ${e.toString()}");
    }
  }

  Future<Result<List<RequestSignature>>> getRequestsForUser(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('signerIds', arrayContains: userId)
          .get();

      final requests = snapshot.docs
          .map((doc) => RequestSignature.fromMap(doc.data()))
          .toList();

      return Result.success(requests);
    } catch (e) {
      return Result.failure("Error fetching user requests: ${e.toString()}");
    }
  }

  Future<Result<List<RequestSignature>>> getRequestsByCommunity(
      String communityId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('communityId', isEqualTo: communityId)
          .get();

      final requests = snapshot.docs
          .map((doc) => RequestSignature.fromMap(doc.data()))
          .toList();

      return Result.success(requests);
    } catch (e) {
      return Result.failure(
          "Error fetching community requests: ${e.toString()}");
    }
  }

  Future<Result<void>> updateRequest(RequestSignature request) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(request.requestUid)
          .update(request.toMap());
      return Result.success(null);
    } catch (e) {
      return Result.failure("Error updating request: ${e.toString()}");
    }
  }
}
