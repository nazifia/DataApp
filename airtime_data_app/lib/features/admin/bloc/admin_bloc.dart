// Admin (business owner) Bloc — drives the earnings and settings screens.
// One class, instantiated fresh per route, so the two screens never share state.
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_repository.dart';
import '../event/admin_event.dart';
import '../state/admin_state.dart';
import '../../../core/utils/api_error.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({required AdminRepository repository})
      : _repository = repository,
        super(const AdminInitial()) {
    on<LoadEarningsEvent>(_onLoadEarnings);
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
  }

  Future<void> _onLoadEarnings(
      LoadEarningsEvent event, Emitter<AdminState> emit) async {
    emit(const AdminLoading());
    try {
      final stats = await _repository.getDashboardStats();
      final earnings = await _repository.getEarnings(days: event.days);
      emit(EarningsLoaded(
        days: (earnings['days'] as num?)?.toInt() ?? event.days,
        totalRevenue: (earnings['total_revenue'] as num?)?.toDouble() ?? 0,
        totalProfit: (earnings['total_profit'] as num?)?.toDouble() ?? 0,
        transactionCount:
            (earnings['transaction_count'] as num?)?.toInt() ?? 0,
        walletBalance: (stats['total_wallet_balance'] as num?)?.toDouble() ?? 0,
        totalUsers: (stats['total_users'] as num?)?.toInt() ?? 0,
        activeUsers: (stats['active_users'] as num?)?.toInt() ?? 0,
        todayProfit: (stats['today_profit'] as num?)?.toDouble() ?? 0,
        daily: _mapList(earnings['daily']),
        byType: _mapList(earnings['by_type']),
      ));
    } on DioException catch (e) {
      _emitDioError(e, emit);
    } catch (e) {
      emit(AdminError(extractApiError(e)));
    }
  }

  Future<void> _onLoadSettings(
      LoadSettingsEvent event, Emitter<AdminState> emit) async {
    emit(const AdminLoading());
    try {
      final settings = await _repository.getSettings();
      emit(SettingsLoaded(settings));
    } on DioException catch (e) {
      _emitDioError(e, emit);
    } catch (e) {
      emit(AdminError(extractApiError(e)));
    }
  }

  Future<void> _onUpdateSettings(
      UpdateSettingsEvent event, Emitter<AdminState> emit) async {
    // Keep the last-known settings visible behind the saving overlay.
    final current = _currentSettings();
    emit(SettingsSaving(current));
    try {
      final updated = await _repository.updateSettings(event.changes);
      emit(SettingsLoaded(updated, justSaved: true));
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        emit(const AdminNotAuthorized());
      } else {
        emit(SettingsSaveError(current, extractApiError(e)));
      }
    } catch (e) {
      emit(SettingsSaveError(current, extractApiError(e)));
    }
  }

  Map<String, dynamic> _currentSettings() {
    final s = state;
    if (s is SettingsLoaded) return s.settings;
    if (s is SettingsSaving) return s.settings;
    if (s is SettingsSaveError) return s.settings;
    return const {};
  }

  void _emitDioError(DioException e, Emitter<AdminState> emit) {
    if (e.response?.statusCode == 403) {
      emit(const AdminNotAuthorized());
    } else {
      emit(AdminError(extractApiError(e)));
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}
