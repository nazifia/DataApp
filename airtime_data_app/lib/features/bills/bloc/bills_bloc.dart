// Bills Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/bills_repository.dart';
import '../event/bills_event.dart';
import '../state/bills_state.dart';
import '../../../core/utils/api_error.dart';

class BillsBloc extends Bloc<BillsEvent, BillsState> {
  final BillsRepository _repository;

  BillsBloc({required BillsRepository repository})
      : _repository = repository,
        super(const BillsInitial()) {
    on<LoadProvidersEvent>(_onLoadProviders);
    on<LoadVariationsEvent>(_onLoadVariations);
    on<VerifyCustomerEvent>(_onVerifyCustomer);
    on<PayBillEvent>(_onPayBill);
  }

  Future<void> _onLoadProviders(
      LoadProvidersEvent event, Emitter<BillsState> emit) async {
    emit(const ProvidersLoading());
    try {
      final providers = await _repository.getProviders(event.category);
      emit(ProvidersSuccess(providers));
    } catch (e) {
      emit(ProvidersFailure(extractApiError(e)));
    }
  }

  Future<void> _onLoadVariations(
      LoadVariationsEvent event, Emitter<BillsState> emit) async {
    emit(const VariationsLoading());
    try {
      final variations =
          await _repository.getVariations(event.category, event.serviceId);
      emit(VariationsSuccess(variations));
    } catch (e) {
      emit(VariationsFailure(extractApiError(e)));
    }
  }

  Future<void> _onVerifyCustomer(
      VerifyCustomerEvent event, Emitter<BillsState> emit) async {
    emit(const CustomerVerifying());
    try {
      final result = await _repository.verifyCustomer(
          event.serviceId, event.customerId, event.variationCode);
      if (result['success'] == true) {
        emit(CustomerVerified(
          customerName: result['customer_name']?.toString() ?? '',
          customerId: result['customer_id']?.toString() ?? event.customerId,
        ));
      } else {
        emit(CustomerVerifyFailed(
            result['message']?.toString() ?? 'Could not verify customer'));
      }
    } catch (e) {
      emit(CustomerVerifyFailed(extractApiError(e)));
    }
  }

  Future<void> _onPayBill(
      PayBillEvent event, Emitter<BillsState> emit) async {
    emit(const BillPaying());
    try {
      final response = await _repository.payBill(
        category: event.category,
        serviceId: event.serviceId,
        customerId: event.customerId,
        variationCode: event.variationCode,
        amount: event.amount,
        phoneNumber: event.phoneNumber,
      );
      final status = (response['status'] as String?)?.toLowerCase() ?? 'pending';
      if (status == 'failed') {
        emit(BillFailure(response['message']?.toString() ?? 'Payment failed'));
        return;
      }
      emit(BillSuccess(
        reference: response['reference']?.toString() ?? '',
        status: status,
        amount: double.tryParse(response['amount'].toString()) ?? event.amount,
        category: response['category']?.toString() ?? event.category,
        provider: response['provider']?.toString() ?? event.serviceId,
        customerId: response['customer_id']?.toString() ?? event.customerId,
        token: response['token']?.toString() ?? '',
      ));
    } catch (e) {
      emit(BillFailure(extractApiError(e)));
    }
  }
}
