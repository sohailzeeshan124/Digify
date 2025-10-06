import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/document.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class DocumentRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<Result<DocumentModel>> getDocument(String uid) async {
    try {
      final docRef = _firestore.collection('documents').doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final document = DocumentModel.fromMap(snapshot.data()!);
        return Result.success(document);
      } else {
        return Result.failure("Document not found");
      }
    } catch (e) {
      return Result.failure("Error fetching document: ${e.toString()}");
    }
  }

  Future<Result<void>> uploadOrUpdateDocument(DocumentModel doc) async {
    try {
      final docRef = _firestore.collection('documents').doc(doc.docId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // Update existing document (append new signer)
        final existingData = DocumentModel.fromMap(snapshot.data()!);

        final updatedDoc = DocumentModel(
          docId: existingData.docId,
          docName: existingData.docName,
          uploadedBy: existingData.uploadedBy,
          createdAt: existingData.createdAt,
          pdfUrl: doc.pdfUrl,
          qrCodeUrl: doc.qrCodeUrl,
          signedBy: [...existingData.signedBy, ...doc.signedBy],
        );

        await docRef.set(updatedDoc.toMap());
      } else {
        // Create new document
        await docRef.set(doc.toMap());
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure("Firestore Error: ${e.toString()}");
    }
  }
}
