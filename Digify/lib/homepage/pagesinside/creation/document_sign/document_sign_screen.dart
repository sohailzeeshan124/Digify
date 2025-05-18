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
import 'package:path/path.dart' as p;

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
  bool isDragging = false;

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

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // First, create the Firestore document to get the UID
      final docRef = FirebaseFirestore.instance.collection('documents').doc();
      final docId = docRef.id;

      // Get the filename from the PDF path
      final fileName = widget.pdfPath.split('/').last.replaceAll('.pdf', '');

      // Get current user data
      final currentUser = FirebaseAuth.instance.currentUser;
      final userdataviewmodel = UserViewModel();
      final UserData? userData =
          await userdataviewmodel.fetchUserData(currentUser!.uid);

      // Create the document model
      final document = DocumentModel(
        docId: docId,
        docName: fileName,
        uploadedBy: currentUser.uid,
        createdAt: DateTime.now(),
        pdfUrl: widget.pdfPath, // Use original path initially
        qrCodeUrl: 'qr_code_url_if_applicable',
        signedBy: [
          SignerInfo(
            uid: currentUser.uid,
            displayName: userData!.username,
            signedAt: DateTime.now(),
          )
        ],
      );

      // Save to Firestore first
      await docRef.set(document.toMap());

      // Now modify the PDF with signature and QR code
      final signedPdfPath = await PdfUtils.embedSignature(
        pdfPath: widget.pdfPath,
        signaturePath: signatureImage!.path,
        offset: offset,
        scale: scale,
        rotation: rotation,
      );

      // Add QR code page with the Firestore document UID
      await PdfUtils.appendQrCodePage(signedPdfPath, docId);

      // After all PDF modifications (signature + QR code)
      final docsDir = await getExternalStorageDirectory();
      final signedDocsDir = Directory(p.join(docsDir!.path, 'signed_docs'));
      if (!await signedDocsDir.exists()) {
        await signedDocsDir.create(recursive: true);
      }
      final finalPath = p.join(signedDocsDir.path, '${fileName}_signed.pdf');
      await File(signedPdfPath).copy(finalPath);

      // Update Firestore with the new path
      await docRef.update({
        'pdfUrl': finalPath,
      });

      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document signed successfully.")));
      Navigator.pop(context);
    } catch (e) {
      // Close loading dialog if it's showing
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error signing document: $e")));
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
                onScaleStart: (details) {
                  // Optionally store initial values if needed
                },
                onScaleUpdate: (details) {
                  setState(() {
                    scale = details.scale;
                    rotation = details.rotation;
                    offset += details.focalPointDelta;
                  });
                },
                child: Transform.rotate(
                  angle: rotation,
                  child: Container(
                    width: signatureWidth * scale,
                    height: signatureHeight * scale,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Image.file(
                      signatureImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
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
