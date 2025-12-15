import 'package:flutter/foundation.dart';
import 'package:digify/modal_classes/requestsignature.dart';
import 'package:digify/repositories/request_signature_repository.dart';

class RequestSignatureViewModel extends ChangeNotifier {
  final RequestSignatureRepository _repository = RequestSignatureRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<RequestSignature> _requests = [];
  List<RequestSignature> get requests => _requests;

  Future<void> createRequest(RequestSignature request) async {
    _setLoading(true);
    final result = await _repository.createRequest(request);
    _setLoading(false);

    if (result.error != null) {
      _errorMessage = result.error;
    } else {
      _errorMessage = null;
      // Optionally add to local list immediately
      _requests.add(request);
    }
    notifyListeners();
  }

  Future<void> fetchRequestsForUser(String userId) async {
    _setLoading(true);
    final result = await _repository.getRequestsForUser(userId);
    _setLoading(false);

    if (result.error != null) {
      _errorMessage = result.error;
    } else {
      _errorMessage = null;
      _requests = result.data ?? [];
    }
    notifyListeners();
  }

  Future<void> fetchRequestsByCommunity(String communityId) async {
    _setLoading(true);
    final result = await _repository.getRequestsByCommunity(communityId);
    _setLoading(false);

    if (result.error != null) {
      _errorMessage = result.error;
    } else {
      _errorMessage = null;
      _requests = result.data ?? [];
    }
    notifyListeners();
  }

  Future<void> rejectRequest(String requestUid, String reason) async {
    _setLoading(true);

    // First get the current request to ensure we have the latest data
    final getResult = await _repository.getRequest(requestUid);

    if (getResult.error != null || getResult.data == null) {
      _setLoading(false);
      _errorMessage = getResult.error ?? "Request not found";
      notifyListeners();
      return;
    }

    final currentRequest = getResult.data!;

    // Create updated request object
    final updatedRequest = RequestSignature(
      requestUid: currentRequest.requestUid,
      title: currentRequest.title,
      description: currentRequest.description,
      documentUid: currentRequest.documentUid,
      signerIds: currentRequest.signerIds,
      communityId: currentRequest.communityId,
      isRejected: true, // Set to true
      rejectionReason: reason, // Set reason
      userId: currentRequest.userId,
    );

    final result = await _repository.updateRequest(updatedRequest);
    _setLoading(false);

    if (result.error != null) {
      _errorMessage = result.error;
    } else {
      _errorMessage = null;
      // Update local list
      final index = _requests.indexWhere((r) => r.requestUid == requestUid);
      if (index != -1) {
        _requests[index] = updatedRequest;
      }
    }
    notifyListeners();
  }

  Future<RequestSignature?> getRequest(String requestUid) async {
    _setLoading(true);
    final result = await _repository.getRequest(requestUid);
    _setLoading(false);

    if (result.error != null) {
      _errorMessage = result.error;
      notifyListeners();
      return null;
    }
    return result.data;
  }

  Future<void> updateRequest(RequestSignature request) async {
    _setLoading(true);
    final result = await _repository.updateRequest(request);
    _setLoading(false);

    if (result.error != null) {
      _errorMessage = result.error;
    } else {
      _errorMessage = null;
      final index =
          _requests.indexWhere((r) => r.requestUid == request.requestUid);
      if (index != -1) {
        _requests[index] = request;
      }
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
