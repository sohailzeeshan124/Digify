import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewPage extends StatefulWidget {
  final File pdfFile;

  const PdfPreviewPage({super.key, required this.pdfFile});

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  late TextEditingController _nameController;
  late String currentPath;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    currentPath = widget.pdfFile.path;
    _nameController = TextEditingController(
      text: widget.pdfFile.uri.pathSegments.last.replaceAll('.pdf', ''),
    );
  }

  void _renameFile() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final newPath = widget.pdfFile.parent.path + "/$newName.pdf";
    final newFile = await widget.pdfFile.rename(newPath);

    setState(() {
      currentPath = newFile.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF renamed successfully!')),
    );
  }

  void _shareFile() {
    Share.shareXFiles([XFile(currentPath)], text: 'Here is your PDF!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 🟢 Helps show space between pages
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _renameFile,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareFile,
          ),
        ],
        backgroundColor: const Color(0xFF274A31),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Page $_currentPage of $_totalPages",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 6,
        radius: const Radius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SfPdfViewer.file(
            File(currentPath),
            controller: _pdfViewerController,
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
            },
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        ),
      ),
    );
  }
}
