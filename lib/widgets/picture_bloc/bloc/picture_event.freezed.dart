// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'picture_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PictureEvent {

 PictureInfo get pictureInfo; bool get usePlugin;
/// Create a copy of PictureEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PictureEventCopyWith<PictureEvent> get copyWith => _$PictureEventCopyWithImpl<PictureEvent>(this as PictureEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PictureEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PictureEvent&&(identical(other.pictureInfo, _this.pictureInfo) || other.pictureInfo == _this.pictureInfo)&&(identical(other.usePlugin, _this.usePlugin) || other.usePlugin == _this.usePlugin));
}


@override
int get hashCode {
  final _this = this as PictureEvent;
  return Object.hash(runtimeType,_this.pictureInfo,_this.usePlugin);
}

@override
String toString() {
  final _this = this as PictureEvent;
  return 'PictureEvent(pictureInfo: ${_this.pictureInfo}, usePlugin: ${_this.usePlugin})';
}


}

/// @nodoc
abstract mixin class $PictureEventCopyWith<$Res>  {
  factory $PictureEventCopyWith(PictureEvent value, $Res Function(PictureEvent) _then) = _$PictureEventCopyWithImpl;
@useResult
$Res call({
 PictureInfo pictureInfo, bool usePlugin
});


$PictureInfoCopyWith<$Res> get pictureInfo;

}
/// @nodoc
class _$PictureEventCopyWithImpl<$Res>
    implements $PictureEventCopyWith<$Res> {
  _$PictureEventCopyWithImpl(this._self, this._then);

  final PictureEvent _self;
  final $Res Function(PictureEvent) _then;

/// Create a copy of PictureEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pictureInfo = null,Object? usePlugin = null,}) {
  return _then(PictureEvent.getPicture(
null == pictureInfo ? _self.pictureInfo : pictureInfo // ignore: cast_nullable_to_non_nullable
as PictureInfo,usePlugin: null == usePlugin ? _self.usePlugin : usePlugin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PictureEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PictureInfoCopyWith<$Res> get pictureInfo {
  
  return $PictureInfoCopyWith<$Res>(_self.pictureInfo, (value) {
    return _then(_self.copyWith(pictureInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [PictureEvent].
extension PictureEventPatterns on PictureEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GetPicture value)?  getPicture,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GetPicture() when getPicture != null:
return getPicture(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GetPicture value)  getPicture,}){
final _that = this;
switch (_that) {
case GetPicture():
return getPicture(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GetPicture value)?  getPicture,}){
final _that = this;
switch (_that) {
case GetPicture() when getPicture != null:
return getPicture(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( PictureInfo pictureInfo,  bool usePlugin)?  getPicture,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GetPicture() when getPicture != null:
return getPicture(_that.pictureInfo,_that.usePlugin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( PictureInfo pictureInfo,  bool usePlugin)  getPicture,}) {final _that = this;
switch (_that) {
case GetPicture():
return getPicture(_that.pictureInfo,_that.usePlugin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( PictureInfo pictureInfo,  bool usePlugin)?  getPicture,}) {final _that = this;
switch (_that) {
case GetPicture() when getPicture != null:
return getPicture(_that.pictureInfo,_that.usePlugin);case _:
  return null;

}
}

}

/// @nodoc


class GetPicture implements PictureEvent {
  const GetPicture(this.pictureInfo, {this.usePlugin = true});
  

@override final  PictureInfo pictureInfo;
@override@JsonKey() final  bool usePlugin;

/// Create a copy of PictureEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetPictureCopyWith<GetPicture> get copyWith => _$GetPictureCopyWithImpl<GetPicture>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GetPicture&&(identical(other.pictureInfo, pictureInfo) || other.pictureInfo == pictureInfo)&&(identical(other.usePlugin, usePlugin) || other.usePlugin == usePlugin));
}


@override
int get hashCode {
    return Object.hash(runtimeType,pictureInfo,usePlugin);
}

@override
String toString() {
    return 'PictureEvent.getPicture(pictureInfo: $pictureInfo, usePlugin: $usePlugin)';
}


}

/// @nodoc
abstract mixin class $GetPictureCopyWith<$Res> implements $PictureEventCopyWith<$Res> {
  factory $GetPictureCopyWith(GetPicture value, $Res Function(GetPicture) _then) = _$GetPictureCopyWithImpl;
@override @useResult
$Res call({
 PictureInfo pictureInfo, bool usePlugin
});


@override $PictureInfoCopyWith<$Res> get pictureInfo;

}
/// @nodoc
class _$GetPictureCopyWithImpl<$Res>
    implements $GetPictureCopyWith<$Res> {
  _$GetPictureCopyWithImpl(this._self, this._then);

  final GetPicture _self;
  final $Res Function(GetPicture) _then;

/// Create a copy of PictureEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pictureInfo = null,Object? usePlugin = null,}) {
  return _then(GetPicture(
null == pictureInfo ? _self.pictureInfo : pictureInfo // ignore: cast_nullable_to_non_nullable
as PictureInfo,usePlugin: null == usePlugin ? _self.usePlugin : usePlugin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PictureEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PictureInfoCopyWith<$Res> get pictureInfo {
  
  return $PictureInfoCopyWith<$Res>(_self.pictureInfo, (value) {
    return _then(_self.copyWith(pictureInfo: value));
  });
}
}

// dart format on
