import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';
import '../models/donation_model.dart';
import 'package:path/path.dart' as path;

class DonationRepository {
  final ApiService _apiService = ApiService();

  Future<String> uploadImage(File imageFile) async {
    try {
      String fileName = path.basename(imageFile.path);
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _apiService.dio.post(
        'donations/upload',
        data: formData,
      );
      
      return response.data['data'];
    } on DioException catch (e) {
      throw e.error ?? "Failed to upload image";
    }
  }

  Future<DonationModel> createDonation(DonationModel donation, [File? imageFile]) async {
    try {
      String imageUrl = donation.imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImage(imageFile);
      }

      final response = await _apiService.dio.post(
        'donations',
        data: {
          ...donation.toJson(),
          'imageUrl': imageUrl,
        },
      );
      return DonationModel.fromJson(response.data['donation']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to create donation";
    }
  }

  Future<List<DonationModel>> getDonorDonations({String? status, String? search}) async {
    try {
      final response = await _apiService.dio.get(
        'donations/donor',
        queryParameters: {
          'status': status,
          'search': search,
        },
      );
      final List data = response.data['donations'];
      return data.map((json) => DonationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch donations";
    }
  }

  Future<List<DonationModel>> getAvailableDonations({String? search}) async {
    try {
      final response = await _apiService.dio.get(
        'donations',
        queryParameters: {
          'search': search,
        },
      );
      final List data = response.data['donations'];
      return data.map((json) => DonationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch available donations";
    }
  }

  Future<List<DonationModel>> getNgoAssignedDonations() async {
    try {
      final response = await _apiService.dio.get('donations/ngo/assigned');
      final List data = response.data['donations'];
      return data.map((json) => DonationModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch assigned donations";
    }
  }

  Future<DonationModel> getDonationDetails(String id) async {
    try {
      final response = await _apiService.dio.get('donations/$id');
      return DonationModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch donation details";
    }
  }

  Future<DonationModel> updateStatus(String id, String status, {String? description}) async {
    try {
      final response = await _apiService.dio.put(
        'donations/$id/status',
        data: {'status': status, 'description': description},
      );
      return DonationModel.fromJson(response.data['donation']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to update status";
    }
  }

  Future<void> updateDonationCancellation(String id, String reason) async {
    try {
      await _apiService.dio.put(
        'donations/$id/cancel',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to cancel donation";
    }
  }

  Future<void> updateNgoLocation(double lat, double lng) async {
    try {
      await _apiService.dio.put(
        'donations/location',
        data: {'latitude': lat, 'longitude': lng},
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to update location";
    }
  }

  Future<DonationModel> verifyQrPickup(String id, String qrCode) async {
    try {
      final response = await _apiService.dio.post(
        'donations/$id/verify-pickup',
        data: {'qrCode': qrCode},
      );
      return DonationModel.fromJson(response.data['donation']);
    } on DioException catch (e) {
      throw e.error ?? "Invalid QR Code or verification failed";
    }
  }

  Future<List<Map<String, dynamic>>> getOptimizedRoute(double lat, double lng) async {
    try {
      final response = await _apiService.dio.get(
        'donations/volunteer/route',
        queryParameters: {'latitude': lat, 'longitude': lng},
      );
      return List<Map<String, dynamic>>.from(response.data['tasks']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch optimized route";
    }
  }

  Future<DonationModel> confirmDelivery(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post(
        'donations/$id/confirm-delivery',
        data: data,
      );
      return DonationModel.fromJson(response.data['donation']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to confirm delivery";
    }
  }
}
