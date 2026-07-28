import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/socket_service.dart';

class AdminLiveTrackingScreen extends StatefulWidget {
  const AdminLiveTrackingScreen({super.key});

  @override
  State<AdminLiveTrackingScreen> createState() => _AdminLiveTrackingScreenState();
}

class _AdminLiveTrackingScreenState extends State<AdminLiveTrackingScreen> {
  final SocketService _socketService = SocketService();
  final Map<String, Marker> _volunteerMarkers = {};
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _socketService.connect();
    _socketService.onLocationUpdated((data) {
      _updateVolunteerMarker(data);
    });
  }

  void _updateVolunteerMarker(Map<String, dynamic> data) {
    final String userId = data['userId'] ?? 'unknown';
    final LatLng position = LatLng(data['latitude'], data['longitude']);
    final double heading = data['heading']?.toDouble() ?? 0;

    setState(() {
      _volunteerMarkers[userId] = Marker(
        point: position,
        width: 40,
        height: 40,
        child: Transform.rotate(
          angle: heading * (3.14159 / 180),
          child: const Icon(Icons.directions_bike, color: Colors.blue, size: 40),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Fleet Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(13.0827, 80.2707), // Default (Chennai)
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mca_app',
          ),
          MarkerLayer(
            markers: _volunteerMarkers.values.toList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
