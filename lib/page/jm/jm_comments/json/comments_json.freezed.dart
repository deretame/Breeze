// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comments_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentsJson {

@JsonKey(name: "list") List<ListElement> get list;@JsonKey(name: "total") String get total;
/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsJsonCopyWith<CommentsJson> get copyWith => _$CommentsJsonCopyWithImpl<CommentsJson>(this as CommentsJson, _$identity);

  /// Serializes this CommentsJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsJson&&const DeepCollectionEquality().equals(other.list, list)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(list),total);

@override
String toString() {
  return 'CommentsJson(list: $list, total: $total)';
}


}

/// @nodoc
abstract mixin class $CommentsJsonCopyWith<$Res>  {
  factory $CommentsJsonCopyWith(CommentsJson value, $Res Function(CommentsJson) _then) = _$CommentsJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "list") List<ListElement> list,@JsonKey(name: "total") String total
});




}
/// @nodoc
class _$CommentsJsonCopyWithImpl<$Res>
    implements $CommentsJsonCopyWith<$Res> {
  _$CommentsJsonCopyWithImpl(this._self, this._then);

  final CommentsJson _self;
  final $Res Function(CommentsJson) _then;

/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? list = null,Object? total = null,}) {
  return _then(_self.copyWith(
list: null == list ? _self.list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CommentsJson].
extension CommentsJsonPatterns on CommentsJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentsJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentsJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentsJson value)  $default,){
final _that = this;
switch (_that) {
case _CommentsJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentsJson value)?  $default,){
final _that = this;
switch (_that) {
case _CommentsJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "list")  List<ListElement> list, @JsonKey(name: "total")  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommentsJson() when $default != null:
return $default(_that.list,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "list")  List<ListElement> list, @JsonKey(name: "total")  String total)  $default,) {final _that = this;
switch (_that) {
case _CommentsJson():
return $default(_that.list,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "list")  List<ListElement> list, @JsonKey(name: "total")  String total)?  $default,) {final _that = this;
switch (_that) {
case _CommentsJson() when $default != null:
return $default(_that.list,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentsJson implements CommentsJson {
  const _CommentsJson({@JsonKey(name: "list") required final  List<ListElement> list, @JsonKey(name: "total") required this.total}): _list = list;
  factory _CommentsJson.fromJson(Map<String, dynamic> json) => _$CommentsJsonFromJson(json);

 final  List<ListElement> _list;
@override@JsonKey(name: "list") List<ListElement> get list {
  if (_list is EqualUnmodifiableListView) return _list;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_list);
}

@override@JsonKey(name: "total") final  String total;

/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsJsonCopyWith<_CommentsJson> get copyWith => __$CommentsJsonCopyWithImpl<_CommentsJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentsJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsJson&&const DeepCollectionEquality().equals(other._list, _list)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_list),total);

@override
String toString() {
  return 'CommentsJson(list: $list, total: $total)';
}


}

/// @nodoc
abstract mixin class _$CommentsJsonCopyWith<$Res> implements $CommentsJsonCopyWith<$Res> {
  factory _$CommentsJsonCopyWith(_CommentsJson value, $Res Function(_CommentsJson) _then) = __$CommentsJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "list") List<ListElement> list,@JsonKey(name: "total") String total
});




}
/// @nodoc
class __$CommentsJsonCopyWithImpl<$Res>
    implements _$CommentsJsonCopyWith<$Res> {
  __$CommentsJsonCopyWithImpl(this._self, this._then);

  final _CommentsJson _self;
  final $Res Function(_CommentsJson) _then;

/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? list = null,Object? total = null,}) {
  return _then(_CommentsJson(
list: null == list ? _self._list : list // ignore: cast_nullable_to_non_nullable
as List<ListElement>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ListElement {

@JsonKey(name: "AID") String get aid;@JsonKey(name: "BID") dynamic get bid;@JsonKey(name: "CID") String get cid;@JsonKey(name: "UID") String get uid;@JsonKey(name: "username") String get username;@JsonKey(name: "nickname") String get nickname;@JsonKey(name: "likes") String get likes;@JsonKey(name: "gender") String get gender;@JsonKey(name: "update_at") String get updateAt;@JsonKey(name: "addtime") String get addtime;@JsonKey(name: "parent_CID") String get parentCid;@JsonKey(name: "expinfo") Expinfo get expinfo;@JsonKey(name: "name") String get name;@JsonKey(name: "content") String get content;@JsonKey(name: "photo") String get photo;@JsonKey(name: "spoiler") String get spoiler;@JsonKey(name: "replys") List<Reply>? get replys;
/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListElementCopyWith<ListElement> get copyWith => _$ListElementCopyWithImpl<ListElement>(this as ListElement, _$identity);

  /// Serializes this ListElement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListElement&&(identical(other.aid, aid) || other.aid == aid)&&const DeepCollectionEquality().equals(other.bid, bid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.updateAt, updateAt) || other.updateAt == updateAt)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.parentCid, parentCid) || other.parentCid == parentCid)&&(identical(other.expinfo, expinfo) || other.expinfo == expinfo)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.spoiler, spoiler) || other.spoiler == spoiler)&&const DeepCollectionEquality().equals(other.replys, replys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aid,const DeepCollectionEquality().hash(bid),cid,uid,username,nickname,likes,gender,updateAt,addtime,parentCid,expinfo,name,content,photo,spoiler,const DeepCollectionEquality().hash(replys));

@override
String toString() {
  return 'ListElement(aid: $aid, bid: $bid, cid: $cid, uid: $uid, username: $username, nickname: $nickname, likes: $likes, gender: $gender, updateAt: $updateAt, addtime: $addtime, parentCid: $parentCid, expinfo: $expinfo, name: $name, content: $content, photo: $photo, spoiler: $spoiler, replys: $replys)';
}


}

/// @nodoc
abstract mixin class $ListElementCopyWith<$Res>  {
  factory $ListElementCopyWith(ListElement value, $Res Function(ListElement) _then) = _$ListElementCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "AID") String aid,@JsonKey(name: "BID") dynamic bid,@JsonKey(name: "CID") String cid,@JsonKey(name: "UID") String uid,@JsonKey(name: "username") String username,@JsonKey(name: "nickname") String nickname,@JsonKey(name: "likes") String likes,@JsonKey(name: "gender") String gender,@JsonKey(name: "update_at") String updateAt,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "parent_CID") String parentCid,@JsonKey(name: "expinfo") Expinfo expinfo,@JsonKey(name: "name") String name,@JsonKey(name: "content") String content,@JsonKey(name: "photo") String photo,@JsonKey(name: "spoiler") String spoiler,@JsonKey(name: "replys") List<Reply>? replys
});


