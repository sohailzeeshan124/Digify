import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:digify/viewmodels/document_viewmodel.dart';
import 'package:digify/modal_classes/document.dart';
import 'package:intl/intl.dart';

class VerifyMetadataScreen extends StatefulWidget {
  const VerifyMetadataScreen({super.key});

  @override
  State<VerifyMetadataScreen> createState() => _VerifyMetadataScreenState();
}

class _VerifyMetadataScreenState extends State<VerifyMetadataScreen> {
  String? _uid;
  DocumentModel? _document;
  bool _loading = false;
  final DocumentViewModel _documentViewModel = DocumentViewModel();

  Future<void> _pickAndScanPdf() async {
    setState(() {
      _loading = true;
    });
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final pdf = sf.PdfDocument(inputBytes: bytes);
      // Try to extract UID from PDF metadata or a custom field
      String? uid = pdf.documentInformation.subject;
      pdf.dispose();
      if (uid == null || uid.isEmpty) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No UID found in PDF metadata.')));
        return;
      }
      setState(() {
        _uid = uid;
      });
      // Fetch document info from Firestore
      final doc = await _documentViewModel.getDocument(uid);
      setState(() {
        _document = doc;
        _loading = false;
      });
      if (doc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No document found for this UID.')));
      }
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Verify by Metadata'),
          backgroundColor: const Color(0xFF274A31)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _pickAndScanPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select PDF to Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF274A31),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_document != null) ...[
              _buildDocumentDetails(_document!),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentDetails(DocumentModel document) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF274A31).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Color(0xFF274A31)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.docName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${DateFormat('MMM dd, yyyy').format(document.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Document ID
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Document ID: ${document.docId}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Signatures Section
            const Text(
              'Signatures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: document.signedBy.length,
                itemBuilder: (context, index) {
                  final signer = document.signedBy[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              const Color(0xFF274A31).withOpacity(0.1),
                          child: Text(
                            signer.displayName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF274A31),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                signer.displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy HH:mm')
                                    .format(signer.signedAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
