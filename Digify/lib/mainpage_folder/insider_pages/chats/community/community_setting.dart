import 'dart:io';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/community/community_page.dart';
import 'package:digify/mainpage_folder/insider_pages/chats/community/manage_members_page.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/community_viewmodal.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class CommunitySettingPage extends StatefulWidget {
  final CommunityModel community;
  final UserModel currentUser;

  const CommunitySettingPage({
    super.key,
    required this.community,
    required this.currentUser,
  });

  @override
  State<CommunitySettingPage> createState() => _CommunitySettingPageState();
}

class _CommunitySettingPageState extends State<CommunitySettingPage> {
  late CommunityModel _community;
  final CommunityViewModel _viewModel = CommunityViewModel();
  final CloudinaryRepository _cloudinaryRepo = CloudinaryRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
  }

  Future<void> _showEditDialog() async {
    final TextEditingController nameController =
        TextEditingController(text: _community.name);
    final TextEditingController descController =
        TextEditingController(text: _community.description);
    File? newImageFile;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Edit Community Info", style: GoogleFonts.poppins()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setStateDialog(() {
                          newImageFile = File(image.path);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: newImageFile != null
                          ? FileImage(newImageFile!)
                          : _community.communityPicture != null
                              ? NetworkImage(_community.communityPicture!)
                                  as ImageProvider
                              : null,
                      child: newImageFile == null &&
                              _community.communityPicture == null
                          ? const Icon(Icons.camera_alt, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Community Name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel", style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen),
                onPressed: () async {
                  Navigator.pop(
                      context); // Close dialog first using outer context
                  _updateCommunity(
                      nameController.text, descController.text, newImageFile);
                },
                child: Text("Save",
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateCommunity(
      String name, String description, File? imageFile) async {
    setState(() => _isLoading = true);

    String? imageUrl = _community.communityPicture;

    if (imageFile != null) {
      final response = await _cloudinaryRepo.uploadImage(imageFile.path,
          folder: "digify/communities");
      if (response != null) {
        imageUrl = response.secureUrl;
      }
    }

    final updatedCommunity = _community.copyWith(
      name: name,
      description: description,
      communityPicture: imageUrl,
    );

    final success = await _viewModel.updateCommunity(updatedCommunity);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _community = updatedCommunity;
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Community updated successfully")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error: ${_viewModel.errorMessage}")));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Community Settings",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Header Section
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _community.communityPicture != null
                              ? NetworkImage(_community.communityPicture!)
                              : null,
                          backgroundColor: Colors.purple[100],
                          child: _community.communityPicture == null
                              ? Text(
                                  _community.name.isNotEmpty
                                      ? _community.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _community.name,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (_community.description != null &&
                            _community.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _community.description!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          "${_community.memberRoles.length} Members",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Settings Section
                  _buildSectionHeader("SETTINGS"),
                  _buildSettingItem(
                    icon: Icons.edit,
                    title: "Edit Community Info",
                    subtitle: "Change name, picture, and description",
                    onTap: _showEditDialog,
                  ),
                  _buildSettingItem(
                    icon: Icons.people_outline,
                    title: "Manage Members",
                    subtitle: "Promote, demote, or remove members",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ManageMembersPage(community: widget.community),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader("DANGER ZONE"),
                  _buildSettingItem(
                    icon: Icons.delete_forever,
                    title: "Delete Community",
                    subtitle: "Permanently delete this community",
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: () {
                      // TODO: Implement Delete
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.black).withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor ?? Colors.black87, size: 24),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor ?? Colors.black87,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        onTap: onTap,
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      ),
    );
  }
}
