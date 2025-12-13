import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:digify/viewmodels/user_viewmodel.dart';
import 'package:digify/cloudinary/cloudinary_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Textsignature extends StatefulWidget {
  const Textsignature({Key? key}) : super(key: key);

  @override
  State<Textsignature> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<Textsignature> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _globalKey = GlobalKey();
  bool _isLoading = false;

  String enteredText = "";
  int selectedIndex = -1;

  final List<Map<String, String>> signatureFonts = [
    {"name": "Alex Brush", "font": "AlexBrush"},
    {"name": "Allura", "font": "Allura"},
    {"name": "Great Vibes", "font": "GreatVibes"},
    {"name": "Pacifico", "font": "Pacifico"},
    {"name": "Sacramento", "font": "Sacramento"},
    {"name": "Yellowtail", "font": "Yellowtail"},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finalizeSignature() async {
    if (selectedIndex == -1) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Capture Image
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to capture signature");

      final buffer = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/signature_$timestamp.png');
      await file.writeAsBytes(buffer);

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

      // 5. Upload New Signature
      final response = await cloudinaryRepo.uploadSignature(file.path);
      if (response == null || response.secureUrl == null) {
        throw Exception("Failed to upload signature");
      }

      // 6. Update User Data
      await userViewModel.updateUser(currentUser.uid, {
        'signatureUrl': response.secureUrl,
        'signatureLocalPath': file.path,
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
          "Signature Generator",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔹 Input Field
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      enteredText = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                /// 🔹 Signature Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: signatureFonts.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF274A31)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Font name label
                                Text(
                                  signatureFonts[index]["name"]!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                /// Signature Text
                                isSelected
                                    ? RepaintBoundary(
                                        key: _globalKey,
                                        child: Container(
                                          color: Colors
                                              .transparent, // Ensure transparency
                                          child: Text(
                                            enteredText.isEmpty
                                                ? "Your Signature"
                                                : enteredText,
                                            style: TextStyle(
                                              fontFamily: signatureFonts[index]
                                                  ["font"],
                                              fontSize: 42,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        enteredText.isEmpty
                                            ? "Your Signature"
                                            : enteredText,
                                        style: TextStyle(
                                          fontFamily: signatureFonts[index]
                                              ["font"],
                                          fontSize: 42,
                                          color: Colors.black87,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (selectedIndex != -1)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _finalizeSignature,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF274A31),
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
                  ),
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
