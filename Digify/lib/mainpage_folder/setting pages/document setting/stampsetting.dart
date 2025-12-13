import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_rembg/local_rembg.dart';

class StampSetting extends StatefulWidget {
  const StampSetting({Key? key}) : super(key: key);

  @override
  State<StampSetting> createState() => _StampSettingState();
}

class _StampSettingState extends State<StampSetting> {
  File? _selectedImage;
  bool _isLoading = false;
  bool _removeBackground = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _finalizeStamp() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      File fileToUpload = _selectedImage!;

      // 1. Background Removal (if enabled)
      if (_removeBackground) {
        try {
          LocalRembgResultModel result = await LocalRembg.removeBackground(
            imagePath: _selectedImage!.path,
          );

          if (result.status == 1 && result.imageBytes != null) {
            final directory = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final processedFile =
                File('${directory.path}/stamp_nobg_$timestamp.png');
            await processedFile.writeAsBytes(result.imageBytes!);
            fileToUpload = processedFile;
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Background removal failed, uploading original image.")),
            );
          }
        } catch (e) {
          print("Background removal error: $e");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Background removal error, uploading original image.")),
          );
        }
      }

      // 2. Get User Data
      final userViewModel = UserViewModel();
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not logged in");

      final userData = await userViewModel.getUser(currentUser.uid);
      if (userData == null) throw Exception("User data not found");

      // 3. Delete Old Stamp (Cloudinary)
      final cloudinaryRepo = CloudinaryRepository();
      if (userData.stampUrl != null && userData.stampUrl!.isNotEmpty) {
        await cloudinaryRepo.deleteImage(userData.stampUrl!);
      }

      // 4. Delete Old Stamp (Local)
      if (userData.stampLocalPath != null &&
          userData.stampLocalPath!.isNotEmpty) {
        final localFile = File(userData.stampLocalPath!);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }

      // 5. Prepare Final File in Specific Directory
      final cacheDir = await getTemporaryDirectory();
      // Ensure the 'stamp' directory exists
      final stampDir = Directory('${cacheDir.path}/stamp');
      if (!await stampDir.exists()) {
        await stampDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFile =
          await fileToUpload.copy('${stampDir.path}/stamp_$timestamp.png');

      // 6. Upload New Stamp
      final response = await cloudinaryRepo.uploadSignature(finalFile
          .path); // Reusing uploadSignature as it likely uploads to a general folder or we can add a specific method if needed, but request said "upload to stampUrl" implying the field, not necessarily a different cloud folder logic unless specified. Assuming uploadSignature is fine for now as it returns a URL.
      if (response == null || response.secureUrl == null) {
        throw Exception("Failed to upload stamp");
      }

      // 7. Update User Data
      await userViewModel.updateUser(currentUser.uid, {
        'stampUrl': response.secureUrl,
        'stampLocalPath': finalFile.path,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stamp Updated Successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Upload Stamp",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: _selectedImage != null
                          ? Border.all(color: const Color(0xFF274A31), width: 2)
                          : Border.all(color: Colors.grey[300]!),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cloud_upload_outlined,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text("Tap to upload stamp image",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: SwitchListTile(
                      title: const Text("Remove Background"),
                      value: _removeBackground,
                      activeColor: const Color(0xFF274A31),
                      onChanged: (bool value) {
                        setState(() {
                          _removeBackground = value;
                        });
                      },
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedImage != null ? _finalizeStamp : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF274A31),
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Finalize",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
