import 'package:flutter/material.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AcknowledgementPage extends StatelessWidget {
  const AcknowledgementPage({super.key});

  final List<Map<String, String>> _dependencies = const [
    {
      'name': 'Flutter',
      'description':
          'Google\'s UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase.'
    },
    {
      'name': 'Firebase',
      'description':
          'Google\'s mobile platform that helps you quicky develop high-quality apps and grow your business.'
    },
    {
      'name': 'Google Fonts',
      'description': 'A Flutter package to use fonts from fonts.google.com.'
    },
    {
      'name': 'Share Plus',
      'description':
          'A Flutter plugin to share content from your Flutter app via the platform\'s share dialog.'
    },
    {
      'name': 'Syncfusion Flutter PDFViewer',
      'description':
          'A Flutter PDF Viewer widget to view PDF documents seamlessly and efficiently.'
    },
    {
      'name': 'Open Filex',
      'description': 'A plug-in to open files with native apps.'
    },
    {
      'name': 'Image Cropper',
      'description': 'A Flutter plugin for cropping images on Android and iOS.'
    },
  ];

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
          'Acknowledgements',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    offset: const Offset(0, 8),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 40, color: AppColors.primaryGreen),
                        const SizedBox(height: 8),
                        Text(
                          "Project Acknowledgement",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          height: 3,
                          width: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSection("Supervisor",
                      "We would like to express my sincere gratitude to my project supervisor Sir Arslan Sarvar, for their invaluable guidance, continuous support, and encouragement throughout the development of this Final Year Project. Their insights and feedback played a crucial role in shaping this project."),
                  _buildSection("Department",
                      "I am thankful to the Department of Computer Science, Comsats Sahiwal campus, for providing the necessary facilities and a supportive academic environment. I also appreciate the efforts of all faculty members who contributed to my academic growth."),
                  _buildSection("Friends & Classmates",
                      "Special thanks to my friends and classmates for their cooperation, constructive feedback, and assistance in testing the application, fostering a collaborative development experience."),
                  _buildSection("Family",
                      "I am deeply grateful to my family for their unwavering support, motivation, and patience during this journey."),
                  _buildSection("Tools & Technologies",
                      "Lastly, I acknowledge the use of modern development tools and technologies such as Flutter, Firebase, Android Studio, Figma, and various open-source resources that made the successful completion of this project possible."),
                ],
              ),
            ),
            Text(
              'We made Digify with ❤️ using these open source libraries:',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            ..._dependencies.map((dep) => _buildDependencyCard(dep)),
            const SizedBox(height: 20),
            Text(
              'Thank you to all the contributors and the open source community!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDependencyCard(Map<String, String> dep) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dep['name']!,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dep['description']!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
