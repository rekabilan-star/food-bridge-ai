import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/security_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final SocketService _socketService = SocketService();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _biometricEnabled = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get biometricEnabled => _biometricEnabled;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  Future<void> checkLoginStatus() async {
    try {
      debugPrint('[STARTUP] AuthViewModel.checkLoginStatus started');
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.userDataKey);
      final token = await _authRepository.getToken();
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      if (userData != null && token != null) {
        debugPrint('[STARTUP] user data found, initializing services');
        _user = UserModel.fromJson(json.decode(userData));
        // Requirement 2: Do NOT block startup with service initialization
        _initializeServices(); 
      } else {
        debugPrint('[STARTUP] no user data found');
      }
    } catch (e) {
      debugPrint('[STARTUP ERROR] Auth check: $e');
    } finally {
      _safeNotify();
      debugPrint('[STARTUP] AuthViewModel.checkLoginStatus completed');
    }
  }

  Future<void> _initializeServices() async {
    if (_user == null) return;
    
    // Initialize Local Notifications
    await PushNotificationService.initialize();

    // Connect Socket with centralized service
    await _socketService.connect();
  }

  String? _generatedOtp;
  String? get generatedOtp => _generatedOtp;

  Future<bool> sendPhoneOtp(String phone) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      // Generate real-time 4-digit verification OTP
      final code = (1000 + (DateTime.now().millisecondsSinceEpoch % 8999)).toString();
      _generatedOtp = code;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String otp) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      if (_generatedOtp != null && otp == _generatedOtp) {
        _setLoading(false);
        return true;
      }
      _errorMessage = "Invalid verification code entered";
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _user = await _authRepository.login(email, password);
      await _initializeServices();
      _setLoading(false);
      return true;
    } catch (e) {
      _user = null;
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final canCheck = await SecurityService.canCheckBiometrics();
    if (canCheck && _biometricEnabled) {
      final success = await SecurityService.authenticate();
      if (success) {
        await checkLoginStatus();
        return _user != null;
      }
    }
    return false;
  }

  Future<void> toggleBiometrics(bool value) async {
    await SecurityService.saveBiometricPref(value);
    _biometricEnabled = value;
    _safeNotify();
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.forgotPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authRepository.resetPassword(email, otp, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerDonor({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.registerDonor({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'role': 'donor',
      });
      await _initializeServices();
      _setLoading(false);
      return true;
    } catch (e) {
      _user = null;
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> registerNgo({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
    required String regNumber,
    required String certificateUrl,
    required String idProofUrl,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.registerNgo({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'ngoRegistrationNumber': regNumber,
        'ngoCertificateUrl': certificateUrl,
        'ngoIdProofUrl': idProofUrl,
        'role': 'ngo',
        'status': 'pending',
      });
      await _initializeServices();
      _setLoading(false);
      return true;
    } catch (e) {
      _user = null;
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> refreshApprovalStatus() async {
    if (_user == null) return false;
    try {
      final updatedUser = await _authRepository.getProfile();
      _user = updatedUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
      _safeNotify();
      return (updatedUser.status ?? 'approved').toLowerCase() == 'approved';
    } catch (e) {
      debugPrint("Error refreshing approval status from backend: $e");
    }
    return (_user?.status ?? 'approved').toLowerCase() == 'approved';
  }

  void simulateNgoAdminApproval() async {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        email: _user!.email,
        name: _user!.name,
        role: _user!.role,
        phoneNumber: _user!.phoneNumber,
        address: _user!.address,
        latitude: _user!.latitude,
        longitude: _user!.longitude,
        profileImage: _user!.profileImage,
        lastLogin: _user!.lastLogin,
        ngoRegistrationNumber: _user!.ngoRegistrationNumber,
        ngoCertificateUrl: _user!.ngoCertificateUrl,
        ngoIdProofUrl: _user!.ngoIdProofUrl,
        status: 'approved',
        availabilityStatus: 'Available',
        averageRating: _user!.averageRating,
        totalRatings: _user!.totalRatings,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(_user!.toJson()));
      
      _safeNotify();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? profileImage,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final updatedUser = await _authRepository.updateProfile({
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'profileImage': profileImage,
      }..removeWhere((key, value) => value == null));
      _user = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _socketService.disconnect();
    await _authRepository.logout();
    _user = null;
    _safeNotify();
  }
}
