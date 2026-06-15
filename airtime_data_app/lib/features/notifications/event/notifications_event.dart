// Notifications Events
import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  final bool unreadOnly;

  const LoadNotificationsEvent({this.unreadOnly = false});

  @override
  List<Object?> get props => [unreadOnly];
}

// Lightweight: refresh only the unread badge count (used by the dashboard).
class LoadUnreadCountEvent extends NotificationsEvent {
  const LoadUnreadCountEvent();
}

class MarkAllReadEvent extends NotificationsEvent {
  const MarkAllReadEvent();
}

class MarkReadEvent extends NotificationsEvent {
  final String id;
  final bool isRead;

  const MarkReadEvent(this.id, {this.isRead = true});

  @override
  List<Object?> get props => [id, isRead];
}

class DeleteNotificationEvent extends NotificationsEvent {
  final String id;

  const DeleteNotificationEvent(this.id);

  @override
  List<Object?> get props => [id];
}
