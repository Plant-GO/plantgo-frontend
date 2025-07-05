// lib/methods/pick_image_upload.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from camera and processes it
  static Future<String?> pickAndProcessImage(BuildContext context, {
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
      String? imageUrl = await _processImage(context, imageFile);

      return imageUrl;
    } catch (e) {
      print("Error in image capture process: $e");
      // Error capturing image, no visual feedback via SnackBar
      return null;
    }
  }

  /// Processes and compresses an image file
  static Future<String?> _processImage(BuildContext context, File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception("Image file not found");
      }

      // Processing image, no need for visual feedback via SnackBar
      
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
        quality = 50;  // Try with more compression
        print("Image still too large (${compressedBytes.length / 1024} KB). Recompressing with quality: $quality%");
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        
        // If still too large, resize further
        if (compressedBytes.length > maxSizeBytes) {
          final scale = 0.6;  // Reduce dimensions further
          final newWidth = (resizedImage.width * scale).round();
          final newHeight = (resizedImage.height * scale).round();
          
          print("Further resizing to ${newWidth}x${newHeight} with quality: $quality%");
          resizedImage = img.copyResize(
            resizedImage, 
            width: newWidth,
            height: newHeight,
          );
          compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        }
      }
      
      // Convert to base64 and check final size
      final base64Image = base64Encode(compressedBytes);
      print("Final image size: ${compressedBytes.length / 1024} KB, Base64 size: ${base64Image.length / 1024} KB");
      
      // Final safety check - if still over limit, reduce quality more drastically
      if (base64Image.length > 900000) {
        print("Image still too large, performing emergency compression");
        quality = 30;
        final scale = 0.4;
        final newWidth = (resizedImage.width * scale).round();
        final newHeight = (resizedImage.height * scale).round();
        resizedImage = img.copyResize(
          resizedImage,
          width: newWidth,
          height: newHeight,
        );
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        final finalBase64Image = base64Encode(compressedBytes);
        print("Emergency compression result: ${finalBase64Image.length / 1024} KB");
        return 'data:image/jpeg;base64,$finalBase64Image';
      }
      
      return 'data:image/jpeg;base64,$base64Image';
    } catch (e) {
      print("Error processing image: $e");
      // Silently return null, caller will handle the error state
      return null;
    }
  }

  /// Shows a dialog to let user name the plant and handle the result
  static void showPlantNameDialog(
    BuildContext context, 
    String imageUrl, 
    Function(String plantName, String imageUrl) onPlantNamed
  ) {
    TextEditingController plantNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text(
          "Name this plant", 
          style: TextStyle(color: Colors.white)
        ),
        content: TextField(
          controller: plantNameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter plant name",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              String plantName = plantNameController.text.trim();
              if (plantName.isNotEmpty) {
                Navigator.pop(context);
                onPlantNamed(plantName, imageUrl);
              } else {
                // Highlight the text field instead of showing a SnackBar
                plantNameController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: plantNameController.text.length
                );
                // Visual error feedback handled in the dialog UI
              }
            },
            child: Text("Save", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  /// Complete flow: pick image, process it, and show naming dialog
  static Future<void> pickImageAndShowDialog(
    BuildContext context,
    Function(String plantName, String imageUrl) onPlantNamed, {
    ImageSource source = ImageSource.camera,
    int imageQuality = 85,
  }) async {
    String? imageUrl = await pickAndProcessImage(
      context, 
      source: source, 
      imageQuality: imageQuality
    );
    
    if (imageUrl != null) {
      showPlantNameDialog(context, imageUrl, onPlantNamed);
    }
  }
}
