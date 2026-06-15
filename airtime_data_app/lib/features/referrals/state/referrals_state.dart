// Referrals States
import 'package:equatable/equatable.dart';

abstract class ReferralsState extends Equatable {
  const ReferralsState();

  @override
  List<Object?> get props => [];
}

class ReferralsInitial extends ReferralsState {
  const ReferralsInitial();
}

class ReferralsLoading extends ReferralsState {
  const ReferralsLoading();
}

class ReferralsLoaded extends ReferralsState {
  final String referralCode;
  final int invitedCount;
  final double totalEarned;
  final double bonusPerReferral;

  const ReferralsLoaded({
    required this.referralCode,
    required this.invitedCount,
    required this.totalEarned,
    required this.bonusPerReferral,
  });

  @override
  List<Object?> get props =>
      [referralCode, invitedCount, totalEarned, bonusPerReferral];
}

class ReferralsError extends ReferralsState {
  final String message;

  const ReferralsError(this.message);

  @override
  List<Object?> get props => [message];
}
