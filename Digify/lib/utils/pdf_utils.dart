import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:qr_flutter/qr_flutter.dart';

class PdfUtils {
  /// Embeds multiple overlays (images, text, drawings) onto the PDF
  static Future<String> embedOverlays({
    required String pdfPath,
    required List<PdfOverlayItem> overlays,
  }) async {
    // Load the original PDF
    final originalPdf = File(pdfPath).readAsBytesSync();
    final document = sf.PdfDocument(inputBytes: originalPdf);

    for (final overlay in overlays) {
      // Determine page index
      int pageIndex = overlay.pageIndex;
      if (pageIndex < 0 || pageIndex >= document.pages.count) {
        // Fallback logic: sign the second-to-last page if > 1 page, else last page
        pageIndex = document.pages.count > 1
            ? document.pages.count - 2
            : document.pages.count - 1;
      }

      final page = document.pages[pageIndex];
      final graphics = page.graphics;

      graphics.save();
      if (overlay is PdfImageOverlay) {
        final imageBytes = File(overlay.imagePath).readAsBytesSync();
        final pdfImage = sf.PdfBitmap(imageBytes);
        graphics.translateTransform(overlay.offset.dx, overlay.offset.dy);
        graphics.rotateTransform(overlay.rotation);
        graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(0, 0, overlay.width, overlay.height),
        );
      } else if (overlay is PdfTextOverlay) {
        final font = sf.PdfStandardFont(
            _getFontFamily(overlay.fontFamily), overlay.fontSize);
        final brush = sf.PdfSolidBrush(sf.PdfColor(
            overlay.color.red, overlay.color.green, overlay.color.blue));
        graphics.drawString(
          overlay.text,
          font,
          brush: brush,
          bounds: Rect.fromLTWH(
              overlay.offset.dx, overlay.offset.dy, 500, 100), // Approx bounds
        );
      } else if (overlay is PdfDrawingOverlay) {
        final pen = sf.PdfPen(
          sf.PdfColor(
              overlay.color.red, overlay.color.green, overlay.color.blue),
          width: overlay.strokeWidth,
        );
        // Draw paths
        for (int i = 0; i < overlay.points.length - 1; i++) {
          if (overlay.points[i] != null && overlay.points[i + 1] != null) {
            graphics.drawLine(
              pen,
              overlay.points[i]!,
              overlay.points[i + 1]!,
            );
          }
        }
      }
      graphics.restore();
    }

    // Save the modified document
    final outputDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${outputDir.path}/signed_document_$timestamp.pdf';
    final outputFile = File(outputPath);
    final bytes = await document.save();
    await outputFile.writeAsBytes(bytes);
    document.dispose();

    return outputPath;
  }

  static sf.PdfFontFamily _getFontFamily(String fontFamily) {
    switch (fontFamily) {
      case 'Times':
        return sf.PdfFontFamily.timesRoman;
      case 'Courier':
        return sf.PdfFontFamily.courier;
      case 'Helvetica':
      case 'Arial':
      case 'Roboto':
      default:
        return sf.PdfFontFamily.helvetica;
    }
  }

  /// Appends a final page with a QR code that links to the Firestore document
  static Future<void> appendQrCodePage(String pdfPath, String docId) async {
    // Load the PDF
    final pdfBytes = File(pdfPath).readAsBytesSync();
    final document = sf.PdfDocument(inputBytes: pdfBytes);

    // Generate QR code data using the Firestore document UID
    final qrData = docId;

    // Generate QR code image
    final qrImage = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: false,
      color: Colors.black,
      emptyColor: Colors.white,
    ).toImageData(400);

    // Add new page
    final page = document.pages.add();
    final graphics = page.graphics;

    // Add text
    final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'This document has been signed.',
      font,
      brush: sf.PdfSolidBrush(sf.PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.size.width, 50),
    );

    // Add QR code
    final qrPdfImage = sf.PdfBitmap(qrImage!.buffer.asUint8List());
    graphics.drawImage(
      qrPdfImage,
      Rect.fromLTWH(
        (page.size.width - 200) / 2,
        100,
        200,
        200,
      ),
    );

    // Add verification text
    graphics.drawString(
      'Scan this QR code to verify the document.',
      font,
      brush: sf.PdfSolidBrush(sf.PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 320, page.size.width, 50),
    );

    // Save the document
    final bytes = await document.save();
    await File(pdfPath).writeAsBytes(bytes);
    document.dispose();
  }

  /// Returns the PDF file path for use with SfPdfViewer.file
  static String getPdfFilePath(String path) {
    return path;
  }
}

// Overlay Classes
abstract class PdfOverlayItem {
  final int pageIndex;
  PdfOverlayItem({this.pageIndex = -1});
}

class PdfImageOverlay extends PdfOverlayItem {
  final String imagePath;
  final Offset offset;
  final double width;
  final double height;
  final double rotation;

  PdfImageOverlay({
    required this.imagePath,
    required this.offset,
    required this.width,
    required this.height,
    this.rotation = 0,
    int pageIndex = -1,
  }) : super(pageIndex: pageIndex);
}

class PdfTextOverlay extends PdfOverlayItem {
  final String text;
  final Offset offset;
  final double fontSize;
  final Color color;
  final String fontFamily;

  PdfTextOverlay({
    required this.text,
    required this.offset,
    required this.fontSize,
    required this.color,
    required this.fontFamily,
    int pageIndex = -1,
  }) : super(pageIndex: pageIndex);
}

class PdfDrawingOverlay extends PdfOverlayItem {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  PdfDrawingOverlay({
    required this.points,
    required this.color,
    required this.strokeWidth,
    int pageIndex = -1,
  }) : super(pageIndex: pageIndex);
}
