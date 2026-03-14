// Data Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data_repository.dart';
import '../event/data_event.dart';
import '../state/data_state.dart';

class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository _dataRepository;

  DataBloc({required DataRepository dataRepository})
      : _dataRepository = dataRepository,
        super(const DataState.initial()) {
    on<PurchaseDataEvent>(_onPurchaseData);
    on<LoadDataPlansEvent>(_onLoadDataPlans);
  }

  Future<void> _onPurchaseData(
      PurchaseDataEvent event, Emitter<DataState> emit) async {
    emit(const DataState.loading());
    try {
      final response = await _dataRepository.purchaseData(
        event.network,
        event.planId,
        event.phoneNumber,
      );
      emit(DataState.success(
        reference: response['reference'].toString(),
        amount: double.tryParse(response['amount'].toString()) ?? 0,
        network: event.network,
        planName: response['plan_name'].toString(),
        phoneNumber: event.phoneNumber,
        data: response['data'].toString(),
        validity: response['validity'].toString(),
      ));
    } catch (e) {
      emit(DataState.failure('Failed to purchase data: $e'));
    }
  }

  Future<void> _onLoadDataPlans(
      LoadDataPlansEvent event, Emitter<DataState> emit) async {
    emit(const DataState.plansLoading());
    try {
      final response = await _dataRepository.getDataPlans(event.network);
      emit(DataState.plansSuccess(List<Map<String, dynamic>>.from(response['plans'] as List)));
    } catch (e) {
      emit(DataState.plansFailure('Failed to load data plans: $e'));
    }
  }
}