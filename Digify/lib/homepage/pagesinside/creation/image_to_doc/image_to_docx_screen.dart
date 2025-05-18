import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:archive/archive.dart';

class ImageToDocxScreen extends StatefulWidget {
  const ImageToDocxScreen({super.key});

  @override
  State<ImageToDocxScreen> createState() => _ImageToDocxScreenState();
}

class _ImageToDocxScreenState extends State<ImageToDocxScreen> {
  File? _imageFile;
  String _extractedText = '';
  File? _generatedDocx;
  final TextEditingController _filenameController =
      TextEditingController(text: 'converted_document');
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  bool _isTextEdited = false;
  List<TextBlock> _textBlocks = [];
  TextRecognizer? _textRecognizer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  @override
  void dispose() {
    _textController.dispose();
    _filenameController.dispose();
    _textRecognizer?.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _isProcessing = true;
      });
      await _extractText();
    }
  }

  Future<void> _extractText() async {
    if (_imageFile == null || _textRecognizer == null) return;

    final inputImage = InputImage.fromFile(_imageFile!);

    try {
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      setState(() {
        _textBlocks = recognizedText.blocks;
        _extractedText = _formatRecognizedText(recognizedText);
        _textController.text = _extractedText;
        _isTextEdited = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extracting text: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _formatRecognizedText(RecognizedText recognizedText) {
    final buffer = StringBuffer();
    String? currentBlockType;
    double? lastLineBottom;

    // Sort blocks by vertical position for better document flow
    final sortedBlocks = recognizedText.blocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (final block in sortedBlocks) {
      final blockType = _detectBlockType(block);

      if (blockType != currentBlockType) {
        if (currentBlockType != null) buffer.write('\n');
        currentBlockType = blockType;
      }

      // Sort lines by vertical position
      final sortedLines = block.lines.toList()
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      for (final line in sortedLines) {
        // Add paragraph break if there's a significant vertical gap
        if (lastLineBottom != null &&
            line.boundingBox.top - lastLineBottom >
                line.boundingBox.height * 0.5) {
          buffer.write('\n');
        }

        // Format text based on confidence, style, and language
        final formattedText = _formatLine(line);
        buffer.write(formattedText);
        buffer.write('\n');

        lastLineBottom = line.boundingBox.bottom;
      }
    }

    return buffer.toString();
  }

  String _detectBlockType(TextBlock block) {
    if (block.lines.isEmpty) return 'normal';

    final firstLine = block.lines.first;
    final avgConfidence = block.lines.map((l) => l.confidence ?? 0.0).average;
    final isHeader = firstLine.boundingBox.height > 40 ||
        avgConfidence > 0.9 ||
        block.recognizedLanguages.contains('en');

    return isHeader ? 'header' : 'normal';
  }

  String _formatLine(TextLine line) {
    final buffer = StringBuffer();
    bool isBold = false;
    bool isItalic = false;

    // Sort elements by horizontal position
    final sortedElements = line.elements.toList()
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    for (final element in sortedElements) {
      // More sophisticated style detection
      final confidence = element.confidence ?? 0.0;
      final height = element.boundingBox.height;
      final width = element.boundingBox.width;
      final text = element.text;

      // Detect bold based on multiple factors
      isBold = confidence > 0.85 &&
          height > 30 &&
          width > height * 0.5 &&
          !text.contains(RegExp(r'[a-z]')); // Often bold text is uppercase

      // Detect italic based on confidence and text characteristics
      isItalic = confidence < 0.7 && text.length > 1 && !isBold;

      // Add appropriate formatting tags
      if (isBold) buffer.write('<b>');
      if (isItalic) buffer.write('<i>');
      buffer.write(text);
      if (isItalic) buffer.write('</i>');
      if (isBold) buffer.write('</b>');
      buffer.write(' ');
    }

    return buffer.toString().trim();
  }

  Future<void> _generateDocx() async {
    try {
      // Create Digify folder in Documents directory
      final documentsDir = Directory('/storage/emulated/0/Documents/Digify');
      final digifyFolder =
          Directory('${documentsDir.path}/digify_image_to_docx');
      if (!await digifyFolder.exists()) {
        await digifyFolder.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${digifyFolder.path}/$fileName.docx';

      // Create the document.xml content with proper text formatting
      final documentXml =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    ${_generateDocumentContent()}
  </w:body>
</w:document>''';

      // Create the styles.xml content
      final stylesXml =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:eastAsia="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
        <w:lang w:val="en-US" w:eastAsia="en-US" w:bidi="ar-SA"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="Heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:rPr>
      <w:b/>
      <w:sz w:val="32"/>
      <w:szCs w:val="32"/>
    </w:rPr>
  </w:style>
</w:styles>''';

      // Create the document.xml.rels content
      final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

      // Create the [Content_Types].xml content
      final contentTypesXml =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

      // Create the archive
      final archive = Archive();

      // Add files to the archive with proper paths
      archive.addFile(ArchiveFile(
          'word/document.xml', documentXml.length, documentXml.codeUnits));
      archive.addFile(ArchiveFile(
          'word/styles.xml', stylesXml.length, stylesXml.codeUnits));
      archive.addFile(ArchiveFile(
          'word/_rels/document.xml.rels', relsXml.length, relsXml.codeUnits));
      archive.addFile(ArchiveFile('[Content_Types].xml', contentTypesXml.length,
          contentTypesXml.codeUnits));

      // Create the _rels folder and add .rels file
      final relsContent =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';
      archive.addFile(ArchiveFile(
          '_rels/.rels', relsContent.length, relsContent.codeUnits));

      // Encode the archive
      final zipData = ZipEncoder().encode(archive);
      if (zipData == null) {
        throw Exception('Failed to create DOCX archive');
      }

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(zipData);

      setState(() {
        _generatedDocx = file;
        _isTextEdited = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document saved to: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint("Error generating DOCX: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating DOCX: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateDocumentContent() {
    final buffer = StringBuffer();
    String? currentBlockType;
    double? lastLineBottom;

    // Sort blocks by vertical position
    final sortedBlocks = _textBlocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (final block in sortedBlocks) {
      final blockType = _detectBlockType(block);

      // Add paragraph break if there's a significant gap
      if (lastLineBottom != null &&
          block.boundingBox.top - lastLineBottom >
              block.boundingBox.height * 0.5) {
        buffer.write('</w:p>\n<w:p>\n');
      }

      if (blockType != currentBlockType) {
        if (currentBlockType != null) buffer.write('</w:p>\n');
        currentBlockType = blockType;

        // Start new paragraph with appropriate style
        buffer.write('<w:p>\n');
        if (blockType == 'header') {
          buffer.write('<w:pPr><w:pStyle w:val="Heading1"/></w:pPr>\n');
        } else {
          buffer.write('<w:pPr><w:pStyle w:val="Normal"/></w:pPr>\n');
        }
      }

      // Sort lines by vertical position
      final sortedLines = block.lines.toList()
        ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

      for (final line in sortedLines) {
        buffer.write('<w:r>\n');
        buffer.write('<w:rPr>\n');

        // More sophisticated style detection
        final avgConfidence =
            line.elements.map((e) => e.confidence ?? 0.0).average;
        final isBold = avgConfidence > 0.85 &&
            line.boundingBox.height > 30 &&
            !line.text.contains(RegExp(r'[a-z]'));
        final isItalic = avgConfidence < 0.7 && line.text.length > 1 && !isBold;

        if (isBold) buffer.write('<w:b/>\n');
        if (isItalic) buffer.write('<w:i/>\n');

        buffer.write('</w:rPr>\n');
        buffer.write('<w:t>${_escapeXml(line.text)}</w:t>\n');
        buffer.write('</w:r>\n');

        lastLineBottom = line.boundingBox.bottom;
      }
    }

    if (currentBlockType != null) {
      buffer.write('</w:p>\n');
    }

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  void _renameFile() async {
    if (_generatedDocx == null) return;

    final newName = _filenameController.text.trim();
    if (newName.isEmpty) return;

    final newPath = '${_generatedDocx!.parent.path}/$newName.docx';
    final newFile = await _generatedDocx!.rename(newPath);

    setState(() {
      _generatedDocx = newFile;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document renamed successfully')),
    );
  }

  void _shareFile() {
    if (_generatedDocx != null) {
      Share.shareXFiles(
        [XFile(_generatedDocx!.path)],
        text: 'Here is my converted document',
      );
    }
  }

  void _previewFile() {
    if (_generatedDocx != null) {
      OpenFilex.open(_generatedDocx!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to Document'),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _filenameController,
              decoration: const InputDecoration(
                labelText: 'Document Name',
                border: OutlineInputBorder(),
                hintText: 'Enter document name',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.image, color: Colors.white),
              label: Text(
                _isProcessing ? 'Processing...' : 'Select Image',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF274A31),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (_extractedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Extracted Text:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Edit the extracted text here...',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isTextEdited = true;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isTextEdited ? _generateDocx : null,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Save Text',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF274A31),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
            if (_generatedDocx != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _previewFile,
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF274A31),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _renameFile,
                    icon: const Icon(Icons.edit),
                    label: const Text('Rename'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF274A31),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _shareFile,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF274A31),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on Iterable<double> {
  double get average => isEmpty ? 0.0 : reduce((a, b) => a + b) / length;
}
