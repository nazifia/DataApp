// Wallet States
import 'package:equatable/equatable.dart';

abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object> get props => [];
}

class WalletInitial extends WalletState {
  const WalletInitial();
}

class WalletLoading extends WalletState {
  const WalletLoading();
}

class WalletSuccess extends WalletState {
  final double balance;

  const WalletSuccess(this.balance);

  @override
  List<Object> get props => [balance];
}

class FundWalletSuccess extends WalletState {
  final double balance;
  final double amount;

  const FundWalletSuccess({required this.balance, required this.amount});

  @override
  List<Object> get props => [balance, amount];
}

class WalletFailure extends WalletState {
  final String message;

  const WalletFailure(this.message);

  @override
  List<Object> get props => [message];
}

class BankDetailsLoaded extends WalletState {
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String note;

  const BankDetailsLoaded({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.note,
  });

  @override
  List<Object> get props => [bankName, accountNumber, accountName, note];
}