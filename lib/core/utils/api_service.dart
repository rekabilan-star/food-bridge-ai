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
        String? token = await _secureStorage.read(key: AppConstants.tokenKey);
        if (token == null || token.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString(AppConstants.tokenKey);
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) => handler.next(response),
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path;
        final isAuthEndpoint = path.contains('auth/login') ||
            path.contains('auth/register') ||
            path.contains('auth/refresh-token') ||
            path.contains('auth/forgot-password') ||
            path.contains('auth/reset-password');

        if (e.response?.statusCode == 401 && !isAuthEndpoint) {
          final refreshToken = await _secureStorage.read(key: 'refresh_token');

          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refreshDio = Dio(BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ));

              final response = await refreshDio.post(
                'auth/refresh-token',
                data: {'refreshToken': refreshToken},
              );

              if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
                final newToken = response.data['token'];
                final newRefreshToken = response.data['refreshToken'];

                if (newToken != null) {
                  await _secureStorage.write(key: AppConstants.tokenKey, value: newToken);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(AppConstants.tokenKey, newToken);
                }

                if (newRefreshToken != null) {
                  await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
                }

                // Retry original request with new access token
                final opts = e.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';

                final retryRes = await dio.fetch(opts);
                return handler.resolve(retryRes);
              }
            } catch (refreshErr) {
              // Refresh failed, clear invalidated token fields
              await _secureStorage.delete(key: AppConstants.tokenKey);
              await _secureStorage.delete(key: 'refresh_token');
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.tokenKey);
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
