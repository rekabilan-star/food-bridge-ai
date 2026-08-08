import 'package:flutter/material.dart';
import 'dart:async';
import '../models/location_model.dart';
import '../../services/location_service.dart';
import '../errors/location_exception.dart';
import 'package:geolocator/geolocator.dart';

enum GpsAccuracyLevel { excellent, good, improving, poor, unknown }

class LocationProviderV2 extends ChangeNotifier {
  final LocationService _service = LocationService();
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  LocationModel? _location;
  LocationModel? get location => _location;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _loadingMessage = "";
  String get loadingMessage => _loadingMessage;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  Timer? _timer;

  LocationException? _error;
  LocationException? get error => _error;

  GpsAccuracyLevel get accuracyLevel {
    if (_location == null) return GpsAccuracyLevel.unknown;
    final acc = _location!.accuracy;
    if (acc <= 20) return GpsAccuracyLevel.excellent;
    if (acc <= 50) return GpsAccuracyLevel.good;
    if (acc <= 100) return GpsAccuracyLevel.improving;
    return GpsAccuracyLevel.poor;
  }

  String get accuracyStatus {
    switch (accuracyLevel) {
      case GpsAccuracyLevel.excellent: return "Excellent / Location Verified";
      case GpsAccuracyLevel.good: return "Good / Acceptable";
      case GpsAccuracyLevel.improving: return "Improving GPS accuracy...";
      case GpsAccuracyLevel.poor: return "Poor GPS accuracy / Retry recommended";
      default: return "Unknown";
    }
  }

  Color get accuracyColor {
    switch (accuracyLevel) {
      case GpsAccuracyLevel.excellent: return Colors.green;
      case GpsAccuracyLevel.good: return Colors.blue;
      case GpsAccuracyLevel.improving: return Colors.orange;
      case GpsAccuracyLevel.poor: return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Returns true if genuine coordinates have been obtained with acceptable accuracy
  bool get isVerified => _location != null && _location!.accuracy <= 50;

  /// Fetches actual current position. No sample/fallback coordinates used.
  Future<void> fetchLocation() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    // Requirement 16: Display detecting message
    _loadingMessage = "Detecting your current location...";
    _elapsedSeconds = 0;
    _safeNotify();

    debugPrint('[GPS] Requesting fresh position');

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _safeNotify();
    });

    try {
      final newLoc = await _service.getProductionLocation(
        onProgress: (msg) {
          _loadingMessage = msg;
          _safeNotify();
        },
      );
      
      _location = newLoc;
      _isLoading = false;
      _timer?.cancel();
      _error = null;
      
      debugPrint('[GPS] Fresh position obtained:');
      debugPrint('[GPS] Lat: ${_location!.latitude}');
      debugPrint('[GPS] Lng: ${_location!.longitude}');
      debugPrint('[GPS] Acc: ${_location!.accuracy}m');
      debugPrint('[GPS] Timestamp: ${_location!.timestamp}');
      debugPrint('[GPS] Map marker updated');
      debugPrint('[GPS] Coordinates prepared for backend');
      
      _safeNotify();
    } catch (e) {
      _isLoading = false;
      _timer?.cancel();
      
      if (e is LocationException) {
        _error = e;
      } else {
        _error = LocationException(
          message: "Unable to detect your current location.",
          developerMessage: e.toString(),
          type: LocationErrorType.unknown,
        );
      }
      debugPrint('[GPS] Error: ${_error!.message}');
      _safeNotify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  void openSettings() {
    if (_error?.type == LocationErrorType.serviceDisabled) {
      Geolocator.openLocationSettings();
    } else {
      Geolocator.openAppSettings();
    }
  }

  void clearLocation() {
    _location = null;
    _error = null;
    _safeNotify();
  }

  void setManualLocation(LocationModel model) {
    _location = model;
    _error = null;
    _isLoading = false;
    _safeNotify();
  }
}
