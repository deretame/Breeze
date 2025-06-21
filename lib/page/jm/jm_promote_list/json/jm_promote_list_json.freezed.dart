// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_promote_list_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmPromoteListJson {

@JsonKey(name: "total") String get total;@JsonKey(name: "list") List<ListElement> get list;
/// Create a copy of JmPromoteListJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmPromoteListJsonCopyWith<JmPromoteListJson> get copyWith => _$JmPromoteListJsonCopyWithImpl<JmPromoteListJson>(this as JmPromoteListJson, _$identity);

  /// Serializes this JmPromoteListJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmPromoteListJson&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.list, list));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(list));

@override
String toString() {
  return 'JmPromoteListJson(total: $total, list: $list)';
}


}

/// @nodoc
abstract mixin class $JmPromoteListJsonCopyWith<$Res>  {
  factory $JmPromoteListJsonCopyWith(JmPromoteListJson value, $Res Function(JmPromoteListJson) _then) = _$JmPromoteListJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "total") String total,@JsonKey(name: "list") List<ListElement> list
});




}
/// @nodoc
class _$JmPromoteListJsonCopyWithImpl<$Res>
    implements $JmPromoteListJsonCopyWith<$Res> {
  _$JmPromoteListJsonCopyWithImpl(this._self, this._then);

  final JmPromoteListJson _self;
  final $Res Function(JmPromoteListJson) _then;

/// Create a copy of JmPromoteListJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? list = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _JmPromoteListJson implements JmPromoteListJson {
  const _JmPromoteListJson({@JsonKey(name: "total") required this.total, @JsonKey(name: "list") required final  List<ListElement> list}): _list = list;
  factory _JmPromoteListJson.fromJson(Map<String, dynamic> json) => _$JmPromoteListJsonFromJson(json);

@override@JsonKey(name: "total") final  String total;
 final  List<ListElement> _list;
@override@JsonKey(name: "list") List<ListElement> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}


/// Create a copy of JmPromoteListJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmPromoteListJsonCopyWith<_JmPromoteListJson> get copyWith => __$JmPromoteListJsonCopyWithImpl<_JmPromoteListJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmPromoteListJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmPromoteListJson&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._list, _list));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,const DeepCollectionEquality().hash(_list));

@override
String toString() {
  return 'JmPromoteListJson(total: $total, list: $list)';
}


}

/// @nodoc
abstract mixin class _$JmPromoteListJsonCopyWith<$Res> implements $JmPromoteListJsonCopyWith<$Res> {
  factory _$JmPromoteListJsonCopyWith(_JmPromoteListJson value, $Res Function(_JmPromoteListJson) _then) = __$JmPromoteListJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "total") String total,@JsonKey(name: "list") List<ListElement> list
});




}
/// @nodoc
class __$JmPromoteListJsonCopyWithImpl<$Res>
    implements _$JmPromoteListJsonCopyWith<$Res> {
  __$JmPromoteListJsonCopyWithImpl(this._self, this._then);

  final _JmPromoteListJson _self;
  final $Res Function(_JmPromoteListJson) _then;

/// Create a copy of JmPromoteListJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? list = null,}) {
  return _then(_JmPromoteListJson(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,
  ));
}


}


/// @nodoc
mixin _$ListElement {

@JsonKey(name: "id") String get id;@JsonKey(name: "author") String get author;@JsonKey(name: "name") dynamic get name;@JsonKey(name: "image") String get image;@JsonKey(name: "category") Category get category;@JsonKey(name: "category_sub") CategorySub get categorySub;@JsonKey(name: "liked") bool get liked;@JsonKey(name: "is_favorite") bool get isFavorite;@JsonKey(name: "update_at") int get updateAt;
/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListElementCopyWith<ListElement> get copyWith => _$ListElementCopyWithImpl<ListElement>(this as ListElement, _$identity);

  /// Serializes this ListElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListElement&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.image, image) || other.image == image)&&(identical(other.category, category) || other.category == category)&&(identical(other.categorySub, categorySub) || other.categorySub == categorySub)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.updateAt, updateAt) || other.updateAt == updateAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,const DeepCollectionEquality().hash(name),image,category,categorySub,liked,isFavorite,updateAt);

@override
String toString() {
  return 'ListElement(id: $id, author: $author, name: $name, image: $image, category: $category, categorySub: $categorySub, liked: $liked, isFavorite: $isFavorite, updateAt: $updateAt)';
}


}

