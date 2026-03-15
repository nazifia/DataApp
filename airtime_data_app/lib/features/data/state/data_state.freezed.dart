// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DataState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataState()';
}


}

/// @nodoc
class $DataStateCopyWith<$Res>  {
$DataStateCopyWith(DataState _, $Res Function(DataState) __);
}


/// Adds pattern-matching-related methods to [DataState].
extension DataStatePatterns on DataState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DataInitial value)?  initial,TResult Function( DataLoading value)?  loading,TResult Function( DataSuccess value)?  success,TResult Function( DataFailure value)?  failure,TResult Function( DataPlansLoading value)?  plansLoading,TResult Function( DataPlansSuccess value)?  plansSuccess,TResult Function( DataPlansFailure value)?  plansFailure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DataInitial() when initial != null:
return initial(_that);case DataLoading() when loading != null:
return loading(_that);case DataSuccess() when success != null:
return success(_that);case DataFailure() when failure != null:
return failure(_that);case DataPlansLoading() when plansLoading != null:
return plansLoading(_that);case DataPlansSuccess() when plansSuccess != null:
return plansSuccess(_that);case DataPlansFailure() when plansFailure != null:
return plansFailure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DataInitial value)  initial,required TResult Function( DataLoading value)  loading,required TResult Function( DataSuccess value)  success,required TResult Function( DataFailure value)  failure,required TResult Function( DataPlansLoading value)  plansLoading,required TResult Function( DataPlansSuccess value)  plansSuccess,required TResult Function( DataPlansFailure value)  plansFailure,}){
final _that = this;
switch (_that) {
case DataInitial():
return initial(_that);case DataLoading():
return loading(_that);case DataSuccess():
return success(_that);case DataFailure():
return failure(_that);case DataPlansLoading():
return plansLoading(_that);case DataPlansSuccess():
return plansSuccess(_that);case DataPlansFailure():
return plansFailure(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DataInitial value)?  initial,TResult? Function( DataLoading value)?  loading,TResult? Function( DataSuccess value)?  success,TResult? Function( DataFailure value)?  failure,TResult? Function( DataPlansLoading value)?  plansLoading,TResult? Function( DataPlansSuccess value)?  plansSuccess,TResult? Function( DataPlansFailure value)?  plansFailure,}){
final _that = this;
switch (_that) {
case DataInitial() when initial != null:
return initial(_that);case DataLoading() when loading != null:
return loading(_that);case DataSuccess() when success != null:
return success(_that);case DataFailure() when failure != null:
return failure(_that);case DataPlansLoading() when plansLoading != null:
return plansLoading(_that);case DataPlansSuccess() when plansSuccess != null:
return plansSuccess(_that);case DataPlansFailure() when plansFailure != null:
return plansFailure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( String reference,  double amount,  String network,  String planName,  String phoneNumber,  String data,  String validity)?  success,TResult Function( String message)?  failure,TResult Function()?  plansLoading,TResult Function( List<Map<String, dynamic>> plans)?  plansSuccess,TResult Function( String message)?  plansFailure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DataInitial() when initial != null:
return initial();case DataLoading() when loading != null:
return loading();case DataSuccess() when success != null:
return success(_that.reference,_that.amount,_that.network,_that.planName,_that.phoneNumber,_that.data,_that.validity);case DataFailure() when failure != null:
return failure(_that.message);case DataPlansLoading() when plansLoading != null:
return plansLoading();case DataPlansSuccess() when plansSuccess != null:
return plansSuccess(_that.plans);case DataPlansFailure() when plansFailure != null:
return plansFailure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( String reference,  double amount,  String network,  String planName,  String phoneNumber,  String data,  String validity)  success,required TResult Function( String message)  failure,required TResult Function()  plansLoading,required TResult Function( List<Map<String, dynamic>> plans)  plansSuccess,required TResult Function( String message)  plansFailure,}) {final _that = this;
switch (_that) {
case DataInitial():
return initial();case DataLoading():
return loading();case DataSuccess():
return success(_that.reference,_that.amount,_that.network,_that.planName,_that.phoneNumber,_that.data,_that.validity);case DataFailure():
return failure(_that.message);case DataPlansLoading():
return plansLoading();case DataPlansSuccess():
return plansSuccess(_that.plans);case DataPlansFailure():
return plansFailure(_that.message);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( String reference,  double amount,  String network,  String planName,  String phoneNumber,  String data,  String validity)?  success,TResult? Function( String message)?  failure,TResult? Function()?  plansLoading,TResult? Function( List<Map<String, dynamic>> plans)?  plansSuccess,TResult? Function( String message)?  plansFailure,}) {final _that = this;
switch (_that) {
case DataInitial() when initial != null:
return initial();case DataLoading() when loading != null:
return loading();case DataSuccess() when success != null:
return success(_that.reference,_that.amount,_that.network,_that.planName,_that.phoneNumber,_that.data,_that.validity);case DataFailure() when failure != null:
return failure(_that.message);case DataPlansLoading() when plansLoading != null:
return plansLoading();case DataPlansSuccess() when plansSuccess != null:
return plansSuccess(_that.plans);case DataPlansFailure() when plansFailure != null:
return plansFailure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class DataInitial implements DataState {
  const DataInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataState.initial()';
}


}




/// @nodoc


class DataLoading implements DataState {
  const DataLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataState.loading()';
}


}




