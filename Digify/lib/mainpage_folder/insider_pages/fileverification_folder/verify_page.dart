import 'package:digify/mainpage_folder/insider_pages/fileverification_folder/qrgeneratorscreen.dart';
import 'package:digify/mainpage_folder/insider_pages/fileverification_folder/qrscannerscreen.dart';
import 'package:digify/mainpage_folder/insider_pages/fileverification_folder/typeuidscreen.dart';
import 'package:digify/mainpage_folder/insider_pages/fileverification_folder/verify_metadata_screen.dart';
import 'package:flutter/material.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  final Color _digifyGreen = const Color(0xFF274A31);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader("Documents"),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.qr_code_scanner,
            title: 'Scan QR Code',
            subtitle: 'Scan QR code to verify document authenticity',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QRScannerScreen()),
              );
            },
          ),
          // const SizedBox(height: 16),
          // _buildOptionCard(
          //   icon: Icons.qr_code,
          //   title: 'Generate QR Code',
          //   subtitle: 'Generate QR code for document verification',
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //           builder: (context) => const QRGeneratorScreen()),
          //     );
          //   },
          // ),
          const SizedBox(height: 16),
          _buildOptionCard(
            icon: Icons.document_scanner,
            title: 'Type Document UID',
            subtitle: 'Enter document unique identifier manually',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TypeUIDScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            icon: Icons.analytics,
            title: 'Scan Document Metadata',
            subtitle: 'Verify document using its metadata',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const VerifyMetadataScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader("Certificates"),
          const SizedBox(height: 12),
          _buildOptionCard(
            icon: Icons.verified_user,
            title: 'Verify Certificate',
            subtitle: 'Verify the authenticity of a certificate',
            onTap: () {
              // TODO: Implement certificate verification
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _digifyGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(height: 1, color: Colors.grey.shade300),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _digifyGreen,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
