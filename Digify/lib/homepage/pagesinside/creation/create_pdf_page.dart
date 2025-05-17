import 'dart:io';
import 'package:digify/homepage/pagesinside/creation/PdfPreviewPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class CreatePdfPage extends StatefulWidget {
  const CreatePdfPage({super.key});

  @override
  State<CreatePdfPage> createState() => _CreatePdfPageState();
}

class _CreatePdfPageState extends State<CreatePdfPage> {
  List<File> scannedImages = [];
  File? generatedPdf;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> scanDocuments() async {
    dynamic scannedDocs;

    try {
      scannedDocs = await FlutterDocScanner().getScanDocuments(page: 3);

      debugPrint('ScannedDocs: $scannedDocs');

      if (scannedDocs != null &&
          scannedDocs is Map &&
          scannedDocs.containsKey('pdfUri')) {
        final pdfUri = scannedDocs['pdfUri'];
        final pdfPath = Uri.parse(pdfUri).toFilePath();
        final originalFile = File(pdfPath);

        if (await originalFile.exists()) {
          debugPrint('✅ PDF file exists at: $pdfPath');

          // Create a better destination folder: /Documents/Digify
          final targetDir = Directory('/storage/emulated/0/Documents/Digify');
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }

          // Generate a unique name for the scanned file
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newFilePath =
              '${targetDir.path}/Scanned_Document_$timestamp.pdf';

          // Move the file
          final movedFile = await originalFile.copy(newFilePath);
          debugPrint('✅ PDF moved to: ${movedFile.path}');

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfPreviewPage(pdfFile: movedFile),
            ),
          );
        } else {
          debugPrint('❌ PDF file does not exist.');
        }
      } else {
        debugPrint('⚠️ Scanning returned no results.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No documents were scanned.')),
        );
      }
    } catch (e) {
      debugPrint('❌ Error during scanning: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanning failed: $e')),
      );
    }
  }

  // Future<void> generatePdf() async {
  //   if (scannedImages.isEmpty) {
  //     debugPrint('No images to generate PDF.');
  //     return;
  //   }

  //   final pdf = pw.Document();

  //   for (File imageFile in scannedImages) {
  //     final Uint8List imageBytes = await imageFile.readAsBytes();
  //     final pw.MemoryImage image = pw.MemoryImage(imageBytes);

  //     pdf.addPage(
  //       pw.Page(
  //         pageFormat: PdfPageFormat.a4,
  //         build: (pw.Context context) => pw.Center(child: pw.Image(image)),
  //       ),
  //     );
  //   }

  //   // Ask for storage permission
  //   var status = await Permission.storage.request();
  //   if (!status.isGranted) {
  //     debugPrint('Storage permission not granted');
  //     return;
  //   }

  //   // Get path to save PDF
  //   final outputDir =
  //       await getExternalStorageDirectory(); // Can also use getDownloadsDirectory
  //   final pdfFile = File(
  //       "${outputDir!.path}/Scanned_Document_${DateTime.now().millisecondsSinceEpoch}.pdf");

  //   await pdfFile.writeAsBytes(await pdf.save());

  //   debugPrint("PDF saved to: ${pdfFile.path}");

  //   // Open the generated PDF
  //   openPdf(pdfFile.path);
  // }

  // void openPdf(String path) {
  //   OpenFilex.open(path);
  // }

  void sharePdf() {
    if (generatedPdf != null) {
      Share.shareXFiles([XFile(generatedPdf!.path)],
          text: 'Here is your scanned PDF');
    }
  }

  void renamePdf() async {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename PDF"),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: "Enter new file name"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newName = _controller.text.trim();
              if (newName.isNotEmpty && generatedPdf != null) {
                final newPath = generatedPdf!.parent.path + "/$newName.pdf";
                final newFile = await generatedPdf!.rename(newPath);
                setState(() {
                  generatedPdf = newFile;
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PDF renamed successfully.")),
                );
              }
            },
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create PDF"),
        backgroundColor: const Color(0xFF274A31),
        actions: [
          if (generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: sharePdf,
            ),
          if (generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: renamePdf,
            ),
        ],
      ),
      body: Center(
        child: scannedImages.isEmpty
            ? ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Scan Documents"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF274A31)),
                onPressed: scanDocuments,
              )
            : const Text("PDF created and saved!"),
      ),
    );
  }
}
