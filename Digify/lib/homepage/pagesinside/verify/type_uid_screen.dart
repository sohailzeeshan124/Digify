import 'package:flutter/material.dart';
import 'package:digify/viewmodels/document_viewmodel.dart';
import 'package:digify/modalclasses/document_model.dart';
import 'package:intl/intl.dart';

class TypeUIDScreen extends StatefulWidget {
  const TypeUIDScreen({super.key});

  @override
  State<TypeUIDScreen> createState() => _TypeUIDScreenState();
}

class _TypeUIDScreenState extends State<TypeUIDScreen> {
  final TextEditingController _uidController = TextEditingController();
  final DocumentViewModel _documentViewModel = DocumentViewModel();

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  void _showDocumentDetails(DocumentModel document) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
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
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _uidController.clear();
                    },
                    child: const Text('Check Another'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF274A31),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyDocument() async {
    if (_uidController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document UID')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Fetch document
    final document = await _documentViewModel.getDocument(_uidController.text);

    // Close loading dialog
    Navigator.of(context).pop();

    if (document == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content:
              Text(_documentViewModel.errorMessage ?? 'Unknown error occurred'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    _showDocumentDetails(document);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enter Document UID',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.fingerprint,
              size: 80,
              color: Color(0xFF274A31),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter Document UID',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Type the unique identifier of the document you want to verify',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _uidController,
              decoration: InputDecoration(
                labelText: 'Document UID',
                hintText: 'Enter the document UID here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.document_scanner),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifyDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF274A31),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Verify Document',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
