// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_comic_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UnifiedComicListItem {

@JsonKey(fromJson: stringFromDynamic) String get source;@JsonKey(fromJson: stringFromDynamic) String get id;@JsonKey(fromJson: stringFromDynamic) String get title;@JsonKey(fromJson: stringFromDynamic) String get subtitle;@JsonKey(fromJson: boolFromDynamic) bool get finished;@JsonKey(fromJson: intFromDynamic) int get likesCount;@JsonKey(fromJson: intFromDynamic) int get viewsCount;@JsonKey(fromJson: stringFromDynamic) String get updatedAt;@JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic) UnifiedComicCover get cover;@JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic) List<UnifiedComicMetadata> get metadata;@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> get raw;@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> get extern;
/// Create a copy of UnifiedComicListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnifiedComicListItemCopyWith<UnifiedComicListItem> get copyWith => _$UnifiedComicListItemCopyWithImpl<UnifiedComicListItem>(this as UnifiedComicListItem, _$identity);

  /// Serializes this UnifiedComicListItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnifiedComicListItem&&(identical(other.source, source) || other.source == source)&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.finished, finished) || other.finished == finished)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&const DeepCollectionEquality().equals(other.raw, raw)&&const DeepCollectionEquality().equals(other.extern, extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,id,title,subtitle,finished,likesCount,viewsCount,updatedAt,cover,const DeepCollectionEquality().hash(metadata),const DeepCollectionEquality().hash(raw),const DeepCollectionEquality().hash(extern));

@override
String toString() {
  return 'UnifiedComicListItem(source: $source, id: $id, title: $title, subtitle: $subtitle, finished: $finished, likesCount: $likesCount, viewsCount: $viewsCount, updatedAt: $updatedAt, cover: $cover, metadata: $metadata, raw: $raw, extern: $extern)';
}


}

/// @nodoc
abstract mixin class $UnifiedComicListItemCopyWith<$Res>  {
  factory $UnifiedComicListItemCopyWith(UnifiedComicListItem value, $Res Function(UnifiedComicListItem) _then) = _$UnifiedComicListItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: stringFromDynamic) String source,@JsonKey(fromJson: stringFromDynamic) String id,@JsonKey(fromJson: stringFromDynamic) String title,@JsonKey(fromJson: stringFromDynamic) String subtitle,@JsonKey(fromJson: boolFromDynamic) bool finished,@JsonKey(fromJson: intFromDynamic) int likesCount,@JsonKey(fromJson: intFromDynamic) int viewsCount,@JsonKey(fromJson: stringFromDynamic) String updatedAt,@JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic) UnifiedComicCover cover,@JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic) List<UnifiedComicMetadata> metadata,@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> raw,@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> extern
});


