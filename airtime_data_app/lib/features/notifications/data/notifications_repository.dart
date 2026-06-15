// Notifications Repository — list, unread count, mark read, delete.
import '../../../core/network/api_client.dart';
import '../../../core/config/app_env.dart';

class NotificationsRepository {
  final ApiClient _apiClient;
  final AppConfig _config;

  NotificationsRepository({required ApiClient apiClient, required AppConfig config})
      : _apiClient = apiClient,
        _config = config;

  List<Map<String, dynamic>> _mockData() => [
        {
          'id': 'n1',
          'title': 'Wallet funded',
          'body': 'Your wallet was credited with ₦5,000.',
          'type': 'wallet',
          'data': const {},
          'is_read': false,
          'created_at': DateTime.now()
              .subtract(const Duration(minutes: 12))
              .toIso8601String(),
        },
        {
          'id': 'n2',
          'title': 'Airtime delivered',
          'body': '₦500 MTN airtime sent to 0803••••567.',
          'type': 'transaction',
          'data': const {},
          'is_read': false,
          'created_at': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
        },
        {
          'id': 'n3',
          'title': 'Welcome to TopUpNaija',
          'body': 'Thanks for joining. Fund your wallet to get started.',
          'type': 'system',
          'data': const {},
          'is_read': true,
          'created_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
        },
      ];

  // GET /notifications/ → {unread_count, results:[...]}.
  // Returns (notifications, unreadCount).
  Future<(List<Map<String, dynamic>>, int)> getNotifications(
      {bool unreadOnly = false}) async {
    if (_config.useMockAuth) {
      var list = _mockData();
      if (unreadOnly) {
        list = list.where((n) => n['is_read'] != true).toList();
      }
      final unread = _mockData().where((n) => n['is_read'] != true).length;
      return (list, unread);
    }
    final response = await _apiClient.dio.get(
      '/notifications/',
      queryParameters: unreadOnly ? {'unread': 'true'} : null,
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final results = (data['results'] ?? []) as List;
    final notifications = results
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final unread = (data['unread_count'] ?? 0) as int;
    return (notifications, unread);
  }

  // GET /notifications/unread-count/ → {unread_count}.
  Future<int> getUnreadCount() async {
    if (_config.useMockAuth) {
      return _mockData().where((n) => n['is_read'] != true).length;
    }
    final response = await _apiClient.dio.get('/notifications/unread-count/');
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['unread_count'] ?? 0) as int;
  }

  // POST /notifications/mark-all-read/ → {marked}.
  Future<void> markAllRead() async {
    if (_config.useMockAuth) return;
    await _apiClient.dio.post('/notifications/mark-all-read/');
  }

  // PATCH /notifications/<id>/ {is_read}.
  Future<void> markRead(String id, {bool isRead = true}) async {
    if (_config.useMockAuth) return;
    await _apiClient.dio.patch('/notifications/$id/', data: {'is_read': isRead});
  }

  // DELETE /notifications/<id>/.
  Future<void> deleteNotification(String id) async {
    if (_config.useMockAuth) return;
    await _apiClient.dio.delete('/notifications/$id/');
  }
}
