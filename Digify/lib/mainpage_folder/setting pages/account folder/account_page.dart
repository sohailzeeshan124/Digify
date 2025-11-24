import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _picker = ImagePicker();

  Future<void> _changeUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Change Username',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Enter new name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey[600])),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ]),
              ]),
        ),
      ),
    );

    if (confirmed != true) return;
    final newName = controller.text.trim();
    if (newName.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': newName,
      }, SetOptions(merge: true));
      await user.updateDisplayName(newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Username updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update username: $e')));
    }
  }

  Future<void> _changeAboutMe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final current = (doc.data()?['aboutme'] as String?) ?? '';
    final controller = TextEditingController(text: current);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Edit About Me',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Write something about yourself',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey[600])),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Save',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )),
                  ),
                ]),
              ]),
        ),
      ),
    );

    if (confirmed != true) return;
    final about = controller.text.trim();

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'aboutme': about,
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('About me updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Change Password',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentCtrl,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Current password'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: Colors.grey[600]))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen),
                    child: Text('Change',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        )),
                  ),
                ]),
              ]),
        ),
      ),
    );

    if (confirmed != true) return;
    final current = currentCtrl.text;
    final neu = newCtrl.text;
    if (current.isEmpty || neu.isEmpty) return;

    try {
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(neu);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password changed')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: ${e.message}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password: $e')));
    }
  }

  Future<void> _pickProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600);
      if (picked == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: AppColors.primaryGreen,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
              ]),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            rotateButtonsHidden: false,
            resetButtonHidden: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile == null) return;

      final file = File(croppedFile.path);

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo, color: AppColors.primaryGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Set Profile Picture',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                      child: ClipOval(
                    child: Image.file(file,
                        width: 120, height: 120, fit: BoxFit.cover),
                  )),
                  const SizedBox(height: 12),
                  const Text('Use this image as your profile picture?'),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('Cancel',
                            style:
                                GoogleFonts.poppins(color: Colors.grey[600]))),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen),
                        child: Text('Use',
                            style: GoogleFonts.poppins(color: Colors.white))),
                  ]),
                ]),
          ),
        ),
      );

      if (confirm != true) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          );
        },
      );

      final cloudinaryRepo = CloudinaryRepository();
      final response = await cloudinaryRepo.uploadImage(file.path,
          folder: "digify/profiles");

      if (response != null && response.secureUrl != null) {
        final userViewModel = UserViewModel();
        await userViewModel
            .updateUser(user.uid, {'profilePicUrl': response.secureUrl});

        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile picture updated successfully')));
      } else {
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture')));
      }
    } catch (e) {
      if (!mounted) return;
      // Ensure loading dialog is dismissed if open
      // This is a bit tricky without a key or state tracking, but for now we assume it might be open
      // A safer way is to track loading state, but following the existing pattern:
      Navigator.of(context)
          .popUntil((route) => route.settings.name != null || route.isFirst);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      String? subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: const Color(0xFF274A31),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildOption(
                    icon: Icons.person,
                    title: 'Change Username',
                    onTap: _changeUsername),
                const Divider(height: 1),
                _buildOption(
                    icon: Icons.description,
                    title: 'About me',
                    onTap: _changeAboutMe),
                const Divider(height: 1),
                _buildOption(
                    icon: Icons.lock,
                    title: 'Change password',
                    onTap: _changePassword),
                const Divider(height: 1),
                _buildOption(
                  icon: Icons.photo,
                  title: 'Change Profile picture',
                  onTap: _pickProfilePicture,
                  // subtitle: 'Pick from gallery'
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
