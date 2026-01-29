// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_promote_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmPromoteJson {

@JsonKey(name: "id") dynamic get id;@JsonKey(name: "title") String get title;@JsonKey(name: "slug") String get slug;@JsonKey(name: "type") String get type;@JsonKey(name: "filter_val") dynamic get filterVal;@JsonKey(name: "content") List<Content> get content;
/// Create a copy of JmPromoteJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmPromoteJsonCopyWith<JmPromoteJson> get copyWith => _$JmPromoteJsonCopyWithImpl<JmPromoteJson>(this as JmPromoteJson, _$identity);

  /// Serializes this JmPromoteJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmPromoteJson&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.filterVal, filterVal)&&const DeepCollectionEquality().equals(other.content, content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),title,slug,type,const DeepCollectionEquality().hash(filterVal),const DeepCollectionEquality().hash(content));

@override
String toString() {
  return 'JmPromoteJson(id: $id, title: $title, slug: $slug, type: $type, filterVal: $filterVal, content: $content)';
}


}

/// @nodoc
abstract mixin class $JmPromoteJsonCopyWith<$Res>  {
  factory $JmPromoteJsonCopyWith(JmPromoteJson value, $Res Function(JmPromoteJson) _then) = _$JmPromoteJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") dynamic id,@JsonKey(name: "title") String title,@JsonKey(name: "slug") String slug,@JsonKey(name: "type") String type,@JsonKey(name: "filter_val") dynamic filterVal,@JsonKey(name: "content") List<Content> content
});




}
/// @nodoc
class _$JmPromoteJsonCopyWithImpl<$Res>
    implements $JmPromoteJsonCopyWith<$Res> {
  _$JmPromoteJsonCopyWithImpl(this._self, this._then);

  final JmPromoteJson _self;
  final $Res Function(JmPromoteJson) _then;

/// Create a copy of JmPromoteJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? title = null,Object? slug = null,Object? type = null,Object? filterVal = freezed,Object? content = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as dynamic,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,filterVal: freezed == filterVal ? _self.filterVal : filterVal // ignore: cast_nullable_to_non_nullable
as dynamic,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as List<Content>,
  ));
}

}


/// Adds pattern-matching-related methods to [JmPromoteJson].
extension JmPromoteJsonPatterns on JmPromoteJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmPromoteJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmPromoteJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmPromoteJson value)  $default,){
final _that = this;
switch (_that) {
case _JmPromoteJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmPromoteJson value)?  $default,){
final _that = this;
switch (_that) {
case _JmPromoteJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  dynamic id, @JsonKey(name: "title")  String title, @JsonKey(name: "slug")  String slug, @JsonKey(name: "type")  String type, @JsonKey(name: "filter_val")  dynamic filterVal, @JsonKey(name: "content")  List<Content> content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmPromoteJson() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.type,_that.filterVal,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  dynamic id, @JsonKey(name: "title")  String title, @JsonKey(name: "slug")  String slug, @JsonKey(name: "type")  String type, @JsonKey(name: "filter_val")  dynamic filterVal, @JsonKey(name: "content")  List<Content> content)  $default,) {final _that = this;
switch (_that) {
case _JmPromoteJson():
return $default(_that.id,_that.title,_that.slug,_that.type,_that.filterVal,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  dynamic id, @JsonKey(name: "title")  String title, @JsonKey(name: "slug")  String slug, @JsonKey(name: "type")  String type, @JsonKey(name: "filter_val")  dynamic filterVal, @JsonKey(name: "content")  List<Content> content)?  $default,) {final _that = this;
switch (_that) {
case _JmPromoteJson() when $default != null:
return $default(_that.id,_that.title,_that.slug,_that.type,_that.filterVal,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JmPromoteJson implements JmPromoteJson {
  const _JmPromoteJson({@JsonKey(name: "id") required this.id, @JsonKey(name: "title") required this.title, @JsonKey(name: "slug") required this.slug, @JsonKey(name: "type") required this.type, @JsonKey(name: "filter_val") required this.filterVal, @JsonKey(name: "content") required final  List<Content> content}): _content = content;
  factory _JmPromoteJson.fromJson(Map<String, dynamic> json) => _$JmPromoteJsonFromJson(json);

@override@JsonKey(name: "id") final  dynamic id;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "slug") final  String slug;
@override@JsonKey(name: "type") final  String type;
@override@JsonKey(name: "filter_val") final  dynamic filterVal;
 final  List<Content> _content;
@override@JsonKey(name: "content") List<Content> get content {
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_content);
}


/// Create a copy of JmPromoteJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmPromoteJsonCopyWith<_JmPromoteJson> get copyWith => __$JmPromoteJsonCopyWithImpl<_JmPromoteJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmPromoteJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmPromoteJson&&const DeepCollectionEquality().equals(other.id, id)&&(identical(other.title, title) || other.title == title)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.filterVal, filterVal)&&const DeepCollectionEquality().equals(other._content, _content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(id),title,slug,type,const DeepCollectionEquality().hash(filterVal),const DeepCollectionEquality().hash(_content));

@override
String toString() {
  return 'JmPromoteJson(id: $id, title: $title, slug: $slug, type: $type, filterVal: $filterVal, content: $content)';
}


}

/// @nodoc
abstract mixin class _$JmPromoteJsonCopyWith<$Res> implements $JmPromoteJsonCopyWith<$Res> {
  factory _$JmPromoteJsonCopyWith(_JmPromoteJson value, $Res Function(_JmPromoteJson) _then) = __$JmPromoteJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") dynamic id,@JsonKey(name: "title") String title,@JsonKey(name: "slug") String slug,@JsonKey(name: "type") String type,@JsonKey(name: "filter_val") dynamic filterVal,@JsonKey(name: "content") List<Content> content
});




}
/// @nodoc
class __$JmPromoteJsonCopyWithImpl<$Res>
    implements _$JmPromoteJsonCopyWith<$Res> {
  __$JmPromoteJsonCopyWithImpl(this._self, this._then);

  final _JmPromoteJson _self;
  final $Res Function(_JmPromoteJson) _then;

/// Create a copy of JmPromoteJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? title = null,Object? slug = null,Object? type = null,Object? filterVal = freezed,Object? content = null,}) {
  return _then(_JmPromoteJson(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as dynamic,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,filterVal: freezed == filterVal ? _self.filterVal : filterVal // ignore: cast_nullable_to_non_nullable
as dynamic,content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<Content>,
  ));
}


}


