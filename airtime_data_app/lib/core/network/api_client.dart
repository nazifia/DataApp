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
          headers: {
            // Required to bypass localtunnel's browser-redirect page for API calls
            'bypass-tunnel-reminder': 'true',
            'X-Tenant-Slug': config.tenantSlug,
          },
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
              final refreshResponse = await Dio(BaseOptions(
                headers: {
                  'bypass-tunnel-reminder': 'true',
                  'X-Tenant-Slug': config.tenantSlug,
                },
              )).post(
                '${config.baseUrl}/auth/refresh-token/',
                data: {'refresh': refreshToken},
              );
              final newAccessToken =
                  refreshResponse.data['access'] as String?;
              if (newAccessToken != null) {
                await _storage.write(
                    key: 'access_token', value: newAccessToken);
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

        // Extract DRF error detail for clean error messages (handles 429, 400, etc.)
        if (error.response != null) {
          final data = error.response!.data;
          if (data is Map) {
            final detail = data['detail']?.toString();
            if (detail != null) {
              return handler.reject(DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                message: detail,
                type: error.type,
              ));
            }
          }
        }

        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  void updateTenantSlug(String slug) {
    _dio.options.headers['X-Tenant-Slug'] = slug;
  }

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
