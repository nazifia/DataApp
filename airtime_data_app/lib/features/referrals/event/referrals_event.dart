// Referrals Events
import 'package:equatable/equatable.dart';

abstract class ReferralsEvent extends Equatable {
  const ReferralsEvent();

  @override
  List<Object> get props => [];
}

class LoadReferralsEvent extends ReferralsEvent {
  const LoadReferralsEvent();
}
