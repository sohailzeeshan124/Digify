import 'dart:io';
import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/pdf_preview_page.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'package:digify/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePdfPage extends StatefulWidget {
  const CreatePdfPage({super.key});

  @override
  State<CreatePdfPage> createState() => _CreatePdfPageState();
}

class _CreatePdfPageState extends State<CreatePdfPage> {
  List<File> scannedImages = [];
  File? generatedPdf;
  bool _isScanning = false;
  UserViewModel _userViewModel = UserViewModel();

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        scanDocuments();
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> scanDocuments() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    dynamic scannedDocs;

    try {
      scannedDocs = await FlutterDocScanner().getScanDocuments(page: 100);

      debugPrint('ScannedDocs: $scannedDocs');

      if (scannedDocs != null &&
          scannedDocs is Map &&
          scannedDocs.containsKey('pdfUri')) {
        final pdfUri = scannedDocs['pdfUri'];
        final pdfPath = Uri.parse(pdfUri).toFilePath();
        final originalFile = File(pdfPath);

        if (await originalFile.exists()) {
          debugPrint('✅ PDF file exists at: $pdfPath');

          // Create a better destination folder: /Documents/PDF_docs
          final targetDir = Directory('/storage/emulated/0/Documents/PDF_docs');
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

          setState(() {
            generatedPdf = movedFile;
            _isScanning = false;
          });

          if (!mounted) return;

          // Show rename dialog immediately for the new file
          await _showRenameDialog(isNewFile: true);
        } else {
          debugPrint('❌ PDF file does not exist.');
          setState(() => _isScanning = false);
        }
      } else {
        debugPrint('⚠️ Scanning returned no results.');
        setState(() => _isScanning = false);
        if (mounted) {
          // If scanning was cancelled or failed, go back
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('❌ Error during scanning: $e');
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanning failed: $e')),
        );
      }
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

  Future<void> _showRenameDialog({bool isNewFile = false}) async {
    final TextEditingController controller = TextEditingController();
    if (generatedPdf != null && !isNewFile) {
      final fileName = generatedPdf!.path.split('/').last;
      controller.text = fileName.replaceAll('.pdf', '');
    }

    await showDialog(
      context: context,
      barrierDismissible: !isNewFile, // Force naming for new files
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isNewFile ? "Name Your Document" : "Rename Document",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isNewFile)
              Text(
                "Please give your PDF file a name.",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Enter file name",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primaryGreen),
                ),
              ),
              style: GoogleFonts.poppins(),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (!isNewFile)
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && generatedPdf != null) {
                try {
                  final parentPath = generatedPdf!.parent.path;
                  final newPath = "$parentPath/$newName.pdf";
                  final newFile = await generatedPdf!.rename(newPath);

                  setState(() {
                    generatedPdf = newFile;
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isNewFile
                              ? "Document saved as $newName.pdf"
                              : "Document renamed successfully",
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error renaming file: $e");
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error renaming file: $e")),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              "Save",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create PDF",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: sharePdf,
            ),
          if (generatedPdf != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showRenameDialog(isNewFile: false),
            ),
        ],
      ),
      body: Center(
        child: _isScanning
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Scanning in progress...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            : generatedPdf != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryGreen,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "PDF Created Successfully!",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          generatedPdf!.path.split('/').last,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PdfPreviewPage(pdfFile: generatedPdf!),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text("View PDF"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: scanDocuments,
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text("Scan Another"),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Start Scanning"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: scanDocuments,
                  ),
      ),
    );
  }
}
