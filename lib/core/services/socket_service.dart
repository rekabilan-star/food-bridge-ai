import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final Logger _logger = Logger();
  bool _isConnected = false;

  io.Socket get socket {
    if (_socket == null) {
      throw Exception("Socket not initialized. Call connect() first.");
    }
    return _socket!;
  }

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected && _socket != null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token == null) {
      _logger.e('SocketService: Cannot connect, no token found');
      return;
    }
    
    // Get the root server URL for socket.io connection
    final String socketUrl = AppConstants.serverBaseUrl;
    
    _logger.i('SocketService: Connecting to $socketUrl');

    _socket = io.io(socketUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(10)
      .setReconnectionDelay(5000)
      .setAuth({'token': token})
      .build());

    _socket!.onConnect((_) {
      _isConnected = true;
      _logger.i('SocketService: Connected to WebSocket server');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _logger.w('SocketService: Disconnected from WebSocket server');
    });

    _socket!.onConnectError((data) {
      _isConnected = false;
      _logger.e('SocketService: Connect Error: $data');
    });

    _socket!.connect();
  }

  void joinDonationRoom(String donationId) {
    socket.emit('join_delivery', donationId);
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
    socket.off('location_update');
    socket.on('location_update', (data) {
      callback(data);
    });
  }

  void onDonationStatusUpdate(Function(Map<String, dynamic>) callback) {
    socket.off('donation_status_update');
    socket.on('donation_status_update', (data) {
      callback(data);
    });
  }

  void onStatusUpdated(Function(Map<String, dynamic>) callback) {
    socket.off('status_updated');
    socket.on('status_updated', (data) {
      callback(data);
    });
  }

  void onNewNotification(Function(Map<String, dynamic>) callback) {
    socket.off('new_notification');
    socket.on('new_notification', (data) {
      callback(data);
    });
  }

  void onNewDonation(Function(Map<String, dynamic>) callback) {
    socket.off('new_donation');
    socket.on('new_donation', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      }
    });
  }

  void onDonationClaimed(Function(Map<String, dynamic>) callback) {
    socket.off('donation_claimed');
    socket.on('donation_claimed', (data) {
      if (data is Map<String, dynamic>) {
        callback(data);
      } else if (data is Map) {
        callback(Map<String, dynamic>.from(data));
      }
    });
  }

  void onUnreadCountUpdate(Function(Map<String, dynamic>) callback) {
    socket.off('unread_count_update');
    socket.on('unread_count_update', (data) {
      callback(data);
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
