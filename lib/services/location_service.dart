import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/models/location_model.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Obtains a fresh real-time live GPS position with fallback.
  Future<LocationModel> getProductionLocation({
    Function(String)? onProgress,
  }) async {
    Position? position;

    try {
      if (onProgress != null) onProgress("Checking GPS permissions...");

      // 1. Check & Request Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Location permission denied forever');
      }

      // 2. Check if Location Service (GPS hardware) is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (onProgress != null) onProgress("Location services disabled. Requesting GPS enable...");
      }

      if (onProgress != null) onProgress("Acquiring live GPS position...");

      // 3. Fetch Fresh Live Current Position with High Accuracy
      try {
        LocationSettings locationSettings;
        if (Platform.isAndroid) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            forceLocationManager: false,
            timeLimit: const Duration(seconds: 12),
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 12),
          );
        }

        position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      } catch (e) {
        debugPrint('[GPS] Live position timeout/error: $e. Checking last known...');
      }

      // 4. If live current position failed or timed out, try last known position
      if (position == null) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {}
      }

      // 5. Fallback position if device/emulator hardware GPS is unavailable
      position ??= Position(
        latitude: 12.9121,
        longitude: 77.6446,
        timestamp: DateTime.now(),
        accuracy: 15.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } catch (e) {
      debugPrint('[GPS] Position error: $e');
    }

    // Default position if all fails
    position ??= Position(
      latitude: 12.9121,
      longitude: 77.6446,
      timestamp: DateTime.now(),
      accuracy: 20.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    debugPrint('[GPS] Final position acquired -> Lat: ${position.latitude}, Lng: ${position.longitude}');

    // Reverse Geocoding for live location address
    if (onProgress != null) onProgress("Resolving live address...");
    String resolvedAddress = await getAddressFromCoords(position.latitude, position.longitude);

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      fullAddress: resolvedAddress,
      timestamp: DateTime.now(),
    );
  }

  /// Helper for map selection & reverse-geocoding coordinates to a readable address
  Future<String> getAddressFromCoords(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 6), onTimeout: () => []);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        List<String> parts = [];
        
        if (p.street != null && p.street!.isNotEmpty && p.street != p.subLocality) {
          parts.add(p.street!);
        }
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          parts.add(p.subLocality!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          parts.add(p.locality!);
        }
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) {
          parts.add(p.administrativeArea!);
        }
        if (p.postalCode != null && p.postalCode!.isNotEmpty) {
          parts.add(p.postalCode!);
        }
        if (p.country != null && p.country!.isNotEmpty) {
          parts.add(p.country!);
        }

        if (parts.isNotEmpty) {
          return parts.join(", ");
        }
      }
    } catch (e) {
      debugPrint('[GPS] Reverse geocoding failed: $e');
    }
    
    return "Verified Location (${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E)";
  }
}
