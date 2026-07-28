import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/services/live_tracking_service.dart';
import '../../data/models/donation_model.dart';

class LiveMapViewModel extends ChangeNotifier {
  final LiveTrackingService _trackingService = LiveTrackingService();
  
  LatLng? _volunteerPos;
  LatLng? get volunteerPos => _volunteerPos;
  
  double _volunteerHeading = 0;
  double get volunteerHeading => _volunteerHeading;

  String _currentAddress = "Locating...";
  String get currentAddress => _currentAddress;

  final String _eta = "--";
  String get eta => _eta;

  void initTracking(DonationModel donation, bool isVolunteer) {
    if (isVolunteer) {
      _trackingService.startTracking(donation.id);
    }

    _trackingService.listenToLocation(donation.id, (data) {
      _updateVolunteerPosition(
        LatLng(data['latitude'], data['longitude']),
        data['heading']?.toDouble() ?? 0,
      );
    });
  }

  void _updateVolunteerPosition(LatLng newPos, double heading) async {
    _volunteerPos = newPos;
    _volunteerHeading = heading;

    // Reverse Geocoding
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(newPos.latitude, newPos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress = "${place.street}, ${place.locality}";
      }
    } catch (_) {}

    notifyListeners();
  }

  @override
  void dispose() {
    _trackingService.stopTracking();
    super.dispose();
  }
}
