import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';

class SocketService {
  late io.Socket socket;
  final Logger _logger = Logger();

  void connect() {
    // Remove /api/ from baseUrl to get the server root for socket.io
    final String socketUrl = AppConstants.baseUrl.replaceAll('/api/', '');
    
    socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    socket.connect();

    socket.onConnect((_) {
      _logger.i('Connected to WebSocket server');
    });

    socket.onDisconnect((_) {
      _logger.w('Disconnected from WebSocket server');
    });

    socket.onConnectError((data) {
      _logger.e('Connect Error: $data');
    });
  }

  void joinDonationRoom(String donationId) {
    socket.emit('join_room', donationId);
    _logger.i('Joined room: $donationId');
  }

  void updateLocation({
    required String userId,
    required String donationId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) {
    socket.emit('update_location', {
      'userId': userId,
      'donationId': donationId,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
    });
  }

  void onLocationUpdated(Function(Map<String, dynamic>) callback) {
    socket.on('location_updated', (data) {
      callback(data);
    });
  }

  void onStatusUpdated(Function(Map<String, dynamic>) callback) {
    socket.on('status_updated', (data) {
      callback(data);
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
