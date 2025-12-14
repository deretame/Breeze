// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jm_cloud_favorite_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JmCloudFavoriteJson {

@JsonKey(name: "list") List<ListElement> get list;@JsonKey(name: "folder_list") List<FolderList> get folderList;@JsonKey(name: "total") String get total;@JsonKey(name: "count") int get count;
/// Create a copy of JmCloudFavoriteJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JmCloudFavoriteJsonCopyWith<JmCloudFavoriteJson> get copyWith => _$JmCloudFavoriteJsonCopyWithImpl<JmCloudFavoriteJson>(this as JmCloudFavoriteJson, _$identity);

  /// Serializes this JmCloudFavoriteJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JmCloudFavoriteJson&&const DeepCollectionEquality().equals(other.list, list)&&const DeepCollectionEquality().equals(other.folderList, folderList)&&(identical(other.total, total) || other.total == total)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(list),const DeepCollectionEquality().hash(folderList),total,count);

@override
String toString() {
  return 'JmCloudFavoriteJson(list: $list, folderList: $folderList, total: $total, count: $count)';
}


}

/// @nodoc
abstract mixin class $JmCloudFavoriteJsonCopyWith<$Res>  {
  factory $JmCloudFavoriteJsonCopyWith(JmCloudFavoriteJson value, $Res Function(JmCloudFavoriteJson) _then) = _$JmCloudFavoriteJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "list") List<ListElement> list,@JsonKey(name: "folder_list") List<FolderList> folderList,@JsonKey(name: "total") String total,@JsonKey(name: "count") int count
});




}
/// @nodoc
class _$JmCloudFavoriteJsonCopyWithImpl<$Res>
    implements $JmCloudFavoriteJsonCopyWith<$Res> {
  _$JmCloudFavoriteJsonCopyWithImpl(this._self, this._then);

  final JmCloudFavoriteJson _self;
  final $Res Function(JmCloudFavoriteJson) _then;

/// Create a copy of JmCloudFavoriteJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? list = null,Object? folderList = null,Object? total = null,Object? count = null,}) {
  return _then(_self.copyWith(
list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,folderList: null == folderList ? _self.folderList : folderList // ignore: cast_nullable_to_non_nullable
as List<FolderList>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JmCloudFavoriteJson].
extension JmCloudFavoriteJsonPatterns on JmCloudFavoriteJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JmCloudFavoriteJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JmCloudFavoriteJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JmCloudFavoriteJson value)  $default,){
final _that = this;
switch (_that) {
case _JmCloudFavoriteJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JmCloudFavoriteJson value)?  $default,){
final _that = this;
switch (_that) {
case _JmCloudFavoriteJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "list")  List<ListElement> list, @JsonKey(name: "folder_list")  List<FolderList> folderList, @JsonKey(name: "total")  String total, @JsonKey(name: "count")  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JmCloudFavoriteJson() when $default != null:
return $default(_that.list,_that.folderList,_that.total,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "list")  List<ListElement> list, @JsonKey(name: "folder_list")  List<FolderList> folderList, @JsonKey(name: "total")  String total, @JsonKey(name: "count")  int count)  $default,) {final _that = this;
switch (_that) {
case _JmCloudFavoriteJson():
return $default(_that.list,_that.folderList,_that.total,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "list")  List<ListElement> list, @JsonKey(name: "folder_list")  List<FolderList> folderList, @JsonKey(name: "total")  String total, @JsonKey(name: "count")  int count)?  $default,) {final _that = this;
switch (_that) {
case _JmCloudFavoriteJson() when $default != null:
return $default(_that.list,_that.folderList,_that.total,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JmCloudFavoriteJson implements JmCloudFavoriteJson {
  const _JmCloudFavoriteJson({@JsonKey(name: "list") required final  List<ListElement> list, @JsonKey(name: "folder_list") required final  List<FolderList> folderList, @JsonKey(name: "total") required this.total, @JsonKey(name: "count") required this.count}): _list = list,_folderList = folderList;
  factory _JmCloudFavoriteJson.fromJson(Map<String, dynamic> json) => _$JmCloudFavoriteJsonFromJson(json);

 final  List<ListElement> _list;
@override@JsonKey(name: "list") List<ListElement> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

 final  List<FolderList> _folderList;
@override@JsonKey(name: "folder_list") List<FolderList> get folderList {
  if (_folderList is EqualUnmodifiableListView) return _folderList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_folderList);
}

@override@JsonKey(name: "total") final  String total;
@override@JsonKey(name: "count") final  int count;

/// Create a copy of JmCloudFavoriteJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JmCloudFavoriteJsonCopyWith<_JmCloudFavoriteJson> get copyWith => __$JmCloudFavoriteJsonCopyWithImpl<_JmCloudFavoriteJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JmCloudFavoriteJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JmCloudFavoriteJson&&const DeepCollectionEquality().equals(other._list, _list)&&const DeepCollectionEquality().equals(other._folderList, _folderList)&&(identical(other.total, total) || other.total == total)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_list),const DeepCollectionEquality().hash(_folderList),total,count);

@override
String toString() {
  return 'JmCloudFavoriteJson(list: $list, folderList: $folderList, total: $total, count: $count)';
}


}

/// @nodoc
abstract mixin class _$JmCloudFavoriteJsonCopyWith<$Res> implements $JmCloudFavoriteJsonCopyWith<$Res> {
  factory _$JmCloudFavoriteJsonCopyWith(_JmCloudFavoriteJson value, $Res Function(_JmCloudFavoriteJson) _then) = __$JmCloudFavoriteJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "list") List<ListElement> list,@JsonKey(name: "folder_list") List<FolderList> folderList,@JsonKey(name: "total") String total,@JsonKey(name: "count") int count
});




}
/// @nodoc
class __$JmCloudFavoriteJsonCopyWithImpl<$Res>
    implements _$JmCloudFavoriteJsonCopyWith<$Res> {
  __$JmCloudFavoriteJsonCopyWithImpl(this._self, this._then);

  final _JmCloudFavoriteJson _self;
  final $Res Function(_JmCloudFavoriteJson) _then;

/// Create a copy of JmCloudFavoriteJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? list = null,Object? folderList = null,Object? total = null,Object? count = null,}) {
  return _then(_JmCloudFavoriteJson(
list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,folderList: null == folderList ? _self._folderList : folderList // ignore: cast_nullable_to_non_nullable
as List<FolderList>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FolderList {

@JsonKey(name: "FID") String get fid;@JsonKey(name: "UID") String get uid;@JsonKey(name: "name") String get name;
/// Create a copy of FolderList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderListCopyWith<FolderList> get copyWith => _$FolderListCopyWithImpl<FolderList>(this as FolderList, _$identity);

  /// Serializes this FolderList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderList&&(identical(other.fid, fid) || other.fid == fid)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fid,uid,name);

@override
String toString() {
  return 'FolderList(fid: $fid, uid: $uid, name: $name)';
}


}

/// @nodoc
abstract mixin class $FolderListCopyWith<$Res>  {
  factory $FolderListCopyWith(FolderList value, $Res Function(FolderList) _then) = _$FolderListCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "FID") String fid,@JsonKey(name: "UID") String uid,@JsonKey(name: "name") String name
});




}
/// @nodoc
class _$FolderListCopyWithImpl<$Res>
    implements $FolderListCopyWith<$Res> {
  _$FolderListCopyWithImpl(this._self, this._then);

  final FolderList _self;
  final $Res Function(FolderList) _then;

/// Create a copy of FolderList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fid = null,Object? uid = null,Object? name = null,}) {
  return _then(_self.copyWith(
fid: null == fid ? _self.fid : fid // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderList].
extension FolderListPatterns on FolderList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderList value)  $default,){
final _that = this;
switch (_that) {
case _FolderList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderList value)?  $default,){
final _that = this;
switch (_that) {
case _FolderList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "FID")  String fid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "name")  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderList() when $default != null:
return $default(_that.fid,_that.uid,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "FID")  String fid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "name")  String name)  $default,) {final _that = this;
switch (_that) {
case _FolderList():
return $default(_that.fid,_that.uid,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "FID")  String fid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "name")  String name)?  $default,) {final _that = this;
switch (_that) {
case _FolderList() when $default != null:
return $default(_that.fid,_that.uid,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FolderList implements FolderList {
  const _FolderList({@JsonKey(name: "FID") required this.fid, @JsonKey(name: "UID") required this.uid, @JsonKey(name: "name") required this.name});
  factory _FolderList.fromJson(Map<String, dynamic> json) => _$FolderListFromJson(json);

@override@JsonKey(name: "FID") final  String fid;
@override@JsonKey(name: "UID") final  String uid;
@override@JsonKey(name: "name") final  String name;

/// Create a copy of FolderList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderListCopyWith<_FolderList> get copyWith => __$FolderListCopyWithImpl<_FolderList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FolderListToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderList&&(identical(other.fid, fid) || other.fid == fid)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fid,uid,name);

@override
String toString() {
  return 'FolderList(fid: $fid, uid: $uid, name: $name)';
}


}

/// @nodoc
abstract mixin class _$FolderListCopyWith<$Res> implements $FolderListCopyWith<$Res> {
  factory _$FolderListCopyWith(_FolderList value, $Res Function(_FolderList) _then) = __$FolderListCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "FID") String fid,@JsonKey(name: "UID") String uid,@JsonKey(name: "name") String name
});




}
/// @nodoc
class __$FolderListCopyWithImpl<$Res>
    implements _$FolderListCopyWith<$Res> {
  __$FolderListCopyWithImpl(this._self, this._then);

  final _FolderList _self;
  final $Res Function(_FolderList) _then;

/// Create a copy of FolderList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fid = null,Object? uid = null,Object? name = null,}) {
  return _then(_FolderList(
fid: null == fid ? _self.fid : fid // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ListElement {

@JsonKey(name: "id") String get id;@JsonKey(name: "author") String get author;@JsonKey(name: "description") String get description;@JsonKey(name: "name") String get name;@JsonKey(name: "latest_ep") String? get latestEp;@JsonKey(name: "latest_ep_aid") String? get latestEpAid;@JsonKey(name: "image") String get image;@JsonKey(name: "category") Category get category;@JsonKey(name: "category_sub") CategorySub get categorySub;
/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListElementCopyWith<ListElement> get copyWith => _$ListElementCopyWithImpl<ListElement>(this as ListElement, _$identity);

  /// Serializes this ListElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListElement&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.description, description) || other.description == description)&&(identical(other.name, name) || other.name == name)&&(identical(other.latestEp, latestEp) || other.latestEp == latestEp)&&(identical(other.latestEpAid, latestEpAid) || other.latestEpAid == latestEpAid)&&(identical(other.image, image) || other.image == image)&&(identical(other.category, category) || other.category == category)&&(identical(other.categorySub, categorySub) || other.categorySub == categorySub));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,description,name,latestEp,latestEpAid,image,category,categorySub);

@override
String toString() {
  return 'ListElement(id: $id, author: $author, description: $description, name: $name, latestEp: $latestEp, latestEpAid: $latestEpAid, image: $image, category: $category, categorySub: $categorySub)';
}


}

/// @nodoc
abstract mixin class $ListElementCopyWith<$Res>  {
  factory $ListElementCopyWith(ListElement value, $Res Function(ListElement) _then) = _$ListElementCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "description") String description,@JsonKey(name: "name") String name,@JsonKey(name: "latest_ep") String? latestEp,@JsonKey(name: "latest_ep_aid") String? latestEpAid,@JsonKey(name: "image") String image,@JsonKey(name: "category") Category category,@JsonKey(name: "category_sub") CategorySub categorySub
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? author = null,Object? description = null,Object? name = null,Object? latestEp = freezed,Object? latestEpAid = freezed,Object? image = null,Object? category = null,Object? categorySub = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latestEp: freezed == latestEp ? _self.latestEp : latestEp // ignore: cast_nullable_to_non_nullable
as String?,latestEpAid: freezed == latestEpAid ? _self.latestEpAid : latestEpAid // ignore: cast_nullable_to_non_nullable
as String?,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,categorySub: null == categorySub ? _self.categorySub : categorySub // ignore: cast_nullable_to_non_nullable
as CategorySub,
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


/// Adds pattern-matching-related methods to [ListElement].
extension ListElementPatterns on ListElement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListElement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListElement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListElement value)  $default,){
final _that = this;
switch (_that) {
case _ListElement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListElement value)?  $default,){
final _that = this;
switch (_that) {
case _ListElement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "description")  String description, @JsonKey(name: "name")  String name, @JsonKey(name: "latest_ep")  String? latestEp, @JsonKey(name: "latest_ep_aid")  String? latestEpAid, @JsonKey(name: "image")  String image, @JsonKey(name: "category")  Category category, @JsonKey(name: "category_sub")  CategorySub categorySub)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListElement() when $default != null:
return $default(_that.id,_that.author,_that.description,_that.name,_that.latestEp,_that.latestEpAid,_that.image,_that.category,_that.categorySub);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "description")  String description, @JsonKey(name: "name")  String name, @JsonKey(name: "latest_ep")  String? latestEp, @JsonKey(name: "latest_ep_aid")  String? latestEpAid, @JsonKey(name: "image")  String image, @JsonKey(name: "category")  Category category, @JsonKey(name: "category_sub")  CategorySub categorySub)  $default,) {final _that = this;
switch (_that) {
case _ListElement():
return $default(_that.id,_that.author,_that.description,_that.name,_that.latestEp,_that.latestEpAid,_that.image,_that.category,_that.categorySub);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "id")  String id, @JsonKey(name: "author")  String author, @JsonKey(name: "description")  String description, @JsonKey(name: "name")  String name, @JsonKey(name: "latest_ep")  String? latestEp, @JsonKey(name: "latest_ep_aid")  String? latestEpAid, @JsonKey(name: "image")  String image, @JsonKey(name: "category")  Category category, @JsonKey(name: "category_sub")  CategorySub categorySub)?  $default,) {final _that = this;
switch (_that) {
case _ListElement() when $default != null:
return $default(_that.id,_that.author,_that.description,_that.name,_that.latestEp,_that.latestEpAid,_that.image,_that.category,_that.categorySub);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListElement implements ListElement {
  const _ListElement({@JsonKey(name: "id") required this.id, @JsonKey(name: "author") required this.author, @JsonKey(name: "description") required this.description, @JsonKey(name: "name") required this.name, @JsonKey(name: "latest_ep") required this.latestEp, @JsonKey(name: "latest_ep_aid") required this.latestEpAid, @JsonKey(name: "image") required this.image, @JsonKey(name: "category") required this.category, @JsonKey(name: "category_sub") required this.categorySub});
  factory _ListElement.fromJson(Map<String, dynamic> json) => _$ListElementFromJson(json);

@override@JsonKey(name: "id") final  String id;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "description") final  String description;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "latest_ep") final  String? latestEp;
@override@JsonKey(name: "latest_ep_aid") final  String? latestEpAid;
@override@JsonKey(name: "image") final  String image;
@override@JsonKey(name: "category") final  Category category;
@override@JsonKey(name: "category_sub") final  CategorySub categorySub;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListElement&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.description, description) || other.description == description)&&(identical(other.name, name) || other.name == name)&&(identical(other.latestEp, latestEp) || other.latestEp == latestEp)&&(identical(other.latestEpAid, latestEpAid) || other.latestEpAid == latestEpAid)&&(identical(other.image, image) || other.image == image)&&(identical(other.category, category) || other.category == category)&&(identical(other.categorySub, categorySub) || other.categorySub == categorySub));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,author,description,name,latestEp,latestEpAid,image,category,categorySub);

