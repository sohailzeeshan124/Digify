import 'dart:io';

import 'package:digify/modal_classes/document.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/pdf_utils.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;

import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

// Embed UID into PDF metadata (subject field)
Future<void> embedUidInPdf(String pdfPath, String uid) async {
  final bytes = await File(pdfPath).readAsBytes();
  final doc = sf.PdfDocument(inputBytes: bytes);
  doc.documentInformation.subject = uid;
  final newBytes = doc.saveSync();
  await File(pdfPath).writeAsBytes(newBytes, flush: true);
  doc.dispose();
}

class DocumentSignScreen extends StatefulWidget {
  final String pdfPath;
  final String documentId; // Firestore doc ID
  const DocumentSignScreen({required this.pdfPath, required this.documentId});

  @override
  State<DocumentSignScreen> createState() => _DocumentSignScreenState();
}

class _DocumentSignScreenState extends State<DocumentSignScreen> {
  // Text overlay state
  bool isTextMode = false;
  Offset? textOffset;
  String overlayText = '';
  double textFontSize = 20;
  Color textColor = Colors.black;
  String textFontFamily = 'Roboto';
  bool isEditingText = false;
  final textController = TextEditingController();
  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  File? signatureImage;
  Offset offset = Offset(100, 100);
  double scale = 1.0;
  double rotation = 0.0;
  double signatureWidth = 100; // Only width in state
  double? aspectRatio; // Store aspect ratio of signature image
  int selectedPage = 0;
  final pdfViewerController = PdfViewerController();
  bool pdfLoaded = false;
  int pageCount = 1;
  final GlobalKey _pdfKey = GlobalKey();
  Size? displayedPageSize;

  Future<Size> _getImageSize(File file) async {
    final decoded = await decodeImageFromList(file.readAsBytesSync());
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }

  @override
  void initState() {
    super.initState();
    // No need to load images, just use SfPdfViewer
  }

