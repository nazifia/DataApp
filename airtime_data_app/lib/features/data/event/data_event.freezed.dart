// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'data_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$DataEvent {
  String get network => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String network, String planId, String phoneNumber)
    purchaseData,
    required TResult Function(String network) loadDataPlans,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String network, String planId, String phoneNumber)?
    purchaseData,
    TResult? Function(String network)? loadDataPlans,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String network, String planId, String phoneNumber)?
    purchaseData,
    TResult Function(String network)? loadDataPlans,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseDataEvent value) purchaseData,
    required TResult Function(LoadDataPlansEvent value) loadDataPlans,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseDataEvent value)? purchaseData,
    TResult? Function(LoadDataPlansEvent value)? loadDataPlans,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseDataEvent value)? purchaseData,
    TResult Function(LoadDataPlansEvent value)? loadDataPlans,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataEventCopyWith<DataEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataEventCopyWith<$Res> {
  factory $DataEventCopyWith(DataEvent value, $Res Function(DataEvent) then) =
      _$DataEventCopyWithImpl<$Res, DataEvent>;
  @useResult
  $Res call({String network});
}

/// @nodoc
class _$DataEventCopyWithImpl<$Res, $Val extends DataEvent>
    implements $DataEventCopyWith<$Res> {
  _$DataEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? network = null}) {
    return _then(
      _value.copyWith(
            network: null == network
                ? _value.network
                : network // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PurchaseDataEventImplCopyWith<$Res>
    implements $DataEventCopyWith<$Res> {
  factory _$$PurchaseDataEventImplCopyWith(
    _$PurchaseDataEventImpl value,
    $Res Function(_$PurchaseDataEventImpl) then,
  ) = __$$PurchaseDataEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String network, String planId, String phoneNumber});
}

/// @nodoc
class __$$PurchaseDataEventImplCopyWithImpl<$Res>
    extends _$DataEventCopyWithImpl<$Res, _$PurchaseDataEventImpl>
    implements _$$PurchaseDataEventImplCopyWith<$Res> {
  __$$PurchaseDataEventImplCopyWithImpl(
    _$PurchaseDataEventImpl _value,
    $Res Function(_$PurchaseDataEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? network = null,
    Object? planId = null,
    Object? phoneNumber = null,
  }) {
    return _then(
      _$PurchaseDataEventImpl(
        network: null == network
            ? _value.network
            : network // ignore: cast_nullable_to_non_nullable
                  as String,
        planId: null == planId
            ? _value.planId
            : planId // ignore: cast_nullable_to_non_nullable
                  as String,
        phoneNumber: null == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PurchaseDataEventImpl implements PurchaseDataEvent {
  const _$PurchaseDataEventImpl({
    required this.network,
    required this.planId,
    required this.phoneNumber,
  });

  @override
  final String network;
  @override
  final String planId;
  @override
  final String phoneNumber;

  @override
  String toString() {
    return 'DataEvent.purchaseData(network: $network, planId: $planId, phoneNumber: $phoneNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PurchaseDataEventImpl &&
            (identical(other.network, network) || other.network == network) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber));
  }

  @override
  int get hashCode => Object.hash(runtimeType, network, planId, phoneNumber);

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PurchaseDataEventImplCopyWith<_$PurchaseDataEventImpl> get copyWith =>
      __$$PurchaseDataEventImplCopyWithImpl<_$PurchaseDataEventImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String network, String planId, String phoneNumber)
    purchaseData,
    required TResult Function(String network) loadDataPlans,
  }) {
    return purchaseData(network, planId, phoneNumber);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String network, String planId, String phoneNumber)?
    purchaseData,
    TResult? Function(String network)? loadDataPlans,
  }) {
    return purchaseData?.call(network, planId, phoneNumber);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String network, String planId, String phoneNumber)?
    purchaseData,
    TResult Function(String network)? loadDataPlans,
    required TResult orElse(),
  }) {
    if (purchaseData != null) {
      return purchaseData(network, planId, phoneNumber);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseDataEvent value) purchaseData,
    required TResult Function(LoadDataPlansEvent value) loadDataPlans,
  }) {
    return purchaseData(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseDataEvent value)? purchaseData,
    TResult? Function(LoadDataPlansEvent value)? loadDataPlans,
  }) {
    return purchaseData?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseDataEvent value)? purchaseData,
    TResult Function(LoadDataPlansEvent value)? loadDataPlans,
    required TResult orElse(),
  }) {
    if (purchaseData != null) {
      return purchaseData(this);
    }
    return orElse();
  }
}

