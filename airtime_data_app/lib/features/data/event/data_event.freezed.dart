// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DataEvent {

 String get network;
/// Create a copy of DataEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataEventCopyWith<DataEvent> get copyWith => _$DataEventCopyWithImpl<DataEvent>(this as DataEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataEvent&&(identical(other.network, network) || other.network == network));
}


@override
int get hashCode => Object.hash(runtimeType,network);

@override
String toString() {
  return 'DataEvent(network: $network)';
}


}

/// @nodoc
abstract mixin class $DataEventCopyWith<$Res>  {
  factory $DataEventCopyWith(DataEvent value, $Res Function(DataEvent) _then) = _$DataEventCopyWithImpl;
@useResult
$Res call({
 String network
});




}
/// @nodoc
class _$DataEventCopyWithImpl<$Res>
    implements $DataEventCopyWith<$Res> {
  _$DataEventCopyWithImpl(this._self, this._then);

  final DataEvent _self;
  final $Res Function(DataEvent) _then;

/// Create a copy of DataEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? network = null,}) {
  return _then(_self.copyWith(
network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DataEvent].
extension DataEventPatterns on DataEvent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PurchaseDataEvent value)?  purchaseData,TResult Function( LoadDataPlansEvent value)?  loadDataPlans,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PurchaseDataEvent() when purchaseData != null:
return purchaseData(_that);case LoadDataPlansEvent() when loadDataPlans != null:
return loadDataPlans(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PurchaseDataEvent value)  purchaseData,required TResult Function( LoadDataPlansEvent value)  loadDataPlans,}){
final _that = this;
switch (_that) {
case PurchaseDataEvent():
return purchaseData(_that);case LoadDataPlansEvent():
return loadDataPlans(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PurchaseDataEvent value)?  purchaseData,TResult? Function( LoadDataPlansEvent value)?  loadDataPlans,}){
final _that = this;
switch (_that) {
case PurchaseDataEvent() when purchaseData != null:
return purchaseData(_that);case LoadDataPlansEvent() when loadDataPlans != null:
return loadDataPlans(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String network,  String planId,  String phoneNumber)?  purchaseData,TResult Function( String network)?  loadDataPlans,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PurchaseDataEvent() when purchaseData != null:
return purchaseData(_that.network,_that.planId,_that.phoneNumber);case LoadDataPlansEvent() when loadDataPlans != null:
return loadDataPlans(_that.network);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String network,  String planId,  String phoneNumber)  purchaseData,required TResult Function( String network)  loadDataPlans,}) {final _that = this;
switch (_that) {
case PurchaseDataEvent():
return purchaseData(_that.network,_that.planId,_that.phoneNumber);case LoadDataPlansEvent():
return loadDataPlans(_that.network);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String network,  String planId,  String phoneNumber)?  purchaseData,TResult? Function( String network)?  loadDataPlans,}) {final _that = this;
switch (_that) {
case PurchaseDataEvent() when purchaseData != null:
return purchaseData(_that.network,_that.planId,_that.phoneNumber);case LoadDataPlansEvent() when loadDataPlans != null:
return loadDataPlans(_that.network);case _:
  return null;

}
}

}

/// @nodoc


class PurchaseDataEvent implements DataEvent {
  const PurchaseDataEvent({required this.network, required this.planId, required this.phoneNumber});
  

@override final  String network;
 final  String planId;
 final  String phoneNumber;

/// Create a copy of DataEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PurchaseDataEventCopyWith<PurchaseDataEvent> get copyWith => _$PurchaseDataEventCopyWithImpl<PurchaseDataEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PurchaseDataEvent&&(identical(other.network, network) || other.network == network)&&(identical(other.planId, planId) || other.planId == planId)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber));
}


@override
int get hashCode => Object.hash(runtimeType,network,planId,phoneNumber);

@override
String toString() {
  return 'DataEvent.purchaseData(network: $network, planId: $planId, phoneNumber: $phoneNumber)';
}


}

/// @nodoc
abstract mixin class $PurchaseDataEventCopyWith<$Res> implements $DataEventCopyWith<$Res> {
  factory $PurchaseDataEventCopyWith(PurchaseDataEvent value, $Res Function(PurchaseDataEvent) _then) = _$PurchaseDataEventCopyWithImpl;
@override @useResult
$Res call({
 String network, String planId, String phoneNumber
});




}
/// @nodoc
class _$PurchaseDataEventCopyWithImpl<$Res>
    implements $PurchaseDataEventCopyWith<$Res> {
  _$PurchaseDataEventCopyWithImpl(this._self, this._then);

  final PurchaseDataEvent _self;
  final $Res Function(PurchaseDataEvent) _then;

/// Create a copy of DataEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? network = null,Object? planId = null,Object? phoneNumber = null,}) {
  return _then(PurchaseDataEvent(
network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,planId: null == planId ? _self.planId : planId // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LoadDataPlansEvent implements DataEvent {
  const LoadDataPlansEvent(this.network);
  

@override final  String network;

/// Create a copy of DataEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadDataPlansEventCopyWith<LoadDataPlansEvent> get copyWith => _$LoadDataPlansEventCopyWithImpl<LoadDataPlansEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadDataPlansEvent&&(identical(other.network, network) || other.network == network));
}


@override
int get hashCode => Object.hash(runtimeType,network);

@override
String toString() {
  return 'DataEvent.loadDataPlans(network: $network)';
}


}

/// @nodoc
abstract mixin class $LoadDataPlansEventCopyWith<$Res> implements $DataEventCopyWith<$Res> {
  factory $LoadDataPlansEventCopyWith(LoadDataPlansEvent value, $Res Function(LoadDataPlansEvent) _then) = _$LoadDataPlansEventCopyWithImpl;
@override @useResult
$Res call({
 String network
});




}
/// @nodoc
class _$LoadDataPlansEventCopyWithImpl<$Res>
    implements $LoadDataPlansEventCopyWith<$Res> {
  _$LoadDataPlansEventCopyWithImpl(this._self, this._then);

  final LoadDataPlansEvent _self;
  final $Res Function(LoadDataPlansEvent) _then;

/// Create a copy of DataEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? network = null,}) {
  return _then(LoadDataPlansEvent(
null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