/// @nodoc


class DataSuccess implements DataState {
  const DataSuccess({required this.reference, required this.amount, required this.network, required this.planName, required this.phoneNumber, required this.data, required this.validity});
  

 final  String reference;
 final  double amount;
 final  String network;
 final  String planName;
 final  String phoneNumber;
 final  String data;
 final  String validity;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataSuccessCopyWith<DataSuccess> get copyWith => _$DataSuccessCopyWithImpl<DataSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataSuccess&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.network, network) || other.network == network)&&(identical(other.planName, planName) || other.planName == planName)&&(identical(other.phoneNumber, phoneNumber) || other.phoneNumber == phoneNumber)&&(identical(other.data, data) || other.data == data)&&(identical(other.validity, validity) || other.validity == validity));
}


@override
int get hashCode => Object.hash(runtimeType,reference,amount,network,planName,phoneNumber,data,validity);

@override
String toString() {
  return 'DataState.success(reference: $reference, amount: $amount, network: $network, planName: $planName, phoneNumber: $phoneNumber, data: $data, validity: $validity)';
}


}

/// @nodoc
abstract mixin class $DataSuccessCopyWith<$Res> implements $DataStateCopyWith<$Res> {
  factory $DataSuccessCopyWith(DataSuccess value, $Res Function(DataSuccess) _then) = _$DataSuccessCopyWithImpl;
@useResult
$Res call({
 String reference, double amount, String network, String planName, String phoneNumber, String data, String validity
});




}
/// @nodoc
class _$DataSuccessCopyWithImpl<$Res>
    implements $DataSuccessCopyWith<$Res> {
  _$DataSuccessCopyWithImpl(this._self, this._then);

  final DataSuccess _self;
  final $Res Function(DataSuccess) _then;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reference = null,Object? amount = null,Object? network = null,Object? planName = null,Object? phoneNumber = null,Object? data = null,Object? validity = null,}) {
  return _then(DataSuccess(
reference: null == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as String,planName: null == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String,phoneNumber: null == phoneNumber ? _self.phoneNumber : phoneNumber // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as String,validity: null == validity ? _self.validity : validity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DataFailure implements DataState {
  const DataFailure(this.message);
  

 final  String message;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataFailureCopyWith<DataFailure> get copyWith => _$DataFailureCopyWithImpl<DataFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DataState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $DataFailureCopyWith<$Res> implements $DataStateCopyWith<$Res> {
  factory $DataFailureCopyWith(DataFailure value, $Res Function(DataFailure) _then) = _$DataFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DataFailureCopyWithImpl<$Res>
    implements $DataFailureCopyWith<$Res> {
  _$DataFailureCopyWithImpl(this._self, this._then);

  final DataFailure _self;
  final $Res Function(DataFailure) _then;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DataFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class DataPlansLoading implements DataState {
  const DataPlansLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataPlansLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DataState.plansLoading()';
}


}




/// @nodoc


class DataPlansSuccess implements DataState {
  const DataPlansSuccess(final  List<Map<String, dynamic>> plans): _plans = plans;
  

 final  List<Map<String, dynamic>> _plans;
 List<Map<String, dynamic>> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}


/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataPlansSuccessCopyWith<DataPlansSuccess> get copyWith => _$DataPlansSuccessCopyWithImpl<DataPlansSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataPlansSuccess&&const DeepCollectionEquality().equals(other._plans, _plans));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_plans));

@override
String toString() {
  return 'DataState.plansSuccess(plans: $plans)';
}


}

/// @nodoc
abstract mixin class $DataPlansSuccessCopyWith<$Res> implements $DataStateCopyWith<$Res> {
  factory $DataPlansSuccessCopyWith(DataPlansSuccess value, $Res Function(DataPlansSuccess) _then) = _$DataPlansSuccessCopyWithImpl;
@useResult
$Res call({
 List<Map<String, dynamic>> plans
});




}
/// @nodoc
class _$DataPlansSuccessCopyWithImpl<$Res>
    implements $DataPlansSuccessCopyWith<$Res> {
  _$DataPlansSuccessCopyWithImpl(this._self, this._then);

  final DataPlansSuccess _self;
  final $Res Function(DataPlansSuccess) _then;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? plans = null,}) {
  return _then(DataPlansSuccess(
null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,
  ));
}


}

/// @nodoc


class DataPlansFailure implements DataState {
  const DataPlansFailure(this.message);
  

 final  String message;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataPlansFailureCopyWith<DataPlansFailure> get copyWith => _$DataPlansFailureCopyWithImpl<DataPlansFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataPlansFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'DataState.plansFailure(message: $message)';
}


}

/// @nodoc
abstract mixin class $DataPlansFailureCopyWith<$Res> implements $DataStateCopyWith<$Res> {
  factory $DataPlansFailureCopyWith(DataPlansFailure value, $Res Function(DataPlansFailure) _then) = _$DataPlansFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$DataPlansFailureCopyWithImpl<$Res>
    implements $DataPlansFailureCopyWith<$Res> {
  _$DataPlansFailureCopyWithImpl(this._self, this._then);

  final DataPlansFailure _self;
  final $Res Function(DataPlansFailure) _then;

/// Create a copy of DataState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(DataPlansFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
