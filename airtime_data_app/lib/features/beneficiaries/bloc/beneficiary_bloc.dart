import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/beneficiary_repository.dart';
import '../event/beneficiary_event.dart';
import '../state/beneficiary_state.dart';
import '../../../core/utils/api_error.dart';

class BeneficiaryBloc extends Bloc<BeneficiaryEvent, BeneficiaryState> {
  final BeneficiaryRepository _repo;

  BeneficiaryBloc({required BeneficiaryRepository repository})
      : _repo = repository,
        super(const BeneficiaryInitial()) {
    on<LoadBeneficiariesEvent>(_onLoad);
    on<SaveBeneficiaryEvent>(_onSave);
    on<DeleteBeneficiaryEvent>(_onDelete);
    on<UpdateBeneficiaryNicknameEvent>(_onUpdateNickname);
  }

  Future<void> _onLoad(LoadBeneficiariesEvent event, Emitter<BeneficiaryState> emit) async {
    emit(const BeneficiaryLoading());
    try {
      final list = await _repo.getBeneficiaries(type: event.type);
      emit(BeneficiaryLoaded(list));
    } catch (e) {
      emit(BeneficiaryFailure(extractApiError(e)));
    }
  }

  Future<void> _onSave(SaveBeneficiaryEvent event, Emitter<BeneficiaryState> emit) async {
    try {
      final b = await _repo.saveBeneficiary(
        phoneNumber: event.phoneNumber,
        network: event.network,
        type: event.type,
        nickname: event.nickname,
      );
      emit(BeneficiarySaved(b));
      // Reload list
      final list = await _repo.getBeneficiaries(type: event.type);
      emit(BeneficiaryLoaded(list));
    } catch (e) {
      emit(BeneficiaryFailure(extractApiError(e)));
    }
  }

  Future<void> _onDelete(DeleteBeneficiaryEvent event, Emitter<BeneficiaryState> emit) async {
    try {
      await _repo.deleteBeneficiary(event.id);
      final list = await _repo.getBeneficiaries();
      emit(BeneficiaryLoaded(list));
    } catch (e) {
      emit(BeneficiaryFailure(extractApiError(e)));
    }
  }

  Future<void> _onUpdateNickname(UpdateBeneficiaryNicknameEvent event, Emitter<BeneficiaryState> emit) async {
    try {
      await _repo.updateNickname(event.id, event.nickname);
      final list = await _repo.getBeneficiaries();
      emit(BeneficiaryLoaded(list));
    } catch (e) {
      emit(BeneficiaryFailure(extractApiError(e)));
    }
  }
}
