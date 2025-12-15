import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/certification_page/audio%20certificate/audio_certificate.dart';
import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/certification_page/purchase%20certificate/purchase_certificate.dart';
import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/certification_page/vide%20certificate/video_certificate.dart';
import 'package:flutter/material.dart';
import 'photo_certificate/photo_certificate.dart';

class CertificateTypeScreen extends StatelessWidget {
  const CertificateTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your category'),
        backgroundColor: const Color(0xFF274A31),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildCategoryCard(
              icon: Icons.photo_camera,
              title: 'Photo',
              subtitle: 'Picture certificate',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhotoCertificate(),
                  ),
                );
              },
            ),
            _buildCategoryCard(
              icon: Icons.videocam,
              title: 'Video',
              subtitle: 'video certificate',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoCertificate(),
                  ),
                );
              },
            ),
            _buildCategoryCard(
              icon: Icons.audiotrack,
              title: 'Audio',
              subtitle: 'Audio certificate',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AudioCertificate(),
                  ),
                );
              },
            ),
            _buildCategoryCard(
              icon: Icons.storefront,
              title: 'Market',
              subtitle: 'Purchase certificate',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PurchaseCertificate(),
                  ),
                );
              },
            ),
            // _buildCategoryCard(
            //   icon: Icons.school,
            //   title: 'Education',
            //   subtitle: 'Educational certificate',
            //   onTap: () {
            //     // Navigate to Education certificate flow
            //   },
            // ),
            // _buildCategoryCard(
            //   icon: Icons.business,
            //   title: 'Organization',
            //   subtitle: 'Organizational certificate',
            //   onTap: () {
            //     // Navigate to Organization certificate flow
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF274A31),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
