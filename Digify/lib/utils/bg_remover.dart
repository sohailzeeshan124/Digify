// lib/utils/bg_remove.dart
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Apply a simple alpha-based background removal.
/// [threshold] is 0..1 where 1 = most aggressive removal (more pixels become transparent).
Future<File> applyAlphaBackgroundRemoval(File file,
    {double threshold = 0.9}) async {
  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) return file;

  // Create a writable copy of the decoded image
  final out = img.Image.from(image);
  final int t = (threshold * 255).toInt();

  for (int y = 0; y < out.height; y++) {
    for (int x = 0; x < out.width; x++) {
      // getPixel returns an int (ARGB) representing the pixel
      final int pixel = out.getPixel(x, y) as int;

      // use top-level helpers to extract channels
      final int r = (pixel >> 16) & 0xFF;
      final int g = (pixel >> 8) & 0xFF;
      final int b = pixel & 0xFF;

      // simple brightness heuristic
      final int brightness = ((r + g + b) / 3).round();
      if (brightness > t) {
        // make pixel fully transparent
        out.setPixelRgba(x, y, r, g, b, 0);
      }
    }
  }

  final png = img.encodePng(out);
  final dir = await getTemporaryDirectory();
  final outFile = File(
      '${dir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png');
  await outFile.writeAsBytes(png);
  return outFile;
}
