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

class PaystackPaymentInitiated extends WalletState {
  final String authorizationUrl;
  final String reference;
  final double amount;

  const PaystackPaymentInitiated({
    required this.authorizationUrl,
    required this.reference,
    required this.amount,
  });

  @override
  List<Object> get props => [authorizationUrl, reference, amount];
}

// ─── Withdrawal flow ─────────────────────────────────────────────────────────

class BanksLoading extends WalletState {
  const BanksLoading();
}

class BanksLoaded extends WalletState {
  final List<Map<String, dynamic>> banks;
  const BanksLoaded(this.banks);

  @override
  List<Object> get props => [banks];
}

class BanksLoadFailure extends WalletState {
  final String message;
  const BanksLoadFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AccountResolving extends WalletState {
  const AccountResolving();
}

class AccountResolved extends WalletState {
  final String accountName;
  const AccountResolved(this.accountName);

  @override
  List<Object> get props => [accountName];
}

class AccountResolveFailure extends WalletState {
  final String message;
  const AccountResolveFailure(this.message);

  @override
  List<Object> get props => [message];
}

class WithdrawProcessing extends WalletState {
  const WithdrawProcessing();
}

class WithdrawSuccess extends WalletState {
  final double balance;
  final double amount;
  final String message;

  const WithdrawSuccess(
      {required this.balance, required this.amount, required this.message});

  @override
  List<Object> get props => [balance, amount, message];
}

class WithdrawFailure extends WalletState {
  final String message;
  const WithdrawFailure(this.message);

  @override
  List<Object> get props => [message];
}