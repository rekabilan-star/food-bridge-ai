import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';

class EmergencyRequestModel {
  final String id;
  final String ngoId;
  final String? ngoName;
  final String title;
  final String reason;
  final int requiredMembers;
  final String foodType;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime requiredBefore;
  final String priority;
  final String status;

  EmergencyRequestModel({
    required this.id,
    required this.ngoId,
    this.ngoName,
    required this.title,
    required this.reason,
    required this.requiredMembers,
    required this.foodType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.requiredBefore,
    required this.priority,
    required this.status,
  });

  factory EmergencyRequestModel.fromJson(Map<String, dynamic> json) {
    final ngoData = json['ngoId'] is Map ? json['ngoId'] : null;
    return EmergencyRequestModel(
      id: json['_id'] ?? json['id'],
      ngoId: ngoData != null ? ngoData['_id'] : json['ngoId'],
      ngoName: ngoData != null ? ngoData['name'] : null,
      title: json['title'],
      reason: json['reason'],
      requiredMembers: json['requiredMembers'],
      foodType: json['foodType'],
      address: json['address'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      requiredBefore: DateTime.parse(json['requiredBefore']),
      priority: json['priority'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'reason': reason,
      'requiredMembers': requiredMembers,
      'foodType': foodType,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'requiredBefore': requiredBefore.toIso8601String(),
      'priority': priority,
    };
  }
}

class EmergencyRepository {
  final ApiService _apiService = ApiService();

  Future<EmergencyRequestModel> createRequest(EmergencyRequestModel request) async {
    try {
      final response = await _apiService.dio.post(
        'emergency',
        data: request.toJson(),
      );
      return EmergencyRequestModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.error ?? "Failed to create emergency request";
    }
  }

  Future<List<EmergencyRequestModel>> getActiveRequests() async {
    try {
      final response = await _apiService.dio.get('emergency');
      final List data = response.data['data'];
      return data.map((json) => EmergencyRequestModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw e.error ?? "Failed to fetch emergency requests";
    }
  }

  Future<void> updateRequestStatus(String id, String status) async {
    try {
      await _apiService.dio.put(
        'emergency/$id',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to update request";
    }
  }
}