/// @nodoc
mixin _$Content {

@JsonKey(name: "id") String get id;@JsonKey(name: "author") String get author;@JsonKey(name: "name") String get name;@JsonKey(name: "image") String get image;@JsonKey(name: "category") Category? get category;@JsonKey(name: "category_sub") CategorySub? get categorySub;@JsonKey(name: "liked") bool? get liked;@JsonKey(name: "is_favorite") bool? get isFavorite;
/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContentCopyWith<Content> get copyWith => _$ContentCopyWithImpl<Content>(this as Content, _$identity);

  /// Serializes this Content to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Content&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.category, category) || other.category == category)&&(identical(other.categorySub, categorySub) || other.categorySub == categorySub)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,name,image,category,categorySub,liked,isFavorite);

@override
String toString() {
  return 'Content(id: $id, author: $author, name: $name, image: $image, category: $category, categorySub: $categorySub, liked: $liked, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class $ContentCopyWith<$Res>  {
  factory $ContentCopyWith(Content value, $Res Function(Content) _then) = _$ContentCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "name") String name,@JsonKey(name: "image") String image,@JsonKey(name: "category") Category? category,@JsonKey(name: "category_sub") CategorySub? categorySub,@JsonKey(name: "liked") bool? liked,@JsonKey(name: "is_favorite") bool? isFavorite
});


$CategoryCopyWith<$Res>? get category;$CategorySubCopyWith<$Res>? get categorySub;

}
/// @nodoc
class _$ContentCopyWithImpl<$Res>
    implements $ContentCopyWith<$Res> {
  _$ContentCopyWithImpl(this._self, this._then);

  final Content _self;
  final $Res Function(Content) _then;

/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? name = null,Object? image = null,Object? category = freezed,Object? categorySub = freezed,Object? liked = freezed,Object? isFavorite = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,categorySub: freezed == categorySub ? _self.categorySub : categorySub // ignore: cast_nullable_to_non_nullable
as CategorySub?,liked: freezed == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}
/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategorySubCopyWith<$Res>? get categorySub {
    if (_self.categorySub == null) {
    return null;
  }

  return $CategorySubCopyWith<$Res>(_self.categorySub!, (value) {
    return _then(_self.copyWith(categorySub: value));
  });
}
}


