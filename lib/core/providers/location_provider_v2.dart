import 'package:flutter/material.dart';
import 'dart:async';
import '../models/location_model.dart';
import '../../services/location_service.dart';
import '../errors/location_exception.dart';
import 'package:geolocator/geolocator.dart';

class LocationProviderV2 extends ChangeNotifier {
  final LocationService _service = LocationService();

  LocationModel? _location;
  LocationModel? get location => _location;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _loadingMessage = "";
  String get loadingMessage => _loadingMessage;

  int _retryCount = 0;
  int get retryCount => _retryCount;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;

  Timer? _timer;

  LocationException? _error;
  LocationException? get error => _error;

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = null;
    _loadingMessage = "Initializing...";
    _retryCount = 0;
    _elapsedSeconds = 0;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });

    try {
      _location = await _service.getProductionLocation(
        onProgress: (msg) {
          _loadingMessage = msg;
          if (msg.contains("Attempt")) {
             _retryCount++;
          }
          notifyListeners();
        },
      );
      _isLoading = false;
      _timer?.cancel();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _timer?.cancel();
      if (e is LocationException) {
        _error = e;
      } else {
        _error = LocationException(
          message: "An unexpected error occurred",
          developerMessage: e.toString(),
          type: LocationErrorType.unknown,
        );
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
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

  void setManualLocation(LocationModel model) {
    _location = model;
    _error = null;
    notifyListeners();
  }
}