$ExpinfoCopyWith<$Res> get expinfo;

}
/// @nodoc
class _$ListElementCopyWithImpl<$Res>
    implements $ListElementCopyWith<$Res> {
  _$ListElementCopyWithImpl(this._self, this._then);

  final ListElement _self;
  final $Res Function(ListElement) _then;

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aid = null,Object? bid = freezed,Object? cid = null,Object? uid = null,Object? username = null,Object? nickname = null,Object? likes = null,Object? gender = null,Object? updateAt = null,Object? addtime = null,Object? parentCid = null,Object? expinfo = null,Object? name = null,Object? content = null,Object? photo = null,Object? spoiler = null,Object? replys = freezed,}) {
  return _then(_self.copyWith(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as String,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as dynamic,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,updateAt: null == updateAt ? _self.updateAt : updateAt // ignore: cast_nullable_to_non_nullable
as String,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,parentCid: null == parentCid ? _self.parentCid : parentCid // ignore: cast_nullable_to_non_nullable
as String,expinfo: null == expinfo ? _self.expinfo : expinfo // ignore: cast_nullable_to_non_nullable
as Expinfo,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,spoiler: null == spoiler ? _self.spoiler : spoiler // ignore: cast_nullable_to_non_nullable
as String,replys: freezed == replys ? _self.replys : replys // ignore: cast_nullable_to_non_nullable
as List<Reply>?,
  ));
}
/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpinfoCopyWith<$Res> get expinfo {
  
  return $ExpinfoCopyWith<$Res>(_self.expinfo, (value) {
    return _then(_self.copyWith(expinfo: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "AID")  String aid, @JsonKey(name: "BID")  dynamic bid, @JsonKey(name: "CID")  String cid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "username")  String username, @JsonKey(name: "nickname")  String nickname, @JsonKey(name: "likes")  String likes, @JsonKey(name: "gender")  String gender, @JsonKey(name: "update_at")  String updateAt, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "parent_CID")  String parentCid, @JsonKey(name: "expinfo")  Expinfo expinfo, @JsonKey(name: "name")  String name, @JsonKey(name: "content")  String content, @JsonKey(name: "photo")  String photo, @JsonKey(name: "spoiler")  String spoiler, @JsonKey(name: "replys")  List<Reply>? replys)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListElement() when $default != null:
return $default(_that.aid,_that.bid,_that.cid,_that.uid,_that.username,_that.nickname,_that.likes,_that.gender,_that.updateAt,_that.addtime,_that.parentCid,_that.expinfo,_that.name,_that.content,_that.photo,_that.spoiler,_that.replys);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "AID")  String aid, @JsonKey(name: "BID")  dynamic bid, @JsonKey(name: "CID")  String cid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "username")  String username, @JsonKey(name: "nickname")  String nickname, @JsonKey(name: "likes")  String likes, @JsonKey(name: "gender")  String gender, @JsonKey(name: "update_at")  String updateAt, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "parent_CID")  String parentCid, @JsonKey(name: "expinfo")  Expinfo expinfo, @JsonKey(name: "name")  String name, @JsonKey(name: "content")  String content, @JsonKey(name: "photo")  String photo, @JsonKey(name: "spoiler")  String spoiler, @JsonKey(name: "replys")  List<Reply>? replys)  $default,) {final _that = this;
switch (_that) {
case _ListElement():
return $default(_that.aid,_that.bid,_that.cid,_that.uid,_that.username,_that.nickname,_that.likes,_that.gender,_that.updateAt,_that.addtime,_that.parentCid,_that.expinfo,_that.name,_that.content,_that.photo,_that.spoiler,_that.replys);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "AID")  String aid, @JsonKey(name: "BID")  dynamic bid, @JsonKey(name: "CID")  String cid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "username")  String username, @JsonKey(name: "nickname")  String nickname, @JsonKey(name: "likes")  String likes, @JsonKey(name: "gender")  String gender, @JsonKey(name: "update_at")  String updateAt, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "parent_CID")  String parentCid, @JsonKey(name: "expinfo")  Expinfo expinfo, @JsonKey(name: "name")  String name, @JsonKey(name: "content")  String content, @JsonKey(name: "photo")  String photo, @JsonKey(name: "spoiler")  String spoiler, @JsonKey(name: "replys")  List<Reply>? replys)?  $default,) {final _that = this;
switch (_that) {
case _ListElement() when $default != null:
return $default(_that.aid,_that.bid,_that.cid,_that.uid,_that.username,_that.nickname,_that.likes,_that.gender,_that.updateAt,_that.addtime,_that.parentCid,_that.expinfo,_that.name,_that.content,_that.photo,_that.spoiler,_that.replys);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListElement implements ListElement {
  const _ListElement({@JsonKey(name: "AID") required this.aid, @JsonKey(name: "BID") required this.bid, @JsonKey(name: "CID") required this.cid, @JsonKey(name: "UID") required this.uid, @JsonKey(name: "username") required this.username, @JsonKey(name: "nickname") required this.nickname, @JsonKey(name: "likes") required this.likes, @JsonKey(name: "gender") required this.gender, @JsonKey(name: "update_at") required this.updateAt, @JsonKey(name: "addtime") required this.addtime, @JsonKey(name: "parent_CID") required this.parentCid, @JsonKey(name: "expinfo") required this.expinfo, @JsonKey(name: "name") required this.name, @JsonKey(name: "content") required this.content, @JsonKey(name: "photo") required this.photo, @JsonKey(name: "spoiler") required this.spoiler, @JsonKey(name: "replys") final  List<Reply>? replys}): _replys = replys;
  factory _ListElement.fromJson(Map<String, dynamic> json) => _$ListElementFromJson(json);

@override@JsonKey(name: "AID") final  String aid;
@override@JsonKey(name: "BID") final  dynamic bid;
@override@JsonKey(name: "CID") final  String cid;
@override@JsonKey(name: "UID") final  String uid;
@override@JsonKey(name: "username") final  String username;
@override@JsonKey(name: "nickname") final  String nickname;
@override@JsonKey(name: "likes") final  String likes;
@override@JsonKey(name: "gender") final  String gender;
@override@JsonKey(name: "update_at") final  String updateAt;
@override@JsonKey(name: "addtime") final  String addtime;
@override@JsonKey(name: "parent_CID") final  String parentCid;
@override@JsonKey(name: "expinfo") final  Expinfo expinfo;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "content") final  String content;
@override@JsonKey(name: "photo") final  String photo;
@override@JsonKey(name: "spoiler") final  String spoiler;
 final  List<Reply>? _replys;
@override@JsonKey(name: "replys") List<Reply>? get replys {
  final value = _replys;
  if (value == null) return null;
  if (_replys is EqualUnmodifiableListView) return _replys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListElement&&(identical(other.aid, aid) || other.aid == aid)&&const DeepCollectionEquality().equals(other.bid, bid)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.updateAt, updateAt) || other.updateAt == updateAt)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.parentCid, parentCid) || other.parentCid == parentCid)&&(identical(other.expinfo, expinfo) || other.expinfo == expinfo)&&(identical(other.name, name) || other.name == name)&&(identical(other.content, content) || other.content == content)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.spoiler, spoiler) || other.spoiler == spoiler)&&const DeepCollectionEquality().equals(other._replys, _replys));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aid,const DeepCollectionEquality().hash(bid),cid,uid,username,nickname,likes,gender,updateAt,addtime,parentCid,expinfo,name,content,photo,spoiler,const DeepCollectionEquality().hash(_replys));

