import 'package:digify/mainpage_folder/insider_pages/chats/community/community_page.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/community_viewmodal.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SearchCommunityPage extends StatefulWidget {
  const SearchCommunityPage({super.key});

  @override
  State<SearchCommunityPage> createState() => _SearchCommunityPageState();
}

class _SearchCommunityPageState extends State<SearchCommunityPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Search Community",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search for communities...",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 24, color: Colors.grey[600]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = "";
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: AppColors.primaryGreen),
                ),
                title: Text(
                  "Scan QR Code",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "Scan a community QR code to join immediately",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  _scanQR();
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.link_rounded,
                      color: AppColors.primaryGreen),
                ),
                title: Text(
                  "Add Invite Link",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  "Paste an invite link to join a community",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  // TODO: Implement Invite Link input
                },
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Find your community",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Scan QR Code")),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code);
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null && result is String) {
      _fetchAndJoinCommunity(result);
    }
  }

  Future<void> _fetchAndJoinCommunity(String uid) async {
    final CommunityViewModel communityViewModel = CommunityViewModel();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await communityViewModel.fetchCommunity(uid);

    // Check if widget is still mounted before using context
    if (!mounted) return;

    Navigator.pop(context); // Hide loading

    if (communityViewModel.currentCommunity != null) {
      _showJoinDialog(communityViewModel.currentCommunity!);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Community not found: ${communityViewModel.errorMessage ?? 'Unknown error'}")),
      );
    }
  }

  void _showJoinDialog(CommunityModel community) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Join Community?",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: community.communityPicture != null
                    ? NetworkImage(community.communityPicture!)
                    : null,
                child: community.communityPicture == null
                    ? Text(community.name[0].toUpperCase())
                    : null,
              ),
              const SizedBox(height: 16),
              Text(community.name,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              if (community.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(community.description,
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
              const SizedBox(height: 16),
              Text("Do you want to join this community?",
                  style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen),
              onPressed: () {
                Navigator.pop(context);
                _joinCommunity(community);
              },
              child: const Text("Join", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinCommunity(CommunityModel community) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("DEBUG: Current user is null");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: You are not logged in.")),
        );
      }
      return;
    }

    final CommunityViewModel communityViewModel = CommunityViewModel();
    final UserViewModel userViewModel = UserViewModel();

    print(
        "DEBUG: Joining community ${community.uid} for user ${currentUser.uid}");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Processing join request..."),
          duration: Duration(seconds: 1)),
    );

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Assign Role in Community
      print("DEBUG: Assigning role...");
      final roleSuccess = await communityViewModel.assignRole(
          community.uid, currentUser.uid, 'Member');
      print("DEBUG: Role assigned success: $roleSuccess");

      if (roleSuccess) {
        // 2. Add to User's Joined List
        print("DEBUG: Adding to server joined list...");
        await userViewModel.addServerJoined(currentUser.uid, community.uid);
        print("DEBUG: Added to server joined list.");

        if (!mounted) return;
        Navigator.pop(context); // Hide loading

        // Navigate to Community Page
        print("DEBUG: Navigating to Community Page");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => CommunityPage(community: community)),
        );
      } else {
        print(
            "DEBUG: Failed to assign role: ${communityViewModel.errorMessage}");
        if (!mounted) return;
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to join: ${communityViewModel.errorMessage}")),
        );
      }
    } catch (e, stackTrace) {
      print("DEBUG: Exception in _joinCommunity: $e");
      print(stackTrace);
      if (mounted) {
        Navigator.pop(context); // Hide loading if still showing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      }
    }
  }
}