abstract class PurchaseDataEvent implements DataEvent {
  const factory PurchaseDataEvent({
    required final String network,
    required final String planId,
    required final String phoneNumber,
  }) = _$PurchaseDataEventImpl;

  @override
  String get network;
  String get planId;
  String get phoneNumber;

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PurchaseDataEventImplCopyWith<_$PurchaseDataEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadDataPlansEventImplCopyWith<$Res>
    implements $DataEventCopyWith<$Res> {
  factory _$$LoadDataPlansEventImplCopyWith(
    _$LoadDataPlansEventImpl value,
    $Res Function(_$LoadDataPlansEventImpl) then,
  ) = __$$LoadDataPlansEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String network});
}

/// @nodoc
class __$$LoadDataPlansEventImplCopyWithImpl<$Res>
    extends _$DataEventCopyWithImpl<$Res, _$LoadDataPlansEventImpl>
    implements _$$LoadDataPlansEventImplCopyWith<$Res> {
  __$$LoadDataPlansEventImplCopyWithImpl(
    _$LoadDataPlansEventImpl _value,
    $Res Function(_$LoadDataPlansEventImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? network = null}) {
    return _then(
      _$LoadDataPlansEventImpl(
        null == network
            ? _value.network
            : network // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LoadDataPlansEventImpl implements LoadDataPlansEvent {
  const _$LoadDataPlansEventImpl(this.network);

  @override
  final String network;

  @override
  String toString() {
    return 'DataEvent.loadDataPlans(network: $network)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadDataPlansEventImpl &&
            (identical(other.network, network) || other.network == network));
  }

  @override
  int get hashCode => Object.hash(runtimeType, network);

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadDataPlansEventImplCopyWith<_$LoadDataPlansEventImpl> get copyWith =>
      __$$LoadDataPlansEventImplCopyWithImpl<_$LoadDataPlansEventImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String network, String planId, String phoneNumber)
    purchaseData,
    required TResult Function(String network) loadDataPlans,
  }) {
    return loadDataPlans(network);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String network, String planId, String phoneNumber)?
    purchaseData,
    TResult? Function(String network)? loadDataPlans,
  }) {
    return loadDataPlans?.call(network);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String network, String planId, String phoneNumber)?
    purchaseData,
    TResult Function(String network)? loadDataPlans,
    required TResult orElse(),
  }) {
    if (loadDataPlans != null) {
      return loadDataPlans(network);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PurchaseDataEvent value) purchaseData,
    required TResult Function(LoadDataPlansEvent value) loadDataPlans,
  }) {
    return loadDataPlans(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PurchaseDataEvent value)? purchaseData,
    TResult? Function(LoadDataPlansEvent value)? loadDataPlans,
  }) {
    return loadDataPlans?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PurchaseDataEvent value)? purchaseData,
    TResult Function(LoadDataPlansEvent value)? loadDataPlans,
    required TResult orElse(),
  }) {
    if (loadDataPlans != null) {
      return loadDataPlans(this);
    }
    return orElse();
  }
}

abstract class LoadDataPlansEvent implements DataEvent {
  const factory LoadDataPlansEvent(final String network) =
      _$LoadDataPlansEventImpl;

  @override
  String get network;

  /// Create a copy of DataEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadDataPlansEventImplCopyWith<_$LoadDataPlansEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
