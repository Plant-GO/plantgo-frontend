import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';

/// Service for handling user location
class LocationService {
  /// Check and request location permissions
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current user location
  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      debugPrint('Location permission: $hasPermission');

      if (!hasPermission) {
        debugPrint('No location permission, returning default');
        // Return default location if no permission
        return const LatLng(
          AppConstants.defaultLatitude,
          AppConstants.defaultLongitude,
        );
      }

      debugPrint('Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint('Got position: ${position.latitude}, ${position.longitude}');
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Location error: $e');
      // Return default location on error
      return const LatLng(
        AppConstants.defaultLatitude,
        AppConstants.defaultLongitude,
      );
    }
  }

  /// Stream of location updates
  Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Calculate distance between two points in meters
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }
}
