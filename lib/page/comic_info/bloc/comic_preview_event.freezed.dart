// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_preview_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoadComicPreview {

 bool get loadMore;
/// Create a copy of LoadComicPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoadComicPreviewCopyWith<LoadComicPreview> get copyWith => _$LoadComicPreviewCopyWithImpl<LoadComicPreview>(this as LoadComicPreview, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LoadComicPreview;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoadComicPreview&&(identical(other.loadMore, _this.loadMore) || other.loadMore == _this.loadMore));
}


@override
int get hashCode {
  final _this = this as LoadComicPreview;
  return Object.hash(runtimeType,_this.loadMore);
}

@override
String toString() {
  final _this = this as LoadComicPreview;
  return 'LoadComicPreview(loadMore: ${_this.loadMore})';
}


}

/// @nodoc
abstract mixin class $LoadComicPreviewCopyWith<$Res>  {
  factory $LoadComicPreviewCopyWith(LoadComicPreview value, $Res Function(LoadComicPreview) _then) = _$LoadComicPreviewCopyWithImpl;
@useResult
$Res call({
 bool loadMore
});




}
/// @nodoc
class _$LoadComicPreviewCopyWithImpl<$Res>
    implements $LoadComicPreviewCopyWith<$Res> {
  _$LoadComicPreviewCopyWithImpl(this._self, this._then);

  final LoadComicPreview _self;
  final $Res Function(LoadComicPreview) _then;

/// Create a copy of LoadComicPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loadMore = null,}) {
  return _then(LoadComicPreview(
loadMore: null == loadMore ? _self.loadMore : loadMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LoadComicPreview].
extension LoadComicPreviewPatterns on LoadComicPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LoadComicPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadComicPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LoadComicPreview value)  $default,){
final _that = this;
switch (_that) {
case _LoadComicPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LoadComicPreview value)?  $default,){
final _that = this;
switch (_that) {
case _LoadComicPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loadMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadComicPreview() when $default != null:
return $default(_that.loadMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loadMore)  $default,) {final _that = this;
switch (_that) {
case _LoadComicPreview():
return $default(_that.loadMore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loadMore)?  $default,) {final _that = this;
switch (_that) {
case _LoadComicPreview() when $default != null:
return $default(_that.loadMore);case _:
  return null;

}
}

}

/// @nodoc


class _LoadComicPreview implements LoadComicPreview {
  const _LoadComicPreview({this.loadMore = false});
  

@override@JsonKey() final  bool loadMore;

/// Create a copy of LoadComicPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadComicPreviewCopyWith<_LoadComicPreview> get copyWith => __$LoadComicPreviewCopyWithImpl<_LoadComicPreview>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadComicPreview&&(identical(other.loadMore, loadMore) || other.loadMore == loadMore));
}


@override
int get hashCode {
    return Object.hash(runtimeType,loadMore);
}

@override
String toString() {
    return 'LoadComicPreview(loadMore: $loadMore)';
}


}

/// @nodoc
abstract mixin class _$LoadComicPreviewCopyWith<$Res> implements $LoadComicPreviewCopyWith<$Res> {
  factory _$LoadComicPreviewCopyWith(_LoadComicPreview value, $Res Function(_LoadComicPreview) _then) = __$LoadComicPreviewCopyWithImpl;
@override @useResult
$Res call({
 bool loadMore
});




}
/// @nodoc
class __$LoadComicPreviewCopyWithImpl<$Res>
    implements _$LoadComicPreviewCopyWith<$Res> {
  __$LoadComicPreviewCopyWithImpl(this._self, this._then);

  final _LoadComicPreview _self;
  final $Res Function(_LoadComicPreview) _then;

/// Create a copy of LoadComicPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loadMore = null,}) {
  return _then(_LoadComicPreview(
loadMore: null == loadMore ? _self.loadMore : loadMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