/// Adds pattern-matching-related methods to [Content].
extension ContentPatterns on Content {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Content value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Content() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Content value)  $default,){
final _that = this;
switch (_that) {
case _Content():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Content value)?  $default,){
final _that = this;
switch (_that) {
case _Content() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "name")  String name, @JsonKey(name: "image")  String image, @JsonKey(name: "category")  Category? category, @JsonKey(name: "category_sub")  CategorySub? categorySub, @JsonKey(name: "liked")  bool? liked, @JsonKey(name: "is_favorite")  bool? isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Content() when $default != null:
return $default(_that.id,_that.author,_that.name,_that.image,_that.category,_that.categorySub,_that.liked,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "name")  String name, @JsonKey(name: "image")  String image, @JsonKey(name: "category")  Category? category, @JsonKey(name: "category_sub")  CategorySub? categorySub, @JsonKey(name: "liked")  bool? liked, @JsonKey(name: "is_favorite")  bool? isFavorite)  $default,) {final _that = this;
switch (_that) {
case _Content():
return $default(_that.id,_that.author,_that.name,_that.image,_that.category,_that.categorySub,_that.liked,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "name")  String name, @JsonKey(name: "image")  String image, @JsonKey(name: "category")  Category? category, @JsonKey(name: "category_sub")  CategorySub? categorySub, @JsonKey(name: "liked")  bool? liked, @JsonKey(name: "is_favorite")  bool? isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _Content() when $default != null:
return $default(_that.id,_that.author,_that.name,_that.image,_that.category,_that.categorySub,_that.liked,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Content implements Content {
  const _Content({@JsonKey(name: "id") required this.id, @JsonKey(name: "author") required this.author, @JsonKey(name: "name") required this.name, @JsonKey(name: "image") required this.image, @JsonKey(name: "category") required this.category, @JsonKey(name: "category_sub") required this.categorySub, @JsonKey(name: "liked") required this.liked, @JsonKey(name: "is_favorite") required this.isFavorite});
  factory _Content.fromJson(Map<String, dynamic> json) => _$ContentFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "image") final  String image;
@override@JsonKey(name: "category") final  Category? category;
@override@JsonKey(name: "category_sub") final  CategorySub? categorySub;
@override@JsonKey(name: "liked") final  bool? liked;
@override@JsonKey(name: "is_favorite") final  bool? isFavorite;

/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ContentCopyWith<_Content> get copyWith => __$ContentCopyWithImpl<_Content>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Content&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.name, name) || other.name == name)&&(identical(other.image, image) || other.image == image)&&(identical(other.category, category) || other.category == category)&&(identical(other.categorySub, categorySub) || other.categorySub == categorySub)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,name,image,category,categorySub,liked,isFavorite);

@override
String toString() {
  return 'Content(id: $id, author: $author, name: $name, image: $image, category: $category, categorySub: $categorySub, liked: $liked, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$ContentCopyWith<$Res> implements $ContentCopyWith<$Res> {
  factory _$ContentCopyWith(_Content value, $Res Function(_Content) _then) = __$ContentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "name") String name,@JsonKey(name: "image") String image,@JsonKey(name: "category") Category? category,@JsonKey(name: "category_sub") CategorySub? categorySub,@JsonKey(name: "liked") bool? liked,@JsonKey(name: "is_favorite") bool? isFavorite
});


@override $CategoryCopyWith<$Res>? get category;@override $CategorySubCopyWith<$Res>? get categorySub;

}
/// @nodoc
class __$ContentCopyWithImpl<$Res>
    implements _$ContentCopyWith<$Res> {
  __$ContentCopyWithImpl(this._self, this._then);

  final _Content _self;
  final $Res Function(_Content) _then;

/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? name = null,Object? image = null,Object? category = freezed,Object? categorySub = freezed,Object? liked = freezed,Object? isFavorite = freezed,}) {
  return _then(_Content(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category?,categorySub: freezed == categorySub ? _self.categorySub : categorySub // ignore: cast_nullable_to_non_nullable
as CategorySub?,liked: freezed == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool?,isFavorite: freezed == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of Content
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategorySubCopyWith<$Res>? get categorySub {
    if (_self.categorySub == null) {
    return null;
  }

  return $CategorySubCopyWith<$Res>(_self.categorySub!, (value) {
    return _then(_self.copyWith(categorySub: value));
  });
}
}


/// @nodoc
mixin _$Category {

@JsonKey(name: "id") String get id;@JsonKey(name: "title") String get title;
/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryCopyWith<Category> get copyWith => _$CategoryCopyWithImpl<Category>(this as Category, _$identity);

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Category&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'Category(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class $CategoryCopyWith<$Res>  {
  factory $CategoryCopyWith(Category value, $Res Function(Category) _then) = _$CategoryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "title") String title
});




}
/// @nodoc
class _$CategoryCopyWithImpl<$Res>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._self, this._then);

  final Category _self;
  final $Res Function(Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Category].
