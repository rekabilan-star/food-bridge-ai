import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';

class ManualLocationPicker extends StatefulWidget {
  const ManualLocationPicker({super.key});

  @override
  State<ManualLocationPicker> createState() => _ManualLocationPickerState();
}

class _ManualLocationPickerState extends State<ManualLocationPicker> {
  LatLng _selectedPos = const LatLng(13.0827, 80.2707); // Default Chennai
  bool _isMoving = false;
  String _address = "Move map to select location";
  final MapController _mapController = MapController();

  Future<void> _updateAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        setState(() {
          _address = "${p.street}, ${p.locality}, ${p.postalCode}";
        });
      }
    } catch (_) {
      setState(() {
        _address = "Coordinates: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPos,
              initialZoom: 15,
              onPositionChanged: (camera, hasGesture) {
                setState(() {
                  _isMoving = true;
                  _selectedPos = camera.center;
                });
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  setState(() => _isMoving = false);
                  _updateAddress(_selectedPos);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mca_app',
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_on, size: 45, color: Colors.red),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isMoving ? "Detecting..." : _address, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isMoving ? null : () {
                          final model = LocationModel(
                            latitude: _selectedPos.latitude,
                            longitude: _selectedPos.longitude,
                            fullAddress: _address,
                            timestamp: DateTime.now(),
                          );
                          Navigator.pop(context, model);
                        },
                        child: const Text("CONFIRM THIS LOCATION", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
