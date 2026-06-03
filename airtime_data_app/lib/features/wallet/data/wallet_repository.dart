import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class WalletRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  WalletRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  Future<Map<String, dynamic>> getWalletBalance() async {
    if (_config.useMockAuth) return {'balance': 5000.0};
    final response = await _apiClient.dio.get('/wallet/balance/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getBankTransferDetails() async {
    if (_config.useMockAuth) {
      return {
        'bank_name': 'Wema Bank (Paystack)',
        'account_number': '0123456789',
        'account_name': 'TUN/DEMO',
        'note': 'Transfer the exact amount shown. Your wallet will be credited automatically.',
      };
    }
    final response = await _apiClient.dio.get('/wallet/bank-details/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Initiates a Paystack checkout for card/online payment.
  /// Returns [authorization_url] and [reference].
  Future<Map<String, dynamic>> initiatePaystackPayment(double amount) async {
    if (_config.useMockAuth) {
      return {
        'authorization_url': 'https://checkout.paystack.com/dev-demo',
        'reference': 'DEV-${DateTime.now().millisecondsSinceEpoch}',
      };
    }
    final response = await _apiClient.dio.post(
      '/wallet/initiate-payment/',
      data: {'amount': amount},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Direct credit — kept for dev/admin use only.
  Future<Map<String, dynamic>> fundWallet(double amount) async {
    if (_config.useMockAuth) {
      return {'status': 'success', 'message': 'Wallet funded (dev mode)', 'balance': 5000.0 + amount};
    }
    final response = await _apiClient.dio.post('/wallet/fund/', data: {'amount': amount});
    return Map<String, dynamic>.from(response.data as Map);
  }
}
