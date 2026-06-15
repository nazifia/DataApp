// Referrals Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/referrals_repository.dart';
import '../event/referrals_event.dart';
import '../state/referrals_state.dart';
import '../../../core/utils/api_error.dart';

class ReferralsBloc extends Bloc<ReferralsEvent, ReferralsState> {
  final ReferralsRepository _repository;

  ReferralsBloc({required ReferralsRepository repository})
      : _repository = repository,
        super(const ReferralsInitial()) {
    on<LoadReferralsEvent>(_onLoad);
  }

  Future<void> _onLoad(
      LoadReferralsEvent event, Emitter<ReferralsState> emit) async {
    emit(const ReferralsLoading());
    try {
      final data = await _repository.getReferrals();
      emit(ReferralsLoaded(
        referralCode: data['referral_code']?.toString() ?? '',
        invitedCount: (data['invited_count'] as num?)?.toInt() ?? 0,
        totalEarned: (data['total_earned'] as num?)?.toDouble() ?? 0,
        bonusPerReferral: (data['bonus_per_referral'] as num?)?.toDouble() ?? 0,
      ));
    } catch (e) {
      emit(ReferralsError(extractApiError(e)));
    }
  }
}
