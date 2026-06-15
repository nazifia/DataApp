// Notifications State — single mutable-style state so the dashboard badge and
// the list page can both read `unreadCount` without juggling state classes.
import 'package:equatable/equatable.dart';

class NotificationsState extends Equatable {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool loading;
  final bool loadedOnce;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.loading = false,
    this.loadedOnce = false,
    this.error,
  });

  NotificationsState copyWith({
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    bool? loading,
    bool? loadedOnce,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      loading: loading ?? this.loading,
      loadedOnce: loadedOnce ?? this.loadedOnce,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [notifications, unreadCount, loading, loadedOnce, error];
}
