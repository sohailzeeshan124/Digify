import 'dart:io';

import 'package:digify/modalclasses/User_modal.dart';
import 'package:digify/modalclasses/document_model.dart';
import 'package:digify/utils/pdf_utils.dart';
import 'package:digify/viewmodels/User_viewmodal.dart';
import 'package:digify/viewmodels/document_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentSignScreen extends StatefulWidget {
  final String pdfPath;
  final String documentId; // Firestore doc ID
  const DocumentSignScreen({required this.pdfPath, required this.documentId});

  @override
  State<DocumentSignScreen> createState() => _DocumentSignScreenState();
}

class _DocumentSignScreenState extends State<DocumentSignScreen> {
  File? signatureImage;
  Offset offset = Offset(100, 100);
  double scale = 1.0;
  double rotation = 0.0;
  double signatureWidth = 100;
  double signatureHeight = 60;

  Future<void> pickSignatureImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        signatureImage = File(picked.path);
      });
    }
  }

  void onFinalizeAndSign() async {
    final viewmodel = DocumentViewModel();

    try {
      if (signatureImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please select a signature image.")));
        return;
      }

      final signedPdfPath = await PdfUtils.embedSignature(
        pdfPath: widget.pdfPath,
        signaturePath: signatureImage!.path,
        offset: offset,
        scale: scale,
        rotation: rotation,
      );

      await PdfUtils.appendQrCodePage(signedPdfPath, widget.documentId);

      final currentUser = FirebaseAuth.instance.currentUser;
      final userdataviewmodel = UserViewModel();
      final UserData? userData =
          await userdataviewmodel.fetchUserData(currentUser!.uid);

      final docRef = FirebaseFirestore.instance.collection('documents').doc();
      final docId = docRef.id;

      // Get the filename from the PDF path
      final fileName = widget.pdfPath.split('/').last.replaceAll('.pdf', '');

      final document = DocumentModel(
        docId: docId,
        docName: fileName,
        uploadedBy: currentUser!.uid,
        createdAt: DateTime.now(),
        pdfUrl: signedPdfPath,
        qrCodeUrl: 'qr_code_url_if_applicable',
        signedBy: [
          SignerInfo(
            uid: currentUser!.uid,
            displayName: userData!.username,
            signedAt: DateTime.now(),
          )
        ],
      );

      await viewmodel.finalizeSignature(document);

      await docRef.set(document.toMap());

      final directory = await getExternalStorageDirectory();
      final outputPath = '${directory?.path}/your_filename.pdf';
      await File(signedPdfPath).copy(outputPath);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document signed successfully.")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error signing document: \$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Document")),
      body: Stack(
        children: [
          SfPdfViewer.file(File(widget.pdfPath)),
          if (signatureImage != null)
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    offset += details.focalPointDelta;
                    scale = details.scale;
                    rotation = details.rotation;
                  });
                },
                child: Transform.rotate(
                  angle: rotation,
                  child: Image.file(
                    signatureImage!,
                    width: signatureWidth,
                    height: signatureHeight,
                  ),
                ),
              ),
            ),
          // Bottom-right resize handle
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  signatureWidth += details.delta.dx;
                  signatureHeight += details.delta.dy;
                  if (signatureWidth < 30) signatureWidth = 30;
                  if (signatureHeight < 20) signatureHeight = 20;
                });
              },
              child: Icon(Icons.open_in_full, size: 24),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: pickSignatureImage,
            label: Text("Pick Signature"),
            icon: Icon(Icons.image),
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: onFinalizeAndSign,
            label: Text("Finalize & Sign"),
            icon: Icon(Icons.done_all),
          ),
        ],
      ),
    );
  }
}
