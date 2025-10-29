// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bika_setting.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BikaSettingState {

 String get account; String get password; String get authorization; int get level; bool get checkIn; int get proxy; String get imageQuality; Map<String, bool> get shieldCategoryMap; Map<String, bool> get shieldHomePageCategoriesMap; bool get signIn; bool get brevity; bool get slowDownload;
/// Create a copy of BikaSettingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BikaSettingStateCopyWith<BikaSettingState> get copyWith => _$BikaSettingStateCopyWithImpl<BikaSettingState>(this as BikaSettingState, _$identity);

  /// Serializes this BikaSettingState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BikaSettingState&&(identical(other.account, account) || other.account == account)&&(identical(other.password, password) || other.password == password)&&(identical(other.authorization, authorization) || other.authorization == authorization)&&(identical(other.level, level) || other.level == level)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.proxy, proxy) || other.proxy == proxy)&&(identical(other.imageQuality, imageQuality) || other.imageQuality == imageQuality)&&const DeepCollectionEquality().equals(other.shieldCategoryMap, shieldCategoryMap)&&const DeepCollectionEquality().equals(other.shieldHomePageCategoriesMap, shieldHomePageCategoriesMap)&&(identical(other.signIn, signIn) || other.signIn == signIn)&&(identical(other.brevity, brevity) || other.brevity == brevity)&&(identical(other.slowDownload, slowDownload) || other.slowDownload == slowDownload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,password,authorization,level,checkIn,proxy,imageQuality,const DeepCollectionEquality().hash(shieldCategoryMap),const DeepCollectionEquality().hash(shieldHomePageCategoriesMap),signIn,brevity,slowDownload);

@override
String toString() {
  return 'BikaSettingState(account: $account, password: $password, authorization: $authorization, level: $level, checkIn: $checkIn, proxy: $proxy, imageQuality: $imageQuality, shieldCategoryMap: $shieldCategoryMap, shieldHomePageCategoriesMap: $shieldHomePageCategoriesMap, signIn: $signIn, brevity: $brevity, slowDownload: $slowDownload)';
}


}

