import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import 'package:logger/logger.dart';

class CloudinaryHelper {
  static final Logger _logger = Logger();
  static final cloudinary = CloudinaryPublic(
    'YOUR_CLOUD_NAME', 
    'YOUR_UPLOAD_PRESET', 
    cache: false
  );

  static Future<String?> uploadImage(File file) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(file.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      _logger.e('Cloudinary Upload Error: $e');
      return null;
    }
  }
}