$UnifiedComicCoverCopyWith<$Res> get cover;

}
/// @nodoc
class _$UnifiedComicListItemCopyWithImpl<$Res>
    implements $UnifiedComicListItemCopyWith<$Res> {
  _$UnifiedComicListItemCopyWithImpl(this._self, this._then);

  final UnifiedComicListItem _self;
  final $Res Function(UnifiedComicListItem) _then;

/// Create a copy of UnifiedComicListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? id = null,Object? title = null,Object? subtitle = null,Object? finished = null,Object? likesCount = null,Object? viewsCount = null,Object? updatedAt = null,Object? cover = null,Object? metadata = null,Object? raw = null,Object? extern = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as UnifiedComicCover,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<UnifiedComicMetadata>,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extern: null == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of UnifiedComicListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnifiedComicCoverCopyWith<$Res> get cover {
  
  return $UnifiedComicCoverCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// Adds pattern-matching-related methods to [UnifiedComicListItem].
extension UnifiedComicListItemPatterns on UnifiedComicListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnifiedComicListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnifiedComicListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnifiedComicListItem value)  $default,){
final _that = this;
switch (_that) {
case _UnifiedComicListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnifiedComicListItem value)?  $default,){
final _that = this;
switch (_that) {
case _UnifiedComicListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringFromDynamic)  String source, @JsonKey(fromJson: stringFromDynamic)  String id, @JsonKey(fromJson: stringFromDynamic)  String title, @JsonKey(fromJson: stringFromDynamic)  String subtitle, @JsonKey(fromJson: boolFromDynamic)  bool finished, @JsonKey(fromJson: intFromDynamic)  int likesCount, @JsonKey(fromJson: intFromDynamic)  int viewsCount, @JsonKey(fromJson: stringFromDynamic)  String updatedAt, @JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic)  UnifiedComicCover cover, @JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic)  List<UnifiedComicMetadata> metadata, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> raw, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnifiedComicListItem() when $default != null:
return $default(_that.source,_that.id,_that.title,_that.subtitle,_that.finished,_that.likesCount,_that.viewsCount,_that.updatedAt,_that.cover,_that.metadata,_that.raw,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringFromDynamic)  String source, @JsonKey(fromJson: stringFromDynamic)  String id, @JsonKey(fromJson: stringFromDynamic)  String title, @JsonKey(fromJson: stringFromDynamic)  String subtitle, @JsonKey(fromJson: boolFromDynamic)  bool finished, @JsonKey(fromJson: intFromDynamic)  int likesCount, @JsonKey(fromJson: intFromDynamic)  int viewsCount, @JsonKey(fromJson: stringFromDynamic)  String updatedAt, @JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic)  UnifiedComicCover cover, @JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic)  List<UnifiedComicMetadata> metadata, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> raw, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> extern)  $default,) {final _that = this;
switch (_that) {
case _UnifiedComicListItem():
return $default(_that.source,_that.id,_that.title,_that.subtitle,_that.finished,_that.likesCount,_that.viewsCount,_that.updatedAt,_that.cover,_that.metadata,_that.raw,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: stringFromDynamic)  String source, @JsonKey(fromJson: stringFromDynamic)  String id, @JsonKey(fromJson: stringFromDynamic)  String title, @JsonKey(fromJson: stringFromDynamic)  String subtitle, @JsonKey(fromJson: boolFromDynamic)  bool finished, @JsonKey(fromJson: intFromDynamic)  int likesCount, @JsonKey(fromJson: intFromDynamic)  int viewsCount, @JsonKey(fromJson: stringFromDynamic)  String updatedAt, @JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic)  UnifiedComicCover cover, @JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic)  List<UnifiedComicMetadata> metadata, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> raw, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> extern)?  $default,) {final _that = this;
switch (_that) {
case _UnifiedComicListItem() when $default != null:
return $default(_that.source,_that.id,_that.title,_that.subtitle,_that.finished,_that.likesCount,_that.viewsCount,_that.updatedAt,_that.cover,_that.metadata,_that.raw,_that.extern);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnifiedComicListItem extends UnifiedComicListItem {
  const _UnifiedComicListItem({@JsonKey(fromJson: stringFromDynamic) required this.source, @JsonKey(fromJson: stringFromDynamic) required this.id, @JsonKey(fromJson: stringFromDynamic) required this.title, @JsonKey(fromJson: stringFromDynamic) required this.subtitle, @JsonKey(fromJson: boolFromDynamic) required this.finished, @JsonKey(fromJson: intFromDynamic) required this.likesCount, @JsonKey(fromJson: intFromDynamic) required this.viewsCount, @JsonKey(fromJson: stringFromDynamic) required this.updatedAt, @JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic) required this.cover, @JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic) required final  List<UnifiedComicMetadata> metadata, @JsonKey(fromJson: mapFromDynamic) required final  Map<String, dynamic> raw, @JsonKey(fromJson: mapFromDynamic) required final  Map<String, dynamic> extern}): _metadata = metadata,_raw = raw,_extern = extern,super._();
  factory _UnifiedComicListItem.fromJson(Map<String, dynamic> json) => _$UnifiedComicListItemFromJson(json);

@override@JsonKey(fromJson: stringFromDynamic) final  String source;
@override@JsonKey(fromJson: stringFromDynamic) final  String id;
@override@JsonKey(fromJson: stringFromDynamic) final  String title;
@override@JsonKey(fromJson: stringFromDynamic) final  String subtitle;
@override@JsonKey(fromJson: boolFromDynamic) final  bool finished;
@override@JsonKey(fromJson: intFromDynamic) final  int likesCount;
@override@JsonKey(fromJson: intFromDynamic) final  int viewsCount;
@override@JsonKey(fromJson: stringFromDynamic) final  String updatedAt;
@override@JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic) final  UnifiedComicCover cover;
 final  List<UnifiedComicMetadata> _metadata;
@override@JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic) List<UnifiedComicMetadata> get metadata {
  if (_metadata is EqualUnmodifiableListView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metadata);
}

 final  Map<String, dynamic> _raw;
@override@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}

 final  Map<String, dynamic> _extern;
@override@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> get extern {
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extern);
}


