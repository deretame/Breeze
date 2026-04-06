// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_task_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadTaskJson {

 String get from; String get comicId; String get comicName; List<String> get selectedChapters;
/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadTaskJsonCopyWith<DownloadTaskJson> get copyWith => _$DownloadTaskJsonCopyWithImpl<DownloadTaskJson>(this as DownloadTaskJson, _$identity);

  /// Serializes this DownloadTaskJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&const DeepCollectionEquality().equals(other.selectedChapters, selectedChapters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,comicId,comicName,const DeepCollectionEquality().hash(selectedChapters));

@override
String toString() {
  return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, selectedChapters: $selectedChapters)';
}


}

/// @nodoc
abstract mixin class $DownloadTaskJsonCopyWith<$Res>  {
  factory $DownloadTaskJsonCopyWith(DownloadTaskJson value, $Res Function(DownloadTaskJson) _then) = _$DownloadTaskJsonCopyWithImpl;
@useResult
$Res call({
 String from, String comicId, String comicName, List<String> selectedChapters
});




}
/// @nodoc
class _$DownloadTaskJsonCopyWithImpl<$Res>
    implements $DownloadTaskJsonCopyWith<$Res> {
  _$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final DownloadTaskJson _self;
  final $Res Function(DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? selectedChapters = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,selectedChapters: null == selectedChapters ? _self.selectedChapters : selectedChapters // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadTaskJson].
extension DownloadTaskJsonPatterns on DownloadTaskJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadTaskJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadTaskJson value)  $default,){
final _that = this;
switch (_that) {
case _DownloadTaskJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadTaskJson value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String comicId,  String comicName,  List<String> selectedChapters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
return $default(_that.from,_that.comicId,_that.comicName,_that.selectedChapters);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String comicId,  String comicName,  List<String> selectedChapters)  $default,) {final _that = this;
switch (_that) {
case _DownloadTaskJson():
return $default(_that.from,_that.comicId,_that.comicName,_that.selectedChapters);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String comicId,  String comicName,  List<String> selectedChapters)?  $default,) {final _that = this;
switch (_that) {
case _DownloadTaskJson() when $default != null:
return $default(_that.from,_that.comicId,_that.comicName,_that.selectedChapters);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DownloadTaskJson implements DownloadTaskJson {
  const _DownloadTaskJson({required this.from, required this.comicId, required this.comicName, required this.selectedChapters});
  factory _DownloadTaskJson.fromJson(Map<String, dynamic> json) => _$DownloadTaskJsonFromJson(json);

@override final  String from;
@override final  String comicId;
@override final  String comicName;
@override final  List<String> selectedChapters;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadTaskJsonCopyWith<_DownloadTaskJson> get copyWith => __$DownloadTaskJsonCopyWithImpl<_DownloadTaskJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadTaskJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadTaskJson&&(identical(other.from, from) || other.from == from)&&(identical(other.comicId, comicId) || other.comicId == comicId)&&(identical(other.comicName, comicName) || other.comicName == comicName)&&const DeepCollectionEquality().equals(other.selectedChapters, selectedChapters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,comicId,comicName,const DeepCollectionEquality().hash(selectedChapters));

@override
String toString() {
  return 'DownloadTaskJson(from: $from, comicId: $comicId, comicName: $comicName, selectedChapters: $selectedChapters)';
}


}

/// @nodoc
abstract mixin class _$DownloadTaskJsonCopyWith<$Res> implements $DownloadTaskJsonCopyWith<$Res> {
  factory _$DownloadTaskJsonCopyWith(_DownloadTaskJson value, $Res Function(_DownloadTaskJson) _then) = __$DownloadTaskJsonCopyWithImpl;
@override @useResult
$Res call({
 String from, String comicId, String comicName, List<String> selectedChapters
});




}
/// @nodoc
class __$DownloadTaskJsonCopyWithImpl<$Res>
    implements _$DownloadTaskJsonCopyWith<$Res> {
  __$DownloadTaskJsonCopyWithImpl(this._self, this._then);

  final _DownloadTaskJson _self;
  final $Res Function(_DownloadTaskJson) _then;

/// Create a copy of DownloadTaskJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? comicId = null,Object? comicName = null,Object? selectedChapters = null,}) {
  return _then(_DownloadTaskJson(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,comicId: null == comicId ? _self.comicId : comicId // ignore: cast_nullable_to_non_nullable
as String,comicName: null == comicName ? _self.comicName : comicName // ignore: cast_nullable_to_non_nullable
as String,selectedChapters: null == selectedChapters ? _self.selectedChapters : selectedChapters // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
