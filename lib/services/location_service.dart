import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../core/models/location_model.dart';
import '../core/errors/location_exception.dart';
import '../core/utils/permission_helper.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

class LocationService {
  final Logger _logger = Logger();
  static const String _cacheKey = 'cached_location';

  Future<bool> _isEmulator() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return !androidInfo.isPhysicalDevice;
  }

  Future<LocationModel> getProductionLocation({
    Function(String)? onProgress,
    int maxRetries = 3,
  }) async {
    try {
      if (await _isEmulator()) {
        onProgress?.call("Running in Emulator. Note: Please send GPS coords via Extended Controls.");
      }

      onProgress?.call("Checking GPS & Permissions...");
      await PermissionHelper.checkAndRequestLocationPermission();

      // Step 1: Try Last Known Position (Fast)
      onProgress?.call("Checking last known location...");
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        _logger.i("Last known position found: ${position.latitude}, ${position.longitude}");
        return await _convertToLocationModel(position, onProgress);
      }

      // Step 2: Try Current Position with Retries
      int retryCount = 0;
      while (retryCount < maxRetries) {
        try {
          retryCount++;
          onProgress?.call("Fetching live GPS (Attempt $retryCount of $maxRetries)...");
          
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: Duration(seconds: 45),
            ),
          );
          
          _logger.i("Current position found on attempt $retryCount");
          return await _convertToLocationModel(position, onProgress);
        } catch (e) {
          _logger.w("Attempt $retryCount failed: $e");
          if (retryCount >= maxRetries) rethrow;
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      // Step 3: Stream Fallback
      onProgress?.call("Entering high-accuracy satellite search...");
      position = await _getPositionFromStream();
      if (position != null) {
        return await _convertToLocationModel(position, onProgress);
      }

      throw LocationException(
        message: "Unable to determine location automatically after $maxRetries attempts.",
        type: LocationErrorType.timeout,
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      
      // Try Cache as final fallback
      onProgress?.call("Searching cache as fallback...");
      final cached = await getCachedLocation();
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp).inHours;
        if (age < 24) {
          _logger.i("Returning cached location (Age: $age hours)");
          return cached;
        }
      }

      throw LocationException(
        message: "Location capture failed: ${e.toString()}",
        developerMessage: e.toString(),
        type: LocationErrorType.unknown,
      );
    }
  }

  Future<Position?> _getPositionFromStream() async {
    final Completer<Position?> completer = Completer<Position?>();
    StreamSubscription<Position>? subscription;

    subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(
      (Position pos) {
        subscription?.cancel();
        if (!completer.isCompleted) completer.complete(pos);
      },
      onError: (err) {
        subscription?.cancel();
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    // Hard timeout for stream
    Future.delayed(const Duration(seconds: 30), () {
      subscription?.cancel();
      if (!completer.isCompleted) completer.complete(null);
    });

    return completer.future;
  }

  Future<LocationModel> _convertToLocationModel(Position pos, Function(String)? onProgress) async {
    onProgress?.call("Converting coordinates to address...");
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final fullAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";
        
        final model = LocationModel(
          latitude: pos.latitude,
          longitude: pos.longitude,
          fullAddress: fullAddress,
          street: place.street,
          locality: place.locality,
          subLocality: place.subLocality,
          city: place.subAdministrativeArea,
          district: place.administrativeArea,
          state: place.administrativeArea,
          postalCode: place.postalCode,
          country: place.country,
          timestamp: DateTime.now(),
        );

        await _cacheLocation(model);
        return model;
      }
    } catch (e) {
      _logger.e("Geocoding failed: $e");
    }

    // Return model with coordinates even if address fails
    return LocationModel(
      latitude: pos.latitude,
      longitude: pos.longitude,
      fullAddress: "${pos.latitude}, ${pos.longitude}",
      timestamp: DateTime.now(),
    );
  }

  Future<void> _cacheLocation(LocationModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(model.toJson()));
  }

  Future<LocationModel?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cacheKey);
      if (data != null) {
        return LocationModel.fromJson(jsonDecode(data));
      }
    } catch (e) {
      _logger.e("Cache read error: $e");
    }
    return null;
  }
}
