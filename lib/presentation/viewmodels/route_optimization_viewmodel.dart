import 'package:flutter/material.dart';
import '../../data/repositories/donation_repository.dart';
import '../../services/location_service.dart';

class RouteOptimizationViewModel extends ChangeNotifier {
  final DonationRepository _donationRepository = DonationRepository();
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
  
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> get tasks => _tasks;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOptimizedRoute() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final loc = await LocationService().getProductionLocation();
      _tasks = await _donationRepository.getOptimizedRoute(loc.latitude, loc.longitude);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }
}
