// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_number.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ComicNumber {

 int get buildNumber; ComicInfo get comicInfo;
/// Create a copy of ComicNumber
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicNumberCopyWith<ComicNumber> get copyWith => _$ComicNumberCopyWithImpl<ComicNumber>(this as ComicNumber, _$identity);

  /// Serializes this ComicNumber to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicNumber&&(identical(other.buildNumber, buildNumber) || other.buildNumber == buildNumber)&&(identical(other.comicInfo, comicInfo) || other.comicInfo == comicInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,buildNumber,comicInfo);

@override
String toString() {
  return 'ComicNumber(buildNumber: $buildNumber, comicInfo: $comicInfo)';
}


}

/// @nodoc
abstract mixin class $ComicNumberCopyWith<$Res>  {
  factory $ComicNumberCopyWith(ComicNumber value, $Res Function(ComicNumber) _then) = _$ComicNumberCopyWithImpl;
@useResult
$Res call({
 int buildNumber, ComicInfo comicInfo
});


$ComicInfoCopyWith<$Res> get comicInfo;

}
/// @nodoc
class _$ComicNumberCopyWithImpl<$Res>
    implements $ComicNumberCopyWith<$Res> {
  _$ComicNumberCopyWithImpl(this._self, this._then);

  final ComicNumber _self;
  final $Res Function(ComicNumber) _then;

/// Create a copy of ComicNumber
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? buildNumber = null,Object? comicInfo = null,}) {
  return _then(_self.copyWith(
buildNumber: null == buildNumber ? _self.buildNumber : buildNumber // ignore: cast_nullable_to_non_nullable
as int,comicInfo: null == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as ComicInfo,
  ));
}
/// Create a copy of ComicNumber
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<$Res> get comicInfo {
  
  return $ComicInfoCopyWith<$Res>(_self.comicInfo, (value) {
    return _then(_self.copyWith(comicInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicNumber].
extension ComicNumberPatterns on ComicNumber {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicNumber value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicNumber() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicNumber value)  $default,){
final _that = this;
switch (_that) {
case _ComicNumber():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicNumber value)?  $default,){
final _that = this;
switch (_that) {
case _ComicNumber() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int buildNumber,  ComicInfo comicInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicNumber() when $default != null:
return $default(_that.buildNumber,_that.comicInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int buildNumber,  ComicInfo comicInfo)  $default,) {final _that = this;
switch (_that) {
case _ComicNumber():
return $default(_that.buildNumber,_that.comicInfo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int buildNumber,  ComicInfo comicInfo)?  $default,) {final _that = this;
switch (_that) {
case _ComicNumber() when $default != null:
return $default(_that.buildNumber,_that.comicInfo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicNumber implements ComicNumber {
  const _ComicNumber({required this.buildNumber, required this.comicInfo});
  factory _ComicNumber.fromJson(Map<String, dynamic> json) => _$ComicNumberFromJson(json);

@override final  int buildNumber;
@override final  ComicInfo comicInfo;

/// Create a copy of ComicNumber
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicNumberCopyWith<_ComicNumber> get copyWith => __$ComicNumberCopyWithImpl<_ComicNumber>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicNumberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicNumber&&(identical(other.buildNumber, buildNumber) || other.buildNumber == buildNumber)&&(identical(other.comicInfo, comicInfo) || other.comicInfo == comicInfo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,buildNumber,comicInfo);

@override
String toString() {
  return 'ComicNumber(buildNumber: $buildNumber, comicInfo: $comicInfo)';
}


}

/// @nodoc
abstract mixin class _$ComicNumberCopyWith<$Res> implements $ComicNumberCopyWith<$Res> {
  factory _$ComicNumberCopyWith(_ComicNumber value, $Res Function(_ComicNumber) _then) = __$ComicNumberCopyWithImpl;
@override @useResult
$Res call({
 int buildNumber, ComicInfo comicInfo
});


@override $ComicInfoCopyWith<$Res> get comicInfo;

}
/// @nodoc
class __$ComicNumberCopyWithImpl<$Res>
    implements _$ComicNumberCopyWith<$Res> {
  __$ComicNumberCopyWithImpl(this._self, this._then);

  final _ComicNumber _self;
  final $Res Function(_ComicNumber) _then;

/// Create a copy of ComicNumber
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? buildNumber = null,Object? comicInfo = null,}) {
  return _then(_ComicNumber(
buildNumber: null == buildNumber ? _self.buildNumber : buildNumber // ignore: cast_nullable_to_non_nullable
as int,comicInfo: null == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as ComicInfo,
  ));
}

/// Create a copy of ComicNumber
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<$Res> get comicInfo {
  
  return $ComicInfoCopyWith<$Res>(_self.comicInfo, (value) {
    return _then(_self.copyWith(comicInfo: value));
  });
}
}

ComicInfo _$ComicInfoFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'bika':
          return Bika.fromJson(
            json
          );
                case 'jm':
          return Jm.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'ComicInfo',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$ComicInfo {

 Object get comics;

  /// Serializes this ComicInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfo&&const DeepCollectionEquality().equals(other.comics, comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(comics));

@override
String toString() {
  return 'ComicInfo(comics: $comics)';
}


}

/// @nodoc
class $ComicInfoCopyWith<$Res>  {
$ComicInfoCopyWith(ComicInfo _, $Res Function(ComicInfo) __);
}


/// Adds pattern-matching-related methods to [ComicInfo].
extension ComicInfoPatterns on ComicInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Bika value)?  bika,TResult Function( Jm value)?  jm,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Bika() when bika != null:
return bika(_that);case Jm() when jm != null:
return jm(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Bika value)  bika,required TResult Function( Jm value)  jm,}){
final _that = this;
switch (_that) {
case Bika():
return bika(_that);case Jm():
return jm(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Bika value)?  bika,TResult? Function( Jm value)?  jm,}){
final _that = this;
switch (_that) {
case Bika() when bika != null:
return bika(_that);case Jm() when jm != null:
return jm(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Doc comics)?  bika,TResult Function( Content comics)?  jm,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Bika() when bika != null:
return bika(_that.comics);case Jm() when jm != null:
return jm(_that.comics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Doc comics)  bika,required TResult Function( Content comics)  jm,}) {final _that = this;
switch (_that) {
case Bika():
return bika(_that.comics);case Jm():
return jm(_that.comics);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Doc comics)?  bika,TResult? Function( Content comics)?  jm,}) {final _that = this;
switch (_that) {
case Bika() when bika != null:
return bika(_that.comics);case Jm() when jm != null:
return jm(_that.comics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Bika implements ComicInfo {
  const Bika(this.comics, {final  String? $type}): $type = $type ?? 'bika';
  factory Bika.fromJson(Map<String, dynamic> json) => _$BikaFromJson(json);

@override final  Doc comics;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BikaCopyWith<Bika> get copyWith => _$BikaCopyWithImpl<Bika>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BikaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bika&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'ComicInfo.bika(comics: $comics)';
}


}

/// @nodoc
abstract mixin class $BikaCopyWith<$Res> implements $ComicInfoCopyWith<$Res> {
  factory $BikaCopyWith(Bika value, $Res Function(Bika) _then) = _$BikaCopyWithImpl;
@useResult
$Res call({
 Doc comics
});


$DocCopyWith<$Res> get comics;

}
/// @nodoc
class _$BikaCopyWithImpl<$Res>
    implements $BikaCopyWith<$Res> {
  _$BikaCopyWithImpl(this._self, this._then);

  final Bika _self;
  final $Res Function(Bika) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comics = null,}) {
  return _then(Bika(
null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Doc,
  ));
}

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocCopyWith<$Res> get comics {
  
  return $DocCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class Jm implements ComicInfo {
  const Jm(this.comics, {final  String? $type}): $type = $type ?? 'jm';
  factory Jm.fromJson(Map<String, dynamic> json) => _$JmFromJson(json);

@override final  Content comics;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmCopyWith<Jm> get copyWith => _$JmCopyWithImpl<Jm>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Jm&&(identical(other.comics, comics) || other.comics == comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comics);

@override
String toString() {
  return 'ComicInfo.jm(comics: $comics)';
}


}

/// @nodoc
abstract mixin class $JmCopyWith<$Res> implements $ComicInfoCopyWith<$Res> {
  factory $JmCopyWith(Jm value, $Res Function(Jm) _then) = _$JmCopyWithImpl;
@useResult
$Res call({
 Content comics
});


$ContentCopyWith<$Res> get comics;

}
/// @nodoc
class _$JmCopyWithImpl<$Res>
    implements $JmCopyWith<$Res> {
  _$JmCopyWithImpl(this._self, this._then);

  final Jm _self;
  final $Res Function(Jm) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comics = null,}) {
  return _then(Jm(
null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as Content,
  ));
}

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContentCopyWith<$Res> get comics {
  
  return $ContentCopyWith<$Res>(_self.comics, (value) {
    return _then(_self.copyWith(comics: value));
  });
}
}

// dart format on