/// @nodoc
abstract mixin class $BikaSettingStateCopyWith<$Res>  {
  factory $BikaSettingStateCopyWith(BikaSettingState value, $Res Function(BikaSettingState) _then) = _$BikaSettingStateCopyWithImpl;
@useResult
$Res call({
 String account, String password, String authorization, int level, bool checkIn, int proxy, String imageQuality, Map<String, bool> shieldCategoryMap, Map<String, bool> shieldHomePageCategoriesMap, bool signIn, bool brevity, bool slowDownload
});




}
/// @nodoc
class _$BikaSettingStateCopyWithImpl<$Res>
    implements $BikaSettingStateCopyWith<$Res> {
  _$BikaSettingStateCopyWithImpl(this._self, this._then);

  final BikaSettingState _self;
  final $Res Function(BikaSettingState) _then;

/// Create a copy of BikaSettingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = null,Object? password = null,Object? authorization = null,Object? level = null,Object? checkIn = null,Object? proxy = null,Object? imageQuality = null,Object? shieldCategoryMap = null,Object? shieldHomePageCategoriesMap = null,Object? signIn = null,Object? brevity = null,Object? slowDownload = null,}) {
  return _then(_self.copyWith(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,authorization: null == authorization ? _self.authorization : authorization // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as bool,proxy: null == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as int,imageQuality: null == imageQuality ? _self.imageQuality : imageQuality // ignore: cast_nullable_to_non_nullable
as String,shieldCategoryMap: null == shieldCategoryMap ? _self.shieldCategoryMap : shieldCategoryMap // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,shieldHomePageCategoriesMap: null == shieldHomePageCategoriesMap ? _self.shieldHomePageCategoriesMap : shieldHomePageCategoriesMap // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,signIn: null == signIn ? _self.signIn : signIn // ignore: cast_nullable_to_non_nullable
as bool,brevity: null == brevity ? _self.brevity : brevity // ignore: cast_nullable_to_non_nullable
as bool,slowDownload: null == slowDownload ? _self.slowDownload : slowDownload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BikaSettingState].
extension BikaSettingStatePatterns on BikaSettingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BikaSettingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BikaSettingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BikaSettingState value)  $default,){
final _that = this;
switch (_that) {
case _BikaSettingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BikaSettingState value)?  $default,){
final _that = this;
switch (_that) {
case _BikaSettingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String account,  String password,  String authorization,  int level,  bool checkIn,  int proxy,  String imageQuality,  Map<String, bool> shieldCategoryMap,  Map<String, bool> shieldHomePageCategoriesMap,  bool signIn,  bool brevity,  bool slowDownload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BikaSettingState() when $default != null:
return $default(_that.account,_that.password,_that.authorization,_that.level,_that.checkIn,_that.proxy,_that.imageQuality,_that.shieldCategoryMap,_that.shieldHomePageCategoriesMap,_that.signIn,_that.brevity,_that.slowDownload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String account,  String password,  String authorization,  int level,  bool checkIn,  int proxy,  String imageQuality,  Map<String, bool> shieldCategoryMap,  Map<String, bool> shieldHomePageCategoriesMap,  bool signIn,  bool brevity,  bool slowDownload)  $default,) {final _that = this;
switch (_that) {
case _BikaSettingState():
return $default(_that.account,_that.password,_that.authorization,_that.level,_that.checkIn,_that.proxy,_that.imageQuality,_that.shieldCategoryMap,_that.shieldHomePageCategoriesMap,_that.signIn,_that.brevity,_that.slowDownload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String account,  String password,  String authorization,  int level,  bool checkIn,  int proxy,  String imageQuality,  Map<String, bool> shieldCategoryMap,  Map<String, bool> shieldHomePageCategoriesMap,  bool signIn,  bool brevity,  bool slowDownload)?  $default,) {final _that = this;
switch (_that) {
case _BikaSettingState() when $default != null:
return $default(_that.account,_that.password,_that.authorization,_that.level,_that.checkIn,_that.proxy,_that.imageQuality,_that.shieldCategoryMap,_that.shieldHomePageCategoriesMap,_that.signIn,_that.brevity,_that.slowDownload);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BikaSettingState implements BikaSettingState {
  const _BikaSettingState({this.account = '', this.password = '', this.authorization = '', this.level = 0, this.checkIn = false, this.proxy = 3, this.imageQuality = 'original', final  Map<String, bool> shieldCategoryMap = const <String, bool>{}, final  Map<String, bool> shieldHomePageCategoriesMap = const <String, bool>{}, this.signIn = false, this.brevity = false, this.slowDownload = false}): _shieldCategoryMap = shieldCategoryMap,_shieldHomePageCategoriesMap = shieldHomePageCategoriesMap;
  factory _BikaSettingState.fromJson(Map<String, dynamic> json) => _$BikaSettingStateFromJson(json);

@override@JsonKey() final  String account;
@override@JsonKey() final  String password;
@override@JsonKey() final  String authorization;
@override@JsonKey() final  int level;
@override@JsonKey() final  bool checkIn;
@override@JsonKey() final  int proxy;
@override@JsonKey() final  String imageQuality;
 final  Map<String, bool> _shieldCategoryMap;
@override@JsonKey() Map<String, bool> get shieldCategoryMap {
  if (_shieldCategoryMap is EqualUnmodifiableMapView) return _shieldCategoryMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_shieldCategoryMap);
}

 final  Map<String, bool> _shieldHomePageCategoriesMap;
@override@JsonKey() Map<String, bool> get shieldHomePageCategoriesMap {
  if (_shieldHomePageCategoriesMap is EqualUnmodifiableMapView) return _shieldHomePageCategoriesMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_shieldHomePageCategoriesMap);
}

@override@JsonKey() final  bool signIn;
@override@JsonKey() final  bool brevity;
@override@JsonKey() final  bool slowDownload;

/// Create a copy of BikaSettingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BikaSettingStateCopyWith<_BikaSettingState> get copyWith => __$BikaSettingStateCopyWithImpl<_BikaSettingState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BikaSettingStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BikaSettingState&&(identical(other.account, account) || other.account == account)&&(identical(other.password, password) || other.password == password)&&(identical(other.authorization, authorization) || other.authorization == authorization)&&(identical(other.level, level) || other.level == level)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.proxy, proxy) || other.proxy == proxy)&&(identical(other.imageQuality, imageQuality) || other.imageQuality == imageQuality)&&const DeepCollectionEquality().equals(other._shieldCategoryMap, _shieldCategoryMap)&&const DeepCollectionEquality().equals(other._shieldHomePageCategoriesMap, _shieldHomePageCategoriesMap)&&(identical(other.signIn, signIn) || other.signIn == signIn)&&(identical(other.brevity, brevity) || other.brevity == brevity)&&(identical(other.slowDownload, slowDownload) || other.slowDownload == slowDownload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,password,authorization,level,checkIn,proxy,imageQuality,const DeepCollectionEquality().hash(_shieldCategoryMap),const DeepCollectionEquality().hash(_shieldHomePageCategoriesMap),signIn,brevity,slowDownload);

@override
String toString() {
  return 'BikaSettingState(account: $account, password: $password, authorization: $authorization, level: $level, checkIn: $checkIn, proxy: $proxy, imageQuality: $imageQuality, shieldCategoryMap: $shieldCategoryMap, shieldHomePageCategoriesMap: $shieldHomePageCategoriesMap, signIn: $signIn, brevity: $brevity, slowDownload: $slowDownload)';
}


}

/// @nodoc
abstract mixin class _$BikaSettingStateCopyWith<$Res> implements $BikaSettingStateCopyWith<$Res> {
  factory _$BikaSettingStateCopyWith(_BikaSettingState value, $Res Function(_BikaSettingState) _then) = __$BikaSettingStateCopyWithImpl;
@override @useResult
$Res call({
 String account, String password, String authorization, int level, bool checkIn, int proxy, String imageQuality, Map<String, bool> shieldCategoryMap, Map<String, bool> shieldHomePageCategoriesMap, bool signIn, bool brevity, bool slowDownload
});




}
/// @nodoc
class __$BikaSettingStateCopyWithImpl<$Res>
    implements _$BikaSettingStateCopyWith<$Res> {
  __$BikaSettingStateCopyWithImpl(this._self, this._then);

  final _BikaSettingState _self;
  final $Res Function(_BikaSettingState) _then;

/// Create a copy of BikaSettingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = null,Object? password = null,Object? authorization = null,Object? level = null,Object? checkIn = null,Object? proxy = null,Object? imageQuality = null,Object? shieldCategoryMap = null,Object? shieldHomePageCategoriesMap = null,Object? signIn = null,Object? brevity = null,Object? slowDownload = null,}) {
  return _then(_BikaSettingState(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,authorization: null == authorization ? _self.authorization : authorization // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as bool,proxy: null == proxy ? _self.proxy : proxy // ignore: cast_nullable_to_non_nullable
as int,imageQuality: null == imageQuality ? _self.imageQuality : imageQuality // ignore: cast_nullable_to_non_nullable
as String,shieldCategoryMap: null == shieldCategoryMap ? _self._shieldCategoryMap : shieldCategoryMap // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,shieldHomePageCategoriesMap: null == shieldHomePageCategoriesMap ? _self._shieldHomePageCategoriesMap : shieldHomePageCategoriesMap // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,signIn: null == signIn ? _self.signIn : signIn // ignore: cast_nullable_to_non_nullable
as bool,brevity: null == brevity ? _self.brevity : brevity // ignore: cast_nullable_to_non_nullable
as bool,slowDownload: null == slowDownload ? _self.slowDownload : slowDownload // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
