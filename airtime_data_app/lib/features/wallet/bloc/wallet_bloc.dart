// Wallet Bloc
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/wallet_repository.dart';
import '../event/wallet_event.dart';
import '../state/wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(const WalletInitial()) {
    on<LoadWalletEvent>(_onLoadWallet);
    on<FundWalletEvent>(_onFundWallet);
    on<LoadBankDetailsEvent>(_onLoadBankDetails);
  }

  Future<void> _onLoadWallet(
      LoadWalletEvent event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final response = await _walletRepository.getWalletBalance();
      emit(WalletSuccess((response['balance'] as num).toDouble()));
    } catch (e) {
      emit(WalletFailure('Failed to load wallet: $e'));
    }
  }

  Future<void> _onLoadBankDetails(
      LoadBankDetailsEvent event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final data = await _walletRepository.getBankTransferDetails();
      emit(BankDetailsLoaded(
        bankName: data['bank_name'] as String,
        accountNumber: data['account_number'] as String,
        accountName: data['account_name'] as String,
        note: data['note'] as String,
      ));
    } catch (e) {
      emit(WalletFailure('Failed to load bank details: $e'));
    }
  }

  Future<void> _onFundWallet(
      FundWalletEvent event, Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    try {
      final response = await _walletRepository.fundWallet(event.amount);
      final status = (response['status'] as String?)?.toLowerCase();
      if (status != null && status != 'success') {
        emit(WalletFailure(
            response['message']?.toString() ?? 'Wallet funding failed'));
        return;
      }
      final balance = (response['balance'] as num?)?.toDouble() ?? 0.0;
      emit(FundWalletSuccess(balance: balance, amount: event.amount));
    } catch (e) {
      emit(WalletFailure('Failed to fund wallet: $e'));
    }
  }
}