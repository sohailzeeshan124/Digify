// lib/features/profile_completion/profile_completion_screen.dart
import 'dart:io';
import 'package:digify/mainpage_folder/mainpage.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/profile_viewmodal.dart';
import 'package:digify/widgets/signature_drawer_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_rembg/local_rembg.dart';
import 'package:path_provider/path_provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final PageController _pageController = PageController();
  final ProfileViewModel vm = ProfileViewModel();

  // Step 1 controllers
  final _legalNameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  int _selectedDay = 1;
  int _selectedMonth = 1;
  int _selectedYear = DateTime.now().year - 18; // default 18y

  // Step 2 files
  File? _cnicFront;
  File? _cnicBack;

  // Step 3 signature file
  File? _signatureFile;
  // background removal slider value
  // Signature drawn file (file returned from signature drawer)
  File? _drawnSignatureFile;

// flag to indicate the signature was drawn (keeps UI separate)
  bool _signatureDrawn = false;

  int _currentStep = 0;
  bool _isUploading = false;

  bool _removeBg = false;

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _displayNameCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  DateTime getSelectedDob() {
    return DateTime(_selectedYear, _selectedMonth, _selectedDay);
  }

  bool isAdult(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  // Future<void> _captureCnic(bool isFront) async {
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (_) => CnicCameraScreen(
  //         onPictureTaken: (file) {
  //           setState(() {
  //             if (isFront) {
  //               _cnicFront = file;
  //             } else {
  //               _cnicBack = file;
  //             }
  //           });
  //         },
  //       ),
  //     ),
  //   );
  // }

  Future<void> _capturecnicimg(bool isFront) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isFront) {
          _cnicFront = File(picked.path);
        } else {
          _cnicBack = File(picked.path);
        }
      });
    }
  }

  Future<void> _captureSignatureUpload() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    File file = File(picked.path);
    // final processed =
    //     await applyAlphaBackgroundRemoval(file, threshold: _bgThreshold);

    setState(() {
      // clear any drawn signature
      _drawnSignatureFile = null;
      _signatureDrawn = false;

      // set uploaded file
      _signatureFile = file;
    });
  }

  Future<void> _drawSignature() async {
    // If user already uploaded a signature image, block drawing
    if (_signatureFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "You already uploaded a signature image. Clear it first to draw.")),
      );
      return;
    }

    final result = await Navigator.of(context).push<File?>(
      MaterialPageRoute(builder: (_) => const SignatureEditorPage()),
    );

    if (result != null) {
      setState(() {
        // store drawn signature (will NOT be previewed as image per your requirement)
        _drawnSignatureFile = result;
        _signatureDrawn = true;

        // ensure uploaded file is cleared for exclusivity
        _signatureFile = null;
      });
    }
  }

  Future<void> _onNextPressed() async {
    if (_currentStep == 0) {
      // ensure names are provided before proceeding to step 2
      final legal = _legalNameCtrl.text.trim();
      final display = _displayNameCtrl.text.trim();
      if (legal.isEmpty || display.isEmpty) {
        _showSnack('Please enter both Legal Name and Display Name.');
        return;
      }

      _goToStep(1);
    } else if (_currentStep == 1) {
      if (_cnicFront == null || _cnicBack == null) {
        _showSnack('Upload both CNIC front and back.');
        return;
      }
      _goToStep(2);
    } else if (_currentStep == 2) {
      await _completeProfile();
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
      _pageController.animateToPage(step,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    });
  }

  Future<void> _completeProfile({bool removeBg = true}) async {
    removeBg = _removeBg;
    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final dob = getSelectedDob();

      // Step 1: pick the right signature (from file or drawn)
      File? signature = _signatureFile ?? _drawnSignatureFile;

      // Step 2: Run background remover if enabled
      if (removeBg && signature != null) {
        try {
          LocalRembgResultModel result =
              await LocalRembg.removeBackground(imagePath: signature.path);

          if (result.status == 1 && result.imageBytes != null) {
            // Convert Uint8List result into File (so ViewModel works the same)
            final tempDir = await getTemporaryDirectory();
            final processedFile = File('${tempDir.path}/signature_nobg.png');
            await processedFile.writeAsBytes(result.imageBytes!);
            signature = processedFile;
          } else {
            debugPrint("Background remover failed: ${result.errorMessage}");
          }
        } catch (e) {
          debugPrint("BG remover error: $e");
        }
      }

      // Step 3: Pass the processed signature to ViewModel
      await vm.completeProfile(
        uid: user.uid,
        legalName: _legalNameCtrl.text.trim(),
        displayName: _displayNameCtrl.text.trim(),
        dob: dob,
        cnicFront: _cnicFront,
        cnicBack: _cnicBack,
        signatureFile: signature,
      );

      // Update lastLogin and append session info (device, ip, loggedInAt)
      try {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        String deviceName = Platform.operatingSystem;
        try {
          deviceName =
              '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
        } catch (_) {}

        String ipAddress = '';
        try {
          final interfaces = await NetworkInterface.list(
            includeLoopback: false,
            includeLinkLocal: true,
          );
          for (final iface in interfaces) {
            for (final addr in iface.addresses) {
              if (!addr.isLoopback && addr.address.isNotEmpty) {
                ipAddress = addr.address;
                break;
              }
            }
            if (ipAddress.isNotEmpty) break;
          }
        } catch (_) {
          ipAddress = '';
        }

        final sessionEntry = {
          'device': deviceName,
          'ip': ipAddress,
          'loggedInAt': DateTime.now(),
        };

        await userDocRef.set({
          'lastLogin': DateTime.now(),
          'sessions': FieldValue.arrayUnion([sessionEntry]),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to update lastLogin/sessions: $e');
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Mainpage()));
      }
    } catch (e) {
      _showSnack('Failed: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Complete your profile',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _isUploading
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/signup_illustration.png',
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Complete Your Profile",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Please provide the required information to continue",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // Step indicators (3 thick bars)
                  Row(
                    children: List.generate(3, (index) {
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
                  const SizedBox(height: 20),
                  // Content area
                  SizedBox(
                    height: 320, // Reduced height so buttons are more visible
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: () => _goToStep(_currentStep - 1),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.primaryGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(120, 50),
                          ),
                          child: Text(
                            'Back',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      if (_currentStep == 0) const SizedBox(width: 120),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(120, 50),
                        ),
                        child: Text(
                          _currentStep == 2 ? 'Complete' : 'Next',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final days = List<int>.generate(31, (i) => i + 1);
    final months = List<int>.generate(12, (i) => i + 1);
    final years = List<int>.generate(100, (i) => DateTime.now().year - i);

    return ListView(
      children: [
        _buildTextField(
            icon: Icons.person,
            hintText: "Legal Name (Full)",
            controller: _legalNameCtrl),
        _buildTextField(
            icon: Icons.account_circle,
            hintText: "Display Name (Username)",
            controller: _displayNameCtrl),
        const SizedBox(height: 20),
        Text(
          "Date of Birth",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildDropdownField<int>(
                    value: _selectedDay,
                    items: days
                        .map((d) => DropdownMenuItem(
                            value: d, child: Text(d.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDay = v ?? 1),
                    hint: "Day")),
            const SizedBox(width: 8),
            Expanded(
                child: _buildDropdownField<int>(
                    value: _selectedMonth,
                    items: months
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text(m.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedMonth = v ?? 1),
                    hint: "Month")),
            const SizedBox(width: 8),
            Expanded(
                child: _buildDropdownField<int>(
                    value: _selectedYear,
                    items: years
                        .map((y) => DropdownMenuItem(
                            value: y, child: Text(y.toString())))
                        .toList(),
                    onChanged: (v) => setState(
                        () => _selectedYear = v ?? DateTime.now().year - 18),
                    hint: "Year")),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      children: [
        Text(
          'Capture CNIC Front',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildUploadButton(
          onPressed: () => _capturecnicimg(true),
          text: 'click here',
          icon: Icons.camera_alt,
        ),
        if (_cnicFront != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_cnicFront!, height: 150, fit: BoxFit.cover),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Capture CNIC Back',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildUploadButton(
          onPressed: () => _capturecnicimg(false),
          text: 'Click here',
          icon: Icons.camera_alt,
        ),
        if (_cnicBack != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_cnicBack!, height: 150, fit: BoxFit.cover),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Signature configuration',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Upload Image button
        _buildUploadButton(
          onPressed: () {
            if (_signatureDrawn) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        "You already drew a signature. Clear it first to upload.")),
              );
              return;
            }
            _captureSignatureUpload();
          },
          text: 'Upload Image',
          icon: Icons.image,
        ),
        const SizedBox(height: 16),

        // OR divider
        Row(
          children: [
            Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 16),

        // Draw Signature button
        _buildUploadButton(
          onPressed: () {
            if (_signatureFile != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        "You already uploaded a signature image. Clear it first to draw.")),
              );
              return;
            }
            _drawSignature();
          },
          text: 'Draw Signature',
          icon: Icons.edit,
        ),
        const SizedBox(height: 20),

        // Uploaded signature preview (like CNIC)
        if (_signatureFile != null) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _signatureFile!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        setState(() {
                          _signatureFile = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Background removal toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Remove Background',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Switch(
                value: _removeBg,
                activeColor: Theme.of(context).primaryColor, // green app color
                onChanged: (value) {
                  setState(() {
                    _removeBg = value;
                  });
                },
              ),
            ],
          ),
        ],

        // Drawn signature message (no preview)
        if (_signatureDrawn) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.brush, color: Colors.black87),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Signature drawn ✔️ (Your drawn signature will be saved)',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.black87),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _drawnSignatureFile = null;
                      _signatureDrawn = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Reusable styled text field like in sign in screen
  Widget _buildTextField(
      {required IconData icon,
      required String hintText,
      required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primaryGreen),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.black45),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.black45),
        ),
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
        dropdownColor: Colors.white,
        icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
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
          side: BorderSide(color: AppColors.primaryGreen, width: 1),
        ),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
