import 'package:dio/dio.dart';

String extractApiError(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final detail = data['detail']?.toString();
      if (detail != null) return detail;
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
    return 'Network error. Please try again.';
  }
  return e.toString().replaceFirst('Exception: ', '');
}
