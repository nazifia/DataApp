// Disputes Repository — list own disputes & raise new ones.
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class DisputesRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  DisputesRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // GET /disputes/ — StandardPagination {items, total, page, page_size, total_pages}.
  Future<List<Map<String, dynamic>>> getDisputes() async {
    if (_config.useMockAuth) {
      return [
        {
          'id': 'd1',
          'transaction_reference': 'TUN-DEV-001',
          'subject': 'Airtime not delivered',
          'message': 'I bought ₦500 airtime but it never arrived.',
          'status': 'open',
          'admin_notes': '',
          'created_at': DateTime.now().toIso8601String(),
          'resolved_at': null,
        },
      ];
    }
    final response = await _apiClient.dio.get('/disputes/');
    final data = Map<String, dynamic>.from(response.data as Map);
    final results = data['items'] ?? [];
    return (results as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // POST /disputes/
  Future<Map<String, dynamic>> createDispute({
    required String subject,
    required String message,
    String transactionReference = '',
  }) async {
    if (_config.useMockAuth) {
      return {
        'id': 'd_new',
        'transaction_reference': transactionReference,
        'subject': subject,
        'message': message,
        'status': 'open',
        'admin_notes': '',
        'created_at': DateTime.now().toIso8601String(),
        'resolved_at': null,
      };
    }
    final response = await _apiClient.dio.post('/disputes/', data: {
      'transaction_reference': transactionReference,
      'subject': subject,
      'message': message,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }
}
