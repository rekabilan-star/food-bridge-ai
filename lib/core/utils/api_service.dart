import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'package:logger/logger.dart';

class ApiService {
  late Dio dio;
  final Logger _logger = Logger();
  
  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30), // Increased to 30s
      receiveTimeout: const Duration(seconds: 30), // Increased to 30s
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        _logger.d('--- API REQUEST [${DateTime.now().toIso8601String()}] ---');
        _logger.d('URL: ${options.baseUrl}${options.path}');
        _logger.d('Method: ${options.method}');
        _logger.d('Headers: ${options.headers}');
        _logger.d('Body: ${options.data}');
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('--- API RESPONSE [${DateTime.now().toIso8601String()}] ---');
        _logger.d('Status Code: ${response.statusCode}');
        _logger.d('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _logger.e('--- API ERROR [${DateTime.now().toIso8601String()}] ---');
        _logger.e('URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        _logger.e('Type: ${e.type}');
        _logger.e('Message: ${e.message}');
        _logger.e('Error Object: ${e.error}');
        _logger.e('Response Data: ${e.response?.data}');
        
        String message = "Network Error";
        
        if (e.type == DioExceptionType.connectionTimeout || 
            e.type == DioExceptionType.sendTimeout || 
            e.type == DioExceptionType.receiveTimeout) {
          message = "Connection Timed Out. Backend at ${AppConstants.baseUrl} is not responding.";
        } else if (e.type == DioExceptionType.connectionError) {
          message = "Connection Refused. Check if server is running on port 5000 and accessible from this device.";
        } else if (e.response != null) {
          final data = e.response?.data;
          message = (data is Map && data['message'] != null) 
              ? data['message'] 
              : "Server Error: ${e.response?.statusCode}";
        } else {
          message = e.message ?? "Unexpected Network Error";
        }
        
        return handler.next(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: message,
        ));
      }
    ));
  }
}
