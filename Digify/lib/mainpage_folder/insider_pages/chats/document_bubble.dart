import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digify/utils/app_colors.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/document_sign_screen.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/person_to_person/pdf_view_page.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentBubble extends StatefulWidget {
  final String url;
  final String fileName;
  final String msgId;
  final bool isMe;

  const DocumentBubble({
    Key? key,
    required this.url,
    required this.fileName,
    required this.msgId,
    required this.isMe,
  }) : super(key: key);

  @override
  State<DocumentBubble> createState() => _DocumentBubbleState();
}

class _DocumentBubbleState extends State<DocumentBubble> {
  bool isDownloading = false;
  File? localFile;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isMe) {
      _checkAndDownloadFile();
    }
  }

  Future<void> _checkAndDownloadFile() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      // Sanitize filename to remove illegal characters
      // Ensure we don't have empty filename
      String safeName = widget.fileName;
      if (safeName.isEmpty) safeName = "document.pdf";

      final sanitizedFileName =
          safeName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final savePath = '${docsDir.path}/${widget.msgId}_$sanitizedFileName';

      print("DEBUG: Checking file at: $savePath");

      final file = File(savePath);

      if (await file.exists()) {
        print("DEBUG: File exists locally.");
        if (mounted) {
          setState(() {
            localFile = file;
          });
        }
      } else {
        print("DEBUG: File not found locally. Starting download...");
        await _downloadFile(savePath);
      }
    } catch (e) {
      print("DEBUG: Error checking/downloading file: ${e.toString()}");
    }
  }

  Future<void> _downloadFile(String savePath) async {
    if (mounted) {
      setState(() {
        isDownloading = true;
        errorMessage = null;
      });
    }

    try {
      print("DEBUG: Downloading from URL: ${widget.url}");

      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request =
          await httpClient.getUrl(Uri.parse(widget.url));

      // Add Basic Auth Header for Cloudinary
      String apiKey = '332321586294733';
      String apiSecret = 'k2gglkp-xp6x01rEPXGWC8uH_zE';
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$apiKey:$apiSecret'))}';
      request.headers.set(HttpHeaders.authorizationHeader, basicAuth);

      final HttpClientResponse response = await request.close();

      print("DEBUG: Download Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final file = File(savePath);
        final IOSink sink = file.openWrite();

        await response.pipe(sink); // optimizing memory usage by piping stream

        print("DEBUG: File saved successfully to $savePath");
        if (mounted) {
          setState(() {
            localFile = file;
            isDownloading = false;
          });
        }
      } else {
        print("DEBUG: Download failed. Status: ${response.statusCode}");
        if (mounted) {
          setState(() {
            isDownloading = false;
            errorMessage = "Status: ${response.statusCode}";
          });
        }
      }
    } catch (e) {
      print("DEBUG: Exception during download: $e");
      if (mounted) {
        setState(() {
          isDownloading = false;
          errorMessage = "Err: $e";
        });
      }
    }
  }

  void _handleTap() {
    if (localFile != null) {
      _showOptionsDialog(localFile!);
    } else if (!isDownloading) {
      _checkAndDownloadFile();
    }
  }

  void _showOptionsDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Document Options",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text("Do you want to view or sign this document?",
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchFile(file.path);
            },
            child: Text("View", style: GoogleFonts.poppins(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentSignScreen(
                    pdfPath: file.path,
                    documentId: widget.msgId,
                  ),
                ),
              );
            },
            child: Text("Sign",
                style: GoogleFonts.poppins(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchFile(String path) async {
    // Check if it's a PDF
    if (path.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewPage(
            file: File(path),
            fileName: widget.fileName,
          ),
        ),
      );
      return;
    }

    final Uri uri = Uri.file(path);
    // Try generic launch first
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // Fallback or error
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isMe
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insert_drive_file,
              color: widget.isMe ? Colors.white : Colors.black87,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: widget.isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isDownloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            widget.isMe ? Colors.white70 : Colors.blueGrey),
                      ),
                    )
                  else if (errorMessage != null)
                    Text(
                      "Tap to retry",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.redAccent,
                      ),
                    )
                  else if (localFile != null)
                    Text(
                      "Tap to open",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: widget.isMe ? Colors.white70 : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
