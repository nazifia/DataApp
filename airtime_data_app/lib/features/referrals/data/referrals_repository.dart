// Referrals Repository — GET /referrals/ (code, invite count, earnings).
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class ReferralsRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  ReferralsRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  Future<Map<String, dynamic>> getReferrals() async {
    if (_config.useMockAuth) {
      return {
        'referral_code': 'DEV1234',
        'invited_count': 3,
        'total_earned': 450.0,
        'bonus_per_referral': 150.0,
      };
    }
    final response = await _apiClient.dio.get('/referrals/');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
