// Admin Events
import 'package:equatable/equatable.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object?> get props => [];
}

// Earnings screen: load headline stats + earnings for a window.
class LoadEarningsEvent extends AdminEvent {
  final int days;
  const LoadEarningsEvent({this.days = 30});

  @override
  List<Object?> get props => [days];
}

// Settings screen: load current business config.
class LoadSettingsEvent extends AdminEvent {
  const LoadSettingsEvent();
}

// Settings screen: persist the changed fields.
class UpdateSettingsEvent extends AdminEvent {
  final Map<String, dynamic> changes;
  const UpdateSettingsEvent(this.changes);

  @override
  List<Object?> get props => [changes];
}
