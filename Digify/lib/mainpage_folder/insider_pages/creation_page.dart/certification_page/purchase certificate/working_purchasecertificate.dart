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
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:uuid/uuid.dart';

class WorkingPurchaseCertificate extends StatefulWidget {
  const WorkingPurchaseCertificate({super.key});

  @override
  State<WorkingPurchaseCertificate> createState() =>
      _WorkingPurchaseCertificateState();
}

class _WorkingPurchaseCertificateState
    extends State<WorkingPurchaseCertificate> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Section 1: Images
  XFile? _itemImage;
  XFile? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  // Section 2: Details
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _itemQuantityController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopLocationController = TextEditingController();

  // Section 3: Finalize
  final TextEditingController _testimonyController = TextEditingController();
  final TextEditingController _buyerNameController = TextEditingController();
  bool _addLocation = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _buyerNameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _itemNameController.dispose();
    _itemPriceController.dispose();
    _itemQuantityController.dispose();
    _shopNameController.dispose();
    _shopLocationController.dispose();
    _testimonyController.dispose();
    _buyerNameController.dispose();
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
      if (user == null) {
        throw Exception('User not logged in');
      }

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
      // Implement generatePurchaseReport in PdfGeneratorService
      final pdfBytes = await PdfGeneratorService().generatePurchaseReport(
        itemName: _itemNameController.text,
        itemPrice: _itemPriceController.text,
        itemQuantity: _itemQuantityController.text,
        shopName: _shopNameController.text,
        shopLocation: _shopLocationController.text,
        testimony: _testimonyController.text,
        buyerName: _buyerNameController.text,
        itemImage: _itemImage != null ? File(_itemImage!.path) : null,
        receiptImage: _receiptImage != null ? File(_receiptImage!.path) : null,
        userData: userData,
        deviceData: deviceData,
        locationData: locationData,
        certificateId: certDocId,
        signaturePath: signaturePath,
        appName: appName,
      );

      // 3. Upload & Save
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
        Name: "Purchase: ${_itemNameController.text}",
        uploadedBy: user.displayName ?? 'Unknown',
        createdAt: DateTime.now(),
        pdfUrl: response.secureUrl!,
        localpdfpath: localFile.path,
        signedBy: [
          SignerInfo(
            Name: _buyerNameController.text,
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
      if (_itemImage == null || _receiptImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please upload both item and receipt images.')),
        );
        return false;
      }
    } else if (_currentStep == 1) {
      if (_itemNameController.text.isEmpty ||
          _itemPriceController.text.isEmpty ||
          _itemQuantityController.text.isEmpty ||
          _shopNameController.text.isEmpty ||
          _shopLocationController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all details.')),
        );
        return false;
      }
    } else if (_currentStep == 2) {
      if (_buyerNameController.text.isEmpty ||
          _testimonyController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please complete the testimony and signature.')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source, bool isItem) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (isItem) {
            _itemImage = image;
          } else {
            _receiptImage = image;
          }
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
        return 'Upload Images';
      case 1:
        return 'Purchase Details';
      case 2:
        return 'Finalize & Testimony';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Certificate'),
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
                  'Record purchase details and receipt',
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
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildImagePickerRow('Item Image', _itemImage, true),
            const SizedBox(height: 20),
            _buildImagePickerRow('Receipt Image', _receiptImage, false),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerRow(String label, XFile? imageFile, bool isItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (imageFile != null)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(imageFile.path)),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera, isItem),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery, isItem),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _itemQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _shopLocationController,
              decoration: const InputDecoration(
                labelText: 'Shop Location (Address)',
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
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buyer's Testimony",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _testimonyController,
              decoration: const InputDecoration(
                labelText: 'Testimony',
                hintText: 'I hereby certify that I purchased this item...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _buyerNameController,
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
}
