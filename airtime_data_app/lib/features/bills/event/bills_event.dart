// Bills Events
import 'package:equatable/equatable.dart';

abstract class BillsEvent extends Equatable {
  const BillsEvent();

  @override
  List<Object> get props => [];
}

class LoadProvidersEvent extends BillsEvent {
  final String category; // 'electricity' | 'tv'

  const LoadProvidersEvent(this.category);

  @override
  List<Object> get props => [category];
}

class LoadVariationsEvent extends BillsEvent {
  final String category;
  final String serviceId;

  const LoadVariationsEvent(this.category, this.serviceId);

  @override
  List<Object> get props => [category, serviceId];
}

class VerifyCustomerEvent extends BillsEvent {
  final String serviceId;
  final String customerId;
  final String variationCode;

  const VerifyCustomerEvent({
    required this.serviceId,
    required this.customerId,
    this.variationCode = '',
  });

  @override
  List<Object> get props => [serviceId, customerId, variationCode];
}

class PayBillEvent extends BillsEvent {
  final String category;
  final String serviceId;
  final String customerId;
  final String variationCode;
  final double amount;
  final String phoneNumber;

  const PayBillEvent({
    required this.category,
    required this.serviceId,
    required this.customerId,
    required this.amount,
    required this.phoneNumber,
    this.variationCode = '',
  });

  @override
  List<Object> get props =>
      [category, serviceId, customerId, variationCode, amount, phoneNumber];
}
