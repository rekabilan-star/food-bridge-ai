import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';
import '../../services/location_service.dart';

class ManualLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const ManualLocationPicker({super.key, this.initialLat, this.initialLng});

  @override
  State<ManualLocationPicker> createState() => _ManualLocationPickerState();
}

class _ManualLocationPickerState extends State<ManualLocationPicker> {
  late LatLng _selectedPos;
  bool _isMoving = false;
  bool _isSearching = false;
  String _address = "Move map to select location";
  final MapController _mapController = MapController();
  final LocationService _locService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPos = LatLng(widget.initialLat ?? 12.9121, widget.initialLng ?? 77.6446);
    _updateAddress(_selectedPos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(LatLng pos) async {
    final addr = await _locService.getAddressFromCoords(pos.latitude, pos.longitude);
    if (mounted) {
      setState(() {
        _address = addr;
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final locations = await locationFromAddress(query.trim());
      if (locations.isNotEmpty && mounted) {
        final newPos = LatLng(locations.first.latitude, locations.first.longitude);
        _mapController.move(newPos, 16.0);
        setState(() {
          _selectedPos = newPos;
          _isSearching = false;
        });
        _updateAddress(newPos);
      } else if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found. Try entering a city or street name.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not find location. Please try another search term.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Real Location"),
        backgroundColor: const Color(0xFF0F0C29),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPos,
              initialZoom: 16,
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
                userAgentPackageName: 'com.foodbridge.ai',
              ),
            ],
          ),
          const Center(
            child: Icon(Icons.location_on, size: 45, color: Colors.redAccent),
          ),

          // Top Location Search Bar Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF4834D4)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: _searchLocation,
                        decoration: const InputDecoration(
                          hintText: "Search city, area, or address...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4834D4)),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF4834D4)),
                        onPressed: () => _searchLocation(_searchController.text),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Address & Confirmation Card
          Positioned(
            bottom: 24, left: 20, right: 20,
            child: Card(
              color: const Color(0xFF161625),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), 
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isMoving ? "Detecting location..." : _address, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4834D4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isMoving ? null : () {
                          final model = LocationModel(
                            latitude: _selectedPos.latitude,
                            longitude: _selectedPos.longitude,
                            accuracy: 0.0,
                            fullAddress: _address,
                            timestamp: DateTime.now(),
                          );
                          Navigator.pop(context, model);
                        },
                        child: const Text("CONFIRM THIS LOCATION", style: TextStyle(fontWeight: FontWeight.w900)),
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
