import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:local_rembg/local_rembg.dart';

class ImageSignature extends StatefulWidget {
  const ImageSignature({Key? key}) : super(key: key);

  @override
  State<ImageSignature> createState() => _ImageSignatureState();
}

class _ImageSignatureState extends State<ImageSignature> {
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

  Future<void> _finalizeSignature() async {
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
                File('${directory.path}/signature_nobg_$timestamp.png');
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

      // 3. Delete Old Signature (Cloudinary)
      final cloudinaryRepo = CloudinaryRepository();
      if (userData.signatureUrl != null) {
        await cloudinaryRepo.deleteImage(userData.signatureUrl!);
      }

      // 4. Delete Old Signature (Local)
      if (userData.signatureLocalPath != null) {
        final localFile = File(userData.signatureLocalPath!);
        if (await localFile.exists()) {
          await localFile.delete();
        }
      }

      // 5. Prepare Final File
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      File finalFile;
      if (_removeBackground && fileToUpload.path.contains('signature_nobg_')) {
        finalFile = fileToUpload;
      } else {
        finalFile = await fileToUpload
            .copy('${directory.path}/signature_$timestamp.png');
      }

      // 6. Upload New Signature
      final response = await cloudinaryRepo.uploadSignature(finalFile.path);
      if (response == null || response.secureUrl == null) {
        throw Exception("Failed to upload signature");
      }

      // 7. Update User Data
      await userViewModel.updateUser(currentUser.uid, {
        'signatureUrl': response.secureUrl,
        'signatureLocalPath': finalFile.path,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signature Updated Successfully")),
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
          "Upload Signature",
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
                              Text("Tap to upload image",
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
                    onPressed:
                        _selectedImage != null ? _finalizeSignature : null,
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