@override
String toString() {
  return 'ListElement(aid: $aid, bid: $bid, cid: $cid, uid: $uid, username: $username, nickname: $nickname, likes: $likes, gender: $gender, updateAt: $updateAt, addtime: $addtime, parentCid: $parentCid, expinfo: $expinfo, name: $name, content: $content, photo: $photo, spoiler: $spoiler, replys: $replys)';
}


}

/// @nodoc
abstract mixin class _$ListElementCopyWith<$Res> implements $ListElementCopyWith<$Res> {
  factory _$ListElementCopyWith(_ListElement value, $Res Function(_ListElement) _then) = __$ListElementCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "AID") String aid,@JsonKey(name: "BID") dynamic bid,@JsonKey(name: "CID") String cid,@JsonKey(name: "UID") String uid,@JsonKey(name: "username") String username,@JsonKey(name: "nickname") String nickname,@JsonKey(name: "likes") String likes,@JsonKey(name: "gender") String gender,@JsonKey(name: "update_at") String updateAt,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "parent_CID") String parentCid,@JsonKey(name: "expinfo") Expinfo expinfo,@JsonKey(name: "name") String name,@JsonKey(name: "content") String content,@JsonKey(name: "photo") String photo,@JsonKey(name: "spoiler") String spoiler,@JsonKey(name: "replys") List<Reply>? replys
});


