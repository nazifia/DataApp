// Agents (POS) Repository — apply, dashboard, sell on behalf of a customer.
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class AgentsRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  AgentsRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // POST /agents/apply/ — returns the (pending) agent record.
  Future<Map<String, dynamic>> apply(String businessName) async {
    if (_config.useMockAuth) {
      return {
        'id': 'a_new',
        'agent_code': 'AG000000',
        'business_name': businessName,
        'status': 'pending',
        'commission_percent': 1.0,
        'created_at': DateTime.now().toIso8601String(),
      };
    }
    final response = await _apiClient.dio.post(
      '/agents/apply/',
      data: {'business_name': businessName},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // GET /agents/dashboard/ — 403 if the caller is not an agent.
  Future<Map<String, dynamic>> getDashboard() async {
    if (_config.useMockAuth) {
      return {
        'agent': {
          'id': 'a1',
          'agent_code': 'AG123456',
          'business_name': 'Dev POS Store',
          'status': 'active',
          'commission_percent': 1.0,
          'created_at': DateTime.now().toIso8601String(),
        },
        'total_sales_volume': 12500.0,
        'total_sales_count': 8,
        'total_commission': 125.0,
        'float_balance': 5000.0,
      };
    }
    final response = await _apiClient.dio.get('/agents/dashboard/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  // POST /agents/sale/ — type: airtime | data | electricity | tv.
  Future<Map<String, dynamic>> sale({
    required String type,
    required String phoneNumber,
    String network = '',
    String planId = '',
    double? amount,
    String serviceId = '',
    String customerId = '',
    String variationCode = '',
  }) async {
    if (_config.useMockAuth) {
      return {
        'message': 'Sale completed.',
        'reference': 'TUN-DEV-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
        'type': type,
        'amount': amount ?? 0,
        'customer_phone': phoneNumber,
        'token': type == 'electricity' ? '1234567890123456' : '',
      };
    }
    final body = <String, dynamic>{
      'type': type,
      'phone_number': phoneNumber,
    };
    if (network.isNotEmpty) body['network'] = network;
    if (planId.isNotEmpty) body['plan_id'] = planId;
    if (amount != null) body['amount'] = amount;
    if (serviceId.isNotEmpty) body['service_id'] = serviceId;
    if (customerId.isNotEmpty) body['customer_id'] = customerId;
    if (variationCode.isNotEmpty) body['variation_code'] = variationCode;

    final response = await _apiClient.dio.post('/agents/sale/', data: body);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