@override
String toString() {
  return 'ListElement(id: $id, author: $author, description: $description, name: $name, latestEp: $latestEp, latestEpAid: $latestEpAid, image: $image, category: $category, categorySub: $categorySub)';
}


}

/// @nodoc
abstract mixin class _$ListElementCopyWith<$Res> implements $ListElementCopyWith<$Res> {
  factory _$ListElementCopyWith(_ListElement value, $Res Function(_ListElement) _then) = __$ListElementCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "id") String id,@JsonKey(name: "author") String author,@JsonKey(name: "description") String description,@JsonKey(name: "name") String name,@JsonKey(name: "latest_ep") String? latestEp,@JsonKey(name: "latest_ep_aid") String? latestEpAid,@JsonKey(name: "image") String image,@JsonKey(name: "category") Category category,@JsonKey(name: "category_sub") CategorySub categorySub
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? author = null,Object? description = null,Object? name = null,Object? latestEp = freezed,Object? latestEpAid = freezed,Object? image = null,Object? category = null,Object? categorySub = null,}) {
  return _then(_ListElement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,latestEp: freezed == latestEp ? _self.latestEp : latestEp // ignore: cast_nullable_to_non_nullable
as String?,latestEpAid: freezed == latestEpAid ? _self.latestEpAid : latestEpAid // ignore: cast_nullable_to_non_nullable
as String?,image: null == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as Category,categorySub: null == categorySub ? _self.categorySub : categorySub // ignore: cast_nullable_to_non_nullable
as CategorySub,
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
