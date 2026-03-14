// Airtime Events
import 'package:equatable/equatable.dart';

abstract class AirtimeEvent extends Equatable {
  const AirtimeEvent();

  @override
  List<Object> get props => [];
}

class PurchaseAirtimeEvent extends AirtimeEvent {
  final String network;
  final String phoneNumber;
  final double amount;

  const PurchaseAirtimeEvent({
    required this.network,
    required this.phoneNumber,
    required this.amount,
  });

  @override
  List<Object> get props => [network, phoneNumber, amount];
}