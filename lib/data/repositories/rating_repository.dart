import 'package:dio/dio.dart';
import '../../core/utils/api_service.dart';

class RatingRepository {
  final ApiService _apiService = ApiService();

  Future<void> submitRating({
    required String donationId,
    required String toUserId,
    required int rating,
    required String review,
  }) async {
    try {
      await _apiService.dio.post(
        'ratings',
        data: {
          'donationId': donationId,
          'toUserId': toUserId,
          'rating': rating,
          'review': review,
        },
      );
    } on DioException catch (e) {
      throw e.error ?? "Failed to submit rating";
    }
  }
}
