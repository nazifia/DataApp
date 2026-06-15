// Admin (business owner) Repository.
// Wraps the backend /admin/ endpoints used by the owner-only screens:
//   GET   /admin/dashboard/stats/      headline figures (profit, users, wallet)
//   GET   /admin/analytics/earnings/   markup-earnings over a window
//   GET   /admin/settings/             current business config
//   PATCH /admin/settings/             update business config
// All return 403 for non-admin callers — surfaced to the bloc as DioException.
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class AdminRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  AdminRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  Future<Map<String, dynamic>> getDashboardStats() async {
    if (_config.useMockAuth) {
      return {
        'total_users': 128,
        'active_users': 119,
        'total_transactions': 842,
        'successful_transactions': 803,
        'total_revenue': 1284500.0,
        'total_profit': 64225.0,
        'total_wallet_balance': 318900.0,
        'today_transactions': 37,
        'today_revenue': 58200.0,
        'today_profit': 2910.0,
      };
    }
    final response = await _apiClient.dio.get('/admin/dashboard/stats/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getEarnings({int days = 30}) async {
    if (_config.useMockAuth) {
      return {
        'days': days,
        'total_revenue': 1284500.0,
        'total_profit': 64225.0,
        'transaction_count': 803,
        'daily': [
          {'day': '2026-06-13', 'revenue': 41200.0, 'profit': 2060.0, 'count': 28},
          {'day': '2026-06-14', 'revenue': 53800.0, 'profit': 2690.0, 'count': 34},
          {'day': '2026-06-15', 'revenue': 58200.0, 'profit': 2910.0, 'count': 37},
        ],
        'by_type': [
          {'type': 'data', 'revenue': 720300.0, 'profit': 36015.0, 'count': 410},
          {'type': 'airtime', 'revenue': 480100.0, 'profit': 24005.0, 'count': 350},
          {'type': 'electricity', 'revenue': 64100.0, 'profit': 3205.0, 'count': 28},
          {'type': 'tv', 'revenue': 20000.0, 'profit': 1000.0, 'count': 15},
        ],
      };
    }
    final response =
        await _apiClient.dio.get('/admin/analytics/earnings/', queryParameters: {
      'days': days,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getSettings() async {
    if (_config.useMockAuth) {
      return {
        'name': 'Dev Business',
        'logo_url': '',
        'primary_color': '#1976D2',
        'support_email': 'support@dev.test',
        'support_phone': '08000000000',
        'airtime_markup_percent': 2.0,
        'data_markup_percent': 3.0,
        'bill_markup_percent': 1.5,
        'referral_bonus': 150.0,
        'min_wallet_fund': 50.0,
        'min_withdrawal': 100.0,
        'withdrawal_fee': 25.0,
        'max_daily_transaction': 500000.0,
      };
    }
    final response = await _apiClient.dio.get('/admin/settings/');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateSettings(
      Map<String, dynamic> changes) async {
    if (_config.useMockAuth) {
      final current = await getSettings();
      current.addAll(changes);
      return current;
    }
    final response =
        await _apiClient.dio.patch('/admin/settings/', data: changes);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
