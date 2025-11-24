import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'package:digify/utils/app_colors.dart';

class ImageToDocxScreen extends StatefulWidget {
  const ImageToDocxScreen({super.key});

  @override
  State<ImageToDocxScreen> createState() => _ImageToDocxScreenState();
}

class _ImageToDocxScreenState extends State<ImageToDocxScreen> {
  File? _imageFile;
  String _extractedText = '';
  File? _generatedFile;
  final TextEditingController _filenameController =
      TextEditingController(text: 'converted_document');
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  TextRecognizer? _textRecognizer;

  // File format selection
  String _selectedFormat = 'TXT';
  final List<Map<String, dynamic>> _formats = [
    {'name': 'TXT', 'icon': Icons.text_fields, 'ext': 'txt'},
    {'name': 'PDF', 'icon': Icons.picture_as_pdf, 'ext': 'pdf'},
    {'name': 'DOCX', 'icon': Icons.description, 'ext': 'docx'},
    {'name': 'RTF', 'icon': Icons.article, 'ext': 'rtf'},
    {'name': 'HTML', 'icon': Icons.code, 'ext': 'html'},
    {'name': 'MD', 'icon': Icons.notes, 'ext': 'md'},
  ];

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
        _extractedText = _formatRecognizedText(recognizedText);
        _textController.text = _extractedText;
      });
    } catch (e) {
      if (!mounted) return;
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
    double? lastLineBottom;

    // Sort blocks by vertical position for better document flow
    final sortedBlocks = recognizedText.blocks.toList()
      ..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

    for (final block in sortedBlocks) {
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

        // Just add plain text without any HTML formatting
        buffer.write(line.text);
        buffer.write('\n');

        lastLineBottom = line.boundingBox.bottom;
      }
    }

    return buffer.toString();
  }

  Future<void> _generateFile() async {
    switch (_selectedFormat) {
      case 'TXT':
        await _generateTxt();
        break;
      case 'PDF':
        await _generatePdf();
        break;
      case 'DOCX':
        await _generateDocx();
        break;
      case 'RTF':
        await _generateRtf();
        break;
      case 'HTML':
        await _generateHtml();
        break;
      case 'MD':
        await _generateMarkdown();
        break;
    }
  }

  Future<void> _generateTxt() async {
    try {
      final documentsDir =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${documentsDir.path}/$fileName.txt';

      final file = File(filePath);
      await file.writeAsString(_textController.text);

      setState(() {
        _generatedFile = file;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text file saved to: ${file.path}'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error generating TXT: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating TXT: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generatePdf() async {
    try {
      final documentsDir =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${documentsDir.path}/$fileName.pdf';

      final pdf = pw.Document();

      // Split text into paragraphs
      final paragraphs = _textController.text.split('\n\n');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              ...paragraphs.map((para) => pw.Paragraph(
                    text: para.trim(),
                    style: const pw.TextStyle(fontSize: 12),
                    margin: const pw.EdgeInsets.only(bottom: 10),
                  )),
            ];
          },
        ),
      );

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _generatedFile = file;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${file.path}'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error generating PDF: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateDocx() async {
    try {
      final documentsDir =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${documentsDir.path}/$fileName.docx';

      // Create the document.xml content with proper text formatting
      final documentXml =
          '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    ${_generateDocumentContent()}
  </w:body>
</w:document>''';

      // Create the styles.xml content
      const stylesXml =
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
</w:styles>''';

      // Create the document.xml.rels content
      const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

      // Create the [Content_Types].xml content
      const contentTypesXml =
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
      const relsContent =
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
        _generatedFile = file;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document saved to: ${file.path}'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
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
    final lines = _textController.text.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) {
        buffer.write('<w:p><w:pPr><w:pStyle w:val="Normal"/></w:pPr></w:p>\n');
      } else {
        buffer.write('<w:p>\n');
        buffer.write('<w:pPr><w:pStyle w:val="Normal"/></w:pPr>\n');
        buffer.write('<w:r>\n');
        buffer.write('<w:t>${_escapeXml(line)}</w:t>\n');
        buffer.write('</w:r>\n');
        buffer.write('</w:p>\n');
      }
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

  Future<void> _generateRtf() async {
    try {
      final documentsDir =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${documentsDir.path}/$fileName.rtf';

      // Create RTF content
      final rtfContent = StringBuffer();
      rtfContent.write(r'{\rtf1\ansi\deff0');
      rtfContent.write(r'{\fonttbl{\f0 Times New Roman;}}');
      rtfContent.write(r'\f0\fs24 ');

      // Add text with proper RTF escaping
      final lines = _textController.text.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          rtfContent.write(_escapeRtf(line));
          rtfContent.write(r'\par ');
        } else {
          rtfContent.write(r'\par ');
        }
      }

      rtfContent.write('}');

      final file = File(filePath);
      await file.writeAsString(rtfContent.toString());

      setState(() {
        _generatedFile = file;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RTF saved to: ${file.path}'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error generating RTF: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating RTF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _escapeRtf(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('{', r'\{')
        .replaceAll('}', r'\}');
  }

  Future<void> _generateHtml() async {
    try {
      final documentsDir =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${documentsDir.path}/$fileName.html';

      // Create HTML content
      final htmlContent = StringBuffer();
      htmlContent.write('<!DOCTYPE html>\n');
      htmlContent.write('<html lang="en">\n');
      htmlContent.write('<head>\n');
      htmlContent.write('  <meta charset="UTF-8">\n');
      htmlContent.write(
          '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n');
      htmlContent.write('  <title>$fileName</title>\n');
      htmlContent.write('  <style>\n');
      htmlContent.write(
          '    body { font-family: Arial, sans-serif; line-height: 1.6; padding: 20px; max-width: 800px; margin: 0 auto; }\n');
      htmlContent.write('    p { margin-bottom: 10px; }\n');
      htmlContent.write('  </style>\n');
      htmlContent.write('</head>\n');
      htmlContent.write('<body>\n');

      // Add text as paragraphs
      final lines = _textController.text.split('\n');
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          htmlContent.write('  <p>${_escapeHtml(line)}</p>\n');
        } else {
          htmlContent.write('  <br>\n');
        }
      }

      htmlContent.write('</body>\n');
      htmlContent.write('</html>');

      final file = File(filePath);
      await file.writeAsString(htmlContent.toString());

      setState(() {
        _generatedFile = file;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('HTML saved to: ${file.path}'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error generating HTML: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating HTML: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  Future<void> _generateMarkdown() async {
    try {
      final documentsDir =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      final fileName = _filenameController.text.trim().isEmpty
          ? 'converted_document'
          : _filenameController.text.trim();
      final filePath = '${documentsDir.path}/$fileName.md';

      // For markdown, we can just use the plain text
      final file = File(filePath);
      await file.writeAsString(_textController.text);

      setState(() {
        _generatedFile = file;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Markdown saved to: ${file.path}'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint("Error generating Markdown: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating Markdown: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _renameFile() async {
    if (_generatedFile == null) return;

    final newName = _filenameController.text.trim();
    if (newName.isEmpty) return;

    final ext = _formats.firstWhere((f) => f['name'] == _selectedFormat)['ext'];
    final newPath = '${_generatedFile!.parent.path}/$newName.$ext';
    final newFile = await _generatedFile!.rename(newPath);

    setState(() {
      _generatedFile = newFile;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document renamed successfully'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _shareFile() {
    if (_generatedFile != null) {
      Share.shareXFiles(
        [XFile(_generatedFile!.path)],
        text: 'Here is my converted document',
      );
    }
  }

  void _previewFile() {
    if (_generatedFile != null) {
      OpenFilex.open(_generatedFile!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Image to Document',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _filenameController,
              decoration: InputDecoration(
                labelText: 'Document Name',
                labelStyle: GoogleFonts.poppins(),
                border: const OutlineInputBorder(),
                hintText: 'Enter document name',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickImage,
              icon: const Icon(Icons.image, color: Colors.white),
              label: Text(
                _isProcessing ? 'Processing...' : 'Select Image',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            if (_extractedText.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Extracted Text:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Edit the extracted text here...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  ),
                  style: GoogleFonts.poppins(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Output Format:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _formats.map((format) {
                  final isSelected = _selectedFormat == format['name'];
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          format['icon'] as IconData,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          format['name'] as String,
                          style: GoogleFonts.poppins(
                            color: isSelected
                                ? Colors.white
                                : AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFormat = format['name'] as String;
                      });
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.primaryGreen.withOpacity(0.3),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    _textController.text.isNotEmpty ? _generateFile : null,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  'Save as $_selectedFormat',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
            if (_generatedFile != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primaryGreen,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'File Saved Successfully!',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _generatedFile!.path.split('/').last,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _previewFile,
                      icon: const Icon(Icons.preview, size: 18),
                      label: Text(
                        'Preview',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _renameFile,
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(
                        'Rename',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareFile,
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(
                        'Share',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
