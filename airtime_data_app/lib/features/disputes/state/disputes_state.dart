// Disputes States
import 'package:equatable/equatable.dart';

abstract class DisputesState extends Equatable {
  const DisputesState();

  @override
  List<Object?> get props => [];
}

class DisputesInitial extends DisputesState {
  const DisputesInitial();
}

class DisputesLoading extends DisputesState {
  const DisputesLoading();
}

class DisputesLoaded extends DisputesState {
  final List<Map<String, dynamic>> disputes;

  const DisputesLoaded(this.disputes);

  @override
  List<Object?> get props => [disputes];
}

class DisputesError extends DisputesState {
  final String message;

  const DisputesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Creation lifecycle (emitted while the list stays rendered from cache).
class DisputeCreating extends DisputesState {
  const DisputeCreating();
}

class DisputeCreated extends DisputesState {
  const DisputeCreated();
}

class DisputeCreateFailed extends DisputesState {
  final String message;

  const DisputeCreateFailed(this.message);

  @override
  List<Object?> get props => [message];
}
