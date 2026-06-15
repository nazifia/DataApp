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

  /// Lists all NGN banks (commercial + microfinance) for withdrawals.
  Future<List<Map<String, dynamic>>> getBanks() async {
    if (_config.useMockAuth) {
      return const [
        {'name': 'Access Bank', 'code': '044', 'type': 'nuban'},
        {'name': 'Guaranty Trust Bank', 'code': '058', 'type': 'nuban'},
        {'name': 'First Bank of Nigeria', 'code': '011', 'type': 'nuban'},
        {'name': 'Zenith Bank', 'code': '057', 'type': 'nuban'},
        {'name': 'United Bank For Africa', 'code': '033', 'type': 'nuban'},
        {'name': 'Opay', 'code': '999992', 'type': 'nuban'},
        {'name': 'Moniepoint MFB', 'code': '50515', 'type': 'nuban'},
        {'name': 'Kuda Microfinance Bank', 'code': '50211', 'type': 'nuban'},
      ];
    }
    final response = await _apiClient.dio.get('/wallet/banks/');
    final banks = (response.data as Map)['banks'] as List;
    return banks.map((b) => Map<String, dynamic>.from(b as Map)).toList();
  }

  /// Verifies a bank account, returning the registered account name.
  Future<String> resolveAccount(
      {required String accountNumber, required String bankCode}) async {
    if (_config.useMockAuth) return 'JOHN DOE (dev mode)';
    final response = await _apiClient.dio.post(
      '/wallet/resolve-account/',
      data: {'account_number': accountNumber, 'bank_code': bankCode},
    );
    return (response.data as Map)['account_name'] as String;
  }

  /// Debits the wallet and sends a transfer to a bank account.
  Future<Map<String, dynamic>> withdraw({
    required double amount,
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    if (_config.useMockAuth) {
      return {
        'status': 'success',
        'message': 'Withdrawal successful (dev mode)',
        'balance': 5000.0 - amount,
      };
    }
    final response = await _apiClient.dio.post('/wallet/withdraw/', data: {
      'amount': amount,
      'bank_code': bankCode,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Polls a withdrawal's status (webhook fallback). Returns the latest
  /// status string and balance.
  Future<Map<String, dynamic>> getWithdrawalStatus(String reference) async {
    if (_config.useMockAuth) {
      return {'reference': reference, 'status': 'success', 'balance': 5000.0};
    }
    final response =
        await _apiClient.dio.get('/wallet/withdraw/$reference/status/');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
