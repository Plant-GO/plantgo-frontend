import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/plantdatamodel.dart';

class TreasureHuntApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant Go'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: MapScreen(),
    );
  }
}


class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? currentLocation;
  List<Treasure> treasures = [];
  final ImagePicker picker = ImagePicker();
  final TextEditingController searchController = TextEditingController();
  final mapController = MapController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _checkLocationPermission();
      await _getLocation();
      _fetchTreasures();
    } catch (e) {
      print("Initialization error: $e");
      Future.delayed(Duration.zero, () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error initializing app: $e")),
          );
        }
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkLocationPermission() async {
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
  }

  Future<void> _getLocation() async {
    try {
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

  Future<void> _fetchTreasures() async {
    try {
      FirebaseFirestore.instance.collection('treasures').snapshots().listen(
        (snapshot) {
          List<Treasure> newTreasures = snapshot.docs
              .map((doc) {
                try {
                  return Treasure.fromMap(doc.data());
                } catch (e) {
                  print("Error parsing treasure: $e");
                  return null;
                }
              })
              .where((treasure) => treasure != null)
              .cast<Treasure>()
              .toList();
          if (mounted) {
            setState(() {
              treasures = newTreasures;
            });
          }
        },
        onError: (error) {
          print("Firestore stream error: $error");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching plant data: $error")),
            );
          }
        },
      );
    } catch (e) {
      print("Error setting up Firestore listener: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Database connection error: $e")),
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
        title: Text("Name this plant"),
        content: TextField(
          controller: plantNameController,
          decoration: InputDecoration(hintText: "Enter plant name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
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
            child: Text("Save"),
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

  Widget _buildImageWidget(String imageUrl, {List<int>? imageChunks}) {
    if (imageChunks != null && imageChunks.isNotEmpty) {
      try {
        Uint8List imageData = Uint8List.fromList(imageChunks);
        return Image.memory(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Error displaying chunked image: $error");
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.broken_image, color: Colors.red),
            );
          },
        );
      } catch (e) {
        print("Error parsing chunked image: $e");
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, color: Colors.red),
        );
      }
    } else if (imageUrl.startsWith('data:image')) {
      try {
        final imageData = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(imageData),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print("Error displaying base64 image: $error");
            return Container(
              color: Colors.grey[300],
              child: Icon(Icons.broken_image, color: Colors.red),
            );
          },
        );
      } catch (e) {
        print("Error parsing base64 image: $e");
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.error, color: Colors.red),
        );
      }
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print("Error loading network image: $error");
          return Container(
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.red),
          );
        },
      );
    }
  }

  void _centerMapOnPosition(LatLng position) {
    mapController.move(position, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plant Go"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: () async {
              await _getLocation();
              if (currentLocation != null) {
                _centerMapOnPosition(LatLng(
                  currentLocation!.latitude,
                  currentLocation!.longitude,
                ));
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: currentLocation != null
                        ? LatLng(currentLocation!.latitude,
                            currentLocation!.longitude)
                        : LatLng(27.7172, 85.3240),
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        if (currentLocation != null)
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: LatLng(currentLocation!.latitude,
                                currentLocation!.longitude),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ...treasures.map((treasure) {
                          return Marker(
                            width: 40.0,
                            height: 40.0,
                            point: LatLng(treasure.lat, treasure.lng),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(treasure.name),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildImageWidget(treasure.imageUrl),
                                        SizedBox(height: 10),
                                        Text(
                                            "Location: ${treasure.lat.toStringAsFixed(5)}, ${treasure.lng.toStringAsFixed(5)}"),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: Text("Close"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Icon(Icons.eco,
                                  color: Colors.green, size: 40),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: TypeAheadField<Treasure>(
                      controller: searchController,
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: "Search Plants",
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        );
                      },
                      suggestionsCallback: (pattern) {
                        return treasures
                            .where((treasure) => treasure.name
                                .toLowerCase()
                                .contains(pattern.toLowerCase()))
                            .toList();
                      },
                      itemBuilder: (context, Treasure treasure) {
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: _buildImageWidget(treasure.imageUrl),
                            ),
                          ),
                          title: Text(treasure.name),
                          subtitle: Text(
                              "${treasure.lat.toStringAsFixed(5)}, ${treasure.lng.toStringAsFixed(5)}"),
                        );
                      },
                      onSelected: (Treasure selectedTreasure) {
                        searchController.text = selectedTreasure.name;
                        _centerMapOnPosition(LatLng(
                            selectedTreasure.lat, selectedTreasure.lng));
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImageAndUpload,
        child: Icon(Icons.camera_alt),
        tooltip: 'Capture Plant',
      ),
    );
  }
}