@override $ExpinfoCopyWith<$Res> get expinfo;

}
/// @nodoc
class __$ListElementCopyWithImpl<$Res>
    implements _$ListElementCopyWith<$Res> {
  __$ListElementCopyWithImpl(this._self, this._then);

  final _ListElement _self;
  final $Res Function(_ListElement) _then;

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aid = null,Object? bid = freezed,Object? cid = null,Object? uid = null,Object? username = null,Object? nickname = null,Object? likes = null,Object? gender = null,Object? updateAt = null,Object? addtime = null,Object? parentCid = null,Object? expinfo = null,Object? name = null,Object? content = null,Object? photo = null,Object? spoiler = null,Object? replys = freezed,}) {
  return _then(_ListElement(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as String,bid: freezed == bid ? _self.bid : bid // ignore: cast_nullable_to_non_nullable
as dynamic,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,updateAt: null == updateAt ? _self.updateAt : updateAt // ignore: cast_nullable_to_non_nullable
as String,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,parentCid: null == parentCid ? _self.parentCid : parentCid // ignore: cast_nullable_to_non_nullable
as String,expinfo: null == expinfo ? _self.expinfo : expinfo // ignore: cast_nullable_to_non_nullable
as Expinfo,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,spoiler: null == spoiler ? _self.spoiler : spoiler // ignore: cast_nullable_to_non_nullable
as String,replys: freezed == replys ? _self._replys : replys // ignore: cast_nullable_to_non_nullable
as List<Reply>?,
  ));
}

/// Create a copy of ListElement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpinfoCopyWith<$Res> get expinfo {
  
  return $ExpinfoCopyWith<$Res>(_self.expinfo, (value) {
    return _then(_self.copyWith(expinfo: value));
  });
}
}


/// @nodoc
mixin _$Expinfo {

@JsonKey(name: "level_name") String get levelName;@JsonKey(name: "level") int get level;@JsonKey(name: "nextLevelExp") int get nextLevelExp;@JsonKey(name: "exp") String get exp;@JsonKey(name: "expPercent") double get expPercent;@JsonKey(name: "uid") String get uid;@JsonKey(name: "badges") List<Badge> get badges;
/// Create a copy of Expinfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpinfoCopyWith<Expinfo> get copyWith => _$ExpinfoCopyWithImpl<Expinfo>(this as Expinfo, _$identity);

  /// Serializes this Expinfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expinfo&&(identical(other.levelName, levelName) || other.levelName == levelName)&&(identical(other.level, level) || other.level == level)&&(identical(other.nextLevelExp, nextLevelExp) || other.nextLevelExp == nextLevelExp)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.expPercent, expPercent) || other.expPercent == expPercent)&&(identical(other.uid, uid) || other.uid == uid)&&const DeepCollectionEquality().equals(other.badges, badges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,levelName,level,nextLevelExp,exp,expPercent,uid,const DeepCollectionEquality().hash(badges));

@override
String toString() {
  return 'Expinfo(levelName: $levelName, level: $level, nextLevelExp: $nextLevelExp, exp: $exp, expPercent: $expPercent, uid: $uid, badges: $badges)';
}


}

/// @nodoc
abstract mixin class $ExpinfoCopyWith<$Res>  {
  factory $ExpinfoCopyWith(Expinfo value, $Res Function(Expinfo) _then) = _$ExpinfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "level_name") String levelName,@JsonKey(name: "level") int level,@JsonKey(name: "nextLevelExp") int nextLevelExp,@JsonKey(name: "exp") String exp,@JsonKey(name: "expPercent") double expPercent,@JsonKey(name: "uid") String uid,@JsonKey(name: "badges") List<Badge> badges
});




}
/// @nodoc
class _$ExpinfoCopyWithImpl<$Res>
    implements $ExpinfoCopyWith<$Res> {
  _$ExpinfoCopyWithImpl(this._self, this._then);

  final Expinfo _self;
  final $Res Function(Expinfo) _then;

/// Create a copy of Expinfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? levelName = null,Object? level = null,Object? nextLevelExp = null,Object? exp = null,Object? expPercent = null,Object? uid = null,Object? badges = null,}) {
  return _then(_self.copyWith(
levelName: null == levelName ? _self.levelName : levelName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,nextLevelExp: null == nextLevelExp ? _self.nextLevelExp : nextLevelExp // ignore: cast_nullable_to_non_nullable
as int,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as String,expPercent: null == expPercent ? _self.expPercent : expPercent // ignore: cast_nullable_to_non_nullable
as double,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,badges: null == badges ? _self.badges : badges // ignore: cast_nullable_to_non_nullable
as List<Badge>,
  ));
}

}


