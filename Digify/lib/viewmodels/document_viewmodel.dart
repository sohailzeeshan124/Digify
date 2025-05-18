import 'package:digify/modalclasses/document_model.dart';
import 'package:digify/repositories/document_repository.dart';
import 'package:flutter/material.dart';

class DocumentViewModel extends ChangeNotifier {
  final DocumentRepository _repo = DocumentRepository();

  bool isLoading = false;
  String? errorMessage;
  DocumentModel? currentDocument;

  Future<DocumentModel?> getDocument(String uid) async {
    isLoading = true;
    errorMessage = null;
    currentDocument = null;
    notifyListeners();

    final result = await _repo.getDocument(uid);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
      notifyListeners();
      return null;
    }

    currentDocument = result.data;
    notifyListeners();
    return result.data;
  }

  Future<void> finalizeSignature(DocumentModel doc) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.uploadOrUpdateDocument(doc);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }
}
