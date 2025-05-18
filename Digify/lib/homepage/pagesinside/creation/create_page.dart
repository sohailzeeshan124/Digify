import 'package:digify/homepage/pagesinside/creation/document_sign/document_sign_screen.dart';
import 'package:digify/homepage/pagesinside/creation/pdf_creation/create_pdf_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:digify/homepage/pagesinside/creation/image_to_doc/image_to_docx_screen.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Create",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildOptionCard(
              icon: Icons.picture_as_pdf,
              title: 'Create PDF',
              subtitle: 'Combine images into a PDF file',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreatePdfPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.edit_document,
              title: 'Create Signed Document',
              subtitle: 'Digitally sign your documents',
              onTap: () async {
                // Pick a PDF from device
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );

                if (result != null && result.files.single.path != null) {
                  final pdfPath = result.files.single.path!;
                  final documentId = result.files.single.name
                      .split('.')
                      .first; // OR generate a UUID

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentSignScreen(
                        pdfPath: pdfPath,
                        documentId: documentId,
                      ),
                    ),
                  );
                } else {
                  // User canceled the picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("No PDF selected.")),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.workspace_premium,
              title: 'Create Certificate',
              subtitle: 'Design and issue certificates',
              onTap: () {
                // Navigate to Certificate Creator
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.document_scanner,
              title: 'Image to Text to Doc',
              subtitle: 'Convert image text to editable document',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ImageToDocxScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF274A31),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