/// Adds pattern-matching-related methods to [Expinfo].
extension ExpinfoPatterns on Expinfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expinfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expinfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expinfo value)  $default,){
final _that = this;
switch (_that) {
case _Expinfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expinfo value)?  $default,){
final _that = this;
switch (_that) {
case _Expinfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "level_name")  String levelName, @JsonKey(name: "level")  int level, @JsonKey(name: "nextLevelExp")  int nextLevelExp, @JsonKey(name: "exp")  String exp, @JsonKey(name: "expPercent")  double expPercent, @JsonKey(name: "uid")  String uid, @JsonKey(name: "badges")  List<Badge> badges)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expinfo() when $default != null:
return $default(_that.levelName,_that.level,_that.nextLevelExp,_that.exp,_that.expPercent,_that.uid,_that.badges);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "level_name")  String levelName, @JsonKey(name: "level")  int level, @JsonKey(name: "nextLevelExp")  int nextLevelExp, @JsonKey(name: "exp")  String exp, @JsonKey(name: "expPercent")  double expPercent, @JsonKey(name: "uid")  String uid, @JsonKey(name: "badges")  List<Badge> badges)  $default,) {final _that = this;
switch (_that) {
case _Expinfo():
return $default(_that.levelName,_that.level,_that.nextLevelExp,_that.exp,_that.expPercent,_that.uid,_that.badges);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "level_name")  String levelName, @JsonKey(name: "level")  int level, @JsonKey(name: "nextLevelExp")  int nextLevelExp, @JsonKey(name: "exp")  String exp, @JsonKey(name: "expPercent")  double expPercent, @JsonKey(name: "uid")  String uid, @JsonKey(name: "badges")  List<Badge> badges)?  $default,) {final _that = this;
switch (_that) {
case _Expinfo() when $default != null:
return $default(_that.levelName,_that.level,_that.nextLevelExp,_that.exp,_that.expPercent,_that.uid,_that.badges);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Expinfo implements Expinfo {
  const _Expinfo({@JsonKey(name: "level_name") required this.levelName, @JsonKey(name: "level") required this.level, @JsonKey(name: "nextLevelExp") required this.nextLevelExp, @JsonKey(name: "exp") required this.exp, @JsonKey(name: "expPercent") required this.expPercent, @JsonKey(name: "uid") required this.uid, @JsonKey(name: "badges") required final  List<Badge> badges}): _badges = badges;
  factory _Expinfo.fromJson(Map<String, dynamic> json) => _$ExpinfoFromJson(json);

@override@JsonKey(name: "level_name") final  String levelName;
@override@JsonKey(name: "level") final  int level;
@override@JsonKey(name: "nextLevelExp") final  int nextLevelExp;
@override@JsonKey(name: "exp") final  String exp;
@override@JsonKey(name: "expPercent") final  double expPercent;
@override@JsonKey(name: "uid") final  String uid;
 final  List<Badge> _badges;
@override@JsonKey(name: "badges") List<Badge> get badges {
  if (_badges is EqualUnmodifiableListView) return _badges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_badges);
}


/// Create a copy of Expinfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpinfoCopyWith<_Expinfo> get copyWith => __$ExpinfoCopyWithImpl<_Expinfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpinfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expinfo&&(identical(other.levelName, levelName) || other.levelName == levelName)&&(identical(other.level, level) || other.level == level)&&(identical(other.nextLevelExp, nextLevelExp) || other.nextLevelExp == nextLevelExp)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.expPercent, expPercent) || other.expPercent == expPercent)&&(identical(other.uid, uid) || other.uid == uid)&&const DeepCollectionEquality().equals(other._badges, _badges));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,levelName,level,nextLevelExp,exp,expPercent,uid,const DeepCollectionEquality().hash(_badges));

@override
String toString() {
  return 'Expinfo(levelName: $levelName, level: $level, nextLevelExp: $nextLevelExp, exp: $exp, expPercent: $expPercent, uid: $uid, badges: $badges)';
}


}

/// @nodoc
abstract mixin class _$ExpinfoCopyWith<$Res> implements $ExpinfoCopyWith<$Res> {
  factory _$ExpinfoCopyWith(_Expinfo value, $Res Function(_Expinfo) _then) = __$ExpinfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "level_name") String levelName,@JsonKey(name: "level") int level,@JsonKey(name: "nextLevelExp") int nextLevelExp,@JsonKey(name: "exp") String exp,@JsonKey(name: "expPercent") double expPercent,@JsonKey(name: "uid") String uid,@JsonKey(name: "badges") List<Badge> badges
});




}
/// @nodoc
class __$ExpinfoCopyWithImpl<$Res>
    implements _$ExpinfoCopyWith<$Res> {
  __$ExpinfoCopyWithImpl(this._self, this._then);

  final _Expinfo _self;
  final $Res Function(_Expinfo) _then;

/// Create a copy of Expinfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? levelName = null,Object? level = null,Object? nextLevelExp = null,Object? exp = null,Object? expPercent = null,Object? uid = null,Object? badges = null,}) {
  return _then(_Expinfo(
levelName: null == levelName ? _self.levelName : levelName // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,nextLevelExp: null == nextLevelExp ? _self.nextLevelExp : nextLevelExp // ignore: cast_nullable_to_non_nullable
as int,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as String,expPercent: null == expPercent ? _self.expPercent : expPercent // ignore: cast_nullable_to_non_nullable
as double,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,badges: null == badges ? _self._badges : badges // ignore: cast_nullable_to_non_nullable
as List<Badge>,
  ));
}


}


