import 'package:digify/mainpage_folder/insider_pages/chats/person_to_person/person_profile.dart';
import 'package:digify/modal_classes/chat.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/chat_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/document_sign_screen.dart';

class PersonToPersonChatPage extends StatefulWidget {
  final UserModel currentUser;
  final UserModel otherUser;

  const PersonToPersonChatPage({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  State<PersonToPersonChatPage> createState() => _PersonToPersonChatPageState();
}

class _PersonToPersonChatPageState extends State<PersonToPersonChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatViewModel _viewModel = ChatViewModel();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    final chat = ChatModel(
      uid: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: widget.currentUser.uid,
      receiverId: widget.otherUser.uid,
      message: content,
      sentAt: DateTime.now(),
      type: 'text',
    );

    _viewModel.uploadChat(chat).then((_) {
      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      _viewModel.sendFileMessage(
        file: File(image.path),
        type: 'image',
        currentUser: widget.currentUser,
        otherUser: widget.otherUser,
      );
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _viewModel.sendFileMessage(
        file: File(video.path),
        type: 'video',
        currentUser: widget.currentUser,
        otherUser: widget.otherUser,
      );
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      _viewModel.sendFileMessage(
        file: file,
        type: 'document',
        currentUser: widget.currentUser,
        otherUser: widget.otherUser,
        fileName: result.files.single.name,
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentOption(
              icon: Icons.image,
              color: Colors.purple,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            _buildAttachmentOption(
              icon: Icons.camera_alt,
              color: Colors.pink,
              label: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _buildAttachmentOption(
                icon: Icons.videocam,
                color: Colors.orange,
                label: 'Video',
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo();
                }),
            _buildAttachmentOption(
              icon: Icons.insert_drive_file,
              color: Colors.blue,
              label: 'Document',
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return "Today";
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PersonProfilePage(user: widget.otherUser),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.otherUser.profilePicUrl != null
                    ? NetworkImage(widget.otherUser.profilePicUrl!)
                    : null,
                backgroundColor: AppColors.primaryGreen,
                child: widget.otherUser.profilePicUrl == null
                    ? Text(
                        widget.otherUser.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    // 'Online' status could be dynamic later
                    'Digify Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.videocam_outlined, color: Colors.black54),
        //     onPressed: () {},
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.call_outlined, color: Colors.black54),
        //     onPressed: () {},
        //   ),
        //   const SizedBox(width: 8),
        // ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatModel>>(
              stream: _viewModel.getChatStream(
                  widget.currentUser.uid, widget.otherUser.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Start from bottom
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.currentUser.uid;

                    // Grouping Logic
                    bool showDateHeader = false;
                    if (index == messages.length - 1) {
                      showDateHeader = true;
                    } else {
                      final nextMsg = messages[index + 1];
                      if (nextMsg.sentAt.day != msg.sentAt.day ||
                          nextMsg.sentAt.month != msg.sentAt.month ||
                          nextMsg.sentAt.year != msg.sentAt.year) {
                        showDateHeader = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getDateLabel(msg.sentAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                            decoration: BoxDecoration(
                              color:
                                  isMe ? AppColors.primaryGreen : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(0),
                                bottomRight: isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (msg.type == 'text')
                                  Text(
                                    msg.message,
                                    style: GoogleFonts.poppins(
                                      color:
                                          isMe ? Colors.white : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  )
                                else if (msg.type == 'image' &&
                                    msg.attachmentUrl != null)
                                  GestureDetector(
                                    onTap: () => _launchURL(msg.attachmentUrl!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        msg.attachmentUrl!,
                                        height: 200,
                                        width: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    color: Colors.white),
                                      ),
                                    ),
                                  )
                                else if (msg.type == 'video' &&
                                    msg.attachmentUrl != null)
                                  GestureDetector(
                                    onTap: () => _launchURL(msg.attachmentUrl!),
                                    child: Container(
                                      height: 150,
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.black12,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(Icons.play_circle_fill,
                                              size: 48, color: Colors.white),
                                          Positioned(
                                            bottom: 8,
                                            child: Text(
                                              "Video",
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (msg.type == 'document' &&
                                    msg.attachmentUrl != null)
                                  DocumentBubble(
                                    url: msg.attachmentUrl!,
                                    fileName: msg.fileName ?? "document.pdf",
                                    msgId: msg.uid,
                                    isMe: isMe,
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('h:mm a').format(msg.sentAt),
                                      style: GoogleFonts.poppins(
                                        color: isMe
                                            ? Colors.white.withOpacity(0.7)
                                            : Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.done_all,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: AppColors.primaryGreen, size: 28),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: GoogleFonts.poppins(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.poppins(),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
    _checkAndDownloadFile();
  }

  Future<void> _checkAndDownloadFile() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      // Use a consistent path structure.
      final savePath = '${docsDir.path}/${widget.msgId}_${widget.fileName}';
      final file = File(savePath);

      if (await file.exists()) {
        if (mounted) {
          setState(() {
            localFile = file;
          });
        }
      } else {
        await _downloadFile(savePath);
      }
    } catch (e) {
      print("Error checking/downloading file: $e");
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
      final response = await http.get(
        Uri.parse(widget.url),
        headers: {
          'User-Agent': 'DigifyApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          setState(() {
            localFile = file;
            isDownloading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isDownloading = false;
            errorMessage = "Failed (${response.statusCode})";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isDownloading = false;
          errorMessage = "Error";
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
                      "Downloaded",
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: widget.isMe ? Colors.white70 : Colors.green,
                      ),
                    )
                ],
              ),
            ),
            if (localFile != null)
              Icon(Icons.check_circle,
                  size: 16, color: widget.isMe ? Colors.white70 : Colors.green)
          ],
        ),
      ),
    );
  }
}
