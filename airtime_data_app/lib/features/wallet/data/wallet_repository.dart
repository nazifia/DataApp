// Wallet Repository
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class WalletRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  WalletRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

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
      return {
        'status': 'success',
        'message': 'Wallet funded successfully (dev mode)',
        'balance': 5000.0 + amount,
      };
    }
    final response = await _apiClient.dio.post(
      '/wallet/fund',
      data: {'amount': amount},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
