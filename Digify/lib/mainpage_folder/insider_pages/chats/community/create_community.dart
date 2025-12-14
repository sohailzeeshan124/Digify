import 'dart:io';

import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:digify/modal_classes/channel_messages.dart';
import 'package:digify/modal_classes/channels.dart';
import 'package:digify/modal_classes/community.dart';
import 'package:digify/utils/app_colors.dart';
import 'package:digify/viewmodels/channel_message_viewmodal.dart';
import 'package:digify/viewmodels/channel_viewmodal.dart';
import 'package:digify/viewmodels/community_viewmodal.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateCommunityPage extends StatefulWidget {
  const CreateCommunityPage({super.key});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoading = false;

  // Step 1 Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Step 2 Image
  File? _communityImage;
  final ImagePicker _picker = ImagePicker();

  // Step 3 Controllers (Rules)
  final List<TextEditingController> _rulesControllers = [
    TextEditingController()
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var controller in _rulesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Validation Logic ---

  bool _validateStep1() {
    if (_nameController.text.trim().isEmpty) {
      _showError("Community name is required");
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError("Description is required");
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_communityImage == null) {
      _showError("Please upload a community image");
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    bool hasValidRule = false;
    for (var controller in _rulesControllers) {
      if (controller.text.trim().isNotEmpty) {
        hasValidRule = true;
        break;
      }
    }

    if (!hasValidRule) {
      _showError("Please add at least one rule");
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // --- Image Picker Logic ---

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: AppColors.primaryGreen,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _communityImage = File(croppedFile.path);
        });
      }
    } catch (e) {
      _showError("Error picking image: $e");
    }
  }

  // --- Creation Logic ---
  Future<void> _createCommunity() async {
    if (!_validateStep3()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("User not logged in");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload Image
      String? imageUrl;
      if (_communityImage != null) {
        final cloudinaryRepo = CloudinaryRepository();
        final response = await cloudinaryRepo.uploadImage(_communityImage!.path,
            folder: "digify/communities");
        if (response != null && response.secureUrl != null) {
          imageUrl = response.secureUrl;
        }
      }

      if (imageUrl == null) {
        throw Exception("Failed to upload image");
      }

      // 2. Create Community
      final communityId = const Uuid().v4();
      final rules = _rulesControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final community = CommunityModel(
        uid: communityId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        communityPicture: imageUrl,
        admins: [user.uid],
        createdAt: DateTime.now(),
        roles: ['Admin', 'Member'], // Default roles
        memberRoles: {user.uid: 'Admin'},
      );

      final communityVM = CommunityViewModel();
      await communityVM.createCommunity(community);

      // 3. Add to User's joined servers
      final userVM = UserViewModel();
      final userid = FirebaseAuth.instance.currentUser;
      final realuser = await userVM.getUser(userid!.uid);

      if (realuser != null) {
        realuser.serversJoined.add(communityId);
        await userVM.updateUser(realuser.uid, realuser.toMap());
      }

      // 4. Create Introduction Channel
      final channelVM = ChannelViewModel();
      final introChannelId = const Uuid().v4();
      final introChannel = ChannelModel(
        uid: introChannelId,
        communityId: communityId,
        name: "Introduction",
        users: [user.uid],
        canTalk: false,
        createdat: DateTime.now(),
      );
      await channelVM.createChannel(introChannel);

      // 5. Create Rules Channel
      final rulesChannelId = const Uuid().v4();
      final rulesChannel = ChannelModel(
        uid: rulesChannelId,
        communityId: communityId,
        name: "Rules",
        users: [user.uid],
        canTalk:
            false, // Only admins usually talk here, but keeping false as per likely intent
        createdat: DateTime.now(),
      );
      await channelVM.createChannel(rulesChannel);

      // 6. Send Description to Intro Channel
      final messageVM = ChannelMessageViewModel();
      final introMessage = ChannelMessageModel(
        uid: const Uuid().v4(),
        channelId: introChannelId,
        message:
            "Welcome to ${_nameController.text}! \n\nAbout us:\n${_descriptionController.text}",
        senderId: user.uid,
        sentAt: DateTime.now(),
        type: "text",
      );
      await messageVM.sendMessage(introMessage);

      // 7. Send Rules to Rules Channel
      final rulesText = rules.map((r) => "• $r").join("\n");
      final rulesMessage = ChannelMessageModel(
        uid: const Uuid().v4(),
        channelId: rulesChannelId,
        message: "Community Rules:\n\n$rulesText",
        senderId: user.uid,
        sentAt: DateTime.now(),
        type: "text",
      );
      await messageVM.sendMessage(rulesMessage);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Community Created Successfully!",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError("Failed to create community: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Navigation ---

  void _nextStep() {
    bool isValid = false;
    if (_currentStep == 0) isValid = _validateStep1();
    if (_currentStep == 1) isValid = _validateStep2();

    if (isValid && _currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _addRuleField() {
    setState(() {
      _rulesControllers.add(TextEditingController());
    });
  }

  void _removeRuleField(int index) {
    if (_rulesControllers.length > 1) {
      setState(() {
        _rulesControllers[index].dispose();
        _rulesControllers.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentStep + 1) / _totalSteps;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (_currentStep > 0) {
                  _previousStep();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              "Create Community",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFF2F3F5),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                minHeight: 4,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildCurrentStep(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            "Back",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentStep < _totalSteps - 1) {
                            _nextStep();
                          } else {
                            _createCommunity();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentStep == _totalSteps - 1 ? "Create" : "Next",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return Container();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 1: The Basics",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Give your community a name and a description.",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          "Community Name",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: "e.g. Flutter Developers",
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF2F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "Description",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "What topics will you be discussing?",
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            filled: true,
            fillColor: const Color(0xFFF2F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 2: Visual Identity",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add a picture to make your community stand out.",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    image: _communityImage != null
                        ? DecorationImage(
                            image: FileImage(_communityImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _communityImage == null
                      ? Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "Tap to upload an image",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Step 3: Set the Rules",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Establish guidelines. At least one rule is required.",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 32),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _rulesControllers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _rulesControllers[index],
                    decoration: InputDecoration(
                      hintText: "Write a rule...",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFFF2F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                if (_rulesControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red),
                    onPressed: () => _removeRuleField(index),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _addRuleField,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_circle, color: AppColors.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  "Add another rule",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
