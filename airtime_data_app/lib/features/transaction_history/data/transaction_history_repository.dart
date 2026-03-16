// Transaction History Repository
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class TransactionHistoryRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  TransactionHistoryRepository(
      {required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // Get Transaction History
  Future<Map<String, dynamic>> getTransactionHistory() async {
    if (_config.useMockAuth) {
      return {
        'transactions': [
          {
            'id': 'txn_001',
            'type': 'airtime',
            'amount': 500.0,
            'status': 'success',
            'reference': 'REF-DEV-001',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'txn_002',
            'type': 'data',
            'amount': 1000.0,
            'status': 'success',
            'reference': 'REF-DEV-002',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'txn_003',
            'type': 'wallet_fund',
            'amount': 5000.0,
            'status': 'success',
            'reference': 'REF-DEV-003',
            'created_at': DateTime.now().toIso8601String(),
          },
        ]
      };
    }
    final response = await _apiClient.dio.get('/transactions');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
