import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CnicCameraScreen extends StatefulWidget {
  final Function(File) onPictureTaken;
  const CnicCameraScreen({super.key, required this.onPictureTaken});

  @override
  State<CnicCameraScreen> createState() => _CnicCameraScreenState();
}

class _CnicCameraScreenState extends State<CnicCameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _initCameraFlow();
  }

  Future<void> _initCameraFlow() async {
    // ✅ Request permission first
    var status = await Permission.camera.request();
    if (status.isGranted) {
      await _setupCamera();
    } else {
      setState(() {
        _permissionDenied = true;
      });
    }
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint("No camera available");
        return;
      }

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Start initialization and rebuild immediately so UI shows FutureBuilder
      _initializeControllerFuture = _controller!.initialize();
      if (mounted) setState(() {});
      // Let FutureBuilder await the future; no need to await here
    } catch (e) {
      debugPrint("Error setting up camera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;

      final image = await _controller!.takePicture();

      // Save image locally
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(
          directory.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final File savedImage = await File(image.path).copy(filePath);

      widget.onPictureTaken(savedImage);

      if (!mounted) return;
      Navigator.pop(context); // no casting needed
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Camera permission denied. Please enable it in settings.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Failed to initialize camera. Please check permissions or try again.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),

                // ✅ CNIC Frame Overlay
                Center(
                  child: AspectRatio(
                    aspectRatio: 1.585, // NADRA CNIC ratio
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green, width: 3),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),

                // ✅ Capture button
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Colors.green,
                      onPressed: _takePicture,
                      child: const Icon(Icons.camera_alt, size: 30),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
