import 'package:flutter/material.dart';

class VideoCertificate extends StatelessWidget {
  const VideoCertificate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Certificate'),
        backgroundColor: const Color(0xFF274A31),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam,
              size: 100,
              color: Color(0xFF274A31),
            ),
            const SizedBox(height: 20),
            const Text(
              'Create Video Certificate',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Add functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF274A31),
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload Video'),
            ),
          ],
        ),
      ),
    );
  }
}
