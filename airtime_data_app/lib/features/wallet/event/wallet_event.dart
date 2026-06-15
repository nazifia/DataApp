// Wallet Events
import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

class LoadWalletEvent extends WalletEvent {
  const LoadWalletEvent();
}

class FundWalletEvent extends WalletEvent {
  final double amount;

  const FundWalletEvent(this.amount);

  @override
  List<Object> get props => [amount];
}

class LoadBankDetailsEvent extends WalletEvent {
  const LoadBankDetailsEvent();
}

class InitiatePaystackPaymentEvent extends WalletEvent {
  final double amount;
  const InitiatePaystackPaymentEvent(this.amount);

  @override
  List<Object> get props => [amount];
}

class LoadBanksEvent extends WalletEvent {
  const LoadBanksEvent();
}

class ResolveAccountEvent extends WalletEvent {
  final String accountNumber;
  final String bankCode;
  const ResolveAccountEvent({required this.accountNumber, required this.bankCode});

  @override
  List<Object> get props => [accountNumber, bankCode];
}

class WithdrawEvent extends WalletEvent {
  final double amount;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;

  const WithdrawEvent({
    required this.amount,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  @override
  List<Object> get props =>
      [amount, bankCode, bankName, accountNumber, accountName];
}