/// @nodoc
mixin _$Badge {

@JsonKey(name: "content") String get content;@JsonKey(name: "name") String get name;@JsonKey(name: "id") String get id;
/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeCopyWith<Badge> get copyWith => _$BadgeCopyWithImpl<Badge>(this as Badge, _$identity);

  /// Serializes this Badge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Badge&&(identical(other.content, content) || other.content == content)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,name,id);

@override
String toString() {
  return 'Badge(content: $content, name: $name, id: $id)';
}


}

/// @nodoc
abstract mixin class $BadgeCopyWith<$Res>  {
  factory $BadgeCopyWith(Badge value, $Res Function(Badge) _then) = _$BadgeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "content") String content,@JsonKey(name: "name") String name,@JsonKey(name: "id") String id
});




}
/// @nodoc
class _$BadgeCopyWithImpl<$Res>
    implements $BadgeCopyWith<$Res> {
  _$BadgeCopyWithImpl(this._self, this._then);

  final Badge _self;
  final $Res Function(Badge) _then;

/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? name = null,Object? id = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Badge].
extension BadgePatterns on Badge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Badge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Badge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Badge value)  $default,){
final _that = this;
switch (_that) {
case _Badge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Badge value)?  $default,){
final _that = this;
switch (_that) {
case _Badge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "content")  String content, @JsonKey(name: "name")  String name, @JsonKey(name: "id")  String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Badge() when $default != null:
return $default(_that.content,_that.name,_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "content")  String content, @JsonKey(name: "name")  String name, @JsonKey(name: "id")  String id)  $default,) {final _that = this;
switch (_that) {
case _Badge():
return $default(_that.content,_that.name,_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "content")  String content, @JsonKey(name: "name")  String name, @JsonKey(name: "id")  String id)?  $default,) {final _that = this;
switch (_that) {
case _Badge() when $default != null:
return $default(_that.content,_that.name,_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Badge implements Badge {
  const _Badge({@JsonKey(name: "content") required this.content, @JsonKey(name: "name") required this.name, @JsonKey(name: "id") required this.id});
  factory _Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);

@override@JsonKey(name: "content") final  String content;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "id") final  String id;

/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeCopyWith<_Badge> get copyWith => __$BadgeCopyWithImpl<_Badge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Badge&&(identical(other.content, content) || other.content == content)&&(identical(other.name, name) || other.name == name)&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,name,id);

@override
String toString() {
  return 'Badge(content: $content, name: $name, id: $id)';
}


}

/// @nodoc
abstract mixin class _$BadgeCopyWith<$Res> implements $BadgeCopyWith<$Res> {
  factory _$BadgeCopyWith(_Badge value, $Res Function(_Badge) _then) = __$BadgeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "content") String content,@JsonKey(name: "name") String name,@JsonKey(name: "id") String id
});




}
/// @nodoc
class __$BadgeCopyWithImpl<$Res>
    implements _$BadgeCopyWith<$Res> {
  __$BadgeCopyWithImpl(this._self, this._then);

  final _Badge _self;
  final $Res Function(_Badge) _then;

/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? name = null,Object? id = null,}) {
  return _then(_Badge(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Reply {

@JsonKey(name: "CID") String get cid;@JsonKey(name: "UID") String get uid;@JsonKey(name: "username") String get username;@JsonKey(name: "nickname") String get nickname;@JsonKey(name: "likes") String get likes;@JsonKey(name: "gender") String get gender;@JsonKey(name: "update_at") String get updateAt;@JsonKey(name: "addtime") String get addtime;@JsonKey(name: "parent_CID") String get parentCid;@JsonKey(name: "photo") String get photo;@JsonKey(name: "content") String get content;@JsonKey(name: "expinfo") Expinfo get expinfo;@JsonKey(name: "spoiler") String get spoiler;
/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReplyCopyWith<Reply> get copyWith => _$ReplyCopyWithImpl<Reply>(this as Reply, _$identity);

  /// Serializes this Reply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reply&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.updateAt, updateAt) || other.updateAt == updateAt)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.parentCid, parentCid) || other.parentCid == parentCid)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.content, content) || other.content == content)&&(identical(other.expinfo, expinfo) || other.expinfo == expinfo)&&(identical(other.spoiler, spoiler) || other.spoiler == spoiler));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cid,uid,username,nickname,likes,gender,updateAt,addtime,parentCid,photo,content,expinfo,spoiler);

@override
String toString() {
  return 'Reply(cid: $cid, uid: $uid, username: $username, nickname: $nickname, likes: $likes, gender: $gender, updateAt: $updateAt, addtime: $addtime, parentCid: $parentCid, photo: $photo, content: $content, expinfo: $expinfo, spoiler: $spoiler)';
}


}

/// @nodoc
abstract mixin class $ReplyCopyWith<$Res>  {
  factory $ReplyCopyWith(Reply value, $Res Function(Reply) _then) = _$ReplyCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "CID") String cid,@JsonKey(name: "UID") String uid,@JsonKey(name: "username") String username,@JsonKey(name: "nickname") String nickname,@JsonKey(name: "likes") String likes,@JsonKey(name: "gender") String gender,@JsonKey(name: "update_at") String updateAt,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "parent_CID") String parentCid,@JsonKey(name: "photo") String photo,@JsonKey(name: "content") String content,@JsonKey(name: "expinfo") Expinfo expinfo,@JsonKey(name: "spoiler") String spoiler
});


