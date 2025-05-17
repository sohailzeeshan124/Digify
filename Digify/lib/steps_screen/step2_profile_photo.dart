import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Step2ProfilePhoto extends StatefulWidget {
  @override
  _Step2ProfilePhotoState createState() => _Step2ProfilePhotoState();
}

class _Step2ProfilePhotoState extends State<Step2ProfilePhoto> {
  XFile? profileImage;
  XFile? cnicImage;
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(bool isProfile) async {
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => isProfile ? profileImage = image : cnicImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text("Step 2: Upload Photos", style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 20),
        _buildImageUploadSection(
          "Profile Picture",
          profileImage,
          () => pickImage(true),
        ),
        SizedBox(height: 20),
        _buildImageUploadSection(
          "CNIC Picture",
          cnicImage,
          () => pickImage(false),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection(
    String label,
    XFile? image,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade100,
            ),
            child:
                image == null
                    ? Icon(Icons.camera_alt, color: Colors.grey, size: 40)
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(image.path), fit: BoxFit.cover),
                    ),
          ),
        ),
      ],
    );
  }
}
