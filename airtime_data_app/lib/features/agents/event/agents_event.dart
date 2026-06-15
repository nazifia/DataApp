// Agents (POS) Events
import 'package:equatable/equatable.dart';

abstract class AgentsEvent extends Equatable {
  const AgentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAgentDashboardEvent extends AgentsEvent {
  const LoadAgentDashboardEvent();
}

class ApplyAgentEvent extends AgentsEvent {
  final String businessName;

  const ApplyAgentEvent(this.businessName);

  @override
  List<Object?> get props => [businessName];
}

class MakeAgentSaleEvent extends AgentsEvent {
  final String type; // airtime | data | electricity | tv
  final String phoneNumber;
  final String network;
  final String planId;
  final double? amount;
  final String serviceId;
  final String customerId;
  final String variationCode;

  const MakeAgentSaleEvent({
    required this.type,
    required this.phoneNumber,
    this.network = '',
    this.planId = '',
    this.amount,
    this.serviceId = '',
    this.customerId = '',
    this.variationCode = '',
  });

  @override
  List<Object?> get props => [
        type,
        phoneNumber,
        network,
        planId,
        amount,
        serviceId,
        customerId,
        variationCode,
      ];
}
