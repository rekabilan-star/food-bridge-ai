import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';
import '../models/user_model.dart';
import '../models/donation_model.dart';

class AdminRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiService.dio.get('admin/dashboard');
      return response.data['data'];
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch dashboard stats";
    }
  }

  Future<List<UserModel>> getNgos({String? status}) async {
    try {
      final response = await _apiService.dio.get(
        'admin/ngos',
        queryParameters: status != null ? {'status': status} : null,
      );
      final List data = response.data['data'];
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch NGOs";
    }
  }

  Future<void> updateNgoStatus(String id, String status) async {
    try {
      await _apiService.dio.put(
        'admin/ngos/$id/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to update NGO status";
    }
  }

  Future<List<DonationModel>> getAllDonations() async {
    try {
      final response = await _apiService.dio.get('admin/donations');
      final List data = response.data['data'];
      return data.map((json) => DonationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch all donations";
    }
  }
}
