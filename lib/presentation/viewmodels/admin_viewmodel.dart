import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/models/donation_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../core/services/socket_service.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository = AdminRepository();
  final SocketService _socketService = SocketService();
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _socketService.socket.off('new_donation');
    _socketService.socket.off('donation_status_update');
    super.dispose();
  }

  Map<String, dynamic> _stats = {};
  List<UserModel> _users = [];
  List<UserModel> _ngos = [];
  List<DonationModel> _donations = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  // Pagination states (accessible via getters if needed)
  int userPage = 1;
  int userTotalPages = 1;
  int ngoPage = 1;
  int ngoTotalPages = 1;
  int donationPage = 1;
  int donationTotalPages = 1;

  Map<String, dynamic> get stats => _stats;
  List<UserModel> get users => _users;
  List<UserModel> get ngos => _ngos;
  List<DonationModel> get donations => _donations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void initSocketListeners() {
    if (!_socketService.isConnected) return;
    
    _socketService.socket.off('new_donation');
    _socketService.socket.on('new_donation', (_) {
      fetchDashboardStats();
    });
    
    _socketService.socket.off('donation_status_update');
    _socketService.socket.on('donation_status_update', (_) {
      fetchDashboardStats();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  Future<void> fetchDashboardStats() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _stats = await _repository.getDashboardStats();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchUsers({String? role, String? status, String? search, int page = 1}) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      final result = await _repository.getUsers(role: role, status: status, search: search, page: page);
      _users = result['data'];
      userPage = result['pagination']['page'];
      userTotalPages = result['pagination']['pages'];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _users = [];
    }
    _setLoading(false);
  }

  Future<void> fetchNgos({String? status, String? search, int page = 1}) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      final result = await _repository.getNgos(status: status, search: search, page: page);
      _ngos = List<UserModel>.from(result['data']);
      ngoPage = result['pagination']['page'] ?? 1;
      ngoTotalPages = result['pagination']['pages'] ?? 1;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _ngos = [];
    }
    _setLoading(false);
  }

  Future<void> fetchAllDonations({String? status, String? category, String? search, int page = 1}) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      final result = await _repository.getAllDonations(status: status, category: category, search: search, page: page);
      _donations = result['data'];
      donationPage = result['pagination']['page'];
      donationTotalPages = result['pagination']['pages'];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _donations = [];
    }
    _setLoading(false);
  }

  Future<bool> updateNgoStatus(String id, String status) async {
    _setLoading(true);
    try {
      await _repository.updateNgoStatus(id, status);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }

    _ngos.removeWhere((n) => n.id == id);
    _users.removeWhere((u) => u.id == id);
    if (_stats.containsKey('counts') && _stats['counts'].containsKey('pendingNGOs')) {
      final count = _stats['counts']['pendingNGOs'] as int;
      if (count > 0 && status == 'approved') {
        _stats['counts']['pendingNGOs'] = count - 1;
      }
    }
    _setLoading(false);
    return true;
  }

  Future<void> sendAnnouncement(String title, String body, {String targetRole = 'all'}) async {
    _setLoading(true);
    try {
        await _repository.sendAnnouncement(title, body, targetRole: targetRole);
        _errorMessage = null;
    } catch (e) {
        _errorMessage = e.toString();
        rethrow;
    }
    _setLoading(false);
  }

  Future<List<DonationModel>> fetchReportData({String? start, String? end}) async {
    try {
        return await _repository.getReportDonations(start: start, end: end);
    } catch (e) {
        _errorMessage = e.toString();
        return [];
    }
  }
}
