// Authentication Repository
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/validation.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final AppConfig _config;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // Standard Login (phone + password)
  Future<Map<String, dynamic>> login(
      String phoneNumber, String password) async {
    if (_config.useMockAuth) {
      if (password == 'password123') {
        const mockToken = 'dev_access_token_123';
        await _storage.write(key: 'access_token', value: mockToken);
        await _storage.write(
            key: 'refresh_token', value: 'dev_refresh_token_123');
        return {
          'message': 'Login successful (dev mode)',
          'access_token': mockToken,
        };
      } else {
        throw Exception('Invalid credentials. Dev password: password123');
      }
    }
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {
        'phone_number': Validators.formatNigerianPhone(phoneNumber),
        'password': password,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['access_token'] != null) {
      await _storage.write(
          key: 'access_token', value: data['access_token'].toString());
      if (data['refresh_token'] != null) {
        await _storage.write(
            key: 'refresh_token', value: data['refresh_token'].toString());
      }
    }
    return data;
  }

  // Biometric helpers
  Future<void> enableBiometric(String phoneNumber) async {
    await _storage.write(key: 'biometric_enabled', value: 'true');
    await _storage.write(key: 'biometric_phone', value: phoneNumber);
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  Future<String?> getBiometricPhone() async {
    return await _storage.read(key: 'biometric_phone');
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    if (_config.useMockAuth) {
      // Dev: skip real SMS, return mock success immediately
      return {'message': 'OTP sent (dev mode)', 'phone_number': phoneNumber};
    }
    final response = await _apiClient.dio.post(
      '/auth/send-otp',
      data: {
        'phone_number': Validators.formatNigerianPhone(phoneNumber),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    if (_config.useMockAuth) {
      if (otp == _config.testOtp) {
        // Dev: correct test OTP — mock a successful auth response
        const mockToken = 'dev_access_token_123';
        await _storage.write(key: 'access_token', value: mockToken);
        await _storage.write(key: 'refresh_token', value: 'dev_refresh_token_123');
        return {'message': 'OTP verified (dev mode)', 'access_token': mockToken};
      } else {
        throw Exception('Invalid OTP. Use test OTP: ${_config.testOtp}');
      }
    }
    final response = await _apiClient.dio.post(
      '/auth/verify-otp',
      data: {
        'phone_number': Validators.formatNigerianPhone(phoneNumber),
        'otp': otp,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Create User Profile
  Future<Map<String, dynamic>> createProfile(
      String phoneNumber, String fullName) async {
    if (_config.useMockAuth) {
      return {
        'user': {
          'id': 'dev_user_001',
          'phone_number': Validators.formatNigerianPhone(phoneNumber),
          'full_name': fullName,
        }
      };
    }
    final response = await _apiClient.dio.post(
      '/user/profile',
      data: {
        'phone_number': Validators.formatNigerianPhone(phoneNumber),
        'full_name': fullName,
        'device_id': _generateDeviceId(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Get User Profile
  Future<Map<String, dynamic>> getProfile() async {
    if (_config.useMockAuth) {
      return {
        'user': {
          'id': 'dev_user_001',
          'phone_number': '08030000000',
          'full_name': 'Dev User',
        }
      };
    }
    final response = await _apiClient.dio.get('/user/profile');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(String fullName) async {
    if (_config.useMockAuth) {
      return {'message': 'Profile updated (dev mode)'};
    }
    final response = await _apiClient.dio.put(
      '/user/profile',
      data: {'full_name': fullName},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Get Wallet Balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    if (_config.useMockAuth) {
      return {'balance': 5000.0};
    }
    final response = await _apiClient.dio.get('/wallet/balance');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Fund Wallet
  Future<Map<String, dynamic>> fundWallet(double amount) async {
    if (_config.useMockAuth) {
      return {'message': 'Wallet funded (dev mode)', 'balance': 5000.0 + amount};
    }
    final response = await _apiClient.dio.post(
      '/wallet/fund',
      data: {'amount': amount},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Save Tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  // Get Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Clear Tokens (Logout)
  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  // Generate Device ID
  String _generateDeviceId() {
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Upload Profile Picture
  Future<Map<String, dynamic>> uploadProfilePicture(File imageFile) async {
    if (_config.useMockAuth) {
      return {
        'message': 'Profile picture uploaded (dev mode)',
        'profile_picture_url': 'https://via.placeholder.com/150?text=Profile',
      };
    }
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });
    final response = await _apiClient.dio.put(
      '/user/profile/picture',
      data: formData,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Check if User is Logged In
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }
}
