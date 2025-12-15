import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' hide Image;
import 'package:image_picker/image_picker.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/services/pdf_generator_service.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/modal_classes/certificate.dart';
import 'package:digify/viewmodels/certificate_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class WorkingAudioCertificate extends StatefulWidget {
  const WorkingAudioCertificate({super.key});

  @override
  State<WorkingAudioCertificate> createState() =>
      _WorkingAudioCertificateState();
}

class _WorkingAudioCertificateState extends State<WorkingAudioCertificate> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Section 1: Video & Frames
  XFile? _recordedVideo;
  final List<String> _extractedFrames = []; // Paths to frame images
  bool _isExtractingFrames = false;
  final ImagePicker _picker = ImagePicker();

  // Section 2: Attestation & Notes
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _attestationNameController =
      TextEditingController();
  final TextEditingController _attestationStatementController =
      TextEditingController();

  // Section 3: Finalize
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _addLocation = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _attestationNameController.text = user.displayName ?? '';
      _nameController.text = user.displayName ?? '';
      _updateAttestationStatement();
    }
    _attestationNameController.addListener(_updateAttestationStatement);
  }

  void _updateAttestationStatement() {
    final name = _attestationNameController.text.trim();
    if (name.isNotEmpty) {
      // Only update if user hasn't manually edited it heavily?
      // For now, let's keep it simple and just set the default text if empty or similar.
      if (_attestationStatementController.text.isEmpty ||
          _attestationStatementController.text.contains("I, ")) {
        _attestationStatementController.text =
            "I, $name, hereby attest that I made this voice note and testimonial voluntarily and that the information contained herein is true and accurate.";
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    _attestationNameController.dispose();
    _attestationStatementController.dispose();
    _titleController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentStep++;
        });
      }
    } else {
      // Generate Report
      if (_validateCurrentStep()) {
        _generateReport();
      }
    }
  }

  Future<void> _generateReport() async {
    // Show blocking loading dialog
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

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Gather Data
      final deviceData = await _fetchDeviceData();
      final locationData = _addLocation ? await _fetchLocationData() : null;

      final userData = {
        'name': user.displayName ?? 'Unknown',
        'email': user.email ?? 'Unknown',
        'uid': user.uid,
      };

      final certDocId = const Uuid().v4();
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;

      String? signaturePath;
      try {
        final userViewModel = UserViewModel();
        final userDataModel = await userViewModel.getUser(user.uid);
        signaturePath = userDataModel?.signatureLocalPath;
      } catch (e) {
        print('Error fetching signature: $e');
      }

      // 2. Generate PDF
      // Note: We need to implement generateAudioReport in PdfGeneratorService
      final pdfBytes = await PdfGeneratorService().generateAudioReport(
        title: _titleController.text,
        frameImages: _extractedFrames.map((e) => File(e)).toList(),
        attestationStatement: _attestationStatementController.text,
        additionalNotes: _notesController.text,
        userData: userData,
        deviceData: deviceData,
        locationData: locationData,
        certificateId: certDocId,
        signaturePath: signaturePath,
        appName: appName,
      );

      // 3. Upload & Save (Same logic as Photo Certificate)
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/certificate_$certDocId.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      final localDir =
          Directory('/storage/emulated/0/Documents/generated_certificate');
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }
      final localFile = File('${localDir.path}/certificate_$certDocId.pdf');
      await localFile.writeAsBytes(pdfBytes);

      final cloudinaryRepo = CloudinaryRepository();
      final response = await cloudinaryRepo.uploadFile(tempFile.path,
          folder: 'digify/certificates');

      if (response == null || response.secureUrl == null) {
        throw Exception('Failed to upload PDF');
      }

      // 4. Create Certificate Model
      final certificate = CertificateModel(
        docId: certDocId,
        Name: _titleController.text,
        uploadedBy: user.displayName ?? 'Unknown',
        createdAt: DateTime.now(),
        pdfUrl: response.secureUrl!,
        localpdfpath: localFile.path,
        signedBy: [
          SignerInfo(
            Name: _nameController.text,
            uid: user.uid,
            signedAt: DateTime.now(),
          )
        ],
      );

      // 5. Save to Firestore
      final viewModel = CertificateViewModel();
      await viewModel.finalizeSignature(certificate);

      if (viewModel.errorMessage != null) {
        throw Exception(viewModel.errorMessage);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report Generated and Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close screen
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to generate report: $e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  Future<Map<String, String>> _fetchDeviceData() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceData = <String, String>{
      'appName': packageInfo.appName,
      'version': packageInfo.version,
    };

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      deviceData['model'] = '${androidInfo.brand} ${androidInfo.model}';
      deviceData['os'] = 'Android';
      deviceData['osVersion'] = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      deviceData['model'] = '${iosInfo.name} ${iosInfo.model}';
      deviceData['os'] = 'iOS';
      deviceData['osVersion'] = iosInfo.systemVersion;
    }
    return deviceData;
  }

  Future<Map<String, dynamic>?> _fetchLocationData() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition();
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      return null;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_recordedVideo == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please record a video first.')),
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_attestationNameController.text.isEmpty ||
          _attestationStatementController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the attestation.')),
        );
        return false;
      }
    } else if (_currentStep == 2) {
      if (_titleController.text.isEmpty || _nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _recordVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera, maxDuration: const Duration(minutes: 2));
      if (video != null) {
        setState(() {
          _recordedVideo = video;
          _isExtractingFrames = true;
          _extractedFrames.clear();
        });
        await _extractFrames(video.path);
        setState(() {
          _isExtractingFrames = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording video: $e')),
      );
    }
  }

  Future<void> _extractFrames(String videoPath) async {
    try {
      // Extract 3 frames at different intervals (e.g., 20%, 50%, 80%)
      // Note: VideoThumbnail might take time (ms).
      // We'll just take a few frames based on time if possible, or just standard thumbnails.
      // Since we don't know duration easily without another plugin, we'll try to take one at 1000ms, 3000ms, 5000ms?
      // Or just timeMs 0?
      // Let's try to get a few.

      final tempDir = await getTemporaryDirectory();

      for (int i = 1; i <= 3; i++) {
        final path = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: tempDir.path,
          // imageFormat: ImageFormat.JPEG, // Removed to use default or fix error
          timeMs: i * 2000, // 2s, 4s, 6s
          quality: 75,
        );
        _extractedFrames.add(path as String);
      }
    } catch (e) {
      print("Error extracting frames: $e");
    }
  }

  String _getSectionTitle() {
    switch (_currentStep) {
      case 0:
        return 'Record Video';
      case 1:
        return 'Attestation';
      case 2:
        return 'Finalize';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Audio Certificate'),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record testimonial and certify authenticity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Row(
                  children: List.generate(_totalSteps, (index) {
                    return Expanded(
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _currentStep >= index
                              ? AppColors.primaryGreen
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black87, width: 2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  _getSectionTitle(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSection1(),
                _buildSection2(),
                _buildSection3(),
              ],
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildSection1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildUploadButton(
            onPressed: _recordVideo,
            text: _recordedVideo == null ? 'Record Video' : 'Record Again',
            icon: Icons.videocam,
          ),
          const SizedBox(height: 20),
          if (_isExtractingFrames)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("Processing video and extracting frames..."),
              ],
            )
          else if (_extractedFrames.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Extracted Frames:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _extractedFrames.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(_extractedFrames[index]),
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else if (_recordedVideo != null)
            const Text("Video recorded but no frames extracted.")
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 64, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("No video recorded yet",
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Attestation of Authenticity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _attestationNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _attestationStatementController,
              decoration: const InputDecoration(
                labelText: 'Attestation Statement',
                border: OutlineInputBorder(),
                hintText:
                    "I, [Name], hereby attest that I made this voice note...",
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Certification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Digital Signature)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Add Geographical Location'),
              value: _addLocation,
              activeColor: AppColors.primaryGreen,
              onChanged: (bool value) {
                setState(() {
                  _addLocation = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Generate Report' : 'Next',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _previousStep,
              child: Text(
                'Back',
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        foregroundColor: AppColors.primaryGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.primaryGreen, width: 1),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
