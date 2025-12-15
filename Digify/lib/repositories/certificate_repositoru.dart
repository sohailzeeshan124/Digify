import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/certificate.dart';

class Result<T> {
  final T? data;
  final String? error;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

class CertificateRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<Result<CertificateModel>> getCertificate(String uid) async {
    try {
      print("DEBUG: Repository querying Firestore for ID: '$uid'");
      final docRef = _firestore.collection('certificates').doc(uid);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        print("DEBUG: Document found for ID: '$uid'. Data: ${snapshot.data()}");
        final document = CertificateModel.fromMap(snapshot.data()!);
        return Result.success(document);
      } else {
        print("DEBUG: Document NOT found for ID: '$uid'");
        return Result.failure("Certificate not found");
      }
    } catch (e) {
      print("DEBUG: Error fetching certificate: $e");
      return Result.failure("Error fetching certificate: ${e.toString()}");
    }
  }

  Future<Result<void>> deleteCertificate(String docId, String pdfUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection('certificates').doc(docId).delete();

      // Delete local file if it exists
      try {
        final file = File(pdfUrl);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting local file: $e');
        // Continue even if local file deletion fails
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure("Error deleting certificate: ${e.toString()}");
    }
  }

  Future<Result<void>> uploadOrUpdateCertificate(CertificateModel doc) async {
    try {
      final docRef = _firestore.collection('certificates').doc(doc.docId);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // Update existing document (append new signer)
        final existingData = CertificateModel.fromMap(snapshot.data()!);

        final updatedDoc = CertificateModel(
          localpdfpath: doc.localpdfpath,
          docId: existingData.docId,
          Name: existingData.Name,
          uploadedBy: existingData.uploadedBy,
          createdAt: existingData.createdAt,
          pdfUrl: doc.pdfUrl,
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
