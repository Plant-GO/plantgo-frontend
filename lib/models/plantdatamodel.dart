class Treasure {
  final double lat;
  final double lng;
  final String name;
  final String imageUrl;
  // Optional fields for chunked image data if needed
  final List<String>? imageChunks;
  final bool? isChunkedImage;

  Treasure({
    required this.lat,
    required this.lng,
    required this.name,
    required this.imageUrl,
    this.imageChunks,
    this.isChunkedImage,
  });

  factory Treasure.fromMap(Map<String, dynamic> map) {
    return Treasure(
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      name: map['name'] as String,
      imageUrl: map['imageUrl'] as String,
      imageChunks: map['imageChunks'] != null 
          ? List<String>.from(map['imageChunks']) 
          : null,
      isChunkedImage: map['isChunkedImage'] as bool?,
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'lat': lat,
      'lng': lng,
      'name': name,
      'imageUrl': imageUrl,
    };
    
    if (imageChunks != null) {
      data['imageChunks'] = imageChunks;
      data['isChunkedImage'] = true;
    }
    
    return data;
  }
}
