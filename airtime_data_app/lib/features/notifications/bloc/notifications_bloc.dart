// Notifications Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/notifications_repository.dart';
import '../event/notifications_event.dart';
import '../state/notifications_state.dart';
import '../../../core/utils/api_error.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRepository _repository;

  NotificationsBloc({required NotificationsRepository repository})
      : _repository = repository,
        super(const NotificationsState()) {
    on<LoadNotificationsEvent>(_onLoad);
    on<LoadUnreadCountEvent>(_onLoadUnreadCount);
    on<MarkAllReadEvent>(_onMarkAllRead);
    on<MarkReadEvent>(_onMarkRead);
    on<DeleteNotificationEvent>(_onDelete);
  }

  Future<void> _onLoad(
      LoadNotificationsEvent event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final (notifications, unread) =
          await _repository.getNotifications(unreadOnly: event.unreadOnly);
      emit(state.copyWith(
        notifications: notifications,
        unreadCount: unread,
        loading: false,
        loadedOnce: true,
      ));
    } catch (e) {
      emit(state.copyWith(
          loading: false, loadedOnce: true, error: extractApiError(e)));
    }
  }

  Future<void> _onLoadUnreadCount(
      LoadUnreadCountEvent event, Emitter<NotificationsState> emit) async {
    try {
      final count = await _repository.getUnreadCount();
      emit(state.copyWith(unreadCount: count));
    } catch (_) {
      // Badge refresh is best-effort; ignore failures.
    }
  }

  Future<void> _onMarkAllRead(
      MarkAllReadEvent event, Emitter<NotificationsState> emit) async {
    try {
      await _repository.markAllRead();
      final updated = state.notifications
          .map((n) => {...n, 'is_read': true})
          .toList();
      emit(state.copyWith(notifications: updated, unreadCount: 0));
    } catch (e) {
      emit(state.copyWith(error: extractApiError(e)));
    }
  }

  Future<void> _onMarkRead(
      MarkReadEvent event, Emitter<NotificationsState> emit) async {
    try {
      await _repository.markRead(event.id, isRead: event.isRead);
      final updated = state.notifications
          .map((n) => n['id'] == event.id
              ? {...n, 'is_read': event.isRead}
              : n)
          .toList();
      final unread = updated.where((n) => n['is_read'] != true).length;
      emit(state.copyWith(notifications: updated, unreadCount: unread));
    } catch (e) {
      emit(state.copyWith(error: extractApiError(e)));
    }
  }

  Future<void> _onDelete(
      DeleteNotificationEvent event, Emitter<NotificationsState> emit) async {
    try {
      await _repository.deleteNotification(event.id);
      final updated =
          state.notifications.where((n) => n['id'] != event.id).toList();
      final unread = updated.where((n) => n['is_read'] != true).length;
      emit(state.copyWith(notifications: updated, unreadCount: unread));
    } catch (e) {
      emit(state.copyWith(error: extractApiError(e)));
    }
  }
}
