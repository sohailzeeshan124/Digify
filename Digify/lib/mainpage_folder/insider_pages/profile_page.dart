import 'package:digify/authentication/signin_page.dart';
import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserViewModel _userViewModel = UserViewModel();
  final TextEditingController _aboutController = TextEditingController();

  UserModel? _userData;
  bool _isLoading = true;

  // Subscription to user document snapshots for realtime updates
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subscribeToUserDoc();
  }

  void _subscribeToUserDoc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((_) {
      // Re-fetch the user via the viewmodel to keep mapping logic centralized.
      _userViewModel.getUser(user.uid).then((userData) {
        if (!mounted) return;
        setState(() {
          _userData = userData;
          _aboutController.text = userData?.aboutme ?? '';
        });
      }).catchError((_) {
        // Ignore errors from realtime updates
      });
    });
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(user!.uid),
    //     backgroundColor: Colors.green,
    //   ),
    // );

    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final userData = await _userViewModel.getUser(user.uid);
      if (!mounted) return;
      setState(() {
        _userData = userData;
        _isLoading = false;

        _aboutController.text = userData?.aboutme ?? '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAbout(String newAbout) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _userData != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'aboutme': newAbout,
        }, SetOptions(merge: true));

        if (!mounted) return;
        setState(() {
          _userData!.aboutme = newAbout;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('About section updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating about section: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
                    'Edit About',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _aboutController,
                  maxLines: 5,
                  style: GoogleFonts.poppins(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Tell us about yourself...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _updateAbout(_aboutController.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _userData?.fullName ?? '';
    final username = _userData?.username ?? 'username';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: _userData?.profilePicUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      _userData!.profilePicUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return ClipOval(
                                          child: Image.network(
                                            'https://api.dicebear.com/7.x/bottts/png?seed=Digify',
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : ClipOval(
                                    child: Image.network(
                                      'https://api.dicebear.com/7.x/bottts/png?seed=Digify',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName.isNotEmpty ? fullName : 'User',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '@$username',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoCard(
                            'Personal Information',
                            [
                              _buildInfoRow(
                                Icons.email,
                                'Email',
                                _userData?.email ?? 'Not set',
                              ),
                              _buildInfoRow(
                                Icons.calendar_month,
                                'Account Created',
                                // Prefer stored createdAt in user model, fall back to FirebaseAuth metadata
                                () {
                                  final DateTime? createdAt =
                                      _userData?.createdAt ??
                                          FirebaseAuth.instance.currentUser
                                              ?.metadata.creationTime;
                                  return createdAt != null
                                      ? _formatDate(createdAt)
                                      : 'Not set';
                                }(),
                              ),
                              _buildEditableInfoRow(
                                Icons.description,
                                'About Me',
                                _userData?.aboutme ?? 'Not set',
                                _showEditAboutDialog,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoCard(
                            'Documents',
                            [
                              _buildDocumentRow(
                                'CNIC Front',
                                _userData?.cnicFrontUrl,
                              ),
                              _buildDocumentRow(
                                'CNIC Back',
                                _userData?.cnicBackUrl,
                              ),
                              _buildDocumentRow(
                                'Signature',
                                _userData?.signatureUrl,
                              ),
                              _buildDocumentRow(
                                'Stamp',
                                _userData?.stampUrl,
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout),
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(
    IconData icon,
    String label,
    String value,
    VoidCallback onEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.description, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url != null ? 'Download Document' : 'Not uploaded',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: url != null ? AppColors.primaryGreen : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (url != null)
            IconButton(
              icon: const Icon(
                Icons.visibility,
                color: AppColors.primaryGreen,
              ),
              onPressed: () => _confirmAndDownload(label),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDownload(String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Document'),
        content: Text('Do you want to download "$label"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user signed in')),
      );
      return;
    }

    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = docSnap.data();
      if (data == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
        return;
      }

      // map UI label to firestore field name
      final Map<String, String> fieldMap = {
        'CNIC Front': 'cnicFrontUrl',
        'CNIC Back': 'cnicBackUrl',
        'Signature': 'signatureUrl',
        'Stamp': 'stampUrl',
      };

      final fieldName =
          fieldMap[label] ?? label; // fallback if label matches field
      final docUrl =
          (data[fieldName] as String?) ?? (data['$fieldName']?.toString());

      if (docUrl == null || docUrl.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document URL not available')),
        );
        return;
      }

      await _downloadFile(docUrl);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _downloadFile(String url) async {
    try {
      final uri = Uri.parse(url);
      final filename =
          uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'document.pdf';

      Directory saveDir;
      if (Platform.isAndroid) {
        saveDir = Directory('/storage/emulated/0/Download');
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }
      } else {
        saveDir = await getApplicationDocumentsDirectory();
      }

      final filePath = p.join(saveDir.path, filename);

      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final bytes = await consolidateHttpClientResponseBytes(response);
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded to: $filePath')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download file: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  // Optional helper if you prefer a nullable formatter elsewhere
  String _formatDateNullable(DateTime? date) {
    return date == null ? 'Not set' : _formatDate(date);
  }
}
