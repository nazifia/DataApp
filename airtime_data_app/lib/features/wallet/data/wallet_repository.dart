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
  Future<void> fundWallet(double amount) async {
    if (_config.useMockAuth) return;
    await _apiClient.dio.post(
      '/wallet/fund',
      data: {'amount': amount},
    );
  }
}
