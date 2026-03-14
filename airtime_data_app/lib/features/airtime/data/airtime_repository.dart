// Airtime Repository
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class AirtimeRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  AirtimeRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // Purchase Airtime
  Future<Map<String, dynamic>> purchaseAirtime(
      String network, String phoneNumber, double amount) async {
    if (_config.useMockAuth) {
      return {
        'message': 'Airtime purchase successful (dev mode)',
        'reference': 'REF-DEV-${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'network': network,
        'phone_number': phoneNumber,
      };
    }
    final response = await _apiClient.dio.post(
      '/airtime/purchase',
      data: {
        'network': network,
        'phone_number': phoneNumber,
        'amount': amount,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