$ExpinfoCopyWith<$Res> get expinfo;

}
/// @nodoc
class _$ReplyCopyWithImpl<$Res>
    implements $ReplyCopyWith<$Res> {
  _$ReplyCopyWithImpl(this._self, this._then);

  final Reply _self;
  final $Res Function(Reply) _then;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cid = null,Object? uid = null,Object? username = null,Object? nickname = null,Object? likes = null,Object? gender = null,Object? updateAt = null,Object? addtime = null,Object? parentCid = null,Object? photo = null,Object? content = null,Object? expinfo = null,Object? spoiler = null,}) {
  return _then(_self.copyWith(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,updateAt: null == updateAt ? _self.updateAt : updateAt // ignore: cast_nullable_to_non_nullable
as String,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,parentCid: null == parentCid ? _self.parentCid : parentCid // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,expinfo: null == expinfo ? _self.expinfo : expinfo // ignore: cast_nullable_to_non_nullable
as Expinfo,spoiler: null == spoiler ? _self.spoiler : spoiler // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpinfoCopyWith<$Res> get expinfo {
  
  return $ExpinfoCopyWith<$Res>(_self.expinfo, (value) {
    return _then(_self.copyWith(expinfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [Reply].
extension ReplyPatterns on Reply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reply value)  $default,){
final _that = this;
switch (_that) {
case _Reply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reply value)?  $default,){
final _that = this;
switch (_that) {
case _Reply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "CID")  String cid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "username")  String username, @JsonKey(name: "nickname")  String nickname, @JsonKey(name: "likes")  String likes, @JsonKey(name: "gender")  String gender, @JsonKey(name: "update_at")  String updateAt, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "parent_CID")  String parentCid, @JsonKey(name: "photo")  String photo, @JsonKey(name: "content")  String content, @JsonKey(name: "expinfo")  Expinfo expinfo, @JsonKey(name: "spoiler")  String spoiler)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reply() when $default != null:
return $default(_that.cid,_that.uid,_that.username,_that.nickname,_that.likes,_that.gender,_that.updateAt,_that.addtime,_that.parentCid,_that.photo,_that.content,_that.expinfo,_that.spoiler);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "CID")  String cid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "username")  String username, @JsonKey(name: "nickname")  String nickname, @JsonKey(name: "likes")  String likes, @JsonKey(name: "gender")  String gender, @JsonKey(name: "update_at")  String updateAt, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "parent_CID")  String parentCid, @JsonKey(name: "photo")  String photo, @JsonKey(name: "content")  String content, @JsonKey(name: "expinfo")  Expinfo expinfo, @JsonKey(name: "spoiler")  String spoiler)  $default,) {final _that = this;
switch (_that) {
case _Reply():
return $default(_that.cid,_that.uid,_that.username,_that.nickname,_that.likes,_that.gender,_that.updateAt,_that.addtime,_that.parentCid,_that.photo,_that.content,_that.expinfo,_that.spoiler);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "CID")  String cid, @JsonKey(name: "UID")  String uid, @JsonKey(name: "username")  String username, @JsonKey(name: "nickname")  String nickname, @JsonKey(name: "likes")  String likes, @JsonKey(name: "gender")  String gender, @JsonKey(name: "update_at")  String updateAt, @JsonKey(name: "addtime")  String addtime, @JsonKey(name: "parent_CID")  String parentCid, @JsonKey(name: "photo")  String photo, @JsonKey(name: "content")  String content, @JsonKey(name: "expinfo")  Expinfo expinfo, @JsonKey(name: "spoiler")  String spoiler)?  $default,) {final _that = this;
switch (_that) {
case _Reply() when $default != null:
return $default(_that.cid,_that.uid,_that.username,_that.nickname,_that.likes,_that.gender,_that.updateAt,_that.addtime,_that.parentCid,_that.photo,_that.content,_that.expinfo,_that.spoiler);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reply implements Reply {
  const _Reply({@JsonKey(name: "CID") required this.cid, @JsonKey(name: "UID") required this.uid, @JsonKey(name: "username") required this.username, @JsonKey(name: "nickname") required this.nickname, @JsonKey(name: "likes") required this.likes, @JsonKey(name: "gender") required this.gender, @JsonKey(name: "update_at") required this.updateAt, @JsonKey(name: "addtime") required this.addtime, @JsonKey(name: "parent_CID") required this.parentCid, @JsonKey(name: "photo") required this.photo, @JsonKey(name: "content") required this.content, @JsonKey(name: "expinfo") required this.expinfo, @JsonKey(name: "spoiler") required this.spoiler});
  factory _Reply.fromJson(Map<String, dynamic> json) => _$ReplyFromJson(json);

@override@JsonKey(name: "CID") final  String cid;
@override@JsonKey(name: "UID") final  String uid;
@override@JsonKey(name: "username") final  String username;
@override@JsonKey(name: "nickname") final  String nickname;
@override@JsonKey(name: "likes") final  String likes;
@override@JsonKey(name: "gender") final  String gender;
@override@JsonKey(name: "update_at") final  String updateAt;
@override@JsonKey(name: "addtime") final  String addtime;
@override@JsonKey(name: "parent_CID") final  String parentCid;
@override@JsonKey(name: "photo") final  String photo;
@override@JsonKey(name: "content") final  String content;
@override@JsonKey(name: "expinfo") final  Expinfo expinfo;
@override@JsonKey(name: "spoiler") final  String spoiler;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReplyCopyWith<_Reply> get copyWith => __$ReplyCopyWithImpl<_Reply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reply&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.username, username) || other.username == username)&&(identical(other.nickname, nickname) || other.nickname == nickname)&&(identical(other.likes, likes) || other.likes == likes)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.updateAt, updateAt) || other.updateAt == updateAt)&&(identical(other.addtime, addtime) || other.addtime == addtime)&&(identical(other.parentCid, parentCid) || other.parentCid == parentCid)&&(identical(other.photo, photo) || other.photo == photo)&&(identical(other.content, content) || other.content == content)&&(identical(other.expinfo, expinfo) || other.expinfo == expinfo)&&(identical(other.spoiler, spoiler) || other.spoiler == spoiler));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cid,uid,username,nickname,likes,gender,updateAt,addtime,parentCid,photo,content,expinfo,spoiler);

