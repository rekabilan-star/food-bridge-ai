import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/donation_model.dart';
import '../../data/repositories/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();

  Map<String, dynamic> _stats = {};
  List<UserModel> _ngos = [];
  List<DonationModel> _donations = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get stats => _stats;
  List<UserModel> get ngos => _ngos;
  List<DonationModel> get donations => _donations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    try {
      _stats = await _repository.getDashboardStats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchNgos({String? status}) async {
    _setLoading(true);
    try {
      _ngos = await _repository.getNgos(status: status);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAllDonations() async {
    _setLoading(true);
    try {
      _donations = await _repository.getAllDonations();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> updateNgoStatus(String id, String status) async {
    _setLoading(true);
    try {
      await _repository.updateNgoStatus(id, status);
      await fetchNgos(status: 'pending'); // Refresh pending list
      await fetchDashboardStats(); // Refresh stats
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }
}
