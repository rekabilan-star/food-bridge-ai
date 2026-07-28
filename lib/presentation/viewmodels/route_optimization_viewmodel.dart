import 'package:flutter/material.dart';
import '../../data/repositories/donation_repository.dart';
import 'package:geolocator/geolocator.dart';

class RouteOptimizationViewModel extends ChangeNotifier {
  final DonationRepository _donationRepository = DonationRepository();
  
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> get tasks => _tasks;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOptimizedRoute() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Position position = await Geolocator.getCurrentPosition();
      _tasks = await _donationRepository.getOptimizedRoute(position.latitude, position.longitude);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
