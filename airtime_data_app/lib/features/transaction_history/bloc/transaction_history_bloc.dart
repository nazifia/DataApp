// Transaction History Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/transaction_history_repository.dart';
import '../event/transaction_history_event.dart';
import '../state/transaction_history_state.dart';

class TransactionHistoryBloc extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  final TransactionHistoryRepository _transactionHistoryRepository;

  TransactionHistoryBloc({required TransactionHistoryRepository transactionHistoryRepository})
      : _transactionHistoryRepository = transactionHistoryRepository,
        super(const TransactionHistoryInitial()) {
    on<LoadTransactionHistoryEvent>(_onLoadTransactionHistory);
    on<RefreshTransactionHistoryEvent>(_onRefreshTransactionHistory);
  }

  Future<void> _onLoadTransactionHistory(
      LoadTransactionHistoryEvent event, Emitter<TransactionHistoryState> emit) async {
    emit(const TransactionHistoryLoading());
    try {
      final response = await _transactionHistoryRepository.getTransactionHistory();
      emit(TransactionHistorySuccess(List<Map<String, dynamic>>.from(response['transactions'] as List)));
    } catch (e) {
      emit(TransactionHistoryFailure('Failed to load transaction history: $e'));
    }
  }

  Future<void> _onRefreshTransactionHistory(
      RefreshTransactionHistoryEvent event, Emitter<TransactionHistoryState> emit) async {
    emit(const TransactionHistoryLoading());
    try {
      final response = await _transactionHistoryRepository.getTransactionHistory();
      emit(TransactionHistorySuccess(List<Map<String, dynamic>>.from(response['transactions'] as List)));
    } catch (e) {
      emit(TransactionHistoryFailure('Failed to refresh transaction history: $e'));
    }
  }
}