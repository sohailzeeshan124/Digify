import 'package:digify/mainpage_folder/insider_pages/chats/chat_with_ai.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/person_to_person/person_to_personchat.dart';
import 'package:digify/modal_classes/chat.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/chat_viewmodel.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final UserViewModel _userViewModel = UserViewModel();
  final ChatViewModel _chatViewModel = ChatViewModel();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<UserModel> _friends = [];
  List<ChatModel> _recentChats = [];
  Map<String, UserModel> _recentChatUsers = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (currentUserId == null) return;

    // Load current user to get friends
    final currentUser = await _userViewModel.getUser(currentUserId!);
    if (currentUser != null && currentUser.friends.isNotEmpty) {
      final friends = await _userViewModel.getUsers(currentUser.friends);
      setState(() {
        _friends = friends;
      });
    }

    // Load recent chats
    final chats = await _chatViewModel.getRecentChats(currentUserId!);

    // Load users for recent chats
    final userIdsToFetch = chats
        .map((c) {
          return c.senderId == currentUserId ? c.receiverId : c.senderId;
        })
        .toSet()
        .toList();

    if (userIdsToFetch.isNotEmpty) {
      final users = await _userViewModel.getUsers(userIdsToFetch);
      for (var user in users) {
        _recentChatUsers[user.uid] = user;
      }
    }

    setState(() {
      _recentChats = chats;
    });
  }

  void _navigateToChat(UserModel otherUser) async {
    final currentUser = await _userViewModel.getUser(currentUserId!);
    if (currentUser == null) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonToPersonChatPage(
          currentUser: currentUser,
          otherUser: otherUser,
        ),
      ),
    ).then((_) => _loadData());
  }

  void _showAddFriendDialog() {
    final TextEditingController _usernameController = TextEditingController();
    UserModel? _foundUser;
    bool _isSearching = false;
    String? _searchError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Add Friend",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Enter the username with tag (e.g. User#12345)",
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: "Username#Tag",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorText: _searchError,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isSearching)
                    const CircularProgressIndicator()
                  else if (_foundUser != null)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _foundUser!.profilePicUrl != null
                            ? NetworkImage(_foundUser!.profilePicUrl!)
                            : null,
                        child: _foundUser!.profilePicUrl == null
                            ? Text(_foundUser!.username[0].toUpperCase())
                            : null,
                      ),
                      title: Text(
                        _foundUser!.username,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          if (currentUserId != null) {
                            await _userViewModel.addFriend(
                                currentUserId!, _foundUser!.uid);
                            Navigator.pop(context);
                            _loadData(); // Refresh list
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                        ),
                        child: const Text("Add",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                if (_foundUser == null)
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        _isSearching = true;
                        _searchError = null;
                        _foundUser = null;
                      });

                      try {
                        final user = await _userViewModel
                            .getUserByUsername(_usernameController.text.trim());

                        setState(() {
                          _isSearching = false;
                          if (user != null) {
                            if (user.uid == currentUserId) {
                              _searchError = "You cannot add yourself";
                            } else if (_friends.any((f) => f.uid == user.uid)) {
                              _searchError = "User is already your friend";
                            } else {
                              _foundUser = user;
                            }
                          } else {
                            _searchError = "User not found";
                          }
                        });
                      } catch (e) {
                        setState(() {
                          _isSearching = false;
                          _searchError = "An error occurred: $e";
                          debugPrint('Your message here: $e');
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                    ),
                    child: const Text("Search",
                        style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Row(
          children: [
            // Left Sidebar (Server Rail)
            Container(
              width: 72,
              color: const Color(0xFFE3E5E8), // Light Discord rail color
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Home/Chat Icon (Discord Home)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Separator
                  Container(
                    width: 32,
                    height: 2,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  // Add Server/Friend Icon
                  InkWell(
                    onTap: _showAddFriendDialog,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryGreen,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main Content (DM List)
            Expanded(
              child: Column(
                children: [
                  // Top Bar / Search
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Direct Messages",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            IconButton(
                              onPressed: _showAddFriendDialog,
                              icon: const Icon(Icons.person_add_alt_1,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F3F5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Find or start a conversation",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ChatBot Entry
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChatWithAiPage(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryGreen,
                                        AppColors.primaryGreen.withOpacity(0.7)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "AI Chatbot",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Ask me anything!",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Friends List (Horizontal)
                  if (_friends.isNotEmpty)
                    Container(
                      height: 90,
                      padding: const EdgeInsets.only(top: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          return InkWell(
                            onTap: () => _navigateToChat(friend),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundImage:
                                            friend.profilePicUrl != null
                                                ? NetworkImage(
                                                    friend.profilePicUrl!)
                                                : null,
                                        backgroundColor: Colors.grey[300],
                                        child: friend.profilePicUrl == null
                                            ? Text(
                                                friend.username[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    friend.username.split('#')[0],
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Recent Chats List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _recentChats.length,
                      itemBuilder: (context, index) {
                        final chat = _recentChats[index];
                        final otherId = chat.senderId == currentUserId
                            ? chat.receiverId
                            : chat.senderId;
                        final otherUser = _recentChatUsers[otherId];

                        if (otherUser == null) return const SizedBox.shrink();

                        return InkWell(
                          onTap: () => _navigateToChat(otherUser),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          otherUser.profilePicUrl != null
                                              ? NetworkImage(
                                                  otherUser.profilePicUrl!)
                                              : null,
                                      backgroundColor: Colors.grey[300],
                                      child: otherUser.profilePicUrl == null
                                          ? Text(
                                              otherUser.username[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  color: Colors.white),
                                            )
                                          : null,
                                    ),
                                    // Online status indicator (mocked for now)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: Colors.grey, // Offline/Idle
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            otherUser.username,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM d')
                                                .format(chat.sentAt),
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        chat.message,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