/// @nodoc
abstract mixin class $ListElementCopyWith<$Res>  {
  factory $ListElementCopyWith(ListElement value, $Res Function(ListElement) _then) = _$ListElementCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "name") dynamic name,@JsonKey(name: "image") String image,@JsonKey(name: "category") Category category,@JsonKey(name: "category_sub") CategorySub categorySub,@JsonKey(name: "liked") bool liked,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "update_at") int updateAt
});


$CategoryCopyWith<$Res> get category;$CategorySubCopyWith<$Res> get categorySub;

}
/// @nodoc
class _$ListElementCopyWithImpl<$Res>
    implements $ListElementCopyWith<$Res> {
  _$ListElementCopyWithImpl(this._self, this._then);

  final ListElement _self;
  final $Res Function(ListElement) _then;

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? name = freezed,Object? image = null,Object? category = null,Object? categorySub = null,Object? liked = null,Object? isFavorite = null,Object? updateAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as dynamic,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,categorySub: null == categorySub ? _self.categorySub : categorySub // ignore: cast_nullable_to_non_nullable
as CategorySub,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,updateAt: null == updateAt ? _self.updateAt : updateAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategorySubCopyWith<$Res> get categorySub {
  
  return $CategorySubCopyWith<$Res>(_self.categorySub, (value) {
    return _then(_self.copyWith(categorySub: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _ListElement implements ListElement {
  const _ListElement({@JsonKey(name: "id") required this.id, @JsonKey(name: "author") required this.author, @JsonKey(name: "name") required this.name, @JsonKey(name: "image") required this.image, @JsonKey(name: "category") required this.category, @JsonKey(name: "category_sub") required this.categorySub, @JsonKey(name: "liked") required this.liked, @JsonKey(name: "is_favorite") required this.isFavorite, @JsonKey(name: "update_at") required this.updateAt});
  factory _ListElement.fromJson(Map<String, dynamic> json) => _$ListElementFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "name") final  dynamic name;
@override@JsonKey(name: "image") final  String image;
@override@JsonKey(name: "category") final  Category category;
@override@JsonKey(name: "category_sub") final  CategorySub categorySub;
@override@JsonKey(name: "liked") final  bool liked;
@override@JsonKey(name: "is_favorite") final  bool isFavorite;
@override@JsonKey(name: "update_at") final  int updateAt;

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListElementCopyWith<_ListElement> get copyWith => __$ListElementCopyWithImpl<_ListElement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListElementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListElement&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&const DeepCollectionEquality().equals(other.name, name)&&(identical(other.image, image) || other.image == image)&&(identical(other.category, category) || other.category == category)&&(identical(other.categorySub, categorySub) || other.categorySub == categorySub)&&(identical(other.liked, liked) || other.liked == liked)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.updateAt, updateAt) || other.updateAt == updateAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,const DeepCollectionEquality().hash(name),image,category,categorySub,liked,isFavorite,updateAt);

@override
String toString() {
  return 'ListElement(id: $id, author: $author, name: $name, image: $image, category: $category, categorySub: $categorySub, liked: $liked, isFavorite: $isFavorite, updateAt: $updateAt)';
}


}

/// @nodoc
abstract mixin class _$ListElementCopyWith<$Res> implements $ListElementCopyWith<$Res> {
  factory _$ListElementCopyWith(_ListElement value, $Res Function(_ListElement) _then) = __$ListElementCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "name") dynamic name,@JsonKey(name: "image") String image,@JsonKey(name: "category") Category category,@JsonKey(name: "category_sub") CategorySub categorySub,@JsonKey(name: "liked") bool liked,@JsonKey(name: "is_favorite") bool isFavorite,@JsonKey(name: "update_at") int updateAt
});


@override $CategoryCopyWith<$Res> get category;@override $CategorySubCopyWith<$Res> get categorySub;

}
/// @nodoc
class __$ListElementCopyWithImpl<$Res>
    implements _$ListElementCopyWith<$Res> {
  __$ListElementCopyWithImpl(this._self, this._then);

  final _ListElement _self;
  final $Res Function(_ListElement) _then;

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? name = freezed,Object? image = null,Object? category = null,Object? categorySub = null,Object? liked = null,Object? isFavorite = null,Object? updateAt = null,}) {
  return _then(_ListElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as dynamic,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,categorySub: null == categorySub ? _self.categorySub : categorySub // ignore: cast_nullable_to_non_nullable
as CategorySub,liked: null == liked ? _self.liked : liked // ignore: cast_nullable_to_non_nullable
as bool,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,updateAt: null == updateAt ? _self.updateAt : updateAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryCopyWith<$Res> get category {
  
  return $CategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategorySubCopyWith<$Res> get categorySub {
  
  return $CategorySubCopyWith<$Res>(_self.categorySub, (value) {
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
