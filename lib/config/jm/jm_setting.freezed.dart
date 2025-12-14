// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmSettingState {

 String get account; String get password; String get userInfo; LoginStatus get loginStatus; int get favoriteSet;
/// Create a copy of JmSettingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmSettingStateCopyWith<JmSettingState> get copyWith => _$JmSettingStateCopyWithImpl<JmSettingState>(this as JmSettingState, _$identity);

  /// Serializes this JmSettingState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmSettingState&&(identical(other.account, account) || other.account == account)&&(identical(other.password, password) || other.password == password)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&(identical(other.loginStatus, loginStatus) || other.loginStatus == loginStatus)&&(identical(other.favoriteSet, favoriteSet) || other.favoriteSet == favoriteSet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,password,userInfo,loginStatus,favoriteSet);

@override
String toString() {
  return 'JmSettingState(account: $account, password: $password, userInfo: $userInfo, loginStatus: $loginStatus, favoriteSet: $favoriteSet)';
}


}

/// @nodoc
abstract mixin class $JmSettingStateCopyWith<$Res>  {
  factory $JmSettingStateCopyWith(JmSettingState value, $Res Function(JmSettingState) _then) = _$JmSettingStateCopyWithImpl;
@useResult
$Res call({
 String account, String password, String userInfo, LoginStatus loginStatus, int favoriteSet
});




}
/// @nodoc
class _$JmSettingStateCopyWithImpl<$Res>
    implements $JmSettingStateCopyWith<$Res> {
  _$JmSettingStateCopyWithImpl(this._self, this._then);

  final JmSettingState _self;
  final $Res Function(JmSettingState) _then;

/// Create a copy of JmSettingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = null,Object? password = null,Object? userInfo = null,Object? loginStatus = null,Object? favoriteSet = null,}) {
  return _then(_self.copyWith(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,userInfo: null == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as String,loginStatus: null == loginStatus ? _self.loginStatus : loginStatus // ignore: cast_nullable_to_non_nullable
as LoginStatus,favoriteSet: null == favoriteSet ? _self.favoriteSet : favoriteSet // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JmSettingState].
extension JmSettingStatePatterns on JmSettingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmSettingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmSettingState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmSettingState value)  $default,){
final _that = this;
switch (_that) {
case _JmSettingState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmSettingState value)?  $default,){
final _that = this;
switch (_that) {
case _JmSettingState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String account,  String password,  String userInfo,  LoginStatus loginStatus,  int favoriteSet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmSettingState() when $default != null:
return $default(_that.account,_that.password,_that.userInfo,_that.loginStatus,_that.favoriteSet);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String account,  String password,  String userInfo,  LoginStatus loginStatus,  int favoriteSet)  $default,) {final _that = this;
switch (_that) {
case _JmSettingState():
return $default(_that.account,_that.password,_that.userInfo,_that.loginStatus,_that.favoriteSet);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String account,  String password,  String userInfo,  LoginStatus loginStatus,  int favoriteSet)?  $default,) {final _that = this;
switch (_that) {
case _JmSettingState() when $default != null:
return $default(_that.account,_that.password,_that.userInfo,_that.loginStatus,_that.favoriteSet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JmSettingState implements JmSettingState {
  const _JmSettingState({this.account = '', this.password = '', this.userInfo = '', this.loginStatus = LoginStatus.logout, this.favoriteSet = 0});
  factory _JmSettingState.fromJson(Map<String, dynamic> json) => _$JmSettingStateFromJson(json);

@override@JsonKey() final  String account;
@override@JsonKey() final  String password;
@override@JsonKey() final  String userInfo;
@override@JsonKey() final  LoginStatus loginStatus;
@override@JsonKey() final  int favoriteSet;

/// Create a copy of JmSettingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmSettingStateCopyWith<_JmSettingState> get copyWith => __$JmSettingStateCopyWithImpl<_JmSettingState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmSettingStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmSettingState&&(identical(other.account, account) || other.account == account)&&(identical(other.password, password) || other.password == password)&&(identical(other.userInfo, userInfo) || other.userInfo == userInfo)&&(identical(other.loginStatus, loginStatus) || other.loginStatus == loginStatus)&&(identical(other.favoriteSet, favoriteSet) || other.favoriteSet == favoriteSet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,password,userInfo,loginStatus,favoriteSet);

@override
String toString() {
  return 'JmSettingState(account: $account, password: $password, userInfo: $userInfo, loginStatus: $loginStatus, favoriteSet: $favoriteSet)';
}


}

/// @nodoc
abstract mixin class _$JmSettingStateCopyWith<$Res> implements $JmSettingStateCopyWith<$Res> {
  factory _$JmSettingStateCopyWith(_JmSettingState value, $Res Function(_JmSettingState) _then) = __$JmSettingStateCopyWithImpl;
@override @useResult
$Res call({
 String account, String password, String userInfo, LoginStatus loginStatus, int favoriteSet
});




}
/// @nodoc
class __$JmSettingStateCopyWithImpl<$Res>
    implements _$JmSettingStateCopyWith<$Res> {
  __$JmSettingStateCopyWithImpl(this._self, this._then);

  final _JmSettingState _self;
  final $Res Function(_JmSettingState) _then;

/// Create a copy of JmSettingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = null,Object? password = null,Object? userInfo = null,Object? loginStatus = null,Object? favoriteSet = null,}) {
  return _then(_JmSettingState(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,userInfo: null == userInfo ? _self.userInfo : userInfo // ignore: cast_nullable_to_non_nullable
as String,loginStatus: null == loginStatus ? _self.loginStatus : loginStatus // ignore: cast_nullable_to_non_nullable
as LoginStatus,favoriteSet: null == favoriteSet ? _self.favoriteSet : favoriteSet // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
