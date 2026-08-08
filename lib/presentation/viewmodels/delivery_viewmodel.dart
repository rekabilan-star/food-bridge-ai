import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/socket_service.dart';
import '../../data/models/donation_model.dart';

class DeliveryViewModel extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _locationSubscription?.cancel();
    super.dispose();
  }

  DonationModel? _currentDonation;
  DonationModel? get currentDonation => _currentDonation;

  LatLng? _volunteerPosition;
  LatLng? get volunteerPosition => _volunteerPosition;
  
  double _volunteerHeading = 0;
  double get volunteerHeading => _volunteerHeading;

  String _eta = "Calculating...";
  String get eta => _eta;

  String _distance = "0 km";
  String get distance => _distance;

  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<Position>? _locationSubscription;

  void initDelivery(DonationModel donation, String userId) {
    _currentDonation = donation;
    _socketService.connect();
    _socketService.joinDonationRoom(donation.id);
    
    _startLiveTracking(userId, donation.id);
    _listenForUpdates();
  }

  void updateStatus(String status, String description) {
    if (!_socketService.isConnected) return;

    _socketService.socket.emit('status_changed', {
      'donationId': _currentDonation?.id,
      'status': status,
      'description': description,
    });
    if (_currentDonation != null) {
      _currentDonation = _currentDonation!.copyWith(status: status);
      _safeNotify();
    }
  }

  Future<void> confirmDelivery({
    required String donationId,
    required String receiverName,
  }) async {
    updateStatus('completed', 'Food delivered to $receiverName');
  }

  void _startLiveTracking(String userId, String donationId) {
    _locationSubscription?.cancel();
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (_socketService.isConnected) {
        _socketService.updateLocation(
          userId: userId,
          donationId: donationId,
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          speed: position.speed,
        );
      }
      
      _volunteerPosition = LatLng(position.latitude, position.longitude);
      _volunteerHeading = position.heading;
      _calculateDistanceAndEta();
      _safeNotify();
    });
  }

  void _listenForUpdates() {
    _socketService.onLocationUpdated((data) {
      double lat = data['latitude']?.toDouble() ?? 0.0;
      double lng = data['longitude']?.toDouble() ?? 0.0;
      _volunteerHeading = data['heading']?.toDouble() ?? 0.0;
      _volunteerPosition = LatLng(lat, lng);
      _calculateDistanceAndEta();
      _safeNotify();
    });
  }

  void _calculateDistanceAndEta() {
    if (_volunteerPosition == null || _currentDonation == null) return;

    final double dist = Geolocator.distanceBetween(
      _volunteerPosition!.latitude,
      _volunteerPosition!.longitude,
      _currentDonation!.latitude,
      _currentDonation!.longitude,
    );

    _distance = "${(dist / 1000).toStringAsFixed(1)} km";
    int minutes = ((dist / 1000) / 30 * 60).round(); // 30km/h estimate
    _eta = "$minutes mins";
  }
}
