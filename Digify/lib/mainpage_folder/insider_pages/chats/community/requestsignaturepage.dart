import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/modal_classes/requestsignature.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/modal_classes/channels.dart';
import 'package:digify/modal_classes/channel_messages.dart';
import 'package:digify/viewmodels/channel_message_viewmodal.dart';
import 'package:digify/viewmodels/request_signature_viewmodel.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digify/repositories/chat_repository.dart';
import 'package:digify/modal_classes/chat.dart';

import 'dart:convert';

class RequestSignaturePage extends StatefulWidget {
  final CommunityModel community;
  final List<ChannelModel> channels;
  final List<UserModel> members;

  const RequestSignaturePage({
    Key? key,
    required this.community,
    required this.channels,
    required this.members,
  }) : super(key: key);

  @override
  State<RequestSignaturePage> createState() => _RequestSignaturePageState();
}

class _RequestSignaturePageState extends State<RequestSignaturePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final RequestSignatureViewModel _viewModel = RequestSignatureViewModel();
  final CloudinaryRepository _cloudinaryRepository = CloudinaryRepository();
  final ChatRepository _chatRepository = ChatRepository();
  final ChannelMessageViewModel _channelMessageViewModel =
      ChannelMessageViewModel();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  List<UserModel> get _filteredMembers {
    if (_searchQuery.isEmpty) return widget.members;
    return widget.members
        .where((m) =>
            m.username.toLowerCase().contains(_searchQuery) ||
            m.email.toLowerCase().contains(_searchQuery))
        .toList();
  }

  File? _selectedFile;
  String? _fileName;
  List<String> _selectedSignerIds = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // No initialization needed for CloudinaryRepository
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document')),
      );
      return;
    }
    if (_selectedSignerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one signer')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Upload File
      final response = await _cloudinaryRepository.uploadFile(
        _selectedFile!.path,
        folder: 'digify/signature_requests/${widget.community.uid}',
      );

      if (response == null || response.secureUrl == null) {
        throw Exception("Failed to upload file");
      }

      final String documentUrl = response.secureUrl!;

      String finalDocumentUid = documentUrl;

      // Check for PDF metadata
      if (_selectedFile!.path.toLowerCase().endsWith('.pdf')) {
        try {
          final bytes = await _selectedFile!.readAsBytes();
          final pdfDocument = PdfDocument(inputBytes: bytes);
          final String? metadataUid = pdfDocument.documentInformation.subject;
          pdfDocument.dispose();

          if (metadataUid != null && metadataUid.isNotEmpty) {
            finalDocumentUid = metadataUid;
          }
        } catch (e) {
          debugPrint('Error reading PDF metadata: $e');
          // Proceed with documentUrl if metadata read fails
        }
      }

      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // 2. Create Request Object
      final request = RequestSignature(
        requestUid: const Uuid().v1(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        documentUid: finalDocumentUid,
        signerIds: _selectedSignerIds,
        communityId: widget.community.uid,
        userId: currentUserId,
        status: 'in progress',
      );

      // 3. Save to Firestore
      await _viewModel.createRequest(request);

      if (_viewModel.errorMessage != null) {
        throw Exception(_viewModel.errorMessage);
      }

      // 4. Send Confirmation Message (Direct Message)
      final chat = ChatModel(
        uid: const Uuid().v1(),
        senderId: widget.community.uid,
        receiverId: currentUserId,
        message:
            "your request has been accepted with request id: ${request.requestUid}",
        sentAt: DateTime.now(),
      );

      await _chatRepository.uploadChat(chat);

      // 5. Send Request Card to Channel
      if (_selectedSignerIds.isNotEmpty) {
        final firstSignerId = _selectedSignerIds.first;
        final role = widget.community.memberRoles[firstSignerId];

        // Find channel
        ChannelModel targetChannel;
        // Try to find channel with exact same name as role
        try {
          targetChannel = widget.channels.firstWhere(
            (c) => c.name.toLowerCase() == role?.toLowerCase(),
            orElse: () => widget.channels.first,
          );
        } catch (e) {
          targetChannel = widget.channels.isNotEmpty
              ? widget.channels.first
              : throw Exception("No reference channel found");
        }

        final requestData = {
          'requestId': request.requestUid,
          'title': request.title,
          'signerId': firstSignerId,
          'documentUrl': response.secureUrl,
          'requesterName': FirebaseAuth.instance.currentUser?.displayName ??
              "Unknown", // Or fetch from user model if needed
        };

        final channelMessage = ChannelMessageModel(
          uid: const Uuid().v1(),
          channelId: targetChannel.uid,
          senderId: currentUserId,
          message: jsonEncode(requestData),
          type: 'request', // Custom type 'request'
          sentAt: DateTime.now(),
        );

        await _channelMessageViewModel.sendMessage(channelMessage);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signature request sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _toggleSigner(String uid) {
    setState(() {
      if (_selectedSignerIds.contains(uid)) {
        _selectedSignerIds.remove(uid);
      } else {
        _selectedSignerIds.add(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Request Signature",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text("Sending Request...")
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title of Request',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description of Request',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Document Select
                    InkWell(
                      onTap: _pickDocument,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fileName ?? "Select Document to Sign",
                                style: GoogleFonts.poppins(
                                  color: _fileName != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Signers Selection Section
                    Text(
                      "Select Signers",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search members...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selected Signers Chips
                    if (_selectedSignerIds.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSignerIds.map((uid) {
                            final member = widget.members.firstWhere(
                              (m) => m.uid == uid,
                              orElse: () => UserModel(
                                  uid: uid,
                                  username: "Unknown",
                                  email: "",
                                  fullName: "Unknown",
                                  createdAt: DateTime.now(),
                                  dateOfBirth: DateTime.now(),
                                  isGoogleDriveLinked: false,
                                  status: "offline",
                                  profilePicUrl: "",
                                  stampUrl: "",
                                  stampLocalPath: ""),
                            );
                            return Chip(
                              label: Text(member.username),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _toggleSigner(uid),
                              backgroundColor:
                                  AppColors.primaryGreen.withOpacity(0.1),
                              labelStyle: GoogleFonts.poppins(
                                  color: AppColors.primaryGreen, fontSize: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                      color: AppColors.primaryGreen
                                          .withOpacity(0.2))),
                            );
                          }).toList(),
                        ),
                      ),

                    // Filtered List
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _filteredMembers.isEmpty
                          ? Center(
                              child: Text("No members found",
                                  style:
                                      GoogleFonts.poppins(color: Colors.grey)))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _filteredMembers.length,
                              separatorBuilder: (ctx, i) =>
                                  Divider(height: 1, color: Colors.grey[200]),
                              itemBuilder: (context, index) {
                                final member = _filteredMembers[index];
                                final isSelected =
                                    _selectedSignerIds.contains(member.uid);
                                return CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  title: Text(member.username,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Text(member.email,
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: Colors.grey)),
                                  value: isSelected,
                                  activeColor: AppColors.primaryGreen,
                                  onChanged: (_) => _toggleSigner(member.uid),
                                  secondary: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: member.profilePicUrl !=
                                                null &&
                                            member.profilePicUrl!.isNotEmpty
                                        ? NetworkImage(member.profilePicUrl!)
                                        : null,
                                    child: member.profilePicUrl == null ||
                                            member.profilePicUrl!.isEmpty
                                        ? Text(member.username[0].toUpperCase(),
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54))
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Submit Request",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
