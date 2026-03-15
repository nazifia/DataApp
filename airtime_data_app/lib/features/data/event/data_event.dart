// Data Events
import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_event.freezed.dart';

@freezed
sealed class DataEvent with _$DataEvent {
  const factory DataEvent.purchaseData({
    required String network,
    required String planId,
    required String phoneNumber,
  }) = PurchaseDataEvent;
  const factory DataEvent.loadDataPlans(String network) = LoadDataPlansEvent;
}