extension CategoryPatterns on Category {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Category value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Category value)  $default,){
final _that = this;
switch (_that) {
case _Category():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Category value)?  $default,){
final _that = this;
switch (_that) {
case _Category() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "title")  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "title")  String title)  $default,) {final _that = this;
switch (_that) {
case _Category():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "title")  String title)?  $default,) {final _that = this;
switch (_that) {
case _Category() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Category implements Category {
  const _Category({@JsonKey(name: "id") required this.id, @JsonKey(name: "title") required this.title});
  factory _Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "title") final  String title;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryCopyWith<_Category> get copyWith => __$CategoryCopyWithImpl<_Category>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Category&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'Category(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CategoryCopyWith<$Res> implements $CategoryCopyWith<$Res> {
  factory _$CategoryCopyWith(_Category value, $Res Function(_Category) _then) = __$CategoryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "title") String title
});




}
/// @nodoc
class __$CategoryCopyWithImpl<$Res>
    implements _$CategoryCopyWith<$Res> {
  __$CategoryCopyWithImpl(this._self, this._then);

  final _Category _self;
  final $Res Function(_Category) _then;

/// Create a copy of Category
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_Category(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$CategorySub {

@JsonKey(name: "id") String? get id;@JsonKey(name: "title") String? get title;
/// Create a copy of CategorySub
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySubCopyWith<CategorySub> get copyWith => _$CategorySubCopyWithImpl<CategorySub>(this as CategorySub, _$identity);

  /// Serializes this CategorySub to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySub&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'CategorySub(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class $CategorySubCopyWith<$Res>  {
  factory $CategorySubCopyWith(CategorySub value, $Res Function(CategorySub) _then) = _$CategorySubCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String? id,@JsonKey(name: "title") String? title
});




}
/// @nodoc
class _$CategorySubCopyWithImpl<$Res>
    implements $CategorySubCopyWith<$Res> {
  _$CategorySubCopyWithImpl(this._self, this._then);

  final CategorySub _self;
  final $Res Function(CategorySub) _then;

/// Create a copy of CategorySub
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? title = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorySub].
extension CategorySubPatterns on CategorySub {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySub value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySub() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySub value)  $default,){
final _that = this;
switch (_that) {
case _CategorySub():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySub value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySub() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String? id, @JsonKey(name: "title")  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySub() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String? id, @JsonKey(name: "title")  String? title)  $default,) {final _that = this;
switch (_that) {
case _CategorySub():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String? id, @JsonKey(name: "title")  String? title)?  $default,) {final _that = this;
switch (_that) {
case _CategorySub() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategorySub implements CategorySub {
  const _CategorySub({@JsonKey(name: "id") required this.id, @JsonKey(name: "title") required this.title});
  factory _CategorySub.fromJson(Map<String, dynamic> json) => _$CategorySubFromJson(json);

@override@JsonKey(name: "id") final  String? id;
@override@JsonKey(name: "title") final  String? title;

/// Create a copy of CategorySub
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySubCopyWith<_CategorySub> get copyWith => __$CategorySubCopyWithImpl<_CategorySub>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategorySubToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySub&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'CategorySub(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$CategorySubCopyWith<$Res> implements $CategorySubCopyWith<$Res> {
  factory _$CategorySubCopyWith(_CategorySub value, $Res Function(_CategorySub) _then) = __$CategorySubCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String? id,@JsonKey(name: "title") String? title
});




}
/// @nodoc
class __$CategorySubCopyWithImpl<$Res>
    implements _$CategorySubCopyWith<$Res> {
  __$CategorySubCopyWithImpl(this._self, this._then);

  final _CategorySub _self;
  final $Res Function(_CategorySub) _then;

/// Create a copy of CategorySub
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? title = freezed,}) {
  return _then(_CategorySub(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
