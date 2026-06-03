import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';
import '../models/beneficiary.dart';

class BeneficiaryRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  BeneficiaryRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  Future<List<Beneficiary>> getBeneficiaries({String? type}) async {
    if (_config.useMockAuth) {
      return [
        Beneficiary(
          id: 'b1', nickname: 'Mum', phoneNumber: '08011111111',
          network: 'mtn', type: 'airtime', createdAt: DateTime.now().toIso8601String(),
        ),
      ];
    }
    final queryParams = type != null ? {'type': type} : <String, dynamic>{};
    final response = await _apiClient.dio.get('/beneficiaries/', queryParameters: queryParams);
    final list = response.data as List;
    return list.map((e) => Beneficiary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Beneficiary> saveBeneficiary({
    required String phoneNumber,
    required String network,
    required String type,
    String nickname = '',
  }) async {
    if (_config.useMockAuth) {
      return Beneficiary(
        id: 'b_new', nickname: nickname, phoneNumber: phoneNumber,
        network: network, type: type, createdAt: DateTime.now().toIso8601String(),
      );
    }
    final response = await _apiClient.dio.post('/beneficiaries/', data: {
      'phone_number': phoneNumber,
      'network': network,
      'type': type,
      'nickname': nickname,
    });
    return Beneficiary.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteBeneficiary(String id) async {
    if (_config.useMockAuth) return;
    await _apiClient.dio.delete('/beneficiaries/$id/');
  }

  Future<Beneficiary> updateNickname(String id, String nickname) async {
    if (_config.useMockAuth) {
      return Beneficiary(
        id: id, nickname: nickname, phoneNumber: '', network: '', type: 'airtime',
        createdAt: DateTime.now().toIso8601String(),
      );
    }
    final response = await _apiClient.dio.patch('/beneficiaries/$id/', data: {'nickname': nickname});
    return Beneficiary.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
