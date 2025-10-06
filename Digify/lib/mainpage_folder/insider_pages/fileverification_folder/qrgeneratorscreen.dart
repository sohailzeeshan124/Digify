import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _textController = TextEditingController();
  String? _qrData;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _qrData = _textController.text;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Generate QR Code',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF274A31),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'Enter Document UID',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: _generateQR,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_qrData != null) ...[
              Center(
                child: QrImageView(
                  data: _qrData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Add share functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('QR Code generated successfully')),
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text(
                  'Share QR Code',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF274A31),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
