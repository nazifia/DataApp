// Transaction History States
import 'package:equatable/equatable.dart';

abstract class TransactionHistoryState extends Equatable {
  const TransactionHistoryState();

  @override
  List<Object> get props => [];
}

class TransactionHistoryInitial extends TransactionHistoryState {
  const TransactionHistoryInitial();
}

class TransactionHistoryLoading extends TransactionHistoryState {
  const TransactionHistoryLoading();
}

class TransactionHistorySuccess extends TransactionHistoryState {
  final List<Map<String, dynamic>> transactions;

  const TransactionHistorySuccess(this.transactions);

  @override
  List<Object> get props => [transactions];
}

class TransactionHistoryFailure extends TransactionHistoryState {
  final String message;

  const TransactionHistoryFailure(this.message);

  @override
  List<Object> get props => [message];
}