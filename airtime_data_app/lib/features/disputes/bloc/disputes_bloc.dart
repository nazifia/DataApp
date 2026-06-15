// Disputes Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/disputes_repository.dart';
import '../event/disputes_event.dart';
import '../state/disputes_state.dart';
import '../../../core/utils/api_error.dart';

class DisputesBloc extends Bloc<DisputesEvent, DisputesState> {
  final DisputesRepository _repository;

  DisputesBloc({required DisputesRepository repository})
      : _repository = repository,
        super(const DisputesInitial()) {
    on<LoadDisputesEvent>(_onLoad);
    on<CreateDisputeEvent>(_onCreate);
  }

  Future<void> _onLoad(
      LoadDisputesEvent event, Emitter<DisputesState> emit) async {
    emit(const DisputesLoading());
    try {
      final disputes = await _repository.getDisputes();
      emit(DisputesLoaded(disputes));
    } catch (e) {
      emit(DisputesError(extractApiError(e)));
    }
  }

  Future<void> _onCreate(
      CreateDisputeEvent event, Emitter<DisputesState> emit) async {
    emit(const DisputeCreating());
    try {
      await _repository.createDispute(
        subject: event.subject,
        message: event.message,
        transactionReference: event.transactionReference,
      );
      emit(const DisputeCreated());
      // Refresh the list after a successful raise.
      add(const LoadDisputesEvent());
    } catch (e) {
      emit(DisputeCreateFailed(extractApiError(e)));
    }
  }
}
