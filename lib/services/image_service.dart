import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' show max;
import 'package:injectable/injectable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

@singleton
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndProcessImage({
    ImageSource source = ImageSource.camera,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (pickedFile == null) return null;

      File imageFile = File(pickedFile.path);
      return await processAndUploadImage(imageFile.path);
    } catch (e) {
      print("Error in image capture process: $e");
      return null;
    }
  }

  Future<String?> processAndUploadImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      
      if (!await imageFile.exists()) {
        throw Exception("Image file not found");
      }

      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final originalSize = bytes.length;
      print("Original image size: ${originalSize / 1024} KB");

      // Decode the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        throw Exception("Failed to decode image");
      }

      // Get original dimensions
      final originalWidth = originalImage.width;
      final originalHeight = originalImage.height;

      // Resize if necessary
      img.Image resizedImage = originalImage;
      if (originalWidth > 800 || originalHeight > 800) {
        // Calculate scale to resize to reasonable dimensions
        final scale = 800 / max(originalWidth, originalHeight);
        final newWidth = (originalWidth * scale).round();
        final newHeight = (originalHeight * scale).round();

        print("Resizing image from ${originalWidth}x${originalHeight} to ${newWidth}x${newHeight}");
        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
        );
      }

      // Compress the image - start with moderate compression
      int quality = 70;
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);

      // Check if still too large and compress more if needed
      // Firestore limit is ~1MB, but we need to account for base64 encoding overhead
      // Base64 encoding increases size by ~33%, so we aim for 700KB max
      final maxSizeBytes = 700 * 1024;

      // Recompress with lower quality if needed
      if (compressedBytes.length > maxSizeBytes) {
        quality = 50; // Try with more compression
        print("Image still too large (${compressedBytes.length / 1024} KB). Recompressing with quality: $quality%");
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);

        // If still too large, try even more compression
        if (compressedBytes.length > maxSizeBytes) {
          quality = 30;
          print("Image still too large (${compressedBytes.length / 1024} KB). Recompressing with quality: $quality%");
          compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        }
      }

      // Convert to base64 and check final size
      final base64Image = base64Encode(compressedBytes);
      print("Final image size: ${compressedBytes.length / 1024} KB, Base64 size: ${base64Image.length / 1024} KB");

      // Final safety check - if still over limit, reduce quality more drastically
      if (base64Image.length > 900000) {
        quality = 20;
        print("Base64 still too large. Final compression with quality: $quality%");
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        final finalBase64 = base64Encode(compressedBytes);
        return 'data:image/jpeg;base64,$finalBase64';
      }

      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print("Error processing image: $e");
      return null;
    }
  }

  Future<Uint8List?> base64ToImage(String base64String) async {
    try {
      if (base64String.startsWith('data:image')) {
        final base64Data = base64String.split(',')[1];
        return base64Decode(base64Data);
      } else {
        return base64Decode(base64String);
      }
    } catch (e) {
      print("Error converting base64 to image: $e");
      return null;
    }
  }

  bool isValidImageFormat(String fileName) {
    final supportedFormats = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowercaseFileName = fileName.toLowerCase();
    return supportedFormats.any((format) => lowercaseFileName.endsWith(format));
  }

  Future<String?> compressImageToSize(String imagePath, int maxSizeKB) async {
    try {
      File imageFile = File(imagePath);
      if (!await imageFile.exists()) return null;

      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      int quality = 90;
      List<int> compressedBytes;

      do {
        compressedBytes = img.encodeJpg(image, quality: quality);
        quality -= 10;
      } while (compressedBytes.length > maxSizeKB * 1024 && quality > 10);

      final base64Image = base64Encode(compressedBytes);
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print("Error compressing image: $e");
      return null;
    }
  }
}
