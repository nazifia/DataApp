// Agents (POS) States
import 'package:equatable/equatable.dart';

abstract class AgentsState extends Equatable {
  const AgentsState();

  @override
  List<Object?> get props => [];
}

class AgentsInitial extends AgentsState {
  const AgentsInitial();
}

class AgentsLoading extends AgentsState {
  const AgentsLoading();
}

// Caller is not an agent yet — show the apply screen.
class AgentNotRegistered extends AgentsState {
  const AgentNotRegistered();
}

class AgentDashboardLoaded extends AgentsState {
  final Map<String, dynamic> agent;
  final double totalSalesVolume;
  final int totalSalesCount;
  final double totalCommission;
  final double floatBalance;

  const AgentDashboardLoaded({
    required this.agent,
    required this.totalSalesVolume,
    required this.totalSalesCount,
    required this.totalCommission,
    required this.floatBalance,
  });

  String get status => (agent['status'] ?? '').toString();
  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
        agent,
        totalSalesVolume,
        totalSalesCount,
        totalCommission,
        floatBalance,
      ];
}

class AgentsError extends AgentsState {
  final String message;

  const AgentsError(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Apply lifecycle ---
class AgentApplying extends AgentsState {
  const AgentApplying();
}

class AgentApplied extends AgentsState {
  const AgentApplied();
}

class AgentApplyFailed extends AgentsState {
  final String message;

  const AgentApplyFailed(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Sale lifecycle ---
class AgentSelling extends AgentsState {
  const AgentSelling();
}

class AgentSaleSuccess extends AgentsState {
  final String reference;
  final String status;
  final String type;
  final double amount;
  final String customerPhone;
  final String token;

  const AgentSaleSuccess({
    required this.reference,
    required this.status,
    required this.type,
    required this.amount,
    required this.customerPhone,
    required this.token,
  });

  @override
  List<Object?> get props =>
      [reference, status, type, amount, customerPhone, token];
}

class AgentSaleFailure extends AgentsState {
  final String message;

  const AgentSaleFailure(this.message);

  @override
  List<Object?> get props => [message];
}
