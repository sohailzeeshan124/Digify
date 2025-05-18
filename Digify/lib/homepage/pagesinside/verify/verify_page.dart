import 'package:flutter/material.dart';
import 'package:digify/homepage/pagesinside/verify/qr_scanner_screen.dart';
import 'package:digify/homepage/pagesinside/verify/qr_generator_screen.dart';
import 'package:digify/homepage/pagesinside/verify/type_uid_screen.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Verify",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Documents Section Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF274A31),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
            _buildOptionCard(
              icon: Icons.qr_code_scanner,
              title: 'Scan QR Code',
              subtitle: 'Scan QR code to verify document authenticity',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.qr_code,
              title: 'Generate QR Code',
              subtitle: 'Generate QR code for document verification',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRGeneratorScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.document_scanner,
              title: 'Type Document UID',
              subtitle: 'Enter document unique identifier manually',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TypeUIDScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              icon: Icons.analytics,
              title: 'Scan Document Metadata',
              subtitle: 'Verify document using its metadata',
              onTap: () {
                // TODO: Implement metadata scanning functionality
              },
            ),
            const SizedBox(height: 16),

            // Certificates Section Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Certificates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF274A31),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF274A31),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
