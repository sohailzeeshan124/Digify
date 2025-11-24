import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class WorkingPhotocertificate extends StatefulWidget {
  const WorkingPhotocertificate({super.key});

  @override
  State<WorkingPhotocertificate> createState() =>
      _WorkingPhotocertificateState();
}

class _WorkingPhotocertificateState extends State<WorkingPhotocertificate> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Section 1 Data
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Section 2 Data
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();

  // Section 3 Data
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _addLocation = false;

  @override
  void dispose() {
    _pageController.dispose();
    _notesController.dispose();
    _infoController.dispose();
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
      print('Starting report generation...');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // 1. Gather Data
      print('Fetching device data...');
      final deviceData = await _fetchDeviceData();

      print('Fetching location data...');
      final locationData = _addLocation ? await _fetchLocationData() : null;

      final userData = {
        'name': user.displayName ?? 'Unknown',
        'email': user.email ?? 'Unknown',
        'uid': user.uid,
      };

      // Generate a unique ID for the certificate.
      final certDocId = DateTime.now().millisecondsSinceEpoch.toString();

      // 2. Generate PDF
      print('Generating PDF...');
      final pdfBytes = await PdfGeneratorService().generateReport(
        title: _titleController.text,
        images: _selectedImages.map((x) => File(x.path)).toList(),
        additionalNotes: _notesController.text,
        importantInfo: _infoController.text,
        userData: userData,
        deviceData: deviceData,
        locationData: locationData,
        certificateId: certDocId,
      );

      // 3. Upload PDF to Cloudinary
      print('Uploading to Cloudinary...');
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/certificate_$certDocId.pdf');
      await tempFile.writeAsBytes(pdfBytes);

      final cloudinaryRepo = CloudinaryRepository();
      final response = await cloudinaryRepo.uploadFile(tempFile.path,
          folder: 'digify/certificates');

      if (response == null || response.secureUrl == null) {
        throw Exception('Failed to upload PDF to Cloudinary');
      }
      print('Upload successful: ${response.secureUrl}');

      // 4. Create Certificate Model
      final certificate = CertificateModel(
        docId: certDocId,
        Name: _titleController.text,
        uploadedBy: user.displayName ?? 'Unknown',
        createdAt: DateTime.now(),
        pdfUrl: response.secureUrl!,
        signedBy: [
          SignerInfo(
            Name: _nameController.text,
            uid: user.uid,
            signedAt: DateTime.now(),
          )
        ],
      );

      // 5. Save to Firestore
      print('Saving to Firestore...');
      final viewModel = CertificateViewModel();
      await viewModel.finalizeSignature(certificate);

      if (viewModel.errorMessage != null) {
        throw Exception(viewModel.errorMessage);
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report Generated and Saved Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back or show success dialog
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('Error generating report: $e');
      print(stackTrace);

      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to generate report: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
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

    try {
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
      } else {
        deviceData['model'] = 'Unknown';
        deviceData['os'] = Platform.operatingSystem;
        deviceData['osVersion'] = Platform.operatingSystemVersion;
      }

      // IP Address - Add timeout to prevent hanging
      try {
        await Future.any([
          _getIpAddress(deviceData),
          Future.delayed(const Duration(seconds: 2)),
        ]);
      } catch (e) {
        print('Timeout or error fetching IP: $e');
        deviceData['ip'] = 'Unknown';
      }
    } catch (e) {
      print('Error fetching device info: $e');
    }
    return deviceData;
  }

  Future<void> _getIpAddress(Map<String, String> deviceData) async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            deviceData['ip'] = addr.address;
            return;
          }
        }
      }
    } catch (e) {
      print('Error getting IP: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchLocationData() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition();
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Error fetching location: $e');
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
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image.')),
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_notesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter additional notes.')),
        );
        return false;
      }
    } else if (_currentStep == 2) {
      if (_titleController.text.trim().isEmpty ||
          _nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  String _getSectionTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Images';
      case 1:
        return 'Additional Information';
      case 2:
        return 'Finalize Certificate';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Photo Certificate'),
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
                  'Acquire and degify photos in real time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Hero Section Icons
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
                const SizedBox(height: 20),
                Text(
                  _getSectionTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
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
                          border: Border.all(
                              color: Colors.black87,
                              width: 2), // thicker border
                        ),
                      ),
                    );
                  }),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose images from gallery or take a new photo.'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  text: 'Camera',
                  icon: Icons.camera_alt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildUploadButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  text: 'Gallery',
                  icon: Icons.photo_library,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _selectedImages.isEmpty
                ? const Center(child: Text('No images selected'))
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Image.file(
                            File(_selectedImages[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _infoController,
              decoration: const InputDecoration(
                labelText: 'Important Information',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