/// Create a copy of UnifiedComicListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnifiedComicListItemCopyWith<_UnifiedComicListItem> get copyWith => __$UnifiedComicListItemCopyWithImpl<_UnifiedComicListItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnifiedComicListItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnifiedComicListItem&&(identical(other.source, source) || other.source == source)&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.finished, finished) || other.finished == finished)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&const DeepCollectionEquality().equals(other._raw, _raw)&&const DeepCollectionEquality().equals(other._extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,id,title,subtitle,finished,likesCount,viewsCount,updatedAt,cover,const DeepCollectionEquality().hash(_metadata),const DeepCollectionEquality().hash(_raw),const DeepCollectionEquality().hash(_extern));

@override
String toString() {
  return 'UnifiedComicListItem(source: $source, id: $id, title: $title, subtitle: $subtitle, finished: $finished, likesCount: $likesCount, viewsCount: $viewsCount, updatedAt: $updatedAt, cover: $cover, metadata: $metadata, raw: $raw, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$UnifiedComicListItemCopyWith<$Res> implements $UnifiedComicListItemCopyWith<$Res> {
  factory _$UnifiedComicListItemCopyWith(_UnifiedComicListItem value, $Res Function(_UnifiedComicListItem) _then) = __$UnifiedComicListItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: stringFromDynamic) String source,@JsonKey(fromJson: stringFromDynamic) String id,@JsonKey(fromJson: stringFromDynamic) String title,@JsonKey(fromJson: stringFromDynamic) String subtitle,@JsonKey(fromJson: boolFromDynamic) bool finished,@JsonKey(fromJson: intFromDynamic) int likesCount,@JsonKey(fromJson: intFromDynamic) int viewsCount,@JsonKey(fromJson: stringFromDynamic) String updatedAt,@JsonKey(fromJson: _coverFromDynamic, toJson: _coverToDynamic) UnifiedComicCover cover,@JsonKey(fromJson: _metadataListFromDynamic, toJson: _metadataListToDynamic) List<UnifiedComicMetadata> metadata,@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> raw,@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> extern
});


@override $UnifiedComicCoverCopyWith<$Res> get cover;

}
/// @nodoc
class __$UnifiedComicListItemCopyWithImpl<$Res>
    implements _$UnifiedComicListItemCopyWith<$Res> {
  __$UnifiedComicListItemCopyWithImpl(this._self, this._then);

  final _UnifiedComicListItem _self;
  final $Res Function(_UnifiedComicListItem) _then;

/// Create a copy of UnifiedComicListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? id = null,Object? title = null,Object? subtitle = null,Object? finished = null,Object? likesCount = null,Object? viewsCount = null,Object? updatedAt = null,Object? cover = null,Object? metadata = null,Object? raw = null,Object? extern = null,}) {
  return _then(_UnifiedComicListItem(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as UnifiedComicCover,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<UnifiedComicMetadata>,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extern: null == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of UnifiedComicListItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UnifiedComicCoverCopyWith<$Res> get cover {
  
  return $UnifiedComicCoverCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// @nodoc
mixin _$UnifiedComicCover {

@JsonKey(fromJson: stringFromDynamic) String get id;@JsonKey(fromJson: stringFromDynamic) String get url;@JsonKey(fromJson: stringFromDynamic) String get path;@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> get extern;
/// Create a copy of UnifiedComicCover
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnifiedComicCoverCopyWith<UnifiedComicCover> get copyWith => _$UnifiedComicCoverCopyWithImpl<UnifiedComicCover>(this as UnifiedComicCover, _$identity);

  /// Serializes this UnifiedComicCover to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnifiedComicCover&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other.extern, extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,path,const DeepCollectionEquality().hash(extern));

@override
String toString() {
  return 'UnifiedComicCover(id: $id, url: $url, path: $path, extern: $extern)';
}


}

/// @nodoc
abstract mixin class $UnifiedComicCoverCopyWith<$Res>  {
  factory $UnifiedComicCoverCopyWith(UnifiedComicCover value, $Res Function(UnifiedComicCover) _then) = _$UnifiedComicCoverCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: stringFromDynamic) String id,@JsonKey(fromJson: stringFromDynamic) String url,@JsonKey(fromJson: stringFromDynamic) String path,@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> extern
});




}
/// @nodoc
class _$UnifiedComicCoverCopyWithImpl<$Res>
    implements $UnifiedComicCoverCopyWith<$Res> {
  _$UnifiedComicCoverCopyWithImpl(this._self, this._then);

  final UnifiedComicCover _self;
  final $Res Function(UnifiedComicCover) _then;

/// Create a copy of UnifiedComicCover
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? path = null,Object? extern = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,extern: null == extern ? _self.extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnifiedComicCover].
extension UnifiedComicCoverPatterns on UnifiedComicCover {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnifiedComicCover value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnifiedComicCover() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnifiedComicCover value)  $default,){
final _that = this;
switch (_that) {
case _UnifiedComicCover():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnifiedComicCover value)?  $default,){
final _that = this;
switch (_that) {
case _UnifiedComicCover() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringFromDynamic)  String id, @JsonKey(fromJson: stringFromDynamic)  String url, @JsonKey(fromJson: stringFromDynamic)  String path, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> extern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnifiedComicCover() when $default != null:
return $default(_that.id,_that.url,_that.path,_that.extern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringFromDynamic)  String id, @JsonKey(fromJson: stringFromDynamic)  String url, @JsonKey(fromJson: stringFromDynamic)  String path, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> extern)  $default,) {final _that = this;
switch (_that) {
case _UnifiedComicCover():
return $default(_that.id,_that.url,_that.path,_that.extern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: stringFromDynamic)  String id, @JsonKey(fromJson: stringFromDynamic)  String url, @JsonKey(fromJson: stringFromDynamic)  String path, @JsonKey(fromJson: mapFromDynamic)  Map<String, dynamic> extern)?  $default,) {final _that = this;
switch (_that) {
case _UnifiedComicCover() when $default != null:
return $default(_that.id,_that.url,_that.path,_that.extern);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnifiedComicCover extends UnifiedComicCover {
  const _UnifiedComicCover({@JsonKey(fromJson: stringFromDynamic) required this.id, @JsonKey(fromJson: stringFromDynamic) required this.url, @JsonKey(fromJson: stringFromDynamic) required this.path, @JsonKey(fromJson: mapFromDynamic) required final  Map<String, dynamic> extern}): _extern = extern,super._();
  factory _UnifiedComicCover.fromJson(Map<String, dynamic> json) => _$UnifiedComicCoverFromJson(json);

@override@JsonKey(fromJson: stringFromDynamic) final  String id;
@override@JsonKey(fromJson: stringFromDynamic) final  String url;
@override@JsonKey(fromJson: stringFromDynamic) final  String path;
 final  Map<String, dynamic> _extern;
@override@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> get extern {
  if (_extern is EqualUnmodifiableMapView) return _extern;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extern);
}


/// Create a copy of UnifiedComicCover
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnifiedComicCoverCopyWith<_UnifiedComicCover> get copyWith => __$UnifiedComicCoverCopyWithImpl<_UnifiedComicCover>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnifiedComicCoverToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnifiedComicCover&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other._extern, _extern));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,path,const DeepCollectionEquality().hash(_extern));

@override
String toString() {
  return 'UnifiedComicCover(id: $id, url: $url, path: $path, extern: $extern)';
}


}

/// @nodoc
abstract mixin class _$UnifiedComicCoverCopyWith<$Res> implements $UnifiedComicCoverCopyWith<$Res> {
  factory _$UnifiedComicCoverCopyWith(_UnifiedComicCover value, $Res Function(_UnifiedComicCover) _then) = __$UnifiedComicCoverCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: stringFromDynamic) String id,@JsonKey(fromJson: stringFromDynamic) String url,@JsonKey(fromJson: stringFromDynamic) String path,@JsonKey(fromJson: mapFromDynamic) Map<String, dynamic> extern
});




}
/// @nodoc
class __$UnifiedComicCoverCopyWithImpl<$Res>
    implements _$UnifiedComicCoverCopyWith<$Res> {
  __$UnifiedComicCoverCopyWithImpl(this._self, this._then);

  final _UnifiedComicCover _self;
  final $Res Function(_UnifiedComicCover) _then;

/// Create a copy of UnifiedComicCover
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? path = null,Object? extern = null,}) {
  return _then(_UnifiedComicCover(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,extern: null == extern ? _self._extern : extern // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$UnifiedComicMetadata {

@JsonKey(fromJson: stringFromDynamic) String get type;@JsonKey(fromJson: stringFromDynamic) String get name;@JsonKey(fromJson: _metadataValueFromDynamic) List<Object> get value;
/// Create a copy of UnifiedComicMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnifiedComicMetadataCopyWith<UnifiedComicMetadata> get copyWith => _$UnifiedComicMetadataCopyWithImpl<UnifiedComicMetadata>(this as UnifiedComicMetadata, _$identity);

  /// Serializes this UnifiedComicMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnifiedComicMetadata&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.value, value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,name,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'UnifiedComicMetadata(type: $type, name: $name, value: $value)';
}


}

/// @nodoc
abstract mixin class $UnifiedComicMetadataCopyWith<$Res>  {
  factory $UnifiedComicMetadataCopyWith(UnifiedComicMetadata value, $Res Function(UnifiedComicMetadata) _then) = _$UnifiedComicMetadataCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: stringFromDynamic) String type,@JsonKey(fromJson: stringFromDynamic) String name,@JsonKey(fromJson: _metadataValueFromDynamic) List<Object> value
});




}
/// @nodoc
class _$UnifiedComicMetadataCopyWithImpl<$Res>
    implements $UnifiedComicMetadataCopyWith<$Res> {
  _$UnifiedComicMetadataCopyWithImpl(this._self, this._then);

  final UnifiedComicMetadata _self;
  final $Res Function(UnifiedComicMetadata) _then;

/// Create a copy of UnifiedComicMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? name = null,Object? value = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as List<Object>,
  ));
}

}


