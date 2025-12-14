import 'package:digify/modal_classes/user_data.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonProfilePage extends StatelessWidget {
  final UserModel user;

  const PersonProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Contact Info",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryGreen,
                    backgroundImage: user.profilePicUrl != null
                        ? NetworkImage(user.profilePicUrl!)
                        : null,
                    child: user.profilePicUrl == null
                        ? Text(
                            user.username[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName.isNotEmpty ? user.fullName : user.username,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (user.fullName.isNotEmpty)
                    Text(
                      user.username, // Show tag line if fullname exists
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(Icons.call, "Audio"),
                      const SizedBox(width: 24),
                      _buildActionButton(Icons.videocam, "Video"),
                      const SizedBox(width: 24),
                      _buildActionButton(Icons.search, "Search"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Divider(thickness: 8, color: Colors.grey[100]),

            // About Section
            if (user.aboutme.isNotEmpty)
              _buildSection(
                context,
                "About",
                user.aboutme,
                // subtitle: "Jan 1, 2025", // Optional: joined date or similar
              ),

            if (user.aboutme.isNotEmpty)
              Divider(
                  thickness: 1,
                  color: Colors.grey[100],
                  indent: 16,
                  endIndent: 16),

            // Email/Contact
            _buildSection(
              context,
              "Email",
              user.email,
            ),
            Divider(thickness: 8, color: Colors.grey[100]),

            // Options
            _buildOptionItem(Icons.block, "Block ${user.username}", Colors.red),
            _buildOptionItem(
                Icons.thumb_down, "Report ${user.username}", Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]),
          child: Icon(icon, color: AppColors.primaryGreen, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String content,
      {String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOptionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
