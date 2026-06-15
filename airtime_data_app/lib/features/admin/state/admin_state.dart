// Admin States
import 'package:equatable/equatable.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

// Caller is not an admin/owner (HTTP 403).
class AdminNotAuthorized extends AdminState {
  const AdminNotAuthorized();
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Earnings ────────────────────────────────────────────────────────────────

class EarningsLoaded extends AdminState {
  final int days;
  final double totalRevenue;
  final double totalProfit;
  final int transactionCount;
  final double walletBalance;
  final int totalUsers;
  final int activeUsers;
  final double todayProfit;
  final List<Map<String, dynamic>> daily;
  final List<Map<String, dynamic>> byType;

  const EarningsLoaded({
    required this.days,
    required this.totalRevenue,
    required this.totalProfit,
    required this.transactionCount,
    required this.walletBalance,
    required this.totalUsers,
    required this.activeUsers,
    required this.todayProfit,
    required this.daily,
    required this.byType,
  });

  @override
  List<Object?> get props => [
        days,
        totalRevenue,
        totalProfit,
        transactionCount,
        walletBalance,
        totalUsers,
        activeUsers,
        todayProfit,
        daily,
        byType,
      ];
}

// ─── Settings ────────────────────────────────────────────────────────────────

class SettingsLoaded extends AdminState {
  final Map<String, dynamic> settings;
  // True right after a successful save (so the page can show a confirmation).
  final bool justSaved;

  const SettingsLoaded(this.settings, {this.justSaved = false});

  @override
  List<Object?> get props => [settings, justSaved];
}

// Transient while a PATCH is in flight; carries current values so the form
// can stay rendered behind a saving overlay.
class SettingsSaving extends AdminState {
  final Map<String, dynamic> settings;
  const SettingsSaving(this.settings);

  @override
  List<Object?> get props => [settings];
}

// Save failed but the form is still usable; carries current values + message.
class SettingsSaveError extends AdminState {
  final Map<String, dynamic> settings;
  final String message;
  const SettingsSaveError(this.settings, this.message);

  @override
  List<Object?> get props => [settings, message];
}
