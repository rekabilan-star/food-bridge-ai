import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';

class LiveTrackingService {
  static final LiveTrackingService _instance = LiveTrackingService._internal();
  factory LiveTrackingService() => _instance;
  LiveTrackingService._internal();

  io.Socket? _socket;
  StreamSubscription<Position>? _positionSubscription;
  final Logger _logger = Logger();
  String? _currentDonationId;
  final List<Map<String, dynamic>> _offlineQueue = [];

  bool get isTracking => _positionSubscription != null;

  Future<void> initSocket() async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final String socketUrl = AppConstants.baseUrl.replaceAll('/api/', '');

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      _logger.i('LiveTracking: Connected');
      _flushQueue();
    });
    _socket!.onDisconnect((_) => _logger.w('LiveTracking: Disconnected'));
    _socket!.onConnectError((err) => _logger.e('LiveTracking: Connect Error: $err'));
  }

  void startTracking(String donationId) async {
    _currentDonationId = donationId;
    await initSocket();
    
    _socket!.emit('join_delivery', donationId);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Live tracking active for food delivery",
          notificationTitle: "Delivery in Progress",
          enableWifiLock: true,
        ),
      ),
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

    if (_socket == null || !_socket!.connected) {
      _offlineQueue.add(data);
      if (_offlineQueue.length > 100) _offlineQueue.removeAt(0);
      return;
    }

    _socket!.emit('update_location', data);
  }

  void _flushQueue() {
    if (_offlineQueue.isEmpty) return;
    for (var data in _offlineQueue) {
      _socket!.emit('update_location', data);
    }
    _offlineQueue.clear();
  }

  void listenToLocation(String donationId, Function(Map<String, dynamic>) onUpdate) {
    initSocket().then((_) {
      _socket!.emit('join_delivery', donationId);
      _socket!.on('location_update', (data) {
        onUpdate(data);
      });
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentDonationId = null;
    _socket?.disconnect();
    _logger.i('LiveTracking: Stopped tracking');
  }
}
