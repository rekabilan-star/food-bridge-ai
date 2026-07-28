import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/constants/app_constants.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userDataKey);
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (userData != null && token != null) {
      _user = UserModel.fromJson(json.decode(userData));
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _user = await _authRepository.login(email, password);
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
      await _authRepository.registerDonor({
        'name': name,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'role': 'donor',
      });
      _setLoading(false);
      return true;
    } catch (e) {
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
      await _authRepository.registerNgo({
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
      });
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }
}
