import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PdfUtils {
  /// Embeds the signature image onto the existing PDF at the given position, scale, and rotation
  static Future<String> embedSignature({
    required String pdfPath,
    required String signaturePath,
    required Offset offset,
    required double scale,
    required double rotation,
  }) async {
    // Load the original PDF
    final originalPdf = File(pdfPath).readAsBytesSync();
    final document = PdfDocument(inputBytes: originalPdf);

    // Load and decode the signature image
    final signatureImage = File(signaturePath).readAsBytesSync();
    final img.Image decodedSignature = img.decodeImage(signatureImage)!;

    // Add signature to the last page
    final lastPage = document.pages[document.pages.count - 1];
    final graphics = lastPage.graphics;

    // Convert signature to PDF image
    final signaturePdfImage = PdfBitmap(signatureImage);

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
        signaturePdfImage.width * scale,
        signaturePdfImage.height * scale,
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
    final document = PdfDocument(inputBytes: pdfBytes);

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
    final font = PdfStandardFont(PdfFontFamily.helvetica, 18);
    graphics.drawString(
      'This document has been signed.',
      font,
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 0, page.size.width, 50),
    );

    // Add QR code
    final qrPdfImage = PdfBitmap(qrImage!.buffer.asUint8List());
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
      brush: PdfSolidBrush(PdfColor(0, 0, 0)),
      bounds: Rect.fromLTWH(0, 320, page.size.width, 50),
    );

    // Save the document
    final bytes = await document.save();
    await File(pdfPath).writeAsBytes(bytes);
    document.dispose();
  }
}
