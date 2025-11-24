import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digify/modal_classes/certificate.dart';
import 'package:digify/repositories/certificate_repositoru.dart';
import 'package:flutter/material.dart';

class CertificateViewModel extends ChangeNotifier {
  final CertificateRepository _repo = CertificateRepository();

  bool isLoading = false;
  String? errorMessage;
  CertificateModel? currentCertificate;

  Future<CertificateModel?> getCertificate(String uid) async {
    isLoading = true;
    errorMessage = null;
    currentCertificate = null;
    notifyListeners();

    final result = await _repo.getCertificate(uid);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
      notifyListeners();
      return null;
    }

    currentCertificate = result.data;
    notifyListeners();
    return result.data;
  }

  Future<void> finalizeSignature(CertificateModel doc) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.uploadOrUpdateCertificate(doc);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }

  Future<void> deleteCertificate(String docId, String pdfUrl) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await _repo.deleteCertificate(docId, pdfUrl);
    isLoading = false;

    if (result.error != null) {
      errorMessage = result.error;
    }

    notifyListeners();
  }

  Future<List<CertificateModel>> getSignedCertificates(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Get all documents and filter them in memory
      final snapshot =
          await FirebaseFirestore.instance.collection('certificates').get();

      print('Querying documents for user: $userId');
      print('Found ${snapshot.docs.length} total documents');

      final documents = snapshot.docs
          .map((doc) => CertificateModel.fromMap(doc.data()))
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
}
