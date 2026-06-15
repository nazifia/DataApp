// Bills Repository — electricity & cable-TV payments (VTpass via backend).
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class BillsRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  BillsRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  // GET /bills/providers/?category=electricity|tv
  Future<List<Map<String, dynamic>>> getProviders(String category) async {
    if (_config.useMockAuth) {
      return category == 'tv'
          ? const [
              {'id': 'dstv', 'name': 'DStv'},
              {'id': 'gotv', 'name': 'GOtv'},
              {'id': 'startimes', 'name': 'StarTimes'},
              {'id': 'showmax', 'name': 'Showmax'},
            ]
          : const [
              {'id': 'ikeja-electric', 'name': 'Ikeja Electric (IKEDC)'},
              {'id': 'eko-electric', 'name': 'Eko Electric (EKEDC)'},
              {'id': 'kano-electric', 'name': 'Kano Electric (KEDCO)'},
              {'id': 'portharcourt-electric', 'name': 'Port Harcourt Electric (PHED)'},
              {'id': 'jos-electric', 'name': 'Jos Electric (JED)'},
              {'id': 'ibadan-electric', 'name': 'Ibadan Electric (IBEDC)'},
              {'id': 'abuja-electric', 'name': 'Abuja Electric (AEDC)'},
              {'id': 'enugu-electric', 'name': 'Enugu Electric (EEDC)'},
              {'id': 'benin-electric', 'name': 'Benin Electric (BEDC)'},
              {'id': 'kaduna-electric', 'name': 'Kaduna Electric (KAEDCO)'},
            ];
    }
    final response = await _apiClient.dio.get(
      '/bills/providers/',
      queryParameters: {'category': category},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['providers'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // GET /bills/variations/?category=...&service_id=...
  Future<List<Map<String, dynamic>>> getVariations(
      String category, String serviceId) async {
    if (_config.useMockAuth) {
      if (category == 'electricity') {
        return const [
          {'variation_code': 'prepaid', 'name': 'Prepaid Meter'},
          {'variation_code': 'postpaid', 'name': 'Postpaid Meter'},
        ];
      }
      const mock = {
        'dstv': [
          {'variation_code': 'dstv-padi', 'name': 'DStv Padi', 'amount': 2950},
          {'variation_code': 'dstv-yanga', 'name': 'DStv Yanga', 'amount': 4200},
          {'variation_code': 'dstv-confam', 'name': 'DStv Confam', 'amount': 7400},
          {'variation_code': 'dstv-compact', 'name': 'DStv Compact', 'amount': 12500},
        ],
        'gotv': [
          {'variation_code': 'gotv-smallie', 'name': 'GOtv Smallie', 'amount': 1300},
          {'variation_code': 'gotv-jinja', 'name': 'GOtv Jinja', 'amount': 3300},
          {'variation_code': 'gotv-max', 'name': 'GOtv Max', 'amount': 5700},
        ],
        'startimes': [
          {'variation_code': 'nova', 'name': 'Nova (Antenna)', 'amount': 1700},
          {'variation_code': 'basic', 'name': 'Basic (Antenna)', 'amount': 3700},
        ],
      };
      return List<Map<String, dynamic>>.from(
          (mock[serviceId] ?? const []).map((e) => Map<String, dynamic>.from(e)));
    }
    final response = await _apiClient.dio.get(
      '/bills/variations/',
      queryParameters: {'category': category, 'service_id': serviceId},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['variations'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  // POST /bills/verify/ — look up meter/smartcard holder before payment.
  // Backend returns 400 with {success:false, message} on failure; surface that
  // body to the caller instead of throwing so the UI can show the reason.
  Future<Map<String, dynamic>> verifyCustomer(
      String serviceId, String customerId, String variationCode) async {
    if (_config.useMockAuth) {
      return {
        'success': true,
        'customer_name': 'JOHN DOE',
        'customer_id': customerId,
        'message': 'Customer verified (dev mode)',
      };
    }
    try {
      final response = await _apiClient.dio.post(
        '/bills/verify/',
        data: {
          'service_id': serviceId,
          'customer_id': customerId,
          'variation_code': variationCode,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) return Map<String, dynamic>.from(data);
      rethrow;
    }
  }

  // POST /bills/pay/
  Future<Map<String, dynamic>> payBill({
    required String category,
    required String serviceId,
    required String customerId,
    required String variationCode,
    required double amount,
    required String phoneNumber,
  }) async {
    if (_config.useMockAuth) {
      final token = List.generate(16, (i) => (i * 7 % 10)).join();
      return {
        'message': 'Bill paid (dev mode)',
        'reference': 'TUN-DEV-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'success',
        'amount': amount,
        'category': category,
        'provider': serviceId,
        'customer_id': customerId,
        'token': category == 'electricity' ? token : '',
      };
    }
    final response = await _apiClient.dio.post(
      '/bills/pay/',
      data: {
        'category': category,
        'service_id': serviceId,
        'customer_id': customerId,
        'variation_code': variationCode,
        'amount': amount,
        'phone_number': phoneNumber,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }
}
