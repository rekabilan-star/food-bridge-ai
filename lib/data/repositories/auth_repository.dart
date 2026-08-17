import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/services/security_service.dart';
import '../../core/utils/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final _secureStorage = const FlutterSecureStorage();

  Future<UserModel> login(String email, String password) async {
    try {
      final deviceInfo = await SecurityService.getDeviceInfo();
      
      final response = await _apiService.dio.post(
        AppConstants.loginUrl,
        data: {
          'email': email, 
          'password': password,
          ...deviceInfo
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = UserModel.fromJson(data['user']);
        
        // Save sensitive data in Secure Storage
        await _secureStorage.write(key: AppConstants.tokenKey, value: data['token']);
        await _secureStorage.write(key: 'refresh_token', value: data['refreshToken']);
        
        // Save non-sensitive data & fallback token in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString(AppConstants.tokenKey, data['token']);
        }
        await prefs.setString(AppConstants.roleKey, user.role.toString().split('.').last);
        await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
        
        return user;
      } else {
        throw Exception("Login Failed");
      }
    } on DioException catch (e) {
      throw e.error ?? "Connection Error";
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.dio.post('auth/forgot-password', data: {'email': email.trim()});
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['message'] != null) {
        throw e.response?.data['message'];
      }
      throw e.error ?? "Failed to request OTP";
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _apiService.dio.post('auth/reset-password', data: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword
      });
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null && e.response?.data['message'] != null) {
        throw e.response?.data['message'];
      }
      throw e.error ?? "Failed to reset password";
    }
  }

  Future<void> verifyEmail(String otp) async {
    try {
      await _apiService.dio.post('auth/verify-email', data: {'otp': otp});
    } on DioException catch (e) {
      throw e.error ?? "Email verification failed";
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  Future<void> refreshToken() async {
    try {
      final rToken = await _secureStorage.read(key: 'refresh_token');
      if (rToken == null) return;

      final response = await Dio().post(
        '${AppConstants.baseUrl}auth/refresh-token', 
        data: {'refreshToken': rToken}
      );
      
      if (response.statusCode == 200) {
        await _secureStorage.write(key: AppConstants.tokenKey, value: response.data['token']);
        await _secureStorage.write(key: 'refresh_token', value: response.data['refreshToken']);
      }
    } catch (e) {
      await logout();
    }
  }

  Future<UserModel> registerDonor(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.registerDonorUrl,
        data: data,
      );
      final resData = response.data;
      final user = UserModel.fromJson(resData['user']);
      if (resData['token'] != null) {
        await _secureStorage.write(key: AppConstants.tokenKey, value: resData['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, resData['token']);
      }
      if (resData['refreshToken'] != null) {
        await _secureStorage.write(key: 'refresh_token', value: resData['refreshToken']);
      }
      return user;
    } on DioException catch (e) {
      throw e.error ?? "Registration Error";
    }
  }

  Future<UserModel> registerNgo(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.registerNgoUrl,
        data: data,
      );
      final resData = response.data;
      final user = UserModel.fromJson(resData['user']);
      if (resData['token'] != null) {
        await _secureStorage.write(key: AppConstants.tokenKey, value: resData['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, resData['token']);
      }
      if (resData['refreshToken'] != null) {
        await _secureStorage.write(key: 'refresh_token', value: resData['refreshToken']);
      }
      return user;
    } on DioException catch (e) {
      throw e.error ?? "Registration Error";
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _apiService.dio.get('user/profile');
      final user = UserModel.fromJson(response.data['data']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
      
      return user;
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch profile";
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put(
        'user/profile',
        data: data,
      );
      final user = UserModel.fromJson(response.data['data']);
      
      // Update local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userDataKey, json.encode(user.toJson()));
      
      return user;
    } on DioException catch (e) {
      throw e.error ?? "Update Profile Error";
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final biometricPref = prefs.getBool('biometric_enabled') ?? false;
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final email = prefs.getString('saved_email');
    
    await prefs.clear();
    await _secureStorage.deleteAll();
    
    // Restore persistent settings
    await prefs.setBool('biometric_enabled', biometricPref);
    await prefs.setBool('remember_me', rememberMe);
    if (rememberMe && email != null) {
      await prefs.setString('saved_email', email);
    }
  }
}
