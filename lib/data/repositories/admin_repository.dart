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

  Future<Map<String, dynamic>> getUsers({String? role, String? status, String? search, int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.dio.get(
        'admin/users',
        queryParameters: {
          'role': role,
          'status': status,
          'search': search,
          'page': page,
          'limit': limit,
        }..removeWhere((key, value) => value == null),
      );
      final List data = response.data['data'];
      return {
          'pagination': response.data['pagination'],
          'data': data.map((json) => UserModel.fromJson(json)).toList()
      };
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch users";
    }
  }

  Future<Map<String, dynamic>> getNgos({String? status, String? search, int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.dio.get(
        'admin/ngos',
        queryParameters: {
          'status': status,
          'search': search,
          'page': page,
          'limit': limit,
        }..removeWhere((key, value) => value == null),
      );
      final List data = response.data['data'];
      return {
          'pagination': response.data['pagination'],
          'data': data.map((json) => UserModel.fromJson(json)).toList()
      };
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

  Future<Map<String, dynamic>> getAllDonations({String? status, String? category, String? search, int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.dio.get(
        'admin/donations',
        queryParameters: {
          'status': status,
          'category': category,
          'search': search,
          'page': page,
          'limit': limit,
        }..removeWhere((key, value) => value == null),
      );
      final List data = response.data['data'];
      return {
          'pagination': response.data['pagination'],
          'data': data.map((json) => DonationModel.fromJson(json)).toList()
      };
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch all donations";
    }
  }

  Future<void> sendAnnouncement(String title, String body) async {
    try {
      await _apiService.dio.post(
        'admin/announcement',
        data: {'title': title, 'body': body},
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to send announcement";
    }
  }

  Future<List<DonationModel>> getReportDonations({String? start, String? end}) async {
    try {
      final response = await _apiService.dio.get(
        'admin/reports/donations',
        queryParameters: {
          'startDate': start,
          'endDate': end,
        }..removeWhere((key, value) => value == null),
      );
      final List data = response.data['data'];
      return data.map((json) => DonationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch report data";
    }
  }
}
