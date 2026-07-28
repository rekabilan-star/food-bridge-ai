import 'package:flutter/material.dart';
import '../../data/repositories/emergency_repository.dart';

class EmergencyViewModel extends ChangeNotifier {
  final EmergencyRepository _repository = EmergencyRepository();

  List<EmergencyRequestModel> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EmergencyRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchActiveRequests() async {
    _setLoading(true);
    try {
      _requests = await _repository.getActiveRequests();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createRequest(EmergencyRequestModel request) async {
    _setLoading(true);
    try {
      await _repository.createRequest(request);
      await fetchActiveRequests();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> fulfillRequest(String id) async {
    _setLoading(true);
    try {
      await _repository.updateRequestStatus(id, 'fulfilled');
      await fetchActiveRequests();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
