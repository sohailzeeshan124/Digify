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
import 'package:http/http.dart' as http;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum SignMode { none, sign, stamp, highlight, text }

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  DrawingPath(
      {required this.points, required this.color, required this.strokeWidth});
}

class UIOverlayItem {
  final String id;
  final PdfOverlayItem item;
  UIOverlayItem({required this.id, required this.item});
}

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
  // Modes
  SignMode _currentMode = SignMode.none;

  // Overlays (Signatures, Stamps, Text)
  List<UIOverlayItem> _overlays = [];
  String? _selectedOverlayId;

  // Undo State
  List<Map<String, dynamic>> _actionStack =
      []; // [{'type': 'overlay', 'id': '...'}, {'type': 'path'}]

  // Highlight (Drawing)
  List<DrawingPath> _paths = [];
  DrawingPath? _currentPath;
  double _highlightThickness = 15.0;
  Color _highlightColor = Colors.yellow.withOpacity(0.3);
  bool _isEraser = false;

  // Text State
  // bool isTextMode = false; // Replaced by _currentMode == SignMode.text
  // Offset? textOffset; // Managed via _overlays now
  double _textSize = 20;
  Color _textColor = Colors.black;
  String _textFontFamily = 'Roboto';
  final _textController = TextEditingController();

  // PDF State
  int selectedPage = 0;
  final pdfViewerController = PdfViewerController();
  bool pdfLoaded = false;
  int pageCount = 1;
  final GlobalKey _pdfKey = GlobalKey();
  Size? displayedPageSize;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Helper Methods

  void _undo() {
    if (_actionStack.isEmpty) return;
    final lastAction = _actionStack.removeLast();
    setState(() {
      if (lastAction['type'] == 'overlay') {
        _overlays.removeWhere((e) => e.id == lastAction['id']);
        if (_selectedOverlayId == lastAction['id']) _selectedOverlayId = null;
      } else if (lastAction['type'] == 'path') {
        if (_paths.isNotEmpty) _paths.removeLast();
      }
    });
  }

  Future<void> _pickImage(bool isSignature) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userViewModel = UserViewModel();
    final userData = await userViewModel.getUser(currentUser.uid);
    if (userData == null) return;

    String? localPath =
        isSignature ? userData.signatureLocalPath : userData.stampLocalPath;
    String? cloudUrl = isSignature ? userData.signatureUrl : userData.stampUrl;

    File? targetFile;

    // 1. Check Local Path
    if (localPath != null && File(localPath).existsSync()) {
      targetFile = File(localPath);
    }
    // 2. Check Cloud URL and Download
    else if (cloudUrl != null && cloudUrl.isNotEmpty) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        final response = await http.get(Uri.parse(cloudUrl));
        if (response.statusCode == 200) {
          final docsDir = await getApplicationDocumentsDirectory();
          final filename =
              '${isSignature ? "signature" : "stamp"}_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(p.join(docsDir.path, filename));
          await file.writeAsBytes(response.bodyBytes);
          targetFile = file;

          // Optional: Update local path in user data for future use
          // await userViewModel.updateUser(currentUser.uid, {
          //   isSignature ? 'signatureLocalPath' : 'stampLocalPath': file.path
          // });
        }
        Navigator.pop(context); // Hide loading
      } catch (e) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error downloading image: $e")));
      }
    }

    // 3. Use Found File or Fallback to Gallery
    if (targetFile != null) {
      _addOverlay(targetFile);
    } else {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        _addOverlay(File(picked.path));
      }
    }
  }

  Future<void> _addOverlay(File file) async {
    final decoded = await decodeImageFromList(file.readAsBytesSync());
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _overlays.add(UIOverlayItem(
        id: id,
        item: PdfImageOverlay(
          imagePath: file.path,
          offset: const Offset(100, 100),
          width: 150,
          height: 150 * (decoded.height / decoded.width),
          rotation: 0,
          pageIndex: selectedPage,
        ),
      ));
      _selectedOverlayId = id;
      _currentMode = SignMode.none; // Reset mode after adding
      _actionStack.add({'type': 'overlay', 'id': id});
    });
  }

  void _addTextOverlay() {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _overlays.add(UIOverlayItem(
        id: id,
        item: PdfTextOverlay(
          text: 'Enter Text',
          offset: const Offset(100, 100),
          fontSize: 20,
          color: Colors.black,
          fontFamily: 'Helvetica', // Changed default to Helvetica
          pageIndex: selectedPage,
        ),
      ));
      _selectedOverlayId = id;
      _currentMode = SignMode.none;
      _actionStack.add({'type': 'overlay', 'id': id});
    });
    _showTextEditDialog(id);
  }

  void _pickColor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _highlightColor,
            onColorChanged: (color) {
              setState(() => _highlightColor = color.withOpacity(0.5));
            },
          ),
        ),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Got it'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showTextEditDialog(String id) {
    final index = _overlays.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final item = _overlays[index].item as PdfTextOverlay;
    _textController.text = item.text;
    _textSize = item.fontSize;
    _textColor = item.color;
    _textFontFamily = item.fontFamily;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(labelText: 'Text'),
                onChanged: (val) {
                  _updateTextOverlay(id, text: val);
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Size: '),
                  Expanded(
                    child: Slider(
                      value: _textSize,
                      min: 10,
                      max: 100,
                      onChanged: (val) {
                        setState(() => _textSize = val);
                        _updateTextOverlay(id, fontSize: val);
                      },
                    ),
                  ),
                  Text(_textSize.toInt().toString()),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _colorButton(Colors.black, id),
                  _colorButton(Colors.red, id),
                  _colorButton(Colors.blue, id),
                  _colorButton(Colors.green, id),
                ],
              ),
              DropdownButton<String>(
                value: _textFontFamily,
                items: ['Helvetica', 'Times', 'Courier']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _textFontFamily = val);
                    _updateTextOverlay(id, fontFamily: val);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorButton(Color color, String id) {
    return GestureDetector(
      onTap: () {
        setState(() => _textColor = color);
        _updateTextOverlay(id, color: color);
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }

  void _updateTextOverlay(String id,
      {String? text, double? fontSize, Color? color, String? fontFamily}) {
    final index = _overlays.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final oldItem = _overlays[index].item as PdfTextOverlay;
    setState(() {
      _overlays[index] = UIOverlayItem(
        id: id,
        item: PdfTextOverlay(
          text: text ?? oldItem.text,
          offset: oldItem.offset,
          fontSize: fontSize ?? oldItem.fontSize,
          color: color ?? oldItem.color,
          fontFamily: fontFamily ?? oldItem.fontFamily,
          pageIndex: oldItem.pageIndex,
        ),
      );
    });
  }

  void _updateOverlay(String id, PdfOverlayItem newItem) {
    final index = _overlays.indexWhere((e) => e.id == id);
    if (index != -1) {
      setState(() {
        _overlays[index] = UIOverlayItem(id: id, item: newItem);
      });
    }
  }

  void _deleteOverlay(String id) {
    setState(() {
      _overlays.removeWhere((e) => e.id == id);
      if (_selectedOverlayId == id) _selectedOverlayId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Document"),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _undo,
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Finalize & Sign'),
                  content: const Text(
                      'Are you sure you want to finalize and sign this document?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes')),
                  ],
                ),
              );
              if (confirm == true) await onFinalizeAndSign();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: _currentMode == SignMode.highlight
                      ? (details) {
                          setState(() {
                            _currentPath = DrawingPath(
                              points: [
                                details.localPosition,
                                details.localPosition
                              ], // Start and End same initially
                              color: _isEraser
                                  ? Colors.transparent
                                  : _highlightColor,
                              strokeWidth: _highlightThickness,
                            );
                            _paths.add(_currentPath!);
                            _actionStack.add({'type': 'path'});
                          });
                        }
                      : null,
                  onPanUpdate: _currentMode == SignMode.highlight
                      ? (details) {
                          setState(() {
                            // Update end point only for straight line
                            if (_currentPath != null &&
                                _currentPath!.points.isNotEmpty) {
                              if (_currentPath!.points.length > 1) {
                                _currentPath!.points[1] = details.localPosition;
                              } else {
                                _currentPath!.points.add(details.localPosition);
                              }
                            }
                          });
                        }
                      : null,
                  onPanEnd: _currentMode == SignMode.highlight
                      ? (details) {
                          setState(() {
                            _currentPath = null;
                          });
                        }
                      : null,
                  child: Stack(
                    children: [
                      // PDF Viewer
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
                          enableDoubleTapZooming: false,
                          pageLayoutMode: PdfPageLayoutMode.single,
                        ),
                      ),

                      // Highlights
                      if (pdfLoaded)
                        CustomPaint(
                          painter: HighlightPainter(paths: _paths),
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                        ),

                      // Overlays
                      if (pdfLoaded)
                        ..._overlays
                            .map((uiItem) => _OverlayWidget(
                                  key: ValueKey(uiItem.id),
                                  item: uiItem.item,
                                  isSelected: _selectedOverlayId == uiItem.id,
                                  onTap: () {
                                    setState(
                                        () => _selectedOverlayId = uiItem.id);
                                    if (uiItem.item is PdfTextOverlay) {
                                      _showTextEditDialog(uiItem.id);
                                    }
                                  },
                                  onUpdate: (newItem) =>
                                      _updateOverlay(uiItem.id, newItem),
                                  onDelete: () => _deleteOverlay(uiItem.id),
                                ))
                            .toList(),

                      // Secondary Toolbar (Overlay)
                      if (_currentMode == SignMode.highlight)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.grey[200],
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                const Text('Thickness'),
                                Expanded(
                                  child: Slider(
                                    value: _highlightThickness,
                                    min: 5,
                                    max: 50,
                                    onChanged: (val) => setState(
                                        () => _highlightThickness = val),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.circle,
                                      color: Colors.yellow.withOpacity(0.5)),
                                  onPressed: () => setState(() =>
                                      _highlightColor =
                                          Colors.yellow.withOpacity(0.3)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.circle,
                                      color: Colors.green.withOpacity(0.5)),
                                  onPressed: () => setState(() =>
                                      _highlightColor =
                                          Colors.green.withOpacity(0.3)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.color_lens,
                                      color: _highlightColor),
                                  onPressed: _pickColor,
                                  tooltip: 'Pick Color',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () =>
                                      setState(() => _paths.clear()),
                                  tooltip: 'Clear All',
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Bar
          BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.edit,
                      color: _currentMode == SignMode.sign
                          ? Colors.blue
                          : Colors.grey),
                  onPressed: () {
                    setState(() => _currentMode = SignMode.sign);
                    _pickImage(true);
                  },
                  tooltip: 'Signature',
                ),
                IconButton(
                  icon: Icon(Icons.approval,
                      color: _currentMode == SignMode.stamp
                          ? Colors.blue
                          : Colors.grey),
                  onPressed: () {
                    setState(() => _currentMode = SignMode.stamp);
                    _pickImage(false);
                  },
                  tooltip: 'Stamp',
                ),
                IconButton(
                  icon: Icon(Icons.brush,
                      color: _currentMode == SignMode.highlight
                          ? Colors.blue
                          : Colors.grey),
                  onPressed: () => setState(() => _currentMode =
                      _currentMode == SignMode.highlight
                          ? SignMode.none
                          : SignMode.highlight),
                  tooltip: 'Highlight',
                ),
                IconButton(
                  icon: Icon(Icons.text_fields,
                      color: _currentMode == SignMode.text
                          ? Colors.blue
                          : Colors.grey),
                  onPressed: () {
                    setState(() => _currentMode = SignMode.text);
                    _addTextOverlay();
                  },
                  tooltip: 'Text',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> onFinalizeAndSign() async {
    try {
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
        docId = existingUid;
        docRef = FirebaseFirestore.instance.collection('documents').doc(docId);
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
        docRef = FirebaseFirestore.instance.collection('documents').doc();
        docId = docRef.id;
        final document = DocumentModel(
          docId: docId,
          docName: fileName,
          uploadedBy: currentUser.uid,
          createdAt: DateTime.now(),
          pdfUrl: widget.pdfPath,
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

      // Prepare overlays for PdfUtils
      // We need to scale coordinates from UI to PDF
      final inputPdfBytes = File(inputPdfPath).readAsBytesSync();
      final sf.PdfDocument pdfDocForSize =
          sf.PdfDocument(inputBytes: inputPdfBytes);

      // Assuming single page view or we map page indices correctly
      // For now, we map UI overlays to the selected page or default
      // But wait, overlays in UI are on top of the viewer.
      // We need to know which page they belong to.
      // Current implementation: overlays are global on the screen.
      // We need to map them to the PDF page size.

      // Get displayed size
      RenderBox? renderBox =
          _pdfKey.currentContext?.findRenderObject() as RenderBox?;
      displayedPageSize = renderBox?.size;

      // We need to calculate scale for each page?
      // Or assume the viewer shows one page at a time and we only support signing that page?
      // The user requested "imbed pdf file".

      // Let's iterate through overlays and convert them
      List<PdfOverlayItem> pdfOverlays = [];

      // For drawing paths (Highlights)
      // We need to group them by page?
      // Currently _paths are just offsets on the screen.
      // If the user scrolls, the offsets might be wrong if they are relative to the screen.
      // Ideally, we should capture points relative to the PDF page.
      // But SfPdfViewer doesn't easily give us coordinate mapping.

      // SIMPLIFICATION: We assume the user is working on the currently visible page (selectedPage).
      // We will map all current overlays to this page.

      final targetPage = pdfDocForSize.pages[selectedPage];
      final pdfPageWidth = targetPage.size.width;
      final pdfPageHeight = targetPage.size.height;

      double widgetWidth = displayedPageSize?.width ?? pdfPageWidth;
      double widgetHeight = displayedPageSize?.height ?? pdfPageHeight;

      double scaleToFit =
          (widgetWidth / pdfPageWidth).clamp(0.0, double.infinity);
      if ((pdfPageHeight * scaleToFit) > widgetHeight) {
        scaleToFit = (widgetHeight / pdfPageHeight).clamp(0.0, double.infinity);
      }

      double padX = (widgetWidth - pdfPageWidth * scaleToFit) / 2;
      double padY = (widgetHeight - pdfPageHeight * scaleToFit) / 2;

      // Convert UI Overlays
      for (final uiItem in _overlays) {
        final item = uiItem.item;
        if (item is PdfImageOverlay) {
          // Convert offset/size
          final pdfLeft = (item.offset.dx - padX) / scaleToFit;
          final pdfTop = (item.offset.dy - padY) / scaleToFit;
          final pdfWidth =
              (item.width) / scaleToFit; // Width in UI pixels -> PDF units
          final pdfHeight = (item.height) / scaleToFit;

          pdfOverlays.add(PdfImageOverlay(
            imagePath: item.imagePath,
            offset: Offset(pdfLeft, pdfTop),
            width: pdfWidth,
            height: pdfHeight,
            rotation: item.rotation,
            pageIndex: selectedPage,
          ));
        } else if (item is PdfTextOverlay) {
          final pdfLeft = (item.offset.dx - padX) / scaleToFit;
          final pdfTop = (item.offset.dy - padY) / scaleToFit;
          // Font size scaling?
          final pdfFontSize = item.fontSize / scaleToFit;

          pdfOverlays.add(PdfTextOverlay(
            text: item.text,
            offset: Offset(pdfLeft, pdfTop),
            fontSize: pdfFontSize,
            color: item.color,
            fontFamily: item.fontFamily,
            pageIndex: selectedPage,
          ));
        }
      }

      // Convert Highlights
      if (_paths.isNotEmpty) {
        List<Offset?> pdfPoints = [];
        for (final path in _paths) {
          // Start new path
          pdfPoints
              .add(null); // Separator if needed, or we create separate overlays
          // Actually PdfDrawingOverlay takes a list of points.
          // We should create one overlay per path to preserve color/thickness

          List<Offset> convertedPoints = [];
          for (final p in path.points) {
            final pdfX = (p.dx - padX) / scaleToFit;
            final pdfY = (p.dy - padY) / scaleToFit;
            convertedPoints.add(Offset(pdfX, pdfY));
          }

          // Add as separate overlay
          // We need to change PdfDrawingOverlay to take List<Offset> not List<Offset?> for simplicity or handle it
          // My PdfUtils implementation takes List<Offset?>.

          List<Offset?> pointsWithNulls = [];
          pointsWithNulls.addAll(convertedPoints);

          pdfOverlays.add(PdfDrawingOverlay(
            points: pointsWithNulls,
            color: path.color,
            strokeWidth: path.strokeWidth / scaleToFit,
            pageIndex: selectedPage,
          ));
        }
      }

      pdfDocForSize.dispose();

      final signedPdfPath = await PdfUtils.embedOverlays(
        pdfPath: inputPdfPath,
        overlays: pdfOverlays,
      );

      await embedUidInPdf(signedPdfPath, docId);

      if (existingUid.isEmpty) {
        await PdfUtils.appendQrCodePage(signedPdfPath, docId);
      }

      String? finalPath;
      if (Platform.isAndroid) {
        final docsDir = Directory('/storage/emulated/0/Documents/signed_docs');
        if (!await docsDir.exists()) {
          await docsDir.create(recursive: true);
        }
        finalPath = p.join(docsDir.path, '${fileName}_signed.pdf');
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        final signedDocsDir = Directory(p.join(docsDir.path, 'signed_docs'));
        if (!await signedDocsDir.exists()) {
          await signedDocsDir.create(recursive: true);
        }
        finalPath = p.join(signedDocsDir.path, '${fileName}_signed.pdf');
      }
      await File(signedPdfPath).copy(finalPath);

      await docRef.update({
        'pdfUrl': finalPath,
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document signed successfully.")));
      Navigator.pop(context);
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error signing document: $e")));
    }
  }
}

class HighlightPainter extends CustomPainter {
  final List<DrawingPath> paths;
  HighlightPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      final paint = Paint()
        ..color = path.color
        ..strokeWidth = path.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < path.points.length - 1; i++) {
        canvas.drawLine(path.points[i], path.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _OverlayWidget extends StatefulWidget {
  final PdfOverlayItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<PdfOverlayItem> onUpdate;
  final VoidCallback onDelete;

  const _OverlayWidget({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<_OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<_OverlayWidget> {
  late Offset _localOffset;
  late double _localWidth;
  late double _localHeight;
  late double _localRotation;
  late double _localFontSize;

  @override
  void initState() {
    super.initState();
    _initializeLocalState();
  }

  @override
  void didUpdateWidget(covariant _OverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _initializeLocalState();
    }
  }

  void _initializeLocalState() {
    if (widget.item is PdfImageOverlay) {
      final item = widget.item as PdfImageOverlay;
      _localOffset = item.offset;
      _localWidth = item.width;
      _localHeight = item.height;
      _localRotation = item.rotation;
    } else if (widget.item is PdfTextOverlay) {
      final item = widget.item as PdfTextOverlay;
      _localOffset = item.offset;
      _localFontSize = item.fontSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item is PdfImageOverlay) {
      final imgItem = widget.item as PdfImageOverlay;
      return Positioned(
        left: _localOffset.dx,
        top: _localOffset.dy,
        child: GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: (details) {
            setState(() {
              _localOffset += details.delta;
            });
          },
          onPanEnd: (details) {
            widget.onUpdate(PdfImageOverlay(
              imagePath: imgItem.imagePath,
              offset: _localOffset,
              width: _localWidth,
              height: _localHeight,
              rotation: _localRotation,
              pageIndex: imgItem.pageIndex,
            ));
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _localWidth,
                height: _localHeight,
                decoration: widget.isSelected
                    ? BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 2),
                      )
                    : null,
                child: Transform.rotate(
                  angle: _localRotation,
                  child: Image.file(File(imgItem.imagePath), fit: BoxFit.fill),
                ),
              ),
              if (widget.isSelected) ...[
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _localWidth =
                            (_localWidth + details.delta.dx).clamp(50.0, 500.0);
                        final aspectRatio = imgItem.width / imgItem.height;
                        _localHeight = _localWidth / aspectRatio;
                      });
                    },
                    onPanEnd: (details) {
                      widget.onUpdate(PdfImageOverlay(
                        imagePath: imgItem.imagePath,
                        offset: _localOffset,
                        width: _localWidth,
                        height: _localHeight,
                        rotation: _localRotation,
                        pageIndex: imgItem.pageIndex,
                      ));
                    },
                    child: const Icon(Icons.open_with, color: Colors.blue),
                  ),
                ),
                Positioned(
                  top: -25,
                  right: -25,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: widget.onDelete,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } else if (widget.item is PdfTextOverlay) {
      final txtItem = widget.item as PdfTextOverlay;
      return Positioned(
        left: _localOffset.dx,
        top: _localOffset.dy,
        child: GestureDetector(
          onTap: widget.onTap,
          onPanUpdate: (details) {
            setState(() {
              _localOffset += details.delta;
            });
          },
          onPanEnd: (details) {
            widget.onUpdate(PdfTextOverlay(
              text: txtItem.text,
              offset: _localOffset,
              fontSize: txtItem.fontSize,
              color: txtItem.color,
              fontFamily: txtItem.fontFamily,
              pageIndex: txtItem.pageIndex,
            ));
          },
          child: Container(
            decoration: widget.isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 1),
                  )
                : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  txtItem.text,
                  style: TextStyle(
                    fontSize: txtItem.fontSize,
                    color: txtItem.color,
                    fontFamily: txtItem.fontFamily,
                  ),
                ),
                if (widget.isSelected)
                  Positioned(
                    top: -25,
                    right: -25,
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onDelete,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