@override
String toString() {
  return 'Reply(cid: $cid, uid: $uid, username: $username, nickname: $nickname, likes: $likes, gender: $gender, updateAt: $updateAt, addtime: $addtime, parentCid: $parentCid, photo: $photo, content: $content, expinfo: $expinfo, spoiler: $spoiler)';
}


}

/// @nodoc
abstract mixin class _$ReplyCopyWith<$Res> implements $ReplyCopyWith<$Res> {
  factory _$ReplyCopyWith(_Reply value, $Res Function(_Reply) _then) = __$ReplyCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "CID") String cid,@JsonKey(name: "UID") String uid,@JsonKey(name: "username") String username,@JsonKey(name: "nickname") String nickname,@JsonKey(name: "likes") String likes,@JsonKey(name: "gender") String gender,@JsonKey(name: "update_at") String updateAt,@JsonKey(name: "addtime") String addtime,@JsonKey(name: "parent_CID") String parentCid,@JsonKey(name: "photo") String photo,@JsonKey(name: "content") String content,@JsonKey(name: "expinfo") Expinfo expinfo,@JsonKey(name: "spoiler") String spoiler
});


@override $ExpinfoCopyWith<$Res> get expinfo;

}
/// @nodoc
class __$ReplyCopyWithImpl<$Res>
    implements _$ReplyCopyWith<$Res> {
  __$ReplyCopyWithImpl(this._self, this._then);

  final _Reply _self;
  final $Res Function(_Reply) _then;

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cid = null,Object? uid = null,Object? username = null,Object? nickname = null,Object? likes = null,Object? gender = null,Object? updateAt = null,Object? addtime = null,Object? parentCid = null,Object? photo = null,Object? content = null,Object? expinfo = null,Object? spoiler = null,}) {
  return _then(_Reply(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,nickname: null == nickname ? _self.nickname : nickname // ignore: cast_nullable_to_non_nullable
as String,likes: null == likes ? _self.likes : likes // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,updateAt: null == updateAt ? _self.updateAt : updateAt // ignore: cast_nullable_to_non_nullable
as String,addtime: null == addtime ? _self.addtime : addtime // ignore: cast_nullable_to_non_nullable
as String,parentCid: null == parentCid ? _self.parentCid : parentCid // ignore: cast_nullable_to_non_nullable
as String,photo: null == photo ? _self.photo : photo // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,expinfo: null == expinfo ? _self.expinfo : expinfo // ignore: cast_nullable_to_non_nullable
as Expinfo,spoiler: null == spoiler ? _self.spoiler : spoiler // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Reply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExpinfoCopyWith<$Res> get expinfo {
  
  return $ExpinfoCopyWith<$Res>(_self.expinfo, (value) {
    return _then(_self.copyWith(expinfo: value));
  });
}
}

// dart format on
