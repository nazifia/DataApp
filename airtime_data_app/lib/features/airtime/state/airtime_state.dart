// Airtime States
import 'package:equatable/equatable.dart';

abstract class AirtimeState extends Equatable {
  const AirtimeState();

  @override
  List<Object> get props => [];
}

class AirtimeInitial extends AirtimeState {
  const AirtimeInitial();
}

class AirtimeLoading extends AirtimeState {
  const AirtimeLoading();
}

class AirtimeSuccess extends AirtimeState {
  final String reference;
  final double amount;
  final String network;
  final String phoneNumber;

  const AirtimeSuccess({
    required this.reference,
    required this.amount,
    required this.network,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [reference, amount, network, phoneNumber];
}

class AirtimeFailure extends AirtimeState {
  final String message;

  const AirtimeFailure(this.message);

  @override
  List<Object> get props => [message];
}