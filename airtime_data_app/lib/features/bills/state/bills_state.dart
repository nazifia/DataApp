// Bills States
import 'package:equatable/equatable.dart';

abstract class BillsState extends Equatable {
  const BillsState();

  @override
  List<Object?> get props => [];
}

class BillsInitial extends BillsState {
  const BillsInitial();
}

// --- Providers ---
class ProvidersLoading extends BillsState {
  const ProvidersLoading();
}

class ProvidersSuccess extends BillsState {
  final List<Map<String, dynamic>> providers;

  const ProvidersSuccess(this.providers);

  @override
  List<Object?> get props => [providers];
}

class ProvidersFailure extends BillsState {
  final String message;

  const ProvidersFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Variations (TV packages / meter types) ---
class VariationsLoading extends BillsState {
  const VariationsLoading();
}

class VariationsSuccess extends BillsState {
  final List<Map<String, dynamic>> variations;

  const VariationsSuccess(this.variations);

  @override
  List<Object?> get props => [variations];
}

class VariationsFailure extends BillsState {
  final String message;

  const VariationsFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Customer verification ---
class CustomerVerifying extends BillsState {
  const CustomerVerifying();
}

class CustomerVerified extends BillsState {
  final String customerName;
  final String customerId;

  const CustomerVerified({required this.customerName, required this.customerId});

  @override
  List<Object?> get props => [customerName, customerId];
}

class CustomerVerifyFailed extends BillsState {
  final String message;

  const CustomerVerifyFailed(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Payment ---
class BillPaying extends BillsState {
  const BillPaying();
}

class BillSuccess extends BillsState {
  final String reference;
  final String status;
  final double amount;
  final String category;
  final String provider;
  final String customerId;
  final String token;

  const BillSuccess({
    required this.reference,
    required this.status,
    required this.amount,
    required this.category,
    required this.provider,
    required this.customerId,
    required this.token,
  });

  @override
  List<Object?> get props =>
      [reference, status, amount, category, provider, customerId, token];
}

class BillFailure extends BillsState {
  final String message;

  const BillFailure(this.message);

  @override
  List<Object?> get props => [message];
}
