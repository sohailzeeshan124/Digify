import 'dart:io';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';

import 'package:cloudinary_sdk/cloudinary_sdk.dart';

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
          resourceType: CloudinaryResourceType.auto,
          folder: folder,
        ),
      );
      return response;
    } catch (e) {
      print("Cloudinary upload failed: $e");
      return null;
    }
  }
}
