// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'get_comic_info_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GetComicInfoEvent {

 String get comicId; String get from; ComicEntryType get type; Map<String, dynamic>? get extern;
/// Create a copy of GetComicInfoEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetComicInfoEventCopyWith<GetComicInfoEvent> get copyWith => _$GetComicInfoEventCopyWithImpl<GetComicInfoEvent>(this as GetComicInfoEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GetComicInfoEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetComicInfoEvent&&(identical(other.comicId, _this.comicId) || other.comicId == _this.comicId)&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.type, _this.type) || other.type == _this.type)&&const DeepCollectionEquality().equals(other.extern, _this.extern));
}


@override
int get hashCode {
  final _this = this as GetComicInfoEvent;
  return Object.hash(runtimeType,_this.comicId,_this.from,_this.type,const DeepCollectionEquality().hash(_this.extern));
}

@override
String toString() {
  final _this = this as GetComicInfoEvent;
  return 'GetComicInfoEvent(comicId: ${_this.comicId}, from: ${_this.from}, type: ${_this.type}, extern: ${_this.extern})';
}


}

/// @nodoc
abstract mixin class $GetComicInfoEventCopyWith<$Res>  {
  factory $GetComicInfoEventCopyWith(GetComicInfoEvent value, $Res Function(GetComicInfoEvent) _then) = _$GetComicInfoEventCopyWithImpl;
@useResult
$Res call({
 String comicId, String from, ComicEntryType type, Map<String, dynamic>? extern
});




}
/// @nodoc
class _$GetComicInfoEventCopyWithImpl<$Res>
    implements $GetComicInfoEventCopyWith<$Res> {
  _$GetComicInfoEventCopyWithImpl(this._self, this._then);

  final GetComicInfoEvent _self;
  final $Res Function(GetComicInfoEvent) _then;

/// Create a copy of GetComicInfoEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comicId = null,Object? from = null,Object? type = null,Object? extern = freezed,}) {
  return _then(GetComicInfoEvent(
comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ComicEntryType,extern: freezed == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [GetComicInfoEvent].
extension GetComicInfoEventPatterns on GetComicInfoEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GetComicInfoEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GetComicInfoEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GetComicInfoEvent value)  $default,){
final _that = this;
switch (_that) {
case _GetComicInfoEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GetComicInfoEvent value)?  $default,){
final _that = this;
switch (_that) {
case _GetComicInfoEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String comicId,  String from,  ComicEntryType type,  Map<String, dynamic>? extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GetComicInfoEvent() when $default != null:
return $default(_that.comicId,_that.from,_that.type,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String comicId,  String from,  ComicEntryType type,  Map<String, dynamic>? extern)  $default,) {final _that = this;
switch (_that) {
case _GetComicInfoEvent():
return $default(_that.comicId,_that.from,_that.type,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String comicId,  String from,  ComicEntryType type,  Map<String, dynamic>? extern)?  $default,) {final _that = this;
switch (_that) {
case _GetComicInfoEvent() when $default != null:
return $default(_that.comicId,_that.from,_that.type,_that.extern);case _:
  return null;

}
}

}

/// @nodoc


class _GetComicInfoEvent implements GetComicInfoEvent {
  const _GetComicInfoEvent({required this.comicId, required this.from, required this.type,  Map<String, dynamic>? extern}): _extern = extern;
  

@override final  String comicId;
@override final  String from;
@override final  ComicEntryType type;
 final  Map<String, dynamic>? _extern;
@override Map<String, dynamic>? get extern {
  final value = _extern;
  if (value == null) return null;
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of GetComicInfoEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GetComicInfoEventCopyWith<_GetComicInfoEvent> get copyWith => __$GetComicInfoEventCopyWithImpl<_GetComicInfoEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GetComicInfoEvent&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.from, from) || other.from == from)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.extern, _extern));
}


@override
int get hashCode {
    return Object.hash(runtimeType,comicId,from,type,const DeepCollectionEquality().hash(_extern));
}

@override
String toString() {
    return 'GetComicInfoEvent(comicId: $comicId, from: $from, type: $type, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$GetComicInfoEventCopyWith<$Res> implements $GetComicInfoEventCopyWith<$Res> {
  factory _$GetComicInfoEventCopyWith(_GetComicInfoEvent value, $Res Function(_GetComicInfoEvent) _then) = __$GetComicInfoEventCopyWithImpl;
@override @useResult
$Res call({
 String comicId, String from, ComicEntryType type, Map<String, dynamic>? extern
});




}
/// @nodoc
class __$GetComicInfoEventCopyWithImpl<$Res>
    implements _$GetComicInfoEventCopyWith<$Res> {
  __$GetComicInfoEventCopyWithImpl(this._self, this._then);

  final _GetComicInfoEvent _self;
  final $Res Function(_GetComicInfoEvent) _then;

/// Create a copy of GetComicInfoEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comicId = null,Object? from = null,Object? type = null,Object? extern = freezed,}) {
  return _then(_GetComicInfoEvent(
comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ComicEntryType,extern: freezed == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on
