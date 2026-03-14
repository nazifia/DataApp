// Airtime Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/airtime_repository.dart';
import '../event/airtime_event.dart';
import '../state/airtime_state.dart';

class AirtimeBloc extends Bloc<AirtimeEvent, AirtimeState> {
  final AirtimeRepository _airtimeRepository;

  AirtimeBloc({required AirtimeRepository airtimeRepository})
      : _airtimeRepository = airtimeRepository,
        super(const AirtimeInitial()) {
    on<PurchaseAirtimeEvent>(_onPurchaseAirtime);
  }

  Future<void> _onPurchaseAirtime(
      PurchaseAirtimeEvent event, Emitter<AirtimeState> emit) async {
    emit(const AirtimeLoading());
    try {
      final response = await _airtimeRepository.purchaseAirtime(
        event.network,
        event.phoneNumber,
        event.amount,
      );
      emit(AirtimeSuccess(
        reference: response['reference'].toString(),
        amount: event.amount,
        network: event.network,
        phoneNumber: event.phoneNumber,
      ));
    } catch (e) {
      emit(AirtimeFailure('Failed to purchase airtime: $e'));
    }
  }
}