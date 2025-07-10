// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_ep_info_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmEpInfoJson {

@JsonKey(name: "id") int get id;@JsonKey(name: "series") List<Series> get series;@JsonKey(name: "tags") String get tags;@JsonKey(name: "name") String get name;@JsonKey(name: "images") List<String> get images;@JsonKey(name: "addtime") String get addtime;@JsonKey(name: "series_id") String get seriesId;@JsonKey(name: "is_favorite") bool get isFavorite;@JsonKey(name: "liked") bool get liked;
/// Create a copy of JmEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmEpInfoJsonCopyWith<JmEpInfoJson> get copyWith => _$JmEpInfoJsonCopyWithImpl<JmEpInfoJson>(this as JmEpInfoJson, _$identity);

  /// Serializes this JmEpInfoJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmEpInfoJson&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other.series, series)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.liked, liked) || other.liked == liked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(series),tags,name,const DeepCollectionEquality().hash(images),addtime,seriesId,isFavorite,liked);

@override
String toString() {
  return 'JmEpInfoJson(id: $id, series: $series, tags: $tags, name: $name, images: $images, addtime: $addtime, seriesId: $seriesId, isFavorite: $isFavorite, liked: $liked)';
}


}

/// @nodoc
abstract mixin class $JmEpInfoJsonCopyWith<$Res>  {
  factory $JmEpInfoJsonCopyWith(JmEpInfoJson value, $Res Function(JmEpInfoJson) _then) = _$JmEpInfoJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "series") List<Series> series,@JsonKey(name: "tags") String tags,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<String> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "liked") bool liked
});




}
/// @nodoc
class _$JmEpInfoJsonCopyWithImpl<$Res>
    implements $JmEpInfoJsonCopyWith<$Res> {
  _$JmEpInfoJsonCopyWithImpl(this._self, this._then);

  final JmEpInfoJson _self;
  final $Res Function(JmEpInfoJson) _then;

/// Create a copy of JmEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? series = null,Object? tags = null,Object? name = null,Object? images = null,Object? addtime = null,Object? seriesId = null,Object? isFavorite = null,Object? liked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<Series>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [JmEpInfoJson].
extension JmEpInfoJsonPatterns on JmEpInfoJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmEpInfoJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmEpInfoJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmEpInfoJson value)  $default,){
final _that = this;
switch (_that) {
case _JmEpInfoJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmEpInfoJson value)?  $default,){
final _that = this;
switch (_that) {
case _JmEpInfoJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int id, @JsonKey(name: "series")  List<Series> series, @JsonKey(name: "tags")  String tags, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<String> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "liked")  bool liked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmEpInfoJson() when $default != null:
return $default(_that.id,_that.series,_that.tags,_that.name,_that.images,_that.addtime,_that.seriesId,_that.isFavorite,_that.liked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  int id, @JsonKey(name: "series")  List<Series> series, @JsonKey(name: "tags")  String tags, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<String> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "liked")  bool liked)  $default,) {final _that = this;
switch (_that) {
case _JmEpInfoJson():
return $default(_that.id,_that.series,_that.tags,_that.name,_that.images,_that.addtime,_that.seriesId,_that.isFavorite,_that.liked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  int id, @JsonKey(name: "series")  List<Series> series, @JsonKey(name: "tags")  String tags, @JsonKey(name: "name")  String name, @JsonKey(name: "images")  List<String> images, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "series_id")  String seriesId, @JsonKey(name: "is_favorite")  bool isFavorite, @JsonKey(name: "liked")  bool liked)?  $default,) {final _that = this;
switch (_that) {
case _JmEpInfoJson() when $default != null:
return $default(_that.id,_that.series,_that.tags,_that.name,_that.images,_that.addtime,_that.seriesId,_that.isFavorite,_that.liked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JmEpInfoJson implements JmEpInfoJson {
  const _JmEpInfoJson({@JsonKey(name: "id") required this.id, @JsonKey(name: "series") required final  List<Series> series, @JsonKey(name: "tags") required this.tags, @JsonKey(name: "name") required this.name, @JsonKey(name: "images") required final  List<String> images, @JsonKey(name: "addtime") required this.addtime, @JsonKey(name: "series_id") required this.seriesId, @JsonKey(name: "is_favorite") required this.isFavorite, @JsonKey(name: "liked") required this.liked}): _series = series,_images = images;
  factory _JmEpInfoJson.fromJson(Map<String, dynamic> json) => _$JmEpInfoJsonFromJson(json);

@override@JsonKey(name: "id") final  int id;
 final  List<Series> _series;
@override@JsonKey(name: "series") List<Series> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

@override@JsonKey(name: "tags") final  String tags;
@override@JsonKey(name: "name") final  String name;
 final  List<String> _images;
@override@JsonKey(name: "images") List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

@override@JsonKey(name: "addtime") final  String addtime;
@override@JsonKey(name: "series_id") final  String seriesId;
@override@JsonKey(name: "is_favorite") final  bool isFavorite;
@override@JsonKey(name: "liked") final  bool liked;

/// Create a copy of JmEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmEpInfoJsonCopyWith<_JmEpInfoJson> get copyWith => __$JmEpInfoJsonCopyWithImpl<_JmEpInfoJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmEpInfoJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmEpInfoJson&&(identical(other.id, id) || other.id == id)&&const DeepCollectionEquality().equals(other._series, _series)&&(identical(other.tags, tags) || other.tags == tags)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.seriesId, seriesId) || other.seriesId == seriesId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.liked, liked) || other.liked == liked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,const DeepCollectionEquality().hash(_series),tags,name,const DeepCollectionEquality().hash(_images),addtime,seriesId,isFavorite,liked);

@override
String toString() {
  return 'JmEpInfoJson(id: $id, series: $series, tags: $tags, name: $name, images: $images, addtime: $addtime, seriesId: $seriesId, isFavorite: $isFavorite, liked: $liked)';
}


}

/// @nodoc
abstract mixin class _$JmEpInfoJsonCopyWith<$Res> implements $JmEpInfoJsonCopyWith<$Res> {
  factory _$JmEpInfoJsonCopyWith(_JmEpInfoJson value, $Res Function(_JmEpInfoJson) _then) = __$JmEpInfoJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") int id,@JsonKey(name: "series") List<Series> series,@JsonKey(name: "tags") String tags,@JsonKey(name: "name") String name,@JsonKey(name: "images") List<String> images,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "series_id") String seriesId,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "liked") bool liked
});




}
/// @nodoc
class __$JmEpInfoJsonCopyWithImpl<$Res>
    implements _$JmEpInfoJsonCopyWith<$Res> {
  __$JmEpInfoJsonCopyWithImpl(this._self, this._then);

  final _JmEpInfoJson _self;
  final $Res Function(_JmEpInfoJson) _then;

/// Create a copy of JmEpInfoJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? series = null,Object? tags = null,Object? name = null,Object? images = null,Object? addtime = null,Object? seriesId = null,Object? isFavorite = null,Object? liked = null,}) {
  return _then(_JmEpInfoJson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<Series>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,seriesId: null == seriesId ? _self.seriesId : seriesId // ignore: cast_nullable_to_non_nullable
as String,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Series {

@JsonKey(name: "id") String get id;@JsonKey(name: "name") String get name;@JsonKey(name: "sort") String get sort;
/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriesCopyWith<Series> get copyWith => _$SeriesCopyWithImpl<Series>(this as Series, _$identity);

  /// Serializes this Series to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Series&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort);

@override
String toString() {
  return 'Series(id: $id, name: $name, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $SeriesCopyWith<$Res>  {
  factory $SeriesCopyWith(Series value, $Res Function(Series) _then) = _$SeriesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort
});




}
/// @nodoc
class _$SeriesCopyWithImpl<$Res>
    implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._self, this._then);

  final Series _self;
  final $Res Function(Series) _then;

/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? sort = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Series].
extension SeriesPatterns on Series {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Series value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Series() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Series value)  $default,){
final _that = this;
switch (_that) {
case _Series():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Series value)?  $default,){
final _that = this;
switch (_that) {
case _Series() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Series() when $default != null:
return $default(_that.id,_that.name,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort)  $default,) {final _that = this;
switch (_that) {
case _Series():
return $default(_that.id,_that.name,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "name")  String name, @JsonKey(name: "sort")  String sort)?  $default,) {final _that = this;
switch (_that) {
case _Series() when $default != null:
return $default(_that.id,_that.name,_that.sort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Series implements Series {
  const _Series({@JsonKey(name: "id") required this.id, @JsonKey(name: "name") required this.name, @JsonKey(name: "sort") required this.sort});
  factory _Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "sort") final  String sort;

/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriesCopyWith<_Series> get copyWith => __$SeriesCopyWithImpl<_Series>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Series&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,sort);

@override
String toString() {
  return 'Series(id: $id, name: $name, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$SeriesCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$SeriesCopyWith(_Series value, $Res Function(_Series) _then) = __$SeriesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "name") String name,@JsonKey(name: "sort") String sort
});




}
/// @nodoc
class __$SeriesCopyWithImpl<$Res>
    implements _$SeriesCopyWith<$Res> {
  __$SeriesCopyWithImpl(this._self, this._then);

  final _Series _self;
  final $Res Function(_Series) _then;

/// Create a copy of Series
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? sort = null,}) {
  return _then(_Series(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
