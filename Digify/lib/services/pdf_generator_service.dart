import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class PdfGeneratorService {
  Future<Uint8List> generateReport({
    required String title,
    required List<File> images,
    required String additionalNotes,
    required String importantInfo,
    required Map<String, String> userData,
    required Map<String, String> deviceData,
    required Map<String, dynamic>? locationData,
    required String certificateId,
    required String? signaturePath,
    required String appName,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;

    try {
      font = await PdfGoogleFonts.poppinsRegular();
      boldFont = await PdfGoogleFonts.poppinsBold();
    } catch (e) {
      print('Error loading Google Fonts: $e');
      font = pw.Font.courier(); // Fallback
      boldFont = pw.Font.courierBold(); // Fallback
    }

    // Load images
    final List<pw.MemoryImage> pdfImages = [];
    for (var file in images) {
      final imageBytes = await file.readAsBytes();
      pdfImages.add(pw.MemoryImage(imageBytes));
    }

    // Load Signature
    pw.MemoryImage? signatureImage;
    if (signaturePath != null) {
      final sigFile = File(signaturePath);
      if (await sigFile.exists()) {
        final sigBytes = await sigFile.readAsBytes();
        signatureImage = pw.MemoryImage(sigBytes);
      }
    }

    // Load Map Snapshot
    pw.MemoryImage? mapImage;
    if (locationData != null) {
      try {
        final double lat = locationData['latitude'];
        final double lng = locationData['longitude'];
        // Using a public static map service (OSM based)
        final mapUrl =
            'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=600x300&maptype=mapnik&markers=$lat,$lng,red-pushpin';
        final response = await http.get(Uri.parse(mapUrl));
        if (response.statusCode == 200) {
          mapImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading map image: $e');
      }
    }

    final primaryColor = PdfColor.fromInt(0xFF274A31);
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        ),
        header: (context) =>
            _buildHeader(title, formattedDate, boldFont, font, primaryColor),
        footer: (context) => _buildFooter(context, font, primaryColor),
        build: (context) => [
          _buildImagesSection(pdfImages),
          pw.SizedBox(height: 20),
          _buildImageDetailsSection(images, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildNotesSection(
              additionalNotes, importantInfo, boldFont, primaryColor),
          pw.SizedBox(height: 20),
          _buildSignatureSection(signatureImage, boldFont, primaryColor),
          pw.SizedBox(height: 20),
          _buildUserDetailsTable(userData, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildDeviceDetailsTable(
              deviceData, appName, boldFont, font, primaryColor),
          if (locationData != null) ...[
            pw.SizedBox(height: 20),
            _buildGeolocationSection(
                locationData, mapImage, boldFont, primaryColor),
          ],
          pw.SizedBox(height: 20),
          _buildQrCodeSection(certificateId, boldFont, primaryColor),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateAudioReport({
    required String title,
    required List<File> frameImages,
    required String attestationStatement,
    required String additionalNotes,
    required Map<String, String> userData,
    required Map<String, String> deviceData,
    required Map<String, dynamic>? locationData,
    required String certificateId,
    required String? signaturePath,
    required String appName,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;

    try {
      font = await PdfGoogleFonts.poppinsRegular();
      boldFont = await PdfGoogleFonts.poppinsBold();
    } catch (e) {
      print('Error loading Google Fonts: $e');
      font = pw.Font.courier();
      boldFont = pw.Font.courierBold();
    }

    // Load images (frames)
    final List<pw.MemoryImage> pdfImages = [];
    for (var file in frameImages) {
      final imageBytes = await file.readAsBytes();
      pdfImages.add(pw.MemoryImage(imageBytes));
    }

    // Load Signature
    pw.MemoryImage? signatureImage;
    if (signaturePath != null) {
      final sigFile = File(signaturePath);
      if (await sigFile.exists()) {
        final sigBytes = await sigFile.readAsBytes();
        signatureImage = pw.MemoryImage(sigBytes);
      }
    }

    // Load Map Snapshot
    pw.MemoryImage? mapImage;
    if (locationData != null) {
      try {
        final double lat = locationData['latitude'];
        final double lng = locationData['longitude'];
        final mapUrl =
            'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=600x300&maptype=mapnik&markers=$lat,$lng,red-pushpin';
        final response = await http.get(Uri.parse(mapUrl));
        if (response.statusCode == 200) {
          mapImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading map image: $e');
      }
    }

    final primaryColor = PdfColor.fromInt(0xFF274A31);
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        ),
        header: (context) =>
            _buildHeader(title, formattedDate, boldFont, font, primaryColor),
        footer: (context) => _buildFooter(context, font, primaryColor),
        build: (context) => [
          _buildTestimonialSection(
              pdfImages, attestationStatement, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildNotesSection(additionalNotes, '', boldFont, primaryColor),
          pw.SizedBox(height: 20),
          _buildSignatureSection(signatureImage, boldFont, primaryColor),
          pw.SizedBox(height: 20),
          _buildUserDetailsTable(userData, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildDeviceDetailsTable(
              deviceData, appName, boldFont, font, primaryColor),
          if (locationData != null) ...[
            pw.SizedBox(height: 20),
            _buildGeolocationSection(
                locationData, mapImage, boldFont, primaryColor),
          ],
          pw.SizedBox(height: 20),
          _buildQrCodeSection(certificateId, boldFont, primaryColor),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildTestimonialSection(List<pw.MemoryImage> images,
      String statement, pw.Font boldFont, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Video Testimonial Frames',
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        _buildImagesSection(images),
        pw.SizedBox(height: 20),
        pw.Text('Attestation Statement',
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(5),
            color: PdfColors.grey50,
          ),
          child: pw.Text(
            statement,
            style: pw.TextStyle(font: font, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeader(String title, String date, pw.Font boldFont,
      pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          date,
          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: primaryColor),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(
      pw.Context context, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 10),
        pw.Container(height: 1, color: primaryColor),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by Digify',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              '${context.pageNumber}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildImagesSection(List<pw.MemoryImage> images) {
    return pw.GridView(
      crossAxisCount: 3,
      childAspectRatio: 1,
      children: images.map((image) {
        return pw.Container(
          margin: const pw.EdgeInsets.all(4),
          child: pw.Image(image, fit: pw.BoxFit.cover),
        );
      }).toList(),
    );
  }

  pw.Widget _buildImageDetailsSection(List<File> images, pw.Font boldFont,
      pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Captured Photo Details',
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        ...images.map((file) {
          final stat = file.statSync();
          final size = (stat.size / 1024).toStringAsFixed(2) + ' KB';
          final date = DateFormat('yyyy-MM-dd HH:mm:ss').format(stat.changed);
          String resolution = 'Unknown';
          try {
            final image = img.decodeImage(file.readAsBytesSync());
            if (image != null) {
              resolution = '${image.width} x ${image.height}';
            }
          } catch (e) {
            print('Error getting resolution: $e');
          }

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                _buildTableRow('Image Name', file.path.split('/').last,
                    boldFont, font, primaryColor),
                _buildTableRow(
                    'Creation Date', date, boldFont, font, primaryColor),
                _buildTableRow('File Size', size, boldFont, font, primaryColor),
                _buildTableRow(
                    'Resolution', resolution, boldFont, font, primaryColor),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  pw.TableRow _buildTableRow(String label, String value, pw.Font boldFont,
      pw.Font font, PdfColor primaryColor) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          color: PdfColors.grey100,
          child: pw.Text(label,
              style:
                  pw.TextStyle(font: boldFont, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(value, style: pw.TextStyle(font: font)),
        ),
      ],
    );
  }

  pw.Widget _buildNotesSection(
      String notes, String info, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (info.isNotEmpty) ...[
          pw.Text('Important Information',
              style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor)),
          pw.Text(info),
          pw.SizedBox(height: 10),
        ],
        if (notes.isNotEmpty) ...[
          pw.Text('Additional Notes',
              style: pw.TextStyle(
                  font: font,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor)),
          pw.Text(notes),
        ],
      ],
    );
  }

  pw.Widget _buildSignatureSection(
      pw.MemoryImage? signature, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Electronic Signature',
            style: pw.TextStyle(
                font: font,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        if (signature != null)
          pw.Container(
            height: 80,
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(signature, fit: pw.BoxFit.contain),
          )
        else
          pw.Text('No signature available',
              style: pw.TextStyle(font: font, color: PdfColors.grey)),
      ],
    );
  }

  pw.Widget _buildUserDetailsTable(Map<String, String> userData,
      pw.Font boldFont, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('User Details',
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Full Name', userData['name'] ?? 'N/A', boldFont,
                font, primaryColor),
            _buildTableRow('Email', userData['email'] ?? 'N/A', boldFont, font,
                primaryColor),
            _buildTableRow('User ID', userData['uid'] ?? 'N/A', boldFont, font,
                primaryColor),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDeviceDetailsTable(Map<String, String> deviceData,
      String appName, pw.Font boldFont, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Device Details',
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Device Model', deviceData['model'] ?? 'N/A',
                boldFont, font, primaryColor),
            _buildTableRow('Operating System', deviceData['os'] ?? 'N/A',
                boldFont, font, primaryColor),
            _buildTableRow('OS Version', deviceData['osVersion'] ?? 'N/A',
                boldFont, font, primaryColor),
            _buildTableRow('App Name', appName, boldFont, font, primaryColor),
            _buildTableRow('IP Address', deviceData['ip'] ?? 'N/A', boldFont,
                font, primaryColor),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildGeolocationSection(Map<String, dynamic> locationData,
      pw.MemoryImage? mapImage, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Geolocation',
            style: pw.TextStyle(
                font: font,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Text(
            'Latitude: ${locationData['latitude']}, Longitude: ${locationData['longitude']}',
            style: pw.TextStyle(font: font)),
        pw.SizedBox(height: 10),
        if (mapImage != null)
          pw.Container(
            height: 200,
            width: double.infinity,
            child: pw.Image(mapImage, fit: pw.BoxFit.cover),
          )
        else
          pw.Container(
            height: 100,
            width: double.infinity,
            color: PdfColors.grey200,
            alignment: pw.Alignment.center,
            child: pw.Text('Map Snapshot Unavailable',
                style: pw.TextStyle(color: PdfColors.grey700)),
          ),
      ],
    );
  }

  pw.Widget _buildQrCodeSection(
      String data, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      children: [
        pw.Text('Scan to Verify',
            style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: data,
          width: 100,
          height: 100,
        ),
      ],
    );
  }

  Future<Uint8List> generatePurchaseReport({
    required String itemName,
    required String itemPrice,
    required String itemQuantity,
    required String shopName,
    required String shopLocation,
    required String testimony,
    required String buyerName,
    required File? itemImage,
    required File? receiptImage,
    required Map<String, String> userData,
    required Map<String, String> deviceData,
    required Map<String, dynamic>? locationData,
    required String certificateId,
    required String? signaturePath,
    required String appName,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;

    try {
      font = await PdfGoogleFonts.poppinsRegular();
      boldFont = await PdfGoogleFonts.poppinsBold();
    } catch (e) {
      print('Error loading Google Fonts: $e');
      font = pw.Font.courier();
      boldFont = pw.Font.courierBold();
    }

    // Load Images
    pw.MemoryImage? pdfItemImage;
    if (itemImage != null) {
      final imageBytes = await itemImage.readAsBytes();
      pdfItemImage = pw.MemoryImage(imageBytes);
    }
    pw.MemoryImage? pdfReceiptImage;
    if (receiptImage != null) {
      final imageBytes = await receiptImage.readAsBytes();
      pdfReceiptImage = pw.MemoryImage(imageBytes);
    }

    // Load Signature
    pw.MemoryImage? signatureImage;
    if (signaturePath != null) {
      final sigFile = File(signaturePath);
      if (await sigFile.exists()) {
        final sigBytes = await sigFile.readAsBytes();
        signatureImage = pw.MemoryImage(sigBytes);
      }
    }

    // Load Map Snapshot
    pw.MemoryImage? mapImage;
    if (locationData != null) {
      try {
        final double lat = locationData['latitude'];
        final double lng = locationData['longitude'];
        final mapUrl =
            'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=600x300&maptype=mapnik&markers=$lat,$lng,red-pushpin';
        final response = await http.get(Uri.parse(mapUrl));
        if (response.statusCode == 200) {
          mapImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading map image: $e');
      }
    }

    final primaryColor = PdfColor.fromInt(0xFF274A31);
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        ),
        header: (context) => _buildHeader('Purchase Verification',
            formattedDate, boldFont, font, primaryColor),
        footer: (context) => _buildFooter(context, font, primaryColor),
        build: (context) => [
          _buildPurchaseImagesSection(
              pdfItemImage, pdfReceiptImage, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildPurchaseDetailsSection(itemName, itemPrice, itemQuantity,
              shopName, shopLocation, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildTestimonySection(
              testimony, buyerName, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildSignatureSection(signatureImage, boldFont, primaryColor),
          pw.SizedBox(height: 20),
          _buildUserDetailsTable(userData, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildDeviceDetailsTable(
              deviceData, appName, boldFont, font, primaryColor),
          if (locationData != null) ...[
            pw.SizedBox(height: 20),
            _buildGeolocationSection(
                locationData, mapImage, boldFont, primaryColor),
          ],
          pw.SizedBox(height: 20),
          _buildQrCodeSection(certificateId, boldFont, primaryColor),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPurchaseImagesSection(
      pw.MemoryImage? itemImg,
      pw.MemoryImage? receiptImg,
      pw.Font boldFont,
      pw.Font font,
      PdfColor primaryColor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (itemImg != null)
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('Item Image',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor)),
                pw.SizedBox(height: 5),
                pw.Container(
                  height: 150,
                  child: pw.Image(itemImg, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          ),
        if (itemImg != null && receiptImg != null) pw.SizedBox(width: 20),
        if (receiptImg != null)
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('Receipt Image',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor)),
                pw.SizedBox(height: 5),
                pw.Container(
                  height: 150,
                  child: pw.Image(receiptImg, fit: pw.BoxFit.contain),
                ),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _buildPurchaseDetailsSection(
      String name,
      String price,
      String qty,
      String shop,
      String loc,
      pw.Font boldFont,
      pw.Font font,
      PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Purchase Details',
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('Item Name', name, boldFont, font, primaryColor),
            _buildTableRow('Price', price, boldFont, font, primaryColor),
            _buildTableRow('Quantity', qty, boldFont, font, primaryColor),
            _buildTableRow('Shop Name', shop, boldFont, font, primaryColor),
            _buildTableRow('Shop Location', loc, boldFont, font, primaryColor),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTestimonySection(String testimony, String buyer,
      pw.Font boldFont, pw.Font font, PdfColor primaryColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Buyer's Testimony",
            style: pw.TextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor)),
        pw.SizedBox(height: 10),
        pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(5),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    testimony,
                    style: pw.TextStyle(
                        font: font, fontStyle: pw.FontStyle.italic),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text("- $buyer",
                        style: pw.TextStyle(font: boldFont)),
                  )
                ])),
      ],
    );
  }

  Future<Uint8List> generateVideoReport({
    required String title,
    required List<File> frameImages,
    required String attestationStatement,
    required String additionalNotes,
    required Map<String, String> userData,
    required Map<String, String> deviceData,
    required Map<String, dynamic>? locationData,
    required String certificateId,
    required String? signaturePath,
    required String appName,
  }) async {
    final pdf = pw.Document();
    pw.Font font;
    pw.Font boldFont;

    try {
      font = await PdfGoogleFonts.poppinsRegular();
      boldFont = await PdfGoogleFonts.poppinsBold();
    } catch (e) {
      print('Error loading Google Fonts: $e');
      font = pw.Font.courier();
      boldFont = pw.Font.courierBold();
    }

    // Load Frame Images
    List<pw.MemoryImage> pdfFrameImages = [];
    for (var file in frameImages) {
      final imageBytes = await file.readAsBytes();
      pdfFrameImages.add(pw.MemoryImage(imageBytes));
    }

    // Load Signature
    pw.MemoryImage? signatureImage;
    if (signaturePath != null) {
      final sigFile = File(signaturePath);
      if (await sigFile.exists()) {
        final sigBytes = await sigFile.readAsBytes();
        signatureImage = pw.MemoryImage(sigBytes);
      }
    }

    // Load Map Snapshot
    pw.MemoryImage? mapImage;
    if (locationData != null) {
      try {
        final double lat = locationData['latitude'];
        final double lng = locationData['longitude'];
        final mapUrl =
            'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=600x300&maptype=mapnik&markers=$lat,$lng,red-pushpin';
        final response = await http.get(Uri.parse(mapUrl));
        if (response.statusCode == 200) {
          mapImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Error loading map image: $e');
      }
    }

    final primaryColor = PdfColor.fromInt(0xFF274A31);
    final dateFormat = DateFormat('MMMM dd, yyyy - hh:mm a');
    final formattedDate = dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        ),
        header: (context) => _buildHeader('Video Verification', formattedDate,
            boldFont, font, primaryColor), // Changed Header
        footer: (context) => _buildFooter(context, font, primaryColor),
        build: (context) => [
          _buildTestimonialSection(pdfFrameImages, attestationStatement,
              boldFont, font, primaryColor),
          if (additionalNotes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildNotesSection(additionalNotes, "", font,
                primaryColor), // Info is empty for now
          ],
          pw.SizedBox(height: 20),
          _buildSignatureSection(signatureImage, boldFont, primaryColor),
          pw.SizedBox(height: 20),
          _buildUserDetailsTable(userData, boldFont, font, primaryColor),
          pw.SizedBox(height: 20),
          _buildDeviceDetailsTable(
              deviceData, appName, boldFont, font, primaryColor),
          if (locationData != null) ...[
            pw.SizedBox(height: 20),
            _buildGeolocationSection(
                locationData, mapImage, boldFont, primaryColor),
          ],
          pw.SizedBox(height: 20),
          _buildQrCodeSection(certificateId, boldFont, primaryColor),
        ],
      ),
    );

    return pdf.save();
  }
}
