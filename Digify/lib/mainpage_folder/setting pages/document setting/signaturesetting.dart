import 'package:flutter/material.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/mainpage_folder/setting%20pages/document%20setting/signature/textsignature.dart';
import 'package:digify/mainpage_folder/setting%20pages/document%20setting/signature/imagesignature.dart';
import 'package:digify/mainpage_folder/setting%20pages/document%20setting/signature/drawsignature.dart';

class SignatureSettingPage extends StatelessWidget {
  const SignatureSettingPage({super.key});

  Widget _buildOptionCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Signature Setting',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16),
        children: [
          _buildOptionCard(
            context,
            icon: Icons.draw,
            title: 'Draw your signature',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DrawSignature()),
              );
            },
          ),
          _buildOptionCard(
            context,
            icon: Icons.upload_file,
            title: 'Upload signature image',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImageSignature()),
              );
            },
          ),
          _buildOptionCard(
            context,
            icon: Icons.text_fields,
            title: 'Make your own text signature',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Textsignature()),
              );
            },
          ),
        ],
      ),
    );
  }
}
