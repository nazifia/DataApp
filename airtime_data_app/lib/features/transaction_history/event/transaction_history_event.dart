// Transaction History Events
import 'package:equatable/equatable.dart';

abstract class TransactionHistoryEvent extends Equatable {
  const TransactionHistoryEvent();

  @override
  List<Object> get props => [];
}

class LoadTransactionHistoryEvent extends TransactionHistoryEvent {
  const LoadTransactionHistoryEvent();
}

class RefreshTransactionHistoryEvent extends TransactionHistoryEvent {
  const RefreshTransactionHistoryEvent();
}

class ReverseTransactionEvent extends TransactionHistoryEvent {
  final String transactionId;

  const ReverseTransactionEvent(this.transactionId);

  @override
  List<Object> get props => [transactionId];
}