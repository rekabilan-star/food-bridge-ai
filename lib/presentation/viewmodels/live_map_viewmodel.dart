import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/live_tracking_service.dart';
import '../../data/models/donation_model.dart';
import '../../data/repositories/donation_repository.dart';

class LiveMapViewModel extends ChangeNotifier {
  final LiveTrackingService _trackingService = LiveTrackingService();
  final DonationRepository _donationRepository = DonationRepository();
  
  LatLng? _volunteerPos;
  LatLng? get volunteerPos => _volunteerPos;
  
  double _volunteerHeading = 0;
  double get volunteerHeading => _volunteerHeading;

  String _currentAddress = "Locating...";
  String get currentAddress => _currentAddress;

  List<LatLng> _routePoints = [];
  List<LatLng> get routePoints => _routePoints;

  double _routeDistanceKm = 0;
  double get routeDistanceKm => _routeDistanceKm;

  int _routeDurationMins = 0;
  int get routeDurationMins => _routeDurationMins;

  String _routingSource = "NONE";
  String get routingSource => _routingSource;

  bool _isLoadingRoute = false;
  bool get isLoadingRoute => _isLoadingRoute;

  DateTime? _lastLocationUpdate;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;

  // Refresh Control
  DateTime? _lastRouteFetchTime;
  LatLng? _lastRouteFetchPos;
  static const int _refreshIntervalSeconds = 120; // 2 minutes
  static const double _deviationThresholdMeters = 500;

  final String _eta = "--";
  String get eta => _eta;

  bool get hasActiveRoute => _routePoints.isNotEmpty;

  void initTracking(DonationModel donation, bool isVolunteer) {
    // Seed initial position from donation model if present
    if (donation.ngoLat != null && donation.ngoLng != null && donation.ngoLat != 0 && donation.ngoLng != 0) {
      _volunteerPos = LatLng(donation.ngoLat!, donation.ngoLng!);
      _lastLocationUpdate = DateTime.now();
    }

    if (isVolunteer) {
      _trackingService.startTracking(donation.id);
    }

    _fetchRoute(donation);

    _trackingService.listenToLocation(donation.id, (data) {
      final newPos = LatLng(data['latitude'], data['longitude']);
      _updateVolunteerPosition(
        newPos,
        data['heading']?.toDouble() ?? 0,
      );

      // Intelligent Recalculation Check
      if (_shouldRecalculate(newPos)) {
        _fetchRoute(donation, referencePos: newPos);
      }
    });
  }

  bool _shouldRecalculate(LatLng currentPos) {
    if (_isLoadingRoute) return false;
    if (_lastRouteFetchTime == null || _lastRouteFetchPos == null) return true;

    // Check Time Threshold
    final elapsedSecs = DateTime.now().difference(_lastRouteFetchTime!).inSeconds;
    if (elapsedSecs >= _refreshIntervalSeconds) {
      debugPrint('[GPS] Route refresh triggered: Time interval reached ($elapsedSecs s)');
      return true;
    }

    // Check Distance Threshold (Deviation)
    final distanceMoved = Geolocator.distanceBetween(
      _lastRouteFetchPos!.latitude, _lastRouteFetchPos!.longitude,
      currentPos.latitude, currentPos.longitude,
    );

    if (distanceMoved >= _deviationThresholdMeters) {
      debugPrint('[GPS] Route refresh triggered: Significant movement (${distanceMoved.toStringAsFixed(0)} m)');
      return true;
    }

    return false;
  }

  Future<void> refreshRoute(DonationModel donation) async {
    await _fetchRoute(donation, force: true);
  }

  Future<void> _fetchRoute(DonationModel donation, {LatLng? referencePos, bool force = false}) async {
    if (_isLoadingRoute && !force) return;
    
    _isLoadingRoute = true;
    notifyListeners();

    try {
      final data = await _donationRepository.getDonationRoute(donation.id);
      if (data['success'] == true) {
        final List coords = data['coordinates'] ?? [];
        final List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();
        
        _routePoints = points;
        _routeDistanceKm = (data['distanceMeters'] ?? 0) / 1000;
        _routeDurationMins = ((data['durationSeconds'] ?? 0) / 60).round();
        _routingSource = data['source'] ?? "OSRM";

        // Update Reference State
        _lastRouteFetchTime = DateTime.now();
        _lastRouteFetchPos = referencePos ?? _volunteerPos;
      } else {
        _applyDirectEstimateFallback(donation);
      }
    } catch (e) {
      debugPrint('[LiveMapViewModel] Error fetching route: $e. Applying direct estimate fallback.');
      _applyDirectEstimateFallback(donation);
    } finally {
      _isLoadingRoute = false;
      notifyListeners();
    }
  }

  void _applyDirectEstimateFallback(DonationModel donation) {
    final startPos = _volunteerPos;
    final destPos = LatLng(donation.latitude, donation.longitude);

    if (startPos != null && donation.latitude != 0 && donation.longitude != 0) {
      final meters = Geolocator.distanceBetween(
        startPos.latitude, startPos.longitude,
        destPos.latitude, destPos.longitude,
      );
      _routePoints = [startPos, destPos];
      _routeDistanceKm = meters / 1000;
      final mins = (_routeDistanceKm / 30 * 60).round();
      _routeDurationMins = mins > 0 ? mins : 1;
      _routingSource = "DIRECT_ESTIMATE";
      _lastRouteFetchTime = DateTime.now();
      _lastRouteFetchPos = startPos;
    } else {
      _routingSource = "ERROR";
    }
  }

  void _updateVolunteerPosition(LatLng newPos, double heading) async {
    _volunteerPos = newPos;
    _volunteerHeading = heading;
    _lastLocationUpdate = DateTime.now();

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

  void setManualVolunteerPosition(LatLng pos, {double heading = 0}) {
    _volunteerPos = pos;
    _volunteerHeading = heading;
    _lastLocationUpdate = DateTime.now();
    notifyListeners();
  }

  void setRoute(List<LatLng> points, double distanceKm, int durationMins, {String source = "OSRM"}) {
    _routePoints = points;
    _routeDistanceKm = distanceKm;
    _routeDurationMins = durationMins;
    _routingSource = source;
    _lastRouteFetchTime = DateTime.now();
    notifyListeners();
  }

  void clearRoute() {
    _routePoints = [];
    _routeDistanceKm = 0;
    _routeDurationMins = 0;
    _routingSource = "NONE";
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingService.stopTracking();
    super.dispose();
  }
}
