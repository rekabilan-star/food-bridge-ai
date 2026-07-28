import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.loginUrl,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final user = UserModel.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token']);
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

  Future<UserModel> registerDonor(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        AppConstants.registerDonorUrl,
        data: data,
      );
      return UserModel.fromJson(response.data['user']);
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
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw e.error ?? "Registration Error";
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
