import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import 'dart:async';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  final List<Marker> _markers = [];
  
  // Custom marker positions (simulated)
  final LatLng _donorLatLng = const LatLng(13.0827, 80.2707); // Placeholder for Hotel Saravana
  final LatLng _ngoLatLng = const LatLng(13.0900, 80.2800); // Placeholder for Aurobindo

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final locModel = await LocationService().getProductionLocation();
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: locModel.latitude,
            longitude: locModel.longitude,
            timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0,
            altitudeAccuracy: 0, headingAccuracy: 0,
          );
          
          _updateMarkers();
        });
        
        _mapController.move(LatLng(locModel.latitude, locModel.longitude), 15);
      }
    } catch (e) {
      debugPrint("Error initializing location: $e");
    }
  }

  void _updateMarkers() {
    if (_currentPosition == null) return;
    
    setState(() {
      _markers.clear();
      
      // Current User Marker
      _markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.purple, size: 40),
        ),
      );

      // Donor Marker
      _markers.add(
        Marker(
          point: _donorLatLng,
          width: 80,
          height: 80,
          child: const Icon(Icons.restaurant, color: Colors.green, size: 40),
        ),
      );

      // NGO Marker
      _markers.add(
        Marker(
          point: _ngoLatLng,
          width: 80,
          height: 80,
          child: const Icon(Icons.business, color: Colors.orange, size: 40),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(13.0827, 80.2707),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mca_app',
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }
}
