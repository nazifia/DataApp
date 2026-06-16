// Authentication Repository
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/config/app_env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/biometric_service.dart';
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
      '/auth/login/',
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
        final refresh = data['refresh_token'].toString();
        await _storage.write(key: 'refresh_token', value: refresh);
        // Keep the biometric-gated credential current after a fresh login.
        await BiometricService.refreshCredential(refresh);
      }
    }
    return data;
  }

  // Biometric login: verify identity (caller prompts the OS sheet via
  // BiometricService.authenticate) then exchange the biometric-stored refresh
  // token for a fresh access token. Throws a user-facing message if the stored
  // session is missing or expired so the UI can fall back to password login.
  Future<Map<String, dynamic>> biometricLogin() async {
    if (_config.useMockAuth) {
      const mockToken = 'dev_access_token_123';
      await _storage.write(key: 'access_token', value: mockToken);
      await _storage.write(
          key: 'refresh_token', value: 'dev_refresh_token_123');
      return {'access': mockToken};
    }
    final refresh = await _storage.read(key: 'biometric_refresh_token');
    if (refresh == null || refresh.isEmpty) {
      throw Exception(
          'Biometric login is not set up. Please sign in with your password.');
    }
    final slug = await _storage.read(key: 'tenant_slug');
    final response = await _apiClient.dio.post(
      '/auth/refresh-token/',
      data: {'refresh': refresh},
      options: Options(headers: {
        if (slug != null && slug.isNotEmpty) 'X-Tenant-Slug': slug,
      }),
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final access = data['access']?.toString();
    if (access == null || access.isEmpty) {
      throw Exception(
          'Biometric session expired. Please sign in with your password.');
    }
    await _storage.write(key: 'access_token', value: access);
    // Rotate the stored refresh token if the backend issued a new one.
    final newRefresh = data['refresh']?.toString();
    final effectiveRefresh =
        (newRefresh != null && newRefresh.isNotEmpty) ? newRefresh : refresh;
    await _storage.write(key: 'refresh_token', value: effectiveRefresh);
    await _storage.write(
        key: 'biometric_refresh_token', value: effectiveRefresh);
    return data;
  }

  // Validate that a tenant slug exists and, if so, apply it to all future requests
  Future<Map<String, dynamic>> validateAndSetTenant(String slug) async {
    if (_config.useMockAuth) {
      await _storage.write(key: 'tenant_slug', value: slug);
      _apiClient.updateTenantSlug(slug);
      return {'name': 'Dev Org ($slug)', 'slug': slug};
    }
    final response = await _apiClient.dio.get(
      '/tenants/info/',
      options: Options(headers: {'X-Tenant-Slug': slug}),
    );
    // Persist so login (no slug field) and post-restart requests reuse it.
    await _storage.write(key: 'tenant_slug', value: slug);
    _apiClient.updateTenantSlug(slug);
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Register a new business / tenant (public self-service signup).
  // On success persists the returned slug so subsequent requests target it.
  Future<Map<String, dynamic>> registerTenant({
    required String name,
    required String ownerEmail,
    required String ownerPhone,
    required String ownerPassword,
    String? slug,
    String? supportEmail,
    String? supportPhone,
    String? primaryColor,
  }) async {
    if (_config.useMockAuth) {
      final s = (slug != null && slug.isNotEmpty)
          ? slug
          : name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      await _storage.write(key: 'tenant_slug', value: s);
      _apiClient.updateTenantSlug(s);
      return {'name': name, 'slug': s};
    }
    final response = await _apiClient.dio.post(
      '/tenants/register/',
      data: {
        'name': name,
        'owner_email': ownerEmail,
        'owner_phone': Validators.formatNigerianPhone(ownerPhone),
        'owner_password': ownerPassword,
        if (slug != null && slug.isNotEmpty) 'slug': slug,
        if (supportEmail != null && supportEmail.isNotEmpty)
          'support_email': supportEmail,
        if (supportPhone != null && supportPhone.isNotEmpty)
          'support_phone': Validators.formatNigerianPhone(supportPhone),
        if (primaryColor != null && primaryColor.isNotEmpty)
          'primary_color': primaryColor,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final newSlug = data['slug']?.toString();
    if (newSlug != null && newSlug.isNotEmpty) {
      // Persist so the owner's account creation + login target the new workspace.
      await _storage.write(key: 'tenant_slug', value: newSlug);
      _apiClient.updateTenantSlug(newSlug);
    }
    return data;
  }

  // Send OTP
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    if (_config.useMockAuth) {
      // Dev: skip real SMS, return mock success immediately
      return {'message': 'OTP sent (dev mode)', 'phone_number': phoneNumber};
    }
    final response = await _apiClient.dio.post(
      '/auth/send-otp/',
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
        await _storage.write(
            key: 'refresh_token', value: 'dev_refresh_token_123');
        return {
          'message': 'OTP verified (dev mode)',
          'access_token': mockToken
        };
      } else {
        throw Exception('Invalid OTP. Use test OTP: ${_config.testOtp}');
      }
    }
    final response = await _apiClient.dio.post(
      '/auth/verify-otp/',
      data: {
        'phone_number': Validators.formatNigerianPhone(phoneNumber),
        'otp': otp,
      },
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['access_token'] != null) {
      await _storage.write(
          key: 'access_token', value: data['access_token'].toString());
      if (data['refresh_token'] != null) {
        final refresh = data['refresh_token'].toString();
        await _storage.write(key: 'refresh_token', value: refresh);
        await BiometricService.refreshCredential(refresh);
      }
    }
    return data;
  }

  // Create User Profile
  Future<Map<String, dynamic>> createProfile(
      String phoneNumber, String fullName, String password, {String? email}) async {
    if (_config.useMockAuth) {
      return {
        'user': {
          'id': 'dev_user_001',
          'phone_number': Validators.formatNigerianPhone(phoneNumber),
          'full_name': fullName,
          'email': email ?? '',
        }
      };
    }
    final response = await _apiClient.dio.post(
      '/user/profile/setup/',
      data: {
        'phone_number': Validators.formatNigerianPhone(phoneNumber),
        'full_name': fullName,
        'password': password,
        'device_id': _generateDeviceId(),
        if (email != null && email.isNotEmpty) 'email': email,
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
    final response = await _apiClient.dio.get('/user/profile/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateProfile(String fullName, {String? email}) async {
    if (_config.useMockAuth) {
      return {'message': 'Profile updated (dev mode)'};
    }
    final response = await _apiClient.dio.put(
      '/user/profile/',
      data: {
        'full_name': fullName,
        // ignore: use_null_aware_elements
        if (email != null) 'email': email,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    if (_config.useMockAuth) {
      // Dev mode: accept any non-empty current password
      if (currentPassword.isEmpty) {
        throw Exception('Current password cannot be empty.');
      }
      return {'message': 'Password changed successfully (dev mode)'};
    }
    final response = await _apiClient.dio.put(
      '/user/password/',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Get Wallet Balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    if (_config.useMockAuth) {
      return {'balance': 5000.0};
    }
    final response = await _apiClient.dio.get('/wallet/balance/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Fund Wallet
  Future<Map<String, dynamic>> fundWallet(double amount) async {
    if (_config.useMockAuth) {
      return {
        'message': 'Wallet funded (dev mode)',
        'balance': 5000.0 + amount
      };
    }
    final response = await _apiClient.dio.post(
      '/wallet/fund/',
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
    // Keep tenant slug so the user can log back in without re-entering it.
    final slug = await _storage.read(key: 'tenant_slug');
    // Preserve biometric enrollment so the user can biometric-login after
    // logout without re-entering a password.
    final bioEnabled = await _storage.read(key: 'biometric_enabled');
    final bioPhone = await _storage.read(key: 'biometric_phone');
    final bioToken = await _storage.read(key: 'biometric_refresh_token');
    await _storage.deleteAll();
    if (slug != null && slug.isNotEmpty) {
      await _storage.write(key: 'tenant_slug', value: slug);
    }
    if (bioEnabled == 'true') {
      await _storage.write(key: 'biometric_enabled', value: 'true');
      if (bioPhone != null && bioPhone.isNotEmpty) {
        await _storage.write(key: 'biometric_phone', value: bioPhone);
      }
      if (bioToken != null && bioToken.isNotEmpty) {
        await _storage.write(key: 'biometric_refresh_token', value: bioToken);
      }
    }
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
      'picture': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });
    final response = await _apiClient.dio.put(
      '/user/profile/picture/',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Check if User is Logged In
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  // Register FCM token with backend
  Future<void> registerFcmToken(String fcmToken) async {
    if (_config.useMockAuth || fcmToken.isEmpty) return;
    try {
      await _apiClient.dio.post('/user/fcm-token/', data: {'fcm_token': fcmToken});
    } catch (_) {
      // Non-fatal: notifications will just not be delivered
    }
  }
}
