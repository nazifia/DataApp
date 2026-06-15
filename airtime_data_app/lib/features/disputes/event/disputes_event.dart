// Disputes Events
import 'package:equatable/equatable.dart';

abstract class DisputesEvent extends Equatable {
  const DisputesEvent();

  @override
  List<Object> get props => [];
}

class LoadDisputesEvent extends DisputesEvent {
  const LoadDisputesEvent();
}

class CreateDisputeEvent extends DisputesEvent {
  final String subject;
  final String message;
  final String transactionReference;

  const CreateDisputeEvent({
    required this.subject,
    required this.message,
    this.transactionReference = '',
  });

  @override
  List<Object> get props => [subject, message, transactionReference];
}
