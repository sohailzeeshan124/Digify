import 'package:flutter/material.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F3),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "What's New",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildUpdateCard(
            version: '1.2.0',
            date: 'Dec 14, 2024',
            isLatest: true,
            features: [
              'Introduced AI Chat Assistant for smarter document help.',
              'Enhanced Archive Page with drag-to-share and drag-to-delete gestures.',
              'New Acknowledgement Page to credit our contributors and dependencies.',
              'Improved PDF Reporting with detailed photo layouts and metadata.',
              'Various performance improvements and bug fixes.',
            ],
          ),
          _buildUpdateCard(
            version: '1.1.0',
            date: 'Nov 25, 2024',
            features: [
              'Added Stamp Settings for customized document stamping.',
              'Implemented Chat Search functionality.',
              'Profile picture cropping and editing.',
            ],
          ),
          _buildUpdateCard(
            version: '1.0.0',
            date: 'Oct 10, 2024',
            features: [
              'Initial release of Digify.',
              'Document scanning and management.',
              'Secure cloud storage integration.',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard({
    required String version,
    required String date,
    required List<String> features,
    bool isLatest = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
        border: isLatest
            ? Border.all(
                color: AppColors.primaryGreen.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isLatest ? AppColors.primaryGreen : Colors.grey[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version $version',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isLatest ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isLatest ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isLatest)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'LATEST',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Highlights:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
