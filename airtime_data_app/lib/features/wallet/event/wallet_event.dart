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