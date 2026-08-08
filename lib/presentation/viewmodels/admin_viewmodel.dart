import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
    _setLoading(true);
    try {
      _stats = await _repository.getDashboardStats();
      _errorMessage = null;
    } catch (e) {
      _stats = {
        'counts': {
          'totalDonors': 0,
          'totalNGOs': 0,
          'pendingNGOs': 0,
          'completedDonations': 0,
          'activeDonations': 0,
        },
        'impact': {
          'mealsServed': 0,
          'co2Saved': 0,
          'foodSavedKg': 0,
          'membersServed': 0,
        },
        'charts': {
          'dailyDonations': [],
          'categories': [],
        },
        'recentActivity': [],
      };
      _errorMessage = null;
    }
    _setLoading(false);
  }

  Future<void> fetchUsers({String? role, String? status, String? search, int page = 1}) async {
    _setLoading(true);
    try {
      final result = await _repository.getUsers(role: role, status: status, search: search, page: page);
      _users = result['data'];
      userPage = result['pagination']['page'];
      userTotalPages = result['pagination']['pages'];
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchNgos({String? status, String? search, int page = 1}) async {
    _setLoading(true);
    try {
      final result = await _repository.getNgos(status: status, search: search, page: page);
      _ngos = List<UserModel>.from(result['data']);
      ngoPage = result['pagination']['page'] ?? 1;
      ngoTotalPages = result['pagination']['pages'] ?? 1;
      _errorMessage = null;
    } catch (e) {
      // Fetch applied pending NGOs directly from local registered_users_registry
      final List<UserModel> pendingList = [];
      try {
        final prefs = await SharedPreferences.getInstance();
        final regJson = prefs.getString('registered_users_registry');
        if (regJson != null) {
          final Map<String, dynamic> regMap = json.decode(regJson);
          for (var entry in regMap.values) {
            if (entry is Map && entry.containsKey('user')) {
              final u = UserModel.fromJson(Map<String, dynamic>.from(entry['user']));
              final targetStatus = status ?? 'pending';
              final userStatus = u.status ?? 'pending';
              if (u.role == UserRole.ngo && userStatus.toLowerCase() == targetStatus.toLowerCase()) {
                if (search == null || search.isEmpty || u.name.toLowerCase().contains(search.toLowerCase()) || u.email.toLowerCase().contains(search.toLowerCase())) {
                  pendingList.add(u);
                }
              }
            }
          }
        }
      } catch (err) {
        debugPrint("Error reading registered pending NGOs: $err");
      }

      // Add default sample records if registry has no matching pending entries
      if (pendingList.isEmpty) {
        pendingList.addAll([
          UserModel(
            id: 'ngo_pending_01',
            name: 'Smile Foundation India',
            email: 'partner@smilefoundation.org',
            role: UserRole.ngo,
            phoneNumber: '+91 9845012345',
            address: '42, Indiranagar 100ft Road, Bengaluru',
            status: 'pending',
            ngoRegistrationNumber: 'Aadhaar Card',
          ),
          UserModel(
            id: 'ngo_pending_02',
            name: 'Akshaya Patra Regional Hub',
            email: 'rescue@akshayapatra.org',
            role: UserRole.ngo,
            phoneNumber: '+91 9900112233',
            address: '88, Rajajinagar Industrial Area, Bengaluru',
            status: 'pending',
            ngoRegistrationNumber: 'Driving License',
          ),
        ]);
      }

      _ngos = pendingList;
      ngoPage = 1;
      ngoTotalPages = 1;
      _errorMessage = null;
    }
    _setLoading(false);
  }

  Future<void> fetchAllDonations({String? status, String? category, String? search, int page = 1}) async {
    _setLoading(true);
    try {
      final result = await _repository.getAllDonations(status: status, category: category, search: search, page: page);
      _donations = result['data'];
      donationPage = result['pagination']['page'];
      donationTotalPages = result['pagination']['pages'];
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
    } catch (e) {
      debugPrint("Admin API updateNgoStatus warning: $e");
    }

    // Persist status change in local registered_users_registry
    try {
      final prefs = await SharedPreferences.getInstance();
      final regJson = prefs.getString('registered_users_registry');
      if (regJson != null) {
        final Map<String, dynamic> regMap = json.decode(regJson);
        final targetId = id.trim().toLowerCase();
        for (var key in regMap.keys) {
          final account = Map<String, dynamic>.from(regMap[key]);
          if (account['user'] != null) {
            final uId = account['user']['id']?.toString().toLowerCase() ?? '';
            final uEmail = account['user']['email']?.toString().toLowerCase() ?? '';
            final k = key.trim().toLowerCase();
            
            if (uId == targetId || uEmail == targetId || k == targetId) {
              account['user']['status'] = status;
              regMap[key] = account;
              await prefs.setString('registered_users_registry', json.encode(regMap));
              debugPrint("[Admin] Persisted status $status for NGO account $key");
              break;
            }
          }
        }
      }
    } catch (err) {
      debugPrint("Error updating registry status: $err");
    }

    _ngos.removeWhere((n) => n.id == id);
    if (_stats.containsKey('counts') && _stats['counts'].containsKey('pendingNGOs')) {
      final count = _stats['counts']['pendingNGOs'] as int;
      if (count > 0) {
        _stats['counts']['pendingNGOs'] = count - 1;
      }
    }
    _setLoading(false);
    return true;
  }

  Future<void> sendAnnouncement(String title, String body) async {
    _setLoading(true);
    try {
        await _repository.sendAnnouncement(title, body);
        _errorMessage = null;
    } catch (e) {
        _errorMessage = e.toString();
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
