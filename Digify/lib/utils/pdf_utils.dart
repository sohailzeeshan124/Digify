import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:qr_flutter/qr_flutter.dart';

class PdfUtils {
  /// Embeds the signature image onto the existing PDF at the given position, scale, and rotation
  static Future<String> embedSignature({
    required String pdfPath,
    required String signaturePath,
    required Offset offset,
    required double width,
    required double height,
    required double rotation,
  }) async {
    // Load the original PDF
    final originalPdf = File(pdfPath).readAsBytesSync();
    final document = sf.PdfDocument(inputBytes: originalPdf);

    // Load and decode the signature image
    final signatureImage = File(signaturePath).readAsBytesSync();
    final img.Image decodedSignature = img.decodeImage(signatureImage)!;

    // Always sign the second-to-last page if more than one page (assume last is QR code page)
    int signPageIndex = document.pages.count > 1
        ? document.pages.count - 2
        : document.pages.count - 1;
    final signPage = document.pages[signPageIndex];
    final graphics = signPage.graphics;

    // Convert signature to PDF image
    final signaturePdfImage = sf.PdfBitmap(signatureImage);

    // Apply transformations
    graphics.save();
    graphics.translateTransform(offset.dx, offset.dy);
    graphics.rotateTransform(rotation);

    // Draw the signature with scaled dimensions
    graphics.drawImage(
      signaturePdfImage,
      Rect.fromLTWH(
        0,
        0,
        width,
        height,
      ),
    );
    graphics.restore();

    // Save the modified document
    final outputDir = await getTemporaryDirectory();
    final outputPath = '${outputDir.path}/signed_document.pdf';
    final outputFile = File(outputPath);
    final bytes = await document.save();
    await outputFile.writeAsBytes(bytes);
    document.dispose();

    return outputPath;
  }

  /// Appends a final page with a QR code that links to the Firestore document
  static Future<void> appendQrCodePage(String pdfPath, String docId) async {
    // Load the PDF
    final pdfBytes = File(pdfPath).readAsBytesSync();
    final document = sf.PdfDocument(inputBytes: pdfBytes);

    // Generate QR code data using the Firestore document UID
    final qrData = docId; // Just use the document UID

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
    // This method is a placeholder for future logic if needed
    return path;
  }

  // For UI: Use SfPdfViewer.file(File(pdfPath)) to render the PDF.
  // To create a horizontal grid of pages with overlays, use a PageView.builder or ListView.builder
  // and overlay your signature widget using a Stack. For dotted borders, use a CustomPainter.
}