/// Adds pattern-matching-related methods to [UnifiedComicMetadata].
extension UnifiedComicMetadataPatterns on UnifiedComicMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnifiedComicMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnifiedComicMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnifiedComicMetadata value)  $default,){
final _that = this;
switch (_that) {
case _UnifiedComicMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnifiedComicMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _UnifiedComicMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringFromDynamic)  String type, @JsonKey(fromJson: stringFromDynamic)  String name, @JsonKey(fromJson: _metadataValueFromDynamic)  List<Object> value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnifiedComicMetadata() when $default != null:
return $default(_that.type,_that.name,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: stringFromDynamic)  String type, @JsonKey(fromJson: stringFromDynamic)  String name, @JsonKey(fromJson: _metadataValueFromDynamic)  List<Object> value)  $default,) {final _that = this;
switch (_that) {
case _UnifiedComicMetadata():
return $default(_that.type,_that.name,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: stringFromDynamic)  String type, @JsonKey(fromJson: stringFromDynamic)  String name, @JsonKey(fromJson: _metadataValueFromDynamic)  List<Object> value)?  $default,) {final _that = this;
switch (_that) {
case _UnifiedComicMetadata() when $default != null:
return $default(_that.type,_that.name,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UnifiedComicMetadata extends UnifiedComicMetadata {
  const _UnifiedComicMetadata({@JsonKey(fromJson: stringFromDynamic) required this.type, @JsonKey(fromJson: stringFromDynamic) required this.name, @JsonKey(fromJson: _metadataValueFromDynamic) required final  List<Object> value}): _value = value,super._();
  factory _UnifiedComicMetadata.fromJson(Map<String, dynamic> json) => _$UnifiedComicMetadataFromJson(json);

@override@JsonKey(fromJson: stringFromDynamic) final  String type;
@override@JsonKey(fromJson: stringFromDynamic) final  String name;
 final  List<Object> _value;
@override@JsonKey(fromJson: _metadataValueFromDynamic) List<Object> get value {
  if (_value is EqualUnmodifiableListView) return _value;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_value);
}


/// Create a copy of UnifiedComicMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnifiedComicMetadataCopyWith<_UnifiedComicMetadata> get copyWith => __$UnifiedComicMetadataCopyWithImpl<_UnifiedComicMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UnifiedComicMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnifiedComicMetadata&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._value, _value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,name,const DeepCollectionEquality().hash(_value));

@override
String toString() {
  return 'UnifiedComicMetadata(type: $type, name: $name, value: $value)';
}


}

/// @nodoc
abstract mixin class _$UnifiedComicMetadataCopyWith<$Res> implements $UnifiedComicMetadataCopyWith<$Res> {
  factory _$UnifiedComicMetadataCopyWith(_UnifiedComicMetadata value, $Res Function(_UnifiedComicMetadata) _then) = __$UnifiedComicMetadataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: stringFromDynamic) String type,@JsonKey(fromJson: stringFromDynamic) String name,@JsonKey(fromJson: _metadataValueFromDynamic) List<Object> value
});




}
/// @nodoc
class __$UnifiedComicMetadataCopyWithImpl<$Res>
    implements _$UnifiedComicMetadataCopyWith<$Res> {
  __$UnifiedComicMetadataCopyWithImpl(this._self, this._then);

  final _UnifiedComicMetadata _self;
  final $Res Function(_UnifiedComicMetadata) _then;

/// Create a copy of UnifiedComicMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? name = null,Object? value = null,}) {
  return _then(_UnifiedComicMetadata(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self._value : value // ignore: cast_nullable_to_non_nullable
as List<Object>,
  ));
}


}

// dart format on
