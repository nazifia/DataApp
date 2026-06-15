// Agents (POS) Bloc
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/agents_repository.dart';
import '../event/agents_event.dart';
import '../state/agents_state.dart';
import '../../../core/utils/api_error.dart';

class AgentsBloc extends Bloc<AgentsEvent, AgentsState> {
  final AgentsRepository _repository;

  AgentsBloc({required AgentsRepository repository})
      : _repository = repository,
        super(const AgentsInitial()) {
    on<LoadAgentDashboardEvent>(_onLoadDashboard);
    on<ApplyAgentEvent>(_onApply);
    on<MakeAgentSaleEvent>(_onSale);
  }

  Future<void> _onLoadDashboard(
      LoadAgentDashboardEvent event, Emitter<AgentsState> emit) async {
    emit(const AgentsLoading());
    try {
      final data = await _repository.getDashboard();
      emit(_dashboardFrom(data));
    } on DioException catch (e) {
      // 403 = the user has no agent account yet → offer to apply.
      if (e.response?.statusCode == 403) {
        emit(const AgentNotRegistered());
      } else {
        emit(AgentsError(extractApiError(e)));
      }
    } catch (e) {
      emit(AgentsError(extractApiError(e)));
    }
  }

  Future<void> _onApply(
      ApplyAgentEvent event, Emitter<AgentsState> emit) async {
    emit(const AgentApplying());
    try {
      await _repository.apply(event.businessName);
      emit(const AgentApplied());
      add(const LoadAgentDashboardEvent());
    } catch (e) {
      emit(AgentApplyFailed(extractApiError(e)));
    }
  }

  Future<void> _onSale(
      MakeAgentSaleEvent event, Emitter<AgentsState> emit) async {
    emit(const AgentSelling());
    try {
      final response = await _repository.sale(
        type: event.type,
        phoneNumber: event.phoneNumber,
        network: event.network,
        planId: event.planId,
        amount: event.amount,
        serviceId: event.serviceId,
        customerId: event.customerId,
        variationCode: event.variationCode,
      );
      final status =
          (response['status'] as String?)?.toLowerCase() ?? 'pending';
      if (status == 'failed') {
        emit(AgentSaleFailure(
            response['message']?.toString() ?? 'Sale failed'));
        return;
      }
      emit(AgentSaleSuccess(
        reference: response['reference']?.toString() ?? '',
        status: status,
        type: response['type']?.toString() ?? event.type,
        amount: double.tryParse(response['amount'].toString()) ??
            (event.amount ?? 0),
        customerPhone:
            response['customer_phone']?.toString() ?? event.phoneNumber,
        token: response['token']?.toString() ?? '',
      ));
    } catch (e) {
      emit(AgentSaleFailure(extractApiError(e)));
    }
  }

  AgentDashboardLoaded _dashboardFrom(Map<String, dynamic> data) {
    return AgentDashboardLoaded(
      agent: Map<String, dynamic>.from(data['agent'] as Map),
      totalSalesVolume:
          (data['total_sales_volume'] as num?)?.toDouble() ?? 0,
      totalSalesCount: (data['total_sales_count'] as num?)?.toInt() ?? 0,
      totalCommission: (data['total_commission'] as num?)?.toDouble() ?? 0,
      floatBalance: (data['float_balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
