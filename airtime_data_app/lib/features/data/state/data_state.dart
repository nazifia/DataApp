// Data States
import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_state.freezed.dart';

@freezed
class DataState with _$DataState {
  const factory DataState.initial() = DataInitial;
  const factory DataState.loading() = DataLoading;
  const factory DataState.success({
    required String reference,
    required double amount,
    required String network,
    required String planName,
    required String phoneNumber,
    required String data,
    required String validity,
  }) = DataSuccess;
  const factory DataState.failure(String message) = DataFailure;

  // Data Plans State
  const factory DataState.plansLoading() = DataPlansLoading;
  const factory DataState.plansSuccess(List<Map<String, dynamic>> plans) = DataPlansSuccess;
  const factory DataState.plansFailure(String message) = DataPlansFailure;
}