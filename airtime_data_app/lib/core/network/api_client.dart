// API Client with Dio
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_env.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient(AppConfig config)
      : _dio = Dio(BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    if (config.enableLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ));
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Attempt to refresh the access token
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              final refreshResponse = await Dio().post(
                '${config.baseUrl}/auth/refresh-token',
                data: {'refresh_token': refreshToken},
              );
              final newAccessToken =
                  refreshResponse.data['access_token'] as String?;
              if (newAccessToken != null) {
                await _storage.write(
                    key: 'access_token', value: newAccessToken);
                // Retry the original request with the new token
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                final retryResponse = await _dio.fetch(retryOptions);
                return handler.resolve(retryResponse);
              }
            } catch (_) {
              // Refresh failed — clear tokens so the app redirects to login
              await clearTokens();
            }
          } else {
            await clearTokens();
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> refreshToken() async {
    // Implement token refresh logic
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

// Custom Exception for API Errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