  Future<void> pickSignatureImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final decoded = await decodeImageFromList(file.readAsBytesSync());
      setState(() {
        signatureImage = file;
        aspectRatio = decoded.width / decoded.height;
      });
    }
  }

  Future<void> onFinalizeAndSign() async {
    // final viewmodel = DocumentViewModel(); // Not used, remove warning

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

      // Get the filename from the PDF path
      final fileName = widget.pdfPath.split('/').last.replaceAll('.pdf', '');

      // Get current user data
      final currentUser = FirebaseAuth.instance.currentUser;
      final userdataviewmodel = UserViewModel();
      final UserModel? userData =
          await userdataviewmodel.getUser(currentUser!.uid);

      // Check for existing UID in PDF metadata
      String? docId;
      DocumentReference<Map<String, dynamic>>? docRef;
      String inputPdfPath = widget.pdfPath;
      String? firestorePdfUrl;
      final originalPdfBytes = File(widget.pdfPath).readAsBytesSync();
      final sf.PdfDocument pdfDocForMeta =
          sf.PdfDocument(inputBytes: originalPdfBytes);
      final existingUid = pdfDocForMeta.documentInformation.subject;
      pdfDocForMeta.dispose();

      if (existingUid != null && existingUid.isNotEmpty) {
        // Use existing UID, update Firestore document
        docId = existingUid;
        docRef = FirebaseFirestore.instance.collection('documents').doc(docId);
        // Get the latest signed PDF path from Firestore
        final docSnap = await docRef.get();
        if (docSnap.exists &&
            docSnap.data() != null &&
            docSnap.data()!['pdfUrl'] != null) {
          firestorePdfUrl = docSnap.data()!['pdfUrl'] as String;
          if (firestorePdfUrl.isNotEmpty &&
              File(firestorePdfUrl).existsSync()) {
            inputPdfPath = firestorePdfUrl;
          }
        }
        // Only update signedBy array, do not add QR code page or create new doc
        await docRef.update({
          'signedBy': FieldValue.arrayUnion([
            {
              'uid': currentUser.uid,
              'displayName': userData!.username,
              'signedAt': DateTime.now().toString(),
            }
          ])
        });
      } else {
        // Create new Firestore document and UID
        docRef = FirebaseFirestore.instance.collection('documents').doc();
        docId = docRef.id;
        // Create the document model and save to Firestore
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
        await docRef.set(document.toMap());
      }

      // Now modify the PDF with signature and QR code

      // Always use the latest input PDF (original or last signed)
      final inputPdfBytes = File(inputPdfPath).readAsBytesSync();
      final sf.PdfDocument pdfDocForSize =
          sf.PdfDocument(inputBytes: inputPdfBytes);
      final lastPage = pdfDocForSize.pages[pdfDocForSize.pages.count - 1];
      final pdfPageWidth = lastPage.size.width;
      final pdfPageHeight = lastPage.size.height;
      pdfDocForSize.dispose();

      // Get the displayed page size in the widget
      RenderBox? renderBox =
          _pdfKey.currentContext?.findRenderObject() as RenderBox?;
      displayedPageSize = renderBox?.size;
      double widgetWidth = displayedPageSize?.width ?? pdfPageWidth;
      double widgetHeight = displayedPageSize?.height ?? pdfPageHeight;

      // Calculate scale to fit PDF page into widget (preserving aspect ratio)
      double scaleToFit =
          (widgetWidth / pdfPageWidth).clamp(0.0, double.infinity);
      if ((pdfPageHeight * scaleToFit) > widgetHeight) {
        scaleToFit = (widgetHeight / pdfPageHeight).clamp(0.0, double.infinity);
      }

      // Calculate padding (letterboxing)
      double padX = (widgetWidth - pdfPageWidth * scaleToFit) / 2;
      double padY = (widgetHeight - pdfPageHeight * scaleToFit) / 2;

      // Remove padding from overlay offset, then scale to PDF coordinates
      final double overlayLeft = (offset.dx - padX) / scaleToFit;
      final double overlayTop = (offset.dy - padY) / scaleToFit;
      final double overlayWidth = (signatureWidth * scale) / scaleToFit;
      // Use stored aspect ratio
      final double signatureHeight = signatureWidth / (aspectRatio ?? 1.5);
      final double overlayHeight = (signatureHeight * scale) / scaleToFit;

      // Clamp to PDF page bounds
      final Offset pdfOffset = Offset(
        overlayLeft.clamp(0, pdfPageWidth - overlayWidth),
        overlayTop.clamp(0, pdfPageHeight - overlayHeight),
      );
      final double pdfWidth = overlayWidth.clamp(1, pdfPageWidth);
      final double pdfHeight = overlayHeight.clamp(1, pdfPageHeight);

      final signedPdfPath = await PdfUtils.embedSignature(
        pdfPath: inputPdfPath,
        signaturePath: signatureImage!.path,
        offset: pdfOffset,
        width: pdfWidth,
        height: pdfHeight,
        rotation: rotation,
      );

      // Always embed UID in PDF metadata (even for existing documents)
      await embedUidInPdf(signedPdfPath, docId);

      // Only add QR code page if this is a new document (no existing UID)
      if (existingUid.isEmpty) {
        await PdfUtils.appendQrCodePage(signedPdfPath, docId);
      }

      // Store the signed PDF in a user-accessible Documents/Digify/signed_docs folder
      String? finalPath;
      // Directory? signedDocsDir; // Remove unused variable
      if (Platform.isAndroid) {
        // Use the public Documents directory on Android
        final docsDir = Directory('/storage/emulated/0/Documents/signed_docs');
        if (!await docsDir.exists()) {
          await docsDir.create(recursive: true);
        }
        finalPath = p.join(docsDir.path, '${fileName}_signed.pdf');
      } else {
        // Use the user's Documents directory on other platforms
        final docsDir = await getApplicationDocumentsDirectory();
        final signedDocsDir = Directory(p.join(docsDir.path, 'signed_docs'));
        if (!await signedDocsDir.exists()) {
          await signedDocsDir.create(recursive: true);
        }
        finalPath = p.join(signedDocsDir.path, '${fileName}_signed.pdf');
      }
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
      appBar: AppBar(
        title: const Text("Sign Document"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Cancel',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cancel Signing'),
                  content: const Text('Are you sure you want to cancel?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            tooltip: 'Finalize & Sign',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Finalize & Sign'),
                  content: const Text(
                      'Are you sure you want to finalize and sign this document?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await onFinalizeAndSign();
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: isTextMode
                ? (details) {
                    setState(() {
                      textOffset = details.localPosition;
                      isEditingText = true;
                      overlayText = '';
                      textController.text = '';
                    });
                  }
                : null,
            child: Stack(
              children: [
                // PDF Viewer (Syncfusion)
                Container(
                  key: _pdfKey,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: SfPdfViewer.file(
                    File(widget.pdfPath),
                    controller: pdfViewerController,
                    onDocumentLoaded: (details) {
                      setState(() {
                        pdfLoaded = true;
                        pageCount = details.document.pages.count;
                      });
                    },
                    onPageChanged: (details) {
                      setState(() {
                        selectedPage = details.newPageNumber - 1;
                      });
                    },
                    canShowScrollHead: false,
                    canShowScrollStatus: false,
                    enableDoubleTapZooming: false,
                    pageLayoutMode: PdfPageLayoutMode.single,
                  ),
                ),
                // Overlay signature only on the selected page
                if (signatureImage != null && pdfLoaded && aspectRatio != null)
                  Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: _SignatureOverlay(
                      signatureImage: signatureImage!,
                      width: signatureWidth * scale,
                      // height is always width / aspectRatio
                      height: (signatureWidth * scale) / aspectRatio!,
                      scale: scale,
                      rotation: rotation,
                      onResize: (delta) {
                        setState(() {
                          signatureWidth =
                              (signatureWidth + delta.dx).clamp(40, 600);
                          // height is always width / aspectRatio, so no update needed
                        });
                      },
                      onRotate: (delta) {
                        setState(() {
                          rotation += delta.dx * 0.01;
                        });
                      },
                      onMove: (delta) {
                        setState(() {
                          offset += delta;
                        });
                      },
                    ),
                  ),
                // Text overlay box
                if (isTextMode && textOffset != null)
                  Positioned(
                    left: textOffset!.dx,
                    top: textOffset!.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          textOffset = textOffset! + details.delta;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 2),
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: isEditingText
                            ? SizedBox(
                                width: 180,
                                child: TextField(
                                  controller: textController,
                                  autofocus: true,
                                  style: TextStyle(
                                    fontSize: textFontSize,
                                    color: textColor,
                                    fontFamily: textFontFamily,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter text...',
                                  ),
                                  onSubmitted: (val) {
                                    setState(() {
                                      overlayText = val;
                                      isEditingText = false;
                                    });
                                  },
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isEditingText = true;
                                    textController.text = overlayText;
                                  });
                                },
                                child: Text(
                                  overlayText.isEmpty
                                      ? 'Tap to edit'
                                      : overlayText,
                                  style: TextStyle(
                                    fontSize: textFontSize,
                                    color: textColor,
                                    fontFamily: textFontFamily,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                // Dotted border overlay (optional, for visual feedback)
                if (pdfLoaded)
                  IgnorePointer(
                    child: CustomPaint(
                      painter: DottedBorderPainter(),
                      child: Container(),
                    ),
                  ),
                // Page number indicator (e.g., 1/3)
                if (pdfLoaded && pageCount > 1)
                  Positioned(
                    top: 16,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${selectedPage + 1}/$pageCount',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: isTextMode
              ? Row(
                  key: const ValueKey('textOptions'),
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Font size
                    Row(
                      children: [
                        const Text('Size'),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              textFontSize = (textFontSize - 2).clamp(10, 60);
                            });
                          },
                        ),
                        Text(textFontSize.toInt().toString()),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              textFontSize = (textFontSize + 2).clamp(10, 60);
                            });
                          },
                        ),
                      ],
                    ),
                    // Color picker (simple)
                    Row(
                      children: [
                        const Text('Color'),
                        IconButton(
                          icon: Icon(Icons.circle, color: Colors.black),
                          onPressed: () {
                            setState(() {
                              textColor = Colors.black;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.circle, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              textColor = Colors.red;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.circle, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              textColor = Colors.blue;
                            });
                          },
                        ),
                      ],
                    ),
                    // Font family (simple dropdown)
                    DropdownButton<String>(
                      value: textFontFamily,
                      items: const [
                        DropdownMenuItem(
                            value: 'Roboto', child: Text('Roboto')),
                        DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                        DropdownMenuItem(value: 'Times', child: Text('Times')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          textFontFamily = val ?? 'Roboto';
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Close Text Options',
                      onPressed: () {
                        setState(() {
                          isTextMode = false;
                          textOffset = null;
                          overlayText = '';
                        });
                      },
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('iconBar'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: Color(0xFF274A31), size: 32),
                      tooltip: 'Pick Signature',
                      onPressed: pickSignatureImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.text_fields,
                          color: Colors.deepPurple, size: 32),
                      tooltip: 'Add Text',
                      onPressed: () {
                        setState(() {
                          isTextMode = true;
                        });
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// Custom painter for dotted border (optional, for visual feedback)
class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    // Top
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
    // Right
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width, startY),
        Offset(size.width, (startY + dashWidth).clamp(0, size.height)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
    // Bottom
    startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height),
        Offset((startX + dashWidth).clamp(0, size.width), size.height),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
    // Left
    startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashWidth).clamp(0, size.height)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Signature overlay widget with resize and rotate handles
class _SignatureOverlay extends StatelessWidget {
  final File signatureImage;
  final double width;
  final double height;
  final double scale;
  final double rotation;
  final ValueChanged<Offset> onResize;
  final ValueChanged<Offset> onRotate;
  final ValueChanged<Offset> onMove;

  const _SignatureOverlay({
    required this.signatureImage,
    required this.width,
    required this.height,
    required this.scale,
    required this.rotation,
    required this.onResize,
    required this.onRotate,
    required this.onMove,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onMove(details.delta),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: DottedBorderPainter(),
              child: Image.file(
                signatureImage,
                width: width,
                height: height,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Resize handle (arrow) at bottom right
          Positioned(
            right: -16,
            bottom: -16,
            child: GestureDetector(
              onPanUpdate: (details) => onResize(details.delta),
              child: Icon(Icons.open_with, color: Colors.blue, size: 28),
            ),
          ),
          // Rotate handle (loop arrow) above center
          Positioned(
            top: -32,
            child: GestureDetector(
              onPanUpdate: (details) => onRotate(details.delta),
              child: Icon(Icons.rotate_right, color: Colors.orange, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
