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