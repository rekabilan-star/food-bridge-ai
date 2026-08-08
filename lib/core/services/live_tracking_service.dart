import 'dart:async';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'socket_service.dart';
import 'package:logger/logger.dart';

class LiveTrackingService {
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;
  LiveTrackingService._internal();

  final SocketService _socketService = SocketService();
  StreamSubscription<Position>? _positionSubscription;
  final Logger _logger = Logger();
  String? _currentDonationId;
  final List<Map<String, dynamic>> _offlineQueue = [];

  bool get isTracking => _positionSubscription != null;

  void startTracking(String donationId) async {
    _currentDonationId = donationId;
    
    if (!_socketService.isConnected) {
      await _socketService.connect();
    }
    
    _socketService.socket.emit('join_delivery', donationId);

    LocationSettings locationSettings;
    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Live tracking active for food delivery",
          notificationTitle: "Delivery in Progress",
          enableWifiLock: true,
        ),
      );
    } else if (Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _sendLocation(position);
    });
    
    _logger.i('LiveTracking: Started tracking for $donationId');
  }

  void _sendLocation(Position position) {
    if (_currentDonationId == null) return;

    final data = {
      'donationId': _currentDonationId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'speed': position.speed,
      'heading': position.heading,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (!_socketService.isConnected) {
      _offlineQueue.add(data);
      if (_offlineQueue.length > 100) _offlineQueue.removeAt(0);
      return;
    }

    _flushQueue();
    _socketService.socket.emit('update_location', data);
  }

  void _flushQueue() {
    if (_offlineQueue.isEmpty) return;
    if (!_socketService.isConnected) return;

    for (var data in _offlineQueue) {
      _socketService.socket.emit('update_location', data);
    }
    _offlineQueue.clear();
  }

  void listenToLocation(String donationId, Function(Map<String, dynamic>) onUpdate) {
    if (!_socketService.isConnected) {
      _socketService.connect().then((_) => _setupLocationListener(donationId, onUpdate));
    } else {
      _setupLocationListener(donationId, onUpdate);
    }
  }

  void _setupLocationListener(String donationId, Function(Map<String, dynamic>) onUpdate) {
    _socketService.socket.emit('join_delivery', donationId);
    _socketService.socket.off('location_update');
    _socketService.socket.on('location_update', (data) {
      onUpdate(data);
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentDonationId = null;
    _logger.i('LiveTracking: Stopped tracking');
  }
}
