import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late Dio dio;
  final _secureStorage = const FlutterSecureStorage();
  
  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('auth/login')) {
          // Token expired, attempt refresh
          final refreshToken = await _secureStorage.read(key: 'refresh_token');
          
          if (refreshToken != null) {
            try {
              final response = await Dio().post(
                '${AppConstants.baseUrl}auth/refresh-token',
                data: {'refreshToken': refreshToken}
              );
              
              if (response.statusCode == 200) {
                final newToken = response.data['token'];
                final newRefreshToken = response.data['refreshToken'];
                
                await _secureStorage.write(key: AppConstants.tokenKey, value: newToken);
                await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
                
                // Retry the original request
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                
                final retryRes = await dio.fetch(opts);
                return handler.resolve(retryRes);
              }
            } catch (refreshErr) {
              // Refresh failed, logout user
              await _secureStorage.deleteAll();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.userDataKey);
            }
          }
        }
        
        String message = "Network Error";
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          message = e.response?.data['message'];
        } else {
          message = e.message ?? "Connection Error";
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
