import 'package:digify/mainpage_folder/insider_pages/creation_page.dart/certification_page/photo_certificate/working_photocertificate.dart';
import 'package:flutter/material.dart';
import 'package:digify/utils/app_colors.dart';

class PhotoCertificate extends StatelessWidget {
  const PhotoCertificate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Certificate'),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Acquire and certify photos in real time',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              // Hero Section
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.mail_outline,
                        color: Colors.white.withOpacity(0.5)),
                    Icon(Icons.graphic_eq,
                        color: Colors.white.withOpacity(0.5)),
                    Icon(Icons.play_arrow,
                        color: Colors.white.withOpacity(0.5)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 30),
                    ),
                    Icon(Icons.folder_open,
                        color: Colors.white.withOpacity(0.5)),
                    Icon(Icons.qr_code_scanner,
                        color: Colors.white.withOpacity(0.5)),
                    Icon(Icons.location_on_outlined,
                        color: Colors.white.withOpacity(0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Features
              _buildFeatureItem('Timestamping and digital sealing'),
              const SizedBox(height: 10),
              _buildFeatureItem('Verified content'),
              const SizedBox(height: 30),
              // Description
              const Text(
                'Take one or more photos to guarantee authenticity and certify certain date, geolocation and origin from your device.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'You will obtain a forensic technical report, which can be used as an evidentiary document.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'The report and all the data contained are certified with full legal value.',
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WorkingPhotocertificate(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Start Certification',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check, color: AppColors.primaryGreen),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
