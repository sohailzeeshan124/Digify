import 'package:digify/modal_classes/document.dart';
import 'package:flutter/material.dart';
import 'package:digify/viewmodels/document_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:digify/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final DocumentViewModel _documentViewModel = DocumentViewModel();
  List<DocumentModel> _documents = [];
  List<FileSystemEntity> _pdfFiles = [];
  List<FileSystemEntity> _img2txtFiles = [];
  List<FileSystemEntity> _certificateFiles = [];
  bool _isLoading = true;

  final Map<String, String> _categories = {
    'docs': 'Documents',
    'certs': 'Certificates',
    'pdf': 'PDF',
    'img2txt': 'Image to Text',
  };

  String _selectedCategory = 'docs';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final documents = await _documentViewModel.getSignedDocuments(userId);
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdfFiles() async {
    setState(() => _isLoading = true);
    try {
      final directory = Directory('/storage/emulated/0/Documents/PDF_docs');
      if (await directory.exists()) {
        final files = directory.listSync().where((file) {
          return file.path.toLowerCase().endsWith('.pdf');
        }).toList();

        // Sort by modification time, newest first
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        setState(() {
          _pdfFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() {
          _pdfFiles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading PDFs: $e');
      setState(() {
        _pdfFiles = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadImg2TxtFiles() async {
    setState(() => _isLoading = true);
    try {
      final directory =
          Directory('/storage/emulated/0/Documents/ITD_documents');
      if (await directory.exists()) {
        final files = directory.listSync();

        // Sort by modification time, newest first
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        setState(() {
          _img2txtFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() {
          _img2txtFiles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Image to Text files: $e');
      setState(() {
        _img2txtFiles = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCertificateFiles() async {
    setState(() => _isLoading = true);
    try {
      final directory =
          Directory('/storage/emulated/0/Documents/generated_certificate');
      if (await directory.exists()) {
        final files = directory.listSync();

        // Sort by modification time, newest first
        files.sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

        setState(() {
          _certificateFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() {
          _certificateFiles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Certificate files: $e');
      setState(() {
        _certificateFiles = [];
        _isLoading = false;
      });
    }
  }

  void _showPdfViewer(String pdfUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              'PDF Viewer',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.primaryGreen,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SfPdfViewer.file(File(pdfUrl)),
        ),
      ),
    );
  }

  Future<void> _deleteDocument(DocumentModel document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _documentViewModel.deleteDocument(document.docId, document.pdfUrl);
      _loadDocuments(); // Reload the list
    }
  }

  Future<void> _shareDocument(String pdfUrl) async {
    try {
      await Share.shareXFiles([XFile(pdfUrl)],
          text: 'Check out this document!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing document: $e')),
      );
    }
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.entries.map((e) {
          final isSelected = _selectedCategory == e.key;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = e.key;
              });
              if (e.key == 'pdf') {
                _loadPdfFiles();
              } else if (e.key == 'docs') {
                _loadDocuments();
              } else if (e.key == 'img2txt') {
                _loadImg2TxtFiles();
              } else if (e.key == 'certs') {
                _loadCertificateFiles();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.primaryGreen.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: GoogleFonts.poppins(
                    color: isSelected ? Colors.white : AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildCategorySelector(),
          Expanded(
            child: _selectedCategory == 'docs'
                ? (_isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _documents.isEmpty
                        ? const Center(
                            child: Text(
                              "No signed documents found",
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Dismissible(
                                  key: Key(document.docId),
                                  direction: DismissDirection.horizontal,
                                  confirmDismiss: (direction) async {
                                    if (direction ==
                                        DismissDirection.endToStart) {
                                      // Show confirmation dialog here and only delete if confirmed
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Document'),
                                          content: const Text(
                                              'Are you sure you want to delete this document?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed == true) {
                                        // perform deletion and refresh list
                                        await _documentViewModel.deleteDocument(
                                            document.docId, document.pdfUrl);
                                        await _loadDocuments();
                                        return true; // allow Dismissible to animate away
                                      } else {
                                        return false; // cancel the dismiss so the item stays visible
                                      }
                                    } else if (direction ==
                                        DismissDirection.startToEnd) {
                                      // swipe right -> share, don't dismiss item
                                      await _shareDocument(document.pdfUrl);
                                      return false;
                                    }
                                    return false;
                                  },
                                  background: Container(
                                    color: Colors.blue,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(left: 20),
                                    child: const Icon(
                                      Icons.share,
                                      color: Colors.white,
                                    ),
                                  ),
                                  secondaryBackground: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showPdfViewer(document.pdfUrl),
                                    child: Card(
                                      elevation: 4,
                                      color: const Color(0xFFF2F4F3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        height: 120,
                                        child: Row(
                                          children: [
                                            // PDF Icon Section
                                            Container(
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryGreen
                                                    .withOpacity(0.1),
                                                borderRadius: const BorderRadius
                                                    .horizontal(
                                                  left: Radius.circular(12),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.picture_as_pdf,
                                                  size: 48,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ),
                                            // Document Info Section
                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      document.docName,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Created: ${DateFormat('MMM dd, yyyy').format(document.createdAt)}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Signed by: ${document.signedBy.length} people',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Arrow Icon
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(right: 16),
                                              child: Icon(
                                                Icons.arrow_forward_ios,
                                                color: AppColors.primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ))
                : _selectedCategory == 'pdf'
                    ? (_isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _pdfFiles.isEmpty
                            ? const Center(
                                child: Text(
                                  "No PDF files found",
                                  style: TextStyle(fontSize: 18),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _pdfFiles.length,
                                itemBuilder: (context, index) {
                                  final file = _pdfFiles[index];
                                  final fileName = file.path.split('/').last;
                                  final stat = file.statSync();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: GestureDetector(
                                      onTap: () => _showPdfViewer(file.path),
                                      child: Card(
                                        color: const Color(0xFFF2F4F3),
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Container(
                                          height: 120,
                                          child: Row(
                                            children: [
                                              // PDF Icon Section
                                              Container(
                                                width: 100,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryGreen
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      const BorderRadius
                                                          .horizontal(
                                                    left: Radius.circular(12),
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.picture_as_pdf,
                                                    size: 48,
                                                    color:
                                                        AppColors.primaryGreen,
                                                  ),
                                                ),
                                              ),
                                              // Document Info Section
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(16),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        fileName,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Modified: ${DateFormat('MMM dd, yyyy').format(stat.modified)}',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Size: ${(stat.size / 1024).toStringAsFixed(1)} KB',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              // Arrow Icon
                                              const Padding(
                                                padding:
                                                    EdgeInsets.only(right: 16),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: AppColors.primaryGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ))
                    : _selectedCategory == 'img2txt'
                        ? (_isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _img2txtFiles.isEmpty
                                ? const Center(
                                    child: Text(
                                      "No Image to Text files found",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _img2txtFiles.length,
                                    itemBuilder: (context, index) {
                                      final file = _img2txtFiles[index];
                                      final fileName =
                                          file.path.split('/').last;
                                      final stat = file.statSync();
                                      final extension = fileName
                                          .split('.')
                                          .last
                                          .toLowerCase();

                                      IconData iconData;
                                      Color iconColor;

                                      switch (extension) {
                                        case 'pdf':
                                          iconData = Icons.picture_as_pdf;
                                          iconColor = Colors.red;
                                          break;
                                        case 'txt':
                                          iconData = Icons.text_snippet;
                                          iconColor = Colors.blue;
                                          break;
                                        case 'docx':
                                          iconData = Icons.description;
                                          iconColor = Colors.blue[900]!;
                                          break;
                                        case 'rtf':
                                          iconData = Icons.format_align_left;
                                          iconColor = Colors.purple;
                                          break;
                                        case 'html':
                                          iconData = Icons.code;
                                          iconColor = Colors.orange;
                                          break;
                                        case 'md':
                                          iconData = Icons.code;
                                          iconColor = Colors.black87;
                                          break;
                                        default:
                                          iconData = Icons.insert_drive_file;
                                          iconColor = Colors.grey;
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (extension == 'pdf') {
                                              _showPdfViewer(file.path);
                                            } else {
                                              OpenFilex.open(file.path);
                                            }
                                          },
                                          child: Card(
                                            elevation: 4,
                                            color: const Color(0xFFF2F4F3),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Container(
                                              height: 120,
                                              child: Row(
                                                children: [
                                                  // Icon Section
                                                  Container(
                                                    width: 100,
                                                    decoration: BoxDecoration(
                                                      color: iconColor
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          const BorderRadius
                                                              .horizontal(
                                                        left:
                                                            Radius.circular(12),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Icon(
                                                        iconData,
                                                        size: 48,
                                                        color: iconColor,
                                                      ),
                                                    ),
                                                  ),
                                                  // Document Info Section
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            fileName,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                              height: 8),
                                                          Text(
                                                            'Modified: ${DateFormat('MMM dd, yyyy').format(stat.modified)}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            'Size: ${(stat.size / 1024).toStringAsFixed(1)} KB',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  // Arrow Icon
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        right: 16),
                                                    child: Icon(
                                                      Icons.arrow_forward_ios,
                                                      color: AppColors
                                                          .primaryGreen,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ))
                        : _selectedCategory == 'certs'
                            ? (_isLoading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : _certificateFiles.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No Certificates found",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _certificateFiles.length,
                                        itemBuilder: (context, index) {
                                          final file = _certificateFiles[index];
                                          final fileName =
                                              file.path.split('/').last;
                                          final stat = file.statSync();
                                          final extension = fileName
                                              .split('.')
                                              .last
                                              .toLowerCase();

                                          IconData iconData;
                                          Color iconColor;

                                          switch (extension) {
                                            case 'pdf':
                                              iconData = Icons.picture_as_pdf;
                                              iconColor = Colors.red;
                                              break;
                                            case 'jpg':
                                            case 'jpeg':
                                            case 'png':
                                              iconData = Icons.image;
                                              iconColor = Colors.purple;
                                              break;
                                            default:
                                              iconData =
                                                  Icons.insert_drive_file;
                                              iconColor = Colors.grey;
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 16),
                                            child: GestureDetector(
                                              onTap: () {
                                                if (extension == 'pdf') {
                                                  _showPdfViewer(file.path);
                                                } else {
                                                  OpenFilex.open(file.path);
                                                }
                                              },
                                              child: Card(
                                                elevation: 4,
                                                color: const Color(0xFFF2F4F3),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Container(
                                                  height: 120,
                                                  child: Row(
                                                    children: [
                                                      // Icon Section
                                                      Container(
                                                        width: 100,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: iconColor
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .horizontal(
                                                            left:
                                                                Radius.circular(
                                                                    12),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: Icon(
                                                            iconData,
                                                            size: 48,
                                                            color: iconColor,
                                                          ),
                                                        ),
                                                      ),
                                                      // Document Info Section
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                fileName,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              const SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Modified: ${DateFormat('MMM dd, yyyy').format(stat.modified)}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                'Size: ${(stat.size / 1024).toStringAsFixed(1)} KB',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                          .grey[
                                                                      600],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      // Arrow Icon
                                                      const Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                right: 16),
                                                        child: Icon(
                                                          Icons
                                                              .arrow_forward_ios,
                                                          color: AppColors
                                                              .primaryGreen,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ))
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.construction,
                                        size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${_categories[_selectedCategory]} coming soon',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
          ),
        ],
      ),
    );
  }
}
