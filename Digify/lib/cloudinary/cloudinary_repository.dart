import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryRepository {
  late Cloudinary cloudinary;

  CloudinaryRepository() {
    cloudinary = Cloudinary.full(
      apiKey: '332321586294733',
      apiSecret: 'k2gglkp-xp6x01rEPXGWC8uH_zE',
      cloudName: 'dl6euqas9',
    );
  }

  /// Upload any image (profile, CNIC, signature, etc.)
  Future<CloudinaryResponse?> uploadImage(String filePath,
      {String folder = "digify"}) async {
    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: filePath,
          resourceType: CloudinaryResourceType.image,
          folder: folder, // groups uploads inside a folder in Cloudinary
        ),
      );
      return response;
    } catch (e) {
      print("Cloudinary upload failed: $e");
      return null;
    }
  }

  Future<CloudinaryResponse?> uploadSignature(String filePath) async {
    try {
      // apply background remover only for signature images
      // final processedFile = await applyAlphaBackgroundRemoval(filePath as File);

      return await uploadImage(
        filePath,
        folder: "digify/signatures",
      );
    } catch (e) {
      print("Signature upload failed: $e");
      return null;
    }
  }

  /// Upload PDFs or other docs (optional, for Digify future use)
  Future<CloudinaryResponse?> uploadFile(String filePath,
      {String folder = "digify"}) async {
    try {
      final response = await cloudinary.uploadResource(
        CloudinaryUploadResource(
          filePath: filePath,
          resourceType: CloudinaryResourceType.raw,
          folder: folder,
        ),
      );
      return response;
    } catch (e) {
      print("Cloudinary upload failed: $e");
      return null;
    }
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract public ID from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      int uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
        print("Invalid Cloudinary URL format");
        return false;
      }

      List<String> publicIdSegments = pathSegments.sublist(uploadIndex + 2);
      String publicId = publicIdSegments.join('/');
      int dotIndex = publicId.lastIndexOf('.');
      if (dotIndex != -1) {
        publicId = publicId.substring(0, dotIndex);
      }

      // Use HTTP to delete
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);

      final response = await http.post(
        Uri.parse('https://api.cloudinary.com/v1_1/dl6euqas9/image/destroy'),
        body: {
          'public_id': publicId,
          'api_key': '332321586294733',
          'timestamp': timestamp,
          'signature': signature,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Cloudinary delete failed: $e");
      return false;
    }
  }

  String _generateSignature(String publicId, String timestamp) {
    // Simple signature generation: public_id + timestamp + api_secret
    // Note: In production, this should be more robust and handle parameters sorting
    // But for destroy, typically only public_id and timestamp are needed.
    // However, Cloudinary requires parameters to be sorted alphabetically.
    // public_id=...&timestamp=...

    final String params = 'public_id=$publicId&timestamp=$timestamp';
    final String toSign =
        '$params${'k2gglkp-xp6x01rEPXGWC8uH_zE'}'; // Append API Secret

    // SHA1 hash
    var bytes = utf8.encode(toSign);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }
}
