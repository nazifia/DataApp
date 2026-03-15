// Data Repository
import '../../core/network/api_client.dart';
import '../../core/config/app_env.dart';

class DataRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  DataRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // Purchase Data
  Future<Map<String, dynamic>> purchaseData(
      String network, String planId, String phoneNumber) async {
    if (_config.useMockAuth) {
      return {
        'status': 'success',
        'message': 'Data purchase successful (dev mode)',
        'reference': 'REF-DEV-${DateTime.now().millisecondsSinceEpoch}',
        'plan_id': planId,
        'plan_name': planId.replaceAll('_', ' ').toUpperCase(),
        'network': network,
        'phone_number': phoneNumber,
        'amount': 500.0,
        'data': '1GB',
        'validity': '30 days',
      };
    }
    final response = await _apiClient.dio.post(
      '/data/purchase',
      data: {
        'network': network,
        'plan_id': planId,
        'phone_number': phoneNumber,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Get Data Plans
  Future<Map<String, dynamic>> getDataPlans(String network) async {
    if (_config.useMockAuth) {
      return {
        'plans': [
          {'id': 'plan_500mb', 'name': '500MB', 'price': 200.0, 'validity': '1 day'},
          {'id': 'plan_1gb', 'name': '1GB', 'price': 350.0, 'validity': '7 days'},
          {'id': 'plan_2gb', 'name': '2GB', 'price': 600.0, 'validity': '30 days'},
          {'id': 'plan_5gb', 'name': '5GB', 'price': 1500.0, 'validity': '30 days'},
          {'id': 'plan_10gb', 'name': '10GB', 'price': 2500.0, 'validity': '30 days'},
        ]
      };
    }
    final response = await _apiClient.dio.get(
      '/data/plans',
      queryParameters: {'network': network},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
