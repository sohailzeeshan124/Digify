import 'package:digify/modal_classes/chat.dart';
import 'package:provider/provider.dart';
import 'package:digify/modal_classes/channels.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/channel_viewmodal.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:digify/modal_classes/channel_messages.dart';
import 'package:digify/viewmodels/channel_message_viewmodal.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:digify/modal_classes/requestsignature.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/person_to_person/person_to_personchat.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/community/community_setting.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/community/community_signaturescreen.dart';
import 'package:digify/viewmodels/request_signature_viewmodel.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:digify/modal_classes/requestsignature.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/document_bubble.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/community/requestsignaturepage.dart';

class CommunityPage extends StatefulWidget {
  final CommunityModel community;

  const CommunityPage({super.key, required this.community});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ChannelViewModel _channelViewModel = ChannelViewModel();
  final UserViewModel _userViewModel = UserViewModel();
  final ChannelMessageViewModel _channelMessageViewModel =
      ChannelMessageViewModel();
  final TextEditingController _messageController = TextEditingController();

  List<ChannelModel> _channels = [];
  Map<String, List<UserModel>> _membersByRole = {};
  ChannelModel? _selectedChannel;
  bool _isLoading = true;
  bool _showMembers = false; // Toggle for right sidebar
  bool _isDrawerOpen = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1. Fetch Channels
    await _channelViewModel.fetchChannels(widget.community.uid);
    final channels = _channelViewModel.channels;

    // 2. Set Default Channel (Rules or First)
    ChannelModel? defaultChannel;
    if (channels.isNotEmpty) {
      try {
        defaultChannel = channels.firstWhere(
          (c) => c.name.toLowerCase() == 'rules',
          orElse: () => channels.first,
        );
      } catch (_) {
        defaultChannel = channels.first;
      }
    }

    // 3. Fetch Members
    final memberIds = widget.community.memberRoles.keys.toList();
    final members = await _userViewModel.getUsers(memberIds);

    // Group by Role
    final Map<String, List<UserModel>> groupedMembers = {};
    groupedMembers['Admin'] = [];
    groupedMembers['Member'] = [];

    for (var member in members) {
      final role = widget.community.memberRoles[member.uid] ?? 'Member';
      if (!groupedMembers.containsKey(role)) {
        groupedMembers[role] = [];
      }
      groupedMembers[role]!.add(member);
    }

    groupedMembers.removeWhere((key, value) => value.isEmpty);

    final currentUser =
        await _userViewModel.getUser(FirebaseAuth.instance.currentUser!.uid);

