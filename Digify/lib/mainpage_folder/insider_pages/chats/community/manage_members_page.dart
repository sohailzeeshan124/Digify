import 'package:digify/mainpage_folder/insider_pages/chats/community/community_page.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/community_viewmodal.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageMembersPage extends StatefulWidget {
  final CommunityModel community;
  const ManageMembersPage({super.key, required this.community});

  @override
  State<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends State<ManageMembersPage> {
  final UserViewModel _userViewModel = UserViewModel();
  final CommunityViewModel _communityViewModel = CommunityViewModel();
  List<UserModel> _members = [];
  bool _isLoading = true;
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get all member UIDs from the community map
      final memberIds = widget.community.memberRoles.keys.toList();

      // Remove current user from list (admin shouldn't kick themselves here usually,
      // or at least let's filter them if requirement says "except for current user")
      memberIds.removeWhere((id) => id == _currentUserId);

      if (memberIds.isNotEmpty) {
        final users = await _userViewModel.getUsers(memberIds);
        setState(() {
          _members = users;
        });
      } else {
        setState(() {
          _members = [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching members: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _kickUser(UserModel user) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Remove from Community (Roles & Admins lists)
      await _communityViewModel.removeUser(widget.community.uid, user.uid);

      // 2. Remove Community from User's joined list
      await _userViewModel.removeServerJoined(user.uid, widget.community.uid);

      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${user.fullName} kicked successfully")),
        );
        _fetchMembers(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to kick user: $e")),
        );
      }
    }
  }

  Future<void> _assignRole(UserModel user, String newRole) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _communityViewModel.assignRole(
          widget.community.uid, user.uid, newRole);

      // Update local community object reference to reflect change immediately if needed,
      // but simpler to close and rely on fetch.
      // Actually widget.community is passed in, so we might need to update it
      // if we want the list to reflect proper role labels immediately without parent refresh.
      // For now, let's just refresh our member fetching logic or handle it.
      // Since memberRoles is a Map inside CommunityModel, we update that locally for display.
      widget.community.memberRoles[user.uid] = newRole;

      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Role updated to $newRole")),
        );
        setState(() {}); // Rebuild to show new role in list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update role: $e")),
        );
      }
    }
  }

  void _showOptionsDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Manage ${user.fullName}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.all(16),
              child:
                  Text("Change Role", style: GoogleFonts.poppins(fontSize: 16)),
              onPressed: () {
                Navigator.pop(context);
                _showChangeRoleDialog(user);
              },
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.all(16),
              child: Text("Kick User",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _showKickConfirmation(user);
              },
            ),
          ],
        );
      },
    );
  }

  void _showKickConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Kick ${user.fullName}?",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Text(
              "Are you sure you want to remove this user from the community?",
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                _kickUser(user);
              },
              child: const Text("Kick", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showChangeRoleDialog(UserModel user) {
    String currentRole = widget.community.memberRoles[user.uid] ?? 'Member';
    String selectedRole = currentRole;

    // Available roles - ideally from community.roles, defaulting if empty
    final List<String> availableRoles = widget.community.roles.isNotEmpty
        ? widget.community.roles
        : ['Admin', 'Member', 'Moderator'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Change Role",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.profilePicUrl != null
                            ? NetworkImage(user.profilePicUrl!)
                            : null,
                        child: user.profilePicUrl == null
                            ? Text(user.fullName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.fullName,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text(user.username,
                          style: GoogleFonts.poppins(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Select Role:",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: availableRoles.contains(selectedRole)
                        ? selectedRole
                        : availableRoles.first,
                    items: availableRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role, style: GoogleFonts.poppins()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedRole = val;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close role dialog
                      _showCreateRoleDialog(user); // Open create role dialog
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: Text("Create New Role",
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen),
                  onPressed: () {
                    Navigator.pop(context);
                    if (selectedRole != currentRole) {
                      _assignRole(user, selectedRole);
                    }
                  },
                  child: const Text("Assign",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateRoleDialog(UserModel user) {
    final TextEditingController roleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Create New Role",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "This will create a new role and a corresponding channel for it. ${user.fullName} will be assigned this role.",
                style:
                    GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roleController,
                decoration: InputDecoration(
                  labelText: "Role Name",
                  hintText: "e.g., Senior Member",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
                if (roleController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _createRoleAndChannel(user, roleController.text.trim());
                }
              },
              child: const Text("Create & Assign",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createRoleAndChannel(UserModel user, String roleName) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _communityViewModel.createRoleAndChannel(
        widget.community.uid,
        roleName,
        user.uid,
      );

      if (mounted) {
        Navigator.pop(context); // Hide loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Role '$roleName' created and assigned to ${user.fullName}")),
          );
          // Update local state map just in case, though verify should handle it
          widget.community.memberRoles[user.uid] = roleName;

          // Also add to roles list if we want it immediately available elsewhere without full refresh
          if (!widget.community.roles.contains(roleName)) {
            widget.community.roles.add(roleName);
          }

          setState(() {}); // Rebuild UI
          _fetchMembers(); // Refresh full member list/state
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Failed: ${_communityViewModel.errorMessage ?? 'Unknown error'}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Manage Members",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Text("No other members found.",
                      style: GoogleFonts.poppins(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final user = _members[index];
                    final role =
                        widget.community.memberRoles[user.uid] ?? 'Member';

                    return ListTile(
                      onLongPress: () => _showOptionsDialog(user),
                      leading: CircleAvatar(
                        backgroundImage: user.profilePicUrl != null
                            ? NetworkImage(user.profilePicUrl!)
                            : null,
                        child: user.profilePicUrl == null
                            ? Text(user.fullName[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.fullName,
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text("@${user.username}",
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[600])),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(role,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w500)),
                      ),
                    );
                  },
                ),
    );
  }
}
