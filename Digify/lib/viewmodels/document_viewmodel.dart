import 'package:digify/modalclasses/document_model.dart';
import 'package:digify/repositories/document_repository.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> deleteDocument(String docId, String pdfUrl) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.deleteDocument(docId, pdfUrl);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }

  Future<List<DocumentModel>> getSignedDocuments(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Get all documents and filter them in memory
      final snapshot =
          await FirebaseFirestore.instance.collection('documents').get();

      print('Querying documents for user: $userId');
      print('Found ${snapshot.docs.length} total documents');

      final documents = snapshot.docs
          .map((doc) => DocumentModel.fromMap(doc.data()))
          .where((doc) => doc.signedBy.any((signer) => signer.uid == userId))
          .toList();

      print('Filtered to ${documents.length} documents for user $userId');

      isLoading = false;
      notifyListeners();
      return documents;
    } catch (e) {
      print('Error fetching documents: $e');
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void _showPdfViewer(String pdfUrl) {
    // Implementation of _showPdfViewer method
  }
}