    if (mounted) {
      setState(() {
        _channels = channels;
        _selectedChannel = defaultChannel;
        _membersByRole = groupedMembers;
        _currentUser = currentUser;
        _isLoading = false;
      });
    }
  }

  UserModel? _getMember(String uid) {
    for (var list in _membersByRole.values) {
      for (var user in list) {
        if (user.uid == uid) return user;
      }
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedChannel == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final message = ChannelMessageModel(
      uid: const Uuid().v1(),
      channelId: _selectedChannel!.uid,
      senderId: currentUser.uid,
      message: text,
      sentAt: DateTime.now(),
    );

    _messageController.clear();
    await _channelMessageViewModel.sendMessage(message);
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null && _selectedChannel != null && _currentUser != null) {
      _channelMessageViewModel.sendFileMessage(
        file: File(image.path),
        type: 'image',
        currentUser: _currentUser!,
        channelId: _selectedChannel!.uid,
      );
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null && _selectedChannel != null && _currentUser != null) {
      _channelMessageViewModel.sendFileMessage(
        file: File(video.path),
        type: 'video',
        currentUser: _currentUser!,
        channelId: _selectedChannel!.uid,
      );
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && _selectedChannel != null && _currentUser != null) {
      File file = File(result.files.single.path!);
      _channelMessageViewModel.sendFileMessage(
        file: file,
        type: 'document',
        currentUser: _currentUser!,
        channelId: _selectedChannel!.uid,
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
            _buildAttachmentOption(
              icon: Icons.draw,
              color: Colors.teal,
              label: 'Signature',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      // Flatten members from all roles
                      final allMembers = _membersByRole.values
                          .expand((users) => users)
                          .toList();
                      // Remove duplicates if any (though users shouldn't be in multiple roles ideally)
                      final uniqueMembers = <String, UserModel>{};
                      for (var m in allMembers) {
                        uniqueMembers[m.uid] = m;
                      }

                      return RequestSignaturePage(
                        community: widget.community,
                        channels: _channels,
                        members: uniqueMembers.values.toList(),
                      );
                    },
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      onDrawerChanged: (isOpened) {
        setState(() {
          _isDrawerOpen = isOpened;
        });
      },
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        backgroundColor: const Color(0xFFF2F3F5),
        child: Column(
          children: [
            const SizedBox(height: 48), // Padding for status bar
            if (widget.community.communityPicture != null)
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      NetworkImage(widget.community.communityPicture!),
                  backgroundColor: Colors.transparent,
                ),
              )
            else
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    widget.community.name.isNotEmpty
                        ? widget.community.name[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                widget.community.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "CHANNELS",
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _channelViewModel.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Error: ${_channelViewModel.errorMessage}",
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _channels.isEmpty
                      ? Center(
                          child: Text(
                            "No channels found",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _channels.length,
                          itemBuilder: (context, index) {
                            final channel = _channels[index];
                            final isSelected =
                                _selectedChannel?.uid == channel.uid;

                            return InkWell(
                              onLongPress: () {
                                final currentUser =
                                    FirebaseAuth.instance.currentUser;
                                if (currentUser != null &&
                                    widget.community
                                            .memberRoles[currentUser.uid] ==
                                        'Admin') {
                                  _showChannelOptions(channel);
                                }
                              },
                              onTap: () {
                                setState(() {
                                  _selectedChannel = channel;
                                });
                                Navigator.pop(context); // Close sidebar
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.tag,
                                      size: 20,
                                      color: isSelected
                                          ? AppColors.primaryGreen
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        channel.name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.black87
                                              : Colors.grey[700],
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Invite via QR",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: widget.community.uid,
                      version: QrVersions.auto,
                      size: 150.0,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Scan to Join",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (widget.community
                    .memberRoles[FirebaseAuth.instance.currentUser?.uid] ==
                'Admin') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunitySettingPage(
                    community: widget.community,
                    currentUser: _currentUser!,
                  ),
                ),
              );
            }
          },
          child: Text(
            widget.community.name,
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: _isDrawerOpen
            ? []
            : [
                IconButton(
                  icon: Icon(
                    _showMembers ? Icons.people : Icons.people_outline,
                    color: _showMembers ? AppColors.primaryGreen : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _showMembers = !_showMembers;
                    });
                  },
                ),
              ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : Row(
              children: [
                // 2. Main Content (Center)
                Expanded(
                  child: Column(
                    children: [
                      // Channel Header
                      Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(Icons.tag, color: Colors.grey, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedChannel?.name ?? "Select a channel",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_selectedChannel != null &&
                                !_selectedChannel!.canTalk) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border:
                                      Border.all(color: AppColors.primaryGreen),
                                ),
                                child: Text(
                                  "Read-Only",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Chat Area
                      Expanded(
                        child: _selectedChannel == null
                            ? const Center(child: Text("No channel selected"))
                            : StreamBuilder<List<ChannelMessageModel>>(
                                stream: _channelMessageViewModel
                                    .getChatStream(_selectedChannel!.uid),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text("Error: ${snapshot.error}"));
                                  }

                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator(
                                      color: AppColors.primaryGreen,
                                    ));
                                  }

                                  final messages = snapshot.data ?? [];

                                  return ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    reverse: true,
                                    itemCount: messages.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == messages.length) {
                                        // Welcome Message (Top of list)
                                        return Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 24, top: 48),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.tag,
                                                  size: 32,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "Welcome to #${_selectedChannel!.name}!",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "This is the start of the #${_selectedChannel!.name} channel.",
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Divider(color: Colors.grey[300]),
                                            ],
                                          ),
                                        );
                                      }
                                      if (messages[index].type == 'request') {
                                        return _buildRequestCard(
                                            messages[index]);
                                      }

                                      final message = messages[index];
                                      final sender =
                                          _getMember(message.senderId);
                                      final isSameSender =
                                          index < messages.length - 1 &&
                                              messages[index + 1].senderId ==
                                                  message.senderId;

                                      // Simple date formatting
                                      final time = DateFormat('h:mm a')
                                          .format(message.sentAt);
                                      final date = DateFormat('MM/dd/yyyy')
                                          .format(message.sentAt);

                                      return Padding(
                                        padding: EdgeInsets.only(
                                            top: isSameSender ? 4.0 : 16.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (!isSameSender)
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundImage: sender
                                                            ?.profilePicUrl !=
                                                        null
                                                    ? NetworkImage(
                                                        sender!.profilePicUrl!)
                                                    : null,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                child: sender?.profilePicUrl ==
                                                        null
                                                    ? Text(
                                                        sender?.username
                                                                    .isNotEmpty ==
                                                                true
                                                            ? sender!
                                                                .username[0]
                                                                .toUpperCase()
                                                            : '?',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      )
                                                    : null,
                                              )
                                            else
                                              const SizedBox(width: 40),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (!isSameSender)
                                                    if (!isSameSender)
                                                      Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            sender?.username ??
                                                                'Unknown User',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black87,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            "$date at $time",
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: Colors
                                                                  .grey[500],
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                  if (!isSameSender)
                                                    const SizedBox(height: 4),
                                                  if (message.type == 'text')
                                                    Text(
                                                      message.message,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.black87,
                                                        fontSize: 14,
                                                      ),
                                                    )
                                                  else if (message.type ==
                                                          'image' &&
                                                      message.attachmentUrl !=
                                                          null)
                                                    GestureDetector(
                                                      onTap: () => _launchURL(
                                                          message
                                                              .attachmentUrl!),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Image.network(
                                                          message
                                                              .attachmentUrl!,
                                                          height: 200,
                                                          width: 200,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                      ),
                                                    )
                                                  else if (message.type ==
                                                          'video' &&
                                                      message.attachmentUrl !=
                                                          null)
                                                    GestureDetector(
                                                      onTap: () => _launchURL(
                                                          message
                                                              .attachmentUrl!),
                                                      child: Container(
                                                        height: 150,
                                                        width: 200,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black12,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .play_circle_fill,
                                                                size: 48,
                                                                color: Colors
                                                                    .white),
                                                            Positioned(
                                                              bottom: 8,
                                                              child: Text(
                                                                "Video",
                                                                style: GoogleFonts
                                                                    .poppins(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            12),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                  else if (message.type ==
                                                          'document' &&
                                                      message.attachmentUrl !=
                                                          null)
                                                    DocumentBubble(
                                                      url: message
                                                          .attachmentUrl!,
                                                      fileName:
                                                          message.fileName ??
                                                              "document.pdf",
                                                      msgId: message.uid,
                                                      isMe: false,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),

                      // Chat Input
                      if (_selectedChannel != null && _selectedChannel!.canTalk)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F5),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.grey),
                                onPressed: () {
                                  // Added attachment logic
                                  _showAttachmentOptions();
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText:
                                        "Message #${_selectedChannel?.name ?? 'channel'}",
                                    hintStyle:
                                        GoogleFonts.poppins(color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send,
                                    color: AppColors.primaryGreen),
                                onPressed: _sendMessage,
                              ),
                            ],
                          ),
                        )
                      else if (_selectedChannel != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Text(
                            "You do not have permission to send messages in this channel.",
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 3. Members Sidebar (Right) - Collapsible
                if (_showMembers)
                  Container(
                    width: 200,
                    constraints: const BoxConstraints(maxWidth: 200),
                    color: const Color(0xFFF2F3F5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F5),
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          child: Text(
                            "Members",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _membersByRole.length,
                            itemBuilder: (context, index) {
                              final role = _membersByRole.keys.elementAt(index);
                              final members = _membersByRole[role]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    child: Text(
                                      "$role — ${members.length}".toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  ...members.map((member) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: InkWell(
                                          onTap: () =>
                                              _showMemberProfileDialog(member),
                                          child: Row(
                                            children: [
                                              Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundImage:
                                                        member.profilePicUrl !=
                                                                null
                                                            ? NetworkImage(member
                                                                .profilePicUrl!)
                                                            : null,
                                                    backgroundColor:
                                                        Colors.grey[300],
                                                    child:
                                                        member.profilePicUrl ==
                                                                null
                                                            ? Text(
                                                                member
                                                                    .username[0]
                                                                    .toUpperCase(),
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              )
                                                            : null,
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .green, // Mock online status
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFFF2F3F5),
                                                            width: 2),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  member.username,
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                    color: role == 'Admin'
                                                        ? Colors.redAccent
                                                        : Colors.black87,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _showChannelOptions(ChannelModel channel) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Manage #${channel.name}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text("Rename Channel", style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(channel);
                },
              ),
              ListTile(
                leading: Icon(
                    channel.canTalk ? Icons.lock_open : Icons.lock_outline,
                    color: Colors.orange),
                title: Text(
                  channel.canTalk ? "Mute" : "Un Mute",
                  style: GoogleFonts.poppins(),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _channelViewModel.updateChannel(
                      channel.copyWith(canTalk: !channel.canTalk));
                  _loadData();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  "Delete Channel",
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(channel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenameDialog(ChannelModel channel) {
    final TextEditingController controller =
        TextEditingController(text: channel.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rename Channel", style: GoogleFonts.poppins()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Channel Name",
            hintStyle: GoogleFonts.poppins(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _channelViewModel.changeChannelName(
                    channel.uid, controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child:
                Text("Update", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ChannelModel channel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Channel",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete #${channel.name}? All messages will be lost and users in this channel will be downgraded to 'Member'.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text("Cancel", style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final success = await _channelViewModel.deleteChannel(channel);

              if (mounted) {
                if (success) {
                  // If deleted channel was selected, reset selection
                  if (_selectedChannel?.uid == channel.uid) {
                    _selectedChannel = null;
                  }
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Channel deleted",
                            style: GoogleFonts.poppins())),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            "Error: ${_channelViewModel.errorMessage}",
                            style: GoogleFonts.poppins())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child:
                Text("Delete", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMemberProfileDialog(UserModel user) {
    if (_currentUser == null) return;

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            final isFriend = _currentUser!.friends.contains(user.uid);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user.profilePicUrl != null
                        ? NetworkImage(user.profilePicUrl!)
                        : null,
                    backgroundColor: AppColors.primaryGreen,
                    child: user.profilePicUrl == null
                        ? Text(user.username[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                                fontSize: 30, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // Name
                  Text(user.fullName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  // Username + Copy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.username,
                          style: GoogleFonts.poppins(color: Colors.grey)),
                      IconButton(
                        icon: const Icon(Icons.copy,
                            size: 16, color: Colors.grey),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: user.username));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Username copied")));
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  // About Me
                  Text(user.aboutme,
                      style: GoogleFonts.poppins(fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Friend Button
                      if (user.uid != _currentUser!.uid)
                        ElevatedButton(
                          onPressed: () async {
                            if (isFriend) {
                              await _userViewModel.removeFriend(
                                  _currentUser!.uid, user.uid);
                              setStateDialog(() {
                                _currentUser!.friends.remove(user.uid);
                              });
                            } else {
                              await _userViewModel.addFriend(
                                  _currentUser!.uid, user.uid);
                              setStateDialog(() {
                                _currentUser!.friends.add(user.uid);
                              });
                            }
                            // Update parent state as well if needed
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: isFriend
                                  ? Colors.redAccent
                                  : AppColors.primaryGreen),
                          child: Text(isFriend ? "Unfriend" : "Add Friend",
                              style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      // Message Button
                      if (user.uid != _currentUser!.uid)
                        IconButton(
                          icon: const Icon(Icons.message,
                              color: AppColors.primaryGreen),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PersonToPersonChatPage(
                                        currentUser: _currentUser!,
                                        otherUser: user)));
                          },
                        )
                    ],
                  )
                ],
              ),
            );
          });
        });
  }

  Widget _buildRequestCard(ChannelMessageModel message) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message);
    } catch (e) {
      return const SizedBox.shrink();
    }

    final title = data['title'] ?? 'Signature Request';

    // Resolve requester name from senderId
    final sender = _getMember(message.senderId);
    final requester = sender?.fullName ?? data['requesterName'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.draw,
                    color: AppColors.primaryGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Signature Request",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    "From $requester",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FutureBuilder<RequestSignature?>(
                future: Provider.of<RequestSignatureViewModel>(context,
                        listen: false)
                    .getRequest(data['requestId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final status = snapshot.data?.status ?? 'in progress';
                  if (status == 'rejected') {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "REJECTED",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    );
                  } else if (status == 'completed') {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "COMPLETED",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          if (data['signerId'] == _currentUser?.uid)
            FutureBuilder<RequestSignature?>(
                future: Provider.of<RequestSignatureViewModel>(context,
                        listen: false)
                    .getRequest(data['requestId']),
                builder: (context, snapshot) {
                  final status = snapshot.data?.status ?? 'in progress';
                  if (status == 'rejected' || status == 'completed')
                    return const SizedBox.shrink();

                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleRejectTap(message),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Reject",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleRequestTap(message),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Review & Sign",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                })
          else if (data['signerId'] != _currentUser?.uid)
            Center(
              child: Text(
                "Waiting for signer...",
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleRequestTap(ChannelMessageModel message) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(message.message);
    } catch (e) {
      return;
    }

    final url = data['documentUrl'];
    final requestId = data['requestId'];

    if (url == null || url.isEmpty || requestId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid request data')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Fetch Request Status
      final requestVM = RequestSignatureViewModel();
      final request = await requestVM.getRequest(requestId);

      if (request == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request not found or failed to load')),
        );
        return;
      }

      // 2. Check if already signed
      if (request.signedIds.contains(_currentUser!.uid)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have already signed this document.')),
        );
        return;
      }

      // Download file to temp
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file =
            File(p.join(tempDir.path, 'signing_doc_${request.requestUid}.pdf'));
        await file.writeAsBytes(response.bodyBytes);

        Navigator.pop(context); // Hide loading

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunitySignatureScreen(
              pdfPath: file.path,
              request: request,
              community: widget.community,
            ),
          ),
        );
      } else {
        throw Exception("Failed to download file");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Hide loading if still showing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleRejectTap(ChannelMessageModel message) async {
    final data = jsonDecode(message.message);
    final requestVM =
        Provider.of<RequestSignatureViewModel>(context, listen: false);

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Request"),
        content: const Text(
            "Are you sure you want to reject this signature request? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Reject")),
        ],
      ),
    );

    if (confirm == true) {
      await requestVM.rejectRequest(data['requestId'], "Rejected by user");
      setState(() {}); // Refresh UI
    }
  }
}
