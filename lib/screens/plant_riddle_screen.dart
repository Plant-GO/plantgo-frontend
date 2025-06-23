// lib/screens/plant_riddle_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math' show max;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plantdatamodel.dart';
import 'osm_map.dart';

class PlantRiddleScreen extends StatefulWidget {
  final int levelIndex;
  
  const PlantRiddleScreen({Key? key, required this.levelIndex}) : super(key: key);
  
  @override
  _PlantRiddleScreenState createState() => _PlantRiddleScreenState();
}

class _PlantRiddleScreenState extends State<PlantRiddleScreen> {
  List<String> riddleImages = [
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic.png',
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (1).png',
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (2).png',
    'assets/riddles/Hawaiian Theme Party Ideas Blog Graphic (3).png',
  ];

  final ImagePicker picker = ImagePicker();
  Position? currentLocation;

  bool get hasRiddleForLevel => widget.levelIndex < riddleImages.length;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = position;
      });
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to get location: $e")),
        );
      }
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception("Image file not found");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Processing image...")),
      );
      
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to process image: $e")),
        );
      }
      return null;
    }
  }

  Future<void> _pickImageAndUpload() async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      if (currentLocation == null) {
        await _getLocation();
        if (currentLocation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location not available. Please try again.")),
          );
          return;
        }
      }

      File imageFile = File(pickedFile.path);
      String? imageUrl = await _uploadImage(imageFile);

      if (imageUrl != null) {
        _showPlantNameDialog(imageUrl);
      }
    } catch (e) {
      print("Error in image capture process: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error capturing image: $e")),
        );
      }
    }
  }

  void _showPlantNameDialog(String imageUrl) {
    TextEditingController plantNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2A2A),
        title: Text("Name this plant", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: plantNameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter plant name",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.greenAccent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              String plantName = plantNameController.text.trim();
              if (plantName.isNotEmpty) {
                _addTreasure(plantName, imageUrl);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please enter a plant name")),
                );
              }
            },
            child: Text("Save", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _addTreasure(String name, String imageUrl) {
    if (currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Location not available")),
      );
      return;
    }
    try {
      Treasure treasure = Treasure(
        lat: currentLocation!.latitude,
        lng: currentLocation!.longitude,
        name: name,
        imageUrl: imageUrl,
      );
      FirebaseFirestore.instance
          .collection('treasures')
          .add(treasure.toMap())
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Plant added successfully!")),
        );
        // Navigate to map screen to show the newly added plant
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => TreasureHuntApp()),
          (route) => route.isFirst,
        );
      }).catchError((error) {
        print("Error adding treasure: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save plant data")),
        );
      });
    } catch (e) {
      print("Error creating treasure: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating plant record")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101010),
      appBar: AppBar(
        backgroundColor: Color(0xFF101010),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          hasRiddleForLevel ? 'Plant Riddle - Level ${widget.levelIndex + 1}' : 'Coming Soon',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: hasRiddleForLevel ? _buildRiddleContent() : _buildComingSoonContent(),
        ),
      ),
    );
  }

  Widget _buildRiddleContent() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              riddleImages[widget.levelIndex],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 400,
                  color: Colors.grey.shade800,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported, 
                             color: Colors.white54, size: 50),
                        SizedBox(height: 10),
                        Text('Image not found',
                             style: TextStyle(color: Colors.white54)),
                        SizedBox(height: 10),
                        Text(riddleImages[widget.levelIndex],
                             style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: ElevatedButton(
            onPressed: () {
              _pickImageAndUpload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
              shadowColor: Colors.greenAccent.withOpacity(0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 20),
                SizedBox(width: 8),
                Text(
                  'Who am I?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey.shade600,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 20),
              Text(
                'Coming Soon!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Level ${widget.levelIndex + 1}',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'This riddle will be available soon.\nKeep practicing with the current levels!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Get notified when available',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
