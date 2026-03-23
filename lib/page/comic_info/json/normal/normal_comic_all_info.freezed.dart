// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'normal_comic_all_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NormalComicAllInfo {

@JsonKey(name: 'comicInfo') ComicInfo get comicInfo;@JsonKey(name: 'eps') List<Ep> get eps;@JsonKey(name: 'recommend') List<Recommend> get recommend;@JsonKey(name: 'totalViews') int get totalViews;@JsonKey(name: 'totalLikes') int get totalLikes;@JsonKey(name: 'totalComments') int get totalComments;@JsonKey(name: 'isFavourite') bool get isFavourite;@JsonKey(name: 'isLiked') bool get isLiked;@JsonKey(name: 'allowComment') bool get allowComment;@JsonKey(name: 'allowLike') bool get allowLike;@JsonKey(name: 'allowFavorite') bool get allowFavorite;@JsonKey(name: 'allowDownload') bool get allowDownload;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NormalComicAllInfoCopyWith<NormalComicAllInfo> get copyWith => _$NormalComicAllInfoCopyWithImpl<NormalComicAllInfo>(this as NormalComicAllInfo, _$identity);

  /// Serializes this NormalComicAllInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NormalComicAllInfo&&(identical(other.comicInfo, comicInfo) || other.comicInfo == comicInfo)&&const DeepCollectionEquality().equals(other.eps, eps)&&const DeepCollectionEquality().equals(other.recommend, recommend)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.allowLike, allowLike) || other.allowLike == allowLike)&&(identical(other.allowFavorite, allowFavorite) || other.allowFavorite == allowFavorite)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comicInfo,const DeepCollectionEquality().hash(eps),const DeepCollectionEquality().hash(recommend),totalViews,totalLikes,totalComments,isFavourite,isLiked,allowComment,allowLike,allowFavorite,allowDownload,const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'NormalComicAllInfo(comicInfo: $comicInfo, eps: $eps, recommend: $recommend, totalViews: $totalViews, totalLikes: $totalLikes, totalComments: $totalComments, isFavourite: $isFavourite, isLiked: $isLiked, allowComment: $allowComment, allowLike: $allowLike, allowFavorite: $allowFavorite, allowDownload: $allowDownload, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $NormalComicAllInfoCopyWith<$Res>  {
  factory $NormalComicAllInfoCopyWith(NormalComicAllInfo value, $Res Function(NormalComicAllInfo) _then) = _$NormalComicAllInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'comicInfo') ComicInfo comicInfo,@JsonKey(name: 'eps') List<Ep> eps,@JsonKey(name: 'recommend') List<Recommend> recommend,@JsonKey(name: 'totalViews') int totalViews,@JsonKey(name: 'totalLikes') int totalLikes,@JsonKey(name: 'totalComments') int totalComments,@JsonKey(name: 'isFavourite') bool isFavourite,@JsonKey(name: 'isLiked') bool isLiked,@JsonKey(name: 'allowComment') bool allowComment,@JsonKey(name: 'allowLike') bool allowLike,@JsonKey(name: 'allowFavorite') bool allowFavorite,@JsonKey(name: 'allowDownload') bool allowDownload,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


$ComicInfoCopyWith<$Res> get comicInfo;

}
/// @nodoc
class _$NormalComicAllInfoCopyWithImpl<$Res>
    implements $NormalComicAllInfoCopyWith<$Res> {
  _$NormalComicAllInfoCopyWithImpl(this._self, this._then);

  final NormalComicAllInfo _self;
  final $Res Function(NormalComicAllInfo) _then;

/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comicInfo = null,Object? eps = null,Object? recommend = null,Object? totalViews = null,Object? totalLikes = null,Object? totalComments = null,Object? isFavourite = null,Object? isLiked = null,Object? allowComment = null,Object? allowLike = null,Object? allowFavorite = null,Object? allowDownload = null,Object? extension = null,}) {
  return _then(_self.copyWith(
comicInfo: null == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as ComicInfo,eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as List<Ep>,recommend: null == recommend ? _self.recommend : recommend // ignore: cast_nullable_to_non_nullable
as List<Recommend>,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,allowLike: null == allowLike ? _self.allowLike : allowLike // ignore: cast_nullable_to_non_nullable
as bool,allowFavorite: null == allowFavorite ? _self.allowFavorite : allowFavorite // ignore: cast_nullable_to_non_nullable
as bool,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<$Res> get comicInfo {
  
  return $ComicInfoCopyWith<$Res>(_self.comicInfo, (value) {
    return _then(_self.copyWith(comicInfo: value));
  });
}
}


/// Adds pattern-matching-related methods to [NormalComicAllInfo].
extension NormalComicAllInfoPatterns on NormalComicAllInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NormalComicAllInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NormalComicAllInfo value)  $default,){
final _that = this;
switch (_that) {
case _NormalComicAllInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NormalComicAllInfo value)?  $default,){
final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'comicInfo')  ComicInfo comicInfo, @JsonKey(name: 'eps')  List<Ep> eps, @JsonKey(name: 'recommend')  List<Recommend> recommend, @JsonKey(name: 'totalViews')  int totalViews, @JsonKey(name: 'totalLikes')  int totalLikes, @JsonKey(name: 'totalComments')  int totalComments, @JsonKey(name: 'isFavourite')  bool isFavourite, @JsonKey(name: 'isLiked')  bool isLiked, @JsonKey(name: 'allowComment')  bool allowComment, @JsonKey(name: 'allowLike')  bool allowLike, @JsonKey(name: 'allowFavorite')  bool allowFavorite, @JsonKey(name: 'allowDownload')  bool allowDownload, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
return $default(_that.comicInfo,_that.eps,_that.recommend,_that.totalViews,_that.totalLikes,_that.totalComments,_that.isFavourite,_that.isLiked,_that.allowComment,_that.allowLike,_that.allowFavorite,_that.allowDownload,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'comicInfo')  ComicInfo comicInfo, @JsonKey(name: 'eps')  List<Ep> eps, @JsonKey(name: 'recommend')  List<Recommend> recommend, @JsonKey(name: 'totalViews')  int totalViews, @JsonKey(name: 'totalLikes')  int totalLikes, @JsonKey(name: 'totalComments')  int totalComments, @JsonKey(name: 'isFavourite')  bool isFavourite, @JsonKey(name: 'isLiked')  bool isLiked, @JsonKey(name: 'allowComment')  bool allowComment, @JsonKey(name: 'allowLike')  bool allowLike, @JsonKey(name: 'allowFavorite')  bool allowFavorite, @JsonKey(name: 'allowDownload')  bool allowDownload, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _NormalComicAllInfo():
return $default(_that.comicInfo,_that.eps,_that.recommend,_that.totalViews,_that.totalLikes,_that.totalComments,_that.isFavourite,_that.isLiked,_that.allowComment,_that.allowLike,_that.allowFavorite,_that.allowDownload,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'comicInfo')  ComicInfo comicInfo, @JsonKey(name: 'eps')  List<Ep> eps, @JsonKey(name: 'recommend')  List<Recommend> recommend, @JsonKey(name: 'totalViews')  int totalViews, @JsonKey(name: 'totalLikes')  int totalLikes, @JsonKey(name: 'totalComments')  int totalComments, @JsonKey(name: 'isFavourite')  bool isFavourite, @JsonKey(name: 'isLiked')  bool isLiked, @JsonKey(name: 'allowComment')  bool allowComment, @JsonKey(name: 'allowLike')  bool allowLike, @JsonKey(name: 'allowFavorite')  bool allowFavorite, @JsonKey(name: 'allowDownload')  bool allowDownload, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _NormalComicAllInfo() when $default != null:
return $default(_that.comicInfo,_that.eps,_that.recommend,_that.totalViews,_that.totalLikes,_that.totalComments,_that.isFavourite,_that.isLiked,_that.allowComment,_that.allowLike,_that.allowFavorite,_that.allowDownload,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NormalComicAllInfo implements NormalComicAllInfo {
  const _NormalComicAllInfo({@JsonKey(name: 'comicInfo') required this.comicInfo, @JsonKey(name: 'eps') required final  List<Ep> eps, @JsonKey(name: 'recommend') required final  List<Recommend> recommend, @JsonKey(name: 'totalViews') this.totalViews = 0, @JsonKey(name: 'totalLikes') this.totalLikes = 0, @JsonKey(name: 'totalComments') this.totalComments = 0, @JsonKey(name: 'isFavourite') this.isFavourite = false, @JsonKey(name: 'isLiked') this.isLiked = false, @JsonKey(name: 'allowComment') this.allowComment = true, @JsonKey(name: 'allowLike') this.allowLike = true, @JsonKey(name: 'allowFavorite') this.allowFavorite = true, @JsonKey(name: 'allowDownload') this.allowDownload = true, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _eps = eps,_recommend = recommend,_extension = extension;
  factory _NormalComicAllInfo.fromJson(Map<String, dynamic> json) => _$NormalComicAllInfoFromJson(json);

@override@JsonKey(name: 'comicInfo') final  ComicInfo comicInfo;
 final  List<Ep> _eps;
@override@JsonKey(name: 'eps') List<Ep> get eps {
  if (_eps is EqualUnmodifiableListView) return _eps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eps);
}

 final  List<Recommend> _recommend;
@override@JsonKey(name: 'recommend') List<Recommend> get recommend {
  if (_recommend is EqualUnmodifiableListView) return _recommend;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommend);
}

@override@JsonKey(name: 'totalViews') final  int totalViews;
@override@JsonKey(name: 'totalLikes') final  int totalLikes;
@override@JsonKey(name: 'totalComments') final  int totalComments;
@override@JsonKey(name: 'isFavourite') final  bool isFavourite;
@override@JsonKey(name: 'isLiked') final  bool isLiked;
@override@JsonKey(name: 'allowComment') final  bool allowComment;
@override@JsonKey(name: 'allowLike') final  bool allowLike;
@override@JsonKey(name: 'allowFavorite') final  bool allowFavorite;
@override@JsonKey(name: 'allowDownload') final  bool allowDownload;
 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NormalComicAllInfoCopyWith<_NormalComicAllInfo> get copyWith => __$NormalComicAllInfoCopyWithImpl<_NormalComicAllInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NormalComicAllInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NormalComicAllInfo&&(identical(other.comicInfo, comicInfo) || other.comicInfo == comicInfo)&&const DeepCollectionEquality().equals(other._eps, _eps)&&const DeepCollectionEquality().equals(other._recommend, _recommend)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked)&&(identical(other.allowComment, allowComment) || other.allowComment == allowComment)&&(identical(other.allowLike, allowLike) || other.allowLike == allowLike)&&(identical(other.allowFavorite, allowFavorite) || other.allowFavorite == allowFavorite)&&(identical(other.allowDownload, allowDownload) || other.allowDownload == allowDownload)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comicInfo,const DeepCollectionEquality().hash(_eps),const DeepCollectionEquality().hash(_recommend),totalViews,totalLikes,totalComments,isFavourite,isLiked,allowComment,allowLike,allowFavorite,allowDownload,const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'NormalComicAllInfo(comicInfo: $comicInfo, eps: $eps, recommend: $recommend, totalViews: $totalViews, totalLikes: $totalLikes, totalComments: $totalComments, isFavourite: $isFavourite, isLiked: $isLiked, allowComment: $allowComment, allowLike: $allowLike, allowFavorite: $allowFavorite, allowDownload: $allowDownload, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$NormalComicAllInfoCopyWith<$Res> implements $NormalComicAllInfoCopyWith<$Res> {
  factory _$NormalComicAllInfoCopyWith(_NormalComicAllInfo value, $Res Function(_NormalComicAllInfo) _then) = __$NormalComicAllInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'comicInfo') ComicInfo comicInfo,@JsonKey(name: 'eps') List<Ep> eps,@JsonKey(name: 'recommend') List<Recommend> recommend,@JsonKey(name: 'totalViews') int totalViews,@JsonKey(name: 'totalLikes') int totalLikes,@JsonKey(name: 'totalComments') int totalComments,@JsonKey(name: 'isFavourite') bool isFavourite,@JsonKey(name: 'isLiked') bool isLiked,@JsonKey(name: 'allowComment') bool allowComment,@JsonKey(name: 'allowLike') bool allowLike,@JsonKey(name: 'allowFavorite') bool allowFavorite,@JsonKey(name: 'allowDownload') bool allowDownload,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


@override $ComicInfoCopyWith<$Res> get comicInfo;

}
/// @nodoc
class __$NormalComicAllInfoCopyWithImpl<$Res>
    implements _$NormalComicAllInfoCopyWith<$Res> {
  __$NormalComicAllInfoCopyWithImpl(this._self, this._then);

  final _NormalComicAllInfo _self;
  final $Res Function(_NormalComicAllInfo) _then;

/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comicInfo = null,Object? eps = null,Object? recommend = null,Object? totalViews = null,Object? totalLikes = null,Object? totalComments = null,Object? isFavourite = null,Object? isLiked = null,Object? allowComment = null,Object? allowLike = null,Object? allowFavorite = null,Object? allowDownload = null,Object? extension = null,}) {
  return _then(_NormalComicAllInfo(
comicInfo: null == comicInfo ? _self.comicInfo : comicInfo // ignore: cast_nullable_to_non_nullable
as ComicInfo,eps: null == eps ? _self._eps : eps // ignore: cast_nullable_to_non_nullable
as List<Ep>,recommend: null == recommend ? _self._recommend : recommend // ignore: cast_nullable_to_non_nullable
as List<Recommend>,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,allowComment: null == allowComment ? _self.allowComment : allowComment // ignore: cast_nullable_to_non_nullable
as bool,allowLike: null == allowLike ? _self.allowLike : allowLike // ignore: cast_nullable_to_non_nullable
as bool,allowFavorite: null == allowFavorite ? _self.allowFavorite : allowFavorite // ignore: cast_nullable_to_non_nullable
as bool,allowDownload: null == allowDownload ? _self.allowDownload : allowDownload // ignore: cast_nullable_to_non_nullable
as bool,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of NormalComicAllInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<$Res> get comicInfo {
  
  return $ComicInfoCopyWith<$Res>(_self.comicInfo, (value) {
    return _then(_self.copyWith(comicInfo: value));
  });
}
}


/// @nodoc
mixin _$ComicInfoActionItem {

@JsonKey(name: 'name') String get name;@JsonKey(name: 'onTap') Map<String, dynamic> get onTap;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoActionItemCopyWith<ComicInfoActionItem> get copyWith => _$ComicInfoActionItemCopyWithImpl<ComicInfoActionItem>(this as ComicInfoActionItem, _$identity);

  /// Serializes this ComicInfoActionItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfoActionItem&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.onTap, onTap)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(onTap),const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'ComicInfoActionItem(name: $name, onTap: $onTap, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $ComicInfoActionItemCopyWith<$Res>  {
  factory $ComicInfoActionItemCopyWith(ComicInfoActionItem value, $Res Function(ComicInfoActionItem) _then) = _$ComicInfoActionItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'extension') Map<String, dynamic> extension
});




}
/// @nodoc
class _$ComicInfoActionItemCopyWithImpl<$Res>
    implements $ComicInfoActionItemCopyWith<$Res> {
  _$ComicInfoActionItemCopyWithImpl(this._self, this._then);

  final ComicInfoActionItem _self;
  final $Res Function(ComicInfoActionItem) _then;

/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? onTap = null,Object? extension = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,onTap: null == onTap ? _self.onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicInfoActionItem].
extension ComicInfoActionItemPatterns on ComicInfoActionItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicInfoActionItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicInfoActionItem value)  $default,){
final _that = this;
switch (_that) {
case _ComicInfoActionItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicInfoActionItem value)?  $default,){
final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
return $default(_that.name,_that.onTap,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _ComicInfoActionItem():
return $default(_that.name,_that.onTap,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfoActionItem() when $default != null:
return $default(_that.name,_that.onTap,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfoActionItem implements ComicInfoActionItem {
  const _ComicInfoActionItem({@JsonKey(name: 'name') required this.name, @JsonKey(name: 'onTap') final  Map<String, dynamic> onTap = const {}, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _onTap = onTap,_extension = extension;
  factory _ComicInfoActionItem.fromJson(Map<String, dynamic> json) => _$ComicInfoActionItemFromJson(json);

@override@JsonKey(name: 'name') final  String name;
 final  Map<String, dynamic> _onTap;
@override@JsonKey(name: 'onTap') Map<String, dynamic> get onTap {
  if (_onTap is EqualUnmodifiableMapView) return _onTap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_onTap);
}

 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicInfoActionItemCopyWith<_ComicInfoActionItem> get copyWith => __$ComicInfoActionItemCopyWithImpl<_ComicInfoActionItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicInfoActionItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfoActionItem&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._onTap, _onTap)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_onTap),const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'ComicInfoActionItem(name: $name, onTap: $onTap, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoActionItemCopyWith<$Res> implements $ComicInfoActionItemCopyWith<$Res> {
  factory _$ComicInfoActionItemCopyWith(_ComicInfoActionItem value, $Res Function(_ComicInfoActionItem) _then) = __$ComicInfoActionItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'extension') Map<String, dynamic> extension
});




}
/// @nodoc
class __$ComicInfoActionItemCopyWithImpl<$Res>
    implements _$ComicInfoActionItemCopyWith<$Res> {
  __$ComicInfoActionItemCopyWithImpl(this._self, this._then);

  final _ComicInfoActionItem _self;
  final $Res Function(_ComicInfoActionItem) _then;

/// Create a copy of ComicInfoActionItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? onTap = null,Object? extension = null,}) {
  return _then(_ComicInfoActionItem(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,onTap: null == onTap ? _self._onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$ComicInfoMetadata {

@JsonKey(name: 'type') String get type;@JsonKey(name: 'name') String get name;@JsonKey(name: 'value') List<ComicInfoActionItem> get value;
/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoMetadataCopyWith<ComicInfoMetadata> get copyWith => _$ComicInfoMetadataCopyWithImpl<ComicInfoMetadata>(this as ComicInfoMetadata, _$identity);

  /// Serializes this ComicInfoMetadata to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfoMetadata&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.value, value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,name,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'ComicInfoMetadata(type: $type, name: $name, value: $value)';
}


}

/// @nodoc
abstract mixin class $ComicInfoMetadataCopyWith<$Res>  {
  factory $ComicInfoMetadataCopyWith(ComicInfoMetadata value, $Res Function(ComicInfoMetadata) _then) = _$ComicInfoMetadataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'type') String type,@JsonKey(name: 'name') String name,@JsonKey(name: 'value') List<ComicInfoActionItem> value
});




}
/// @nodoc
class _$ComicInfoMetadataCopyWithImpl<$Res>
    implements $ComicInfoMetadataCopyWith<$Res> {
  _$ComicInfoMetadataCopyWithImpl(this._self, this._then);

  final ComicInfoMetadata _self;
  final $Res Function(ComicInfoMetadata) _then;

/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? name = null,Object? value = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as List<ComicInfoActionItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicInfoMetadata].
extension ComicInfoMetadataPatterns on ComicInfoMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicInfoMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicInfoMetadata value)  $default,){
final _that = this;
switch (_that) {
case _ComicInfoMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicInfoMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'type')  String type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'value')  List<ComicInfoActionItem> value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'type')  String type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'value')  List<ComicInfoActionItem> value)  $default,) {final _that = this;
switch (_that) {
case _ComicInfoMetadata():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'type')  String type, @JsonKey(name: 'name')  String name, @JsonKey(name: 'value')  List<ComicInfoActionItem> value)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfoMetadata() when $default != null:
return $default(_that.type,_that.name,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfoMetadata implements ComicInfoMetadata {
  const _ComicInfoMetadata({@JsonKey(name: 'type') required this.type, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'value') required final  List<ComicInfoActionItem> value}): _value = value;
  factory _ComicInfoMetadata.fromJson(Map<String, dynamic> json) => _$ComicInfoMetadataFromJson(json);

@override@JsonKey(name: 'type') final  String type;
@override@JsonKey(name: 'name') final  String name;
 final  List<ComicInfoActionItem> _value;
@override@JsonKey(name: 'value') List<ComicInfoActionItem> get value {
  if (_value is EqualUnmodifiableListView) return _value;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_value);
}


/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicInfoMetadataCopyWith<_ComicInfoMetadata> get copyWith => __$ComicInfoMetadataCopyWithImpl<_ComicInfoMetadata>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicInfoMetadataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfoMetadata&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._value, _value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,name,const DeepCollectionEquality().hash(_value));

@override
String toString() {
  return 'ComicInfoMetadata(type: $type, name: $name, value: $value)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoMetadataCopyWith<$Res> implements $ComicInfoMetadataCopyWith<$Res> {
  factory _$ComicInfoMetadataCopyWith(_ComicInfoMetadata value, $Res Function(_ComicInfoMetadata) _then) = __$ComicInfoMetadataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'type') String type,@JsonKey(name: 'name') String name,@JsonKey(name: 'value') List<ComicInfoActionItem> value
});




}
/// @nodoc
class __$ComicInfoMetadataCopyWithImpl<$Res>
    implements _$ComicInfoMetadataCopyWith<$Res> {
  __$ComicInfoMetadataCopyWithImpl(this._self, this._then);

  final _ComicInfoMetadata _self;
  final $Res Function(_ComicInfoMetadata) _then;

/// Create a copy of ComicInfoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? name = null,Object? value = null,}) {
  return _then(_ComicInfoMetadata(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self._value : value // ignore: cast_nullable_to_non_nullable
as List<ComicInfoActionItem>,
  ));
}


}


/// @nodoc
mixin _$ComicImage {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'url') String get url;@JsonKey(name: 'name') String get name;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicImageCopyWith<ComicImage> get copyWith => _$ComicImageCopyWithImpl<ComicImage>(this as ComicImage, _$identity);

  /// Serializes this ComicImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,name,const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'ComicImage(id: $id, url: $url, name: $name, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $ComicImageCopyWith<$Res>  {
  factory $ComicImageCopyWith(ComicImage value, $Res Function(ComicImage) _then) = _$ComicImageCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'url') String url,@JsonKey(name: 'name') String name,@JsonKey(name: 'extension') Map<String, dynamic> extension
});




}
/// @nodoc
class _$ComicImageCopyWithImpl<$Res>
    implements $ComicImageCopyWith<$Res> {
  _$ComicImageCopyWithImpl(this._self, this._then);

  final ComicImage _self;
  final $Res Function(ComicImage) _then;

/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? name = null,Object? extension = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [ComicImage].
extension ComicImagePatterns on ComicImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicImage value)  $default,){
final _that = this;
switch (_that) {
case _ComicImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicImage value)?  $default,){
final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'url')  String url, @JsonKey(name: 'name')  String name, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
return $default(_that.id,_that.url,_that.name,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'url')  String url, @JsonKey(name: 'name')  String name, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _ComicImage():
return $default(_that.id,_that.url,_that.name,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'url')  String url, @JsonKey(name: 'name')  String name, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _ComicImage() when $default != null:
return $default(_that.id,_that.url,_that.name,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicImage implements ComicImage {
  const _ComicImage({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'url') required this.url, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _extension = extension;
  factory _ComicImage.fromJson(Map<String, dynamic> json) => _$ComicImageFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'url') final  String url;
@override@JsonKey(name: 'name') final  String name;
 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicImageCopyWith<_ComicImage> get copyWith => __$ComicImageCopyWithImpl<_ComicImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,name,const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'ComicImage(id: $id, url: $url, name: $name, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$ComicImageCopyWith<$Res> implements $ComicImageCopyWith<$Res> {
  factory _$ComicImageCopyWith(_ComicImage value, $Res Function(_ComicImage) _then) = __$ComicImageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'url') String url,@JsonKey(name: 'name') String name,@JsonKey(name: 'extension') Map<String, dynamic> extension
});




}
/// @nodoc
class __$ComicImageCopyWithImpl<$Res>
    implements _$ComicImageCopyWith<$Res> {
  __$ComicImageCopyWithImpl(this._self, this._then);

  final _ComicImage _self;
  final $Res Function(_ComicImage) _then;

/// Create a copy of ComicImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? name = null,Object? extension = null,}) {
  return _then(_ComicImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$Creator {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'name') String get name;@JsonKey(name: 'avatar') ComicImage get avatar;@JsonKey(name: 'onTap') Map<String, dynamic> get onTap;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatorCopyWith<Creator> get copyWith => _$CreatorCopyWithImpl<Creator>(this as Creator, _$identity);

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&const DeepCollectionEquality().equals(other.onTap, onTap)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatar,const DeepCollectionEquality().hash(onTap),const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'Creator(id: $id, name: $name, avatar: $avatar, onTap: $onTap, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $CreatorCopyWith<$Res>  {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) _then) = _$CreatorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'avatar') ComicImage avatar,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


$ComicImageCopyWith<$Res> get avatar;

}
/// @nodoc
class _$CreatorCopyWithImpl<$Res>
    implements $CreatorCopyWith<$Res> {
  _$CreatorCopyWithImpl(this._self, this._then);

  final Creator _self;
  final $Res Function(Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? avatar = null,Object? onTap = null,Object? extension = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as ComicImage,onTap: null == onTap ? _self.onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get avatar {
  
  return $ComicImageCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// Adds pattern-matching-related methods to [Creator].
extension CreatorPatterns on Creator {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Creator value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Creator() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Creator value)  $default,){
final _that = this;
switch (_that) {
case _Creator():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Creator value)?  $default,){
final _that = this;
switch (_that) {
case _Creator() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'avatar')  ComicImage avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.onTap,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'avatar')  ComicImage avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _Creator():
return $default(_that.id,_that.name,_that.avatar,_that.onTap,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'avatar')  ComicImage avatar, @JsonKey(name: 'onTap')  Map<String, dynamic> onTap, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _Creator() when $default != null:
return $default(_that.id,_that.name,_that.avatar,_that.onTap,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Creator implements Creator {
  const _Creator({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'avatar') required this.avatar, @JsonKey(name: 'onTap') final  Map<String, dynamic> onTap = const {}, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _onTap = onTap,_extension = extension;
  factory _Creator.fromJson(Map<String, dynamic> json) => _$CreatorFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'avatar') final  ComicImage avatar;
 final  Map<String, dynamic> _onTap;
@override@JsonKey(name: 'onTap') Map<String, dynamic> get onTap {
  if (_onTap is EqualUnmodifiableMapView) return _onTap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_onTap);
}

 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatorCopyWith<_Creator> get copyWith => __$CreatorCopyWithImpl<_Creator>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Creator&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&const DeepCollectionEquality().equals(other._onTap, _onTap)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,avatar,const DeepCollectionEquality().hash(_onTap),const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'Creator(id: $id, name: $name, avatar: $avatar, onTap: $onTap, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$CreatorCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$CreatorCopyWith(_Creator value, $Res Function(_Creator) _then) = __$CreatorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'avatar') ComicImage avatar,@JsonKey(name: 'onTap') Map<String, dynamic> onTap,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


@override $ComicImageCopyWith<$Res> get avatar;

}
/// @nodoc
class __$CreatorCopyWithImpl<$Res>
    implements _$CreatorCopyWith<$Res> {
  __$CreatorCopyWithImpl(this._self, this._then);

  final _Creator _self;
  final $Res Function(_Creator) _then;

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? avatar = null,Object? onTap = null,Object? extension = null,}) {
  return _then(_Creator(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as ComicImage,onTap: null == onTap ? _self._onTap : onTap // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of Creator
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get avatar {
  
  return $ComicImageCopyWith<$Res>(_self.avatar, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// @nodoc
mixin _$ComicInfo {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'title') String get title;@JsonKey(name: 'titleMeta') List<ComicInfoActionItem> get titleMeta;@JsonKey(name: 'creator') Creator get creator;@JsonKey(name: 'description') String get description;@JsonKey(name: 'cover') ComicImage get cover;@JsonKey(name: 'metadata') List<ComicInfoMetadata> get metadata;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicInfoCopyWith<ComicInfo> get copyWith => _$ComicInfoCopyWithImpl<ComicInfo>(this as ComicInfo, _$identity);

  /// Serializes this ComicInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ComicInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.titleMeta, titleMeta)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.description, description) || other.description == description)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(titleMeta),creator,description,cover,const DeepCollectionEquality().hash(metadata),const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'ComicInfo(id: $id, title: $title, titleMeta: $titleMeta, creator: $creator, description: $description, cover: $cover, metadata: $metadata, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $ComicInfoCopyWith<$Res>  {
  factory $ComicInfoCopyWith(ComicInfo value, $Res Function(ComicInfo) _then) = _$ComicInfoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'title') String title,@JsonKey(name: 'titleMeta') List<ComicInfoActionItem> titleMeta,@JsonKey(name: 'creator') Creator creator,@JsonKey(name: 'description') String description,@JsonKey(name: 'cover') ComicImage cover,@JsonKey(name: 'metadata') List<ComicInfoMetadata> metadata,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


$CreatorCopyWith<$Res> get creator;$ComicImageCopyWith<$Res> get cover;

}
/// @nodoc
class _$ComicInfoCopyWithImpl<$Res>
    implements $ComicInfoCopyWith<$Res> {
  _$ComicInfoCopyWithImpl(this._self, this._then);

  final ComicInfo _self;
  final $Res Function(ComicInfo) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? titleMeta = null,Object? creator = null,Object? description = null,Object? cover = null,Object? metadata = null,Object? extension = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,titleMeta: null == titleMeta ? _self.titleMeta : titleMeta // ignore: cast_nullable_to_non_nullable
as List<ComicInfoActionItem>,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Creator,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ComicImage,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<ComicInfoMetadata>,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorCopyWith<$Res> get creator {
  
  return $CreatorCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get cover {
  
  return $ComicImageCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// Adds pattern-matching-related methods to [ComicInfo].
extension ComicInfoPatterns on ComicInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ComicInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ComicInfo value)  $default,){
final _that = this;
switch (_that) {
case _ComicInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ComicInfo value)?  $default,){
final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'titleMeta')  List<ComicInfoActionItem> titleMeta, @JsonKey(name: 'creator')  Creator creator, @JsonKey(name: 'description')  String description, @JsonKey(name: 'cover')  ComicImage cover, @JsonKey(name: 'metadata')  List<ComicInfoMetadata> metadata, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
return $default(_that.id,_that.title,_that.titleMeta,_that.creator,_that.description,_that.cover,_that.metadata,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'titleMeta')  List<ComicInfoActionItem> titleMeta, @JsonKey(name: 'creator')  Creator creator, @JsonKey(name: 'description')  String description, @JsonKey(name: 'cover')  ComicImage cover, @JsonKey(name: 'metadata')  List<ComicInfoMetadata> metadata, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _ComicInfo():
return $default(_that.id,_that.title,_that.titleMeta,_that.creator,_that.description,_that.cover,_that.metadata,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'titleMeta')  List<ComicInfoActionItem> titleMeta, @JsonKey(name: 'creator')  Creator creator, @JsonKey(name: 'description')  String description, @JsonKey(name: 'cover')  ComicImage cover, @JsonKey(name: 'metadata')  List<ComicInfoMetadata> metadata, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _ComicInfo() when $default != null:
return $default(_that.id,_that.title,_that.titleMeta,_that.creator,_that.description,_that.cover,_that.metadata,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ComicInfo implements ComicInfo {
  const _ComicInfo({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'title') required this.title, @JsonKey(name: 'titleMeta') required final  List<ComicInfoActionItem> titleMeta, @JsonKey(name: 'creator') required this.creator, @JsonKey(name: 'description') required this.description, @JsonKey(name: 'cover') required this.cover, @JsonKey(name: 'metadata') required final  List<ComicInfoMetadata> metadata, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _titleMeta = titleMeta,_metadata = metadata,_extension = extension;
  factory _ComicInfo.fromJson(Map<String, dynamic> json) => _$ComicInfoFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'title') final  String title;
 final  List<ComicInfoActionItem> _titleMeta;
@override@JsonKey(name: 'titleMeta') List<ComicInfoActionItem> get titleMeta {
  if (_titleMeta is EqualUnmodifiableListView) return _titleMeta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_titleMeta);
}

@override@JsonKey(name: 'creator') final  Creator creator;
@override@JsonKey(name: 'description') final  String description;
@override@JsonKey(name: 'cover') final  ComicImage cover;
 final  List<ComicInfoMetadata> _metadata;
@override@JsonKey(name: 'metadata') List<ComicInfoMetadata> get metadata {
  if (_metadata is EqualUnmodifiableListView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_metadata);
}

 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicInfoCopyWith<_ComicInfo> get copyWith => __$ComicInfoCopyWithImpl<_ComicInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ComicInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._titleMeta, _titleMeta)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.description, description) || other.description == description)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_titleMeta),creator,description,cover,const DeepCollectionEquality().hash(_metadata),const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'ComicInfo(id: $id, title: $title, titleMeta: $titleMeta, creator: $creator, description: $description, cover: $cover, metadata: $metadata, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$ComicInfoCopyWith<$Res> implements $ComicInfoCopyWith<$Res> {
  factory _$ComicInfoCopyWith(_ComicInfo value, $Res Function(_ComicInfo) _then) = __$ComicInfoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'title') String title,@JsonKey(name: 'titleMeta') List<ComicInfoActionItem> titleMeta,@JsonKey(name: 'creator') Creator creator,@JsonKey(name: 'description') String description,@JsonKey(name: 'cover') ComicImage cover,@JsonKey(name: 'metadata') List<ComicInfoMetadata> metadata,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


@override $CreatorCopyWith<$Res> get creator;@override $ComicImageCopyWith<$Res> get cover;

}
/// @nodoc
class __$ComicInfoCopyWithImpl<$Res>
    implements _$ComicInfoCopyWith<$Res> {
  __$ComicInfoCopyWithImpl(this._self, this._then);

  final _ComicInfo _self;
  final $Res Function(_ComicInfo) _then;

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? titleMeta = null,Object? creator = null,Object? description = null,Object? cover = null,Object? metadata = null,Object? extension = null,}) {
  return _then(_ComicInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,titleMeta: null == titleMeta ? _self._titleMeta : titleMeta // ignore: cast_nullable_to_non_nullable
as List<ComicInfoActionItem>,creator: null == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as Creator,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ComicImage,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as List<ComicInfoMetadata>,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CreatorCopyWith<$Res> get creator {
  
  return $CreatorCopyWith<$Res>(_self.creator, (value) {
    return _then(_self.copyWith(creator: value));
  });
}/// Create a copy of ComicInfo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get cover {
  
  return $ComicImageCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// @nodoc
mixin _$Ep {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'name') String get name;@JsonKey(name: 'order') int get order;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpCopyWith<Ep> get copyWith => _$EpCopyWithImpl<Ep>(this as Ep, _$identity);

  /// Serializes this Ep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ep&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,order,const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'Ep(id: $id, name: $name, order: $order, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $EpCopyWith<$Res>  {
  factory $EpCopyWith(Ep value, $Res Function(Ep) _then) = _$EpCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'order') int order,@JsonKey(name: 'extension') Map<String, dynamic> extension
});




}
/// @nodoc
class _$EpCopyWithImpl<$Res>
    implements $EpCopyWith<$Res> {
  _$EpCopyWithImpl(this._self, this._then);

  final Ep _self;
  final $Res Function(Ep) _then;

/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? order = null,Object? extension = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Ep].
extension EpPatterns on Ep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ep value)  $default,){
final _that = this;
switch (_that) {
case _Ep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ep value)?  $default,){
final _that = this;
switch (_that) {
case _Ep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'order')  int order, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ep() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'order')  int order, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _Ep():
return $default(_that.id,_that.name,_that.order,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'name')  String name, @JsonKey(name: 'order')  int order, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _Ep() when $default != null:
return $default(_that.id,_that.name,_that.order,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ep implements Ep {
  const _Ep({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'name') required this.name, @JsonKey(name: 'order') required this.order, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _extension = extension;
  factory _Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'order') final  int order;
 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpCopyWith<_Ep> get copyWith => __$EpCopyWithImpl<_Ep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ep&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,order,const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'Ep(id: $id, name: $name, order: $order, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$EpCopyWith<$Res> implements $EpCopyWith<$Res> {
  factory _$EpCopyWith(_Ep value, $Res Function(_Ep) _then) = __$EpCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'name') String name,@JsonKey(name: 'order') int order,@JsonKey(name: 'extension') Map<String, dynamic> extension
});




}
/// @nodoc
class __$EpCopyWithImpl<$Res>
    implements _$EpCopyWith<$Res> {
  __$EpCopyWithImpl(this._self, this._then);

  final _Ep _self;
  final $Res Function(_Ep) _then;

/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? order = null,Object? extension = null,}) {
  return _then(_Ep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$Recommend {

@JsonKey(name: 'source') String get source;@JsonKey(name: 'id') String get id;@JsonKey(name: 'title') String get title;@JsonKey(name: 'cover') ComicImage get cover;@JsonKey(name: 'extension') Map<String, dynamic> get extension;
/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendCopyWith<Recommend> get copyWith => _$RecommendCopyWithImpl<Recommend>(this as Recommend, _$identity);

  /// Serializes this Recommend to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recommend&&(identical(other.source, source) || other.source == source)&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other.extension, extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,id,title,cover,const DeepCollectionEquality().hash(extension));

@override
String toString() {
  return 'Recommend(source: $source, id: $id, title: $title, cover: $cover, extension: $extension)';
}


}

/// @nodoc
abstract mixin class $RecommendCopyWith<$Res>  {
  factory $RecommendCopyWith(Recommend value, $Res Function(Recommend) _then) = _$RecommendCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'source') String source,@JsonKey(name: 'id') String id,@JsonKey(name: 'title') String title,@JsonKey(name: 'cover') ComicImage cover,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


$ComicImageCopyWith<$Res> get cover;

}
/// @nodoc
class _$RecommendCopyWithImpl<$Res>
    implements $RecommendCopyWith<$Res> {
  _$RecommendCopyWithImpl(this._self, this._then);

  final Recommend _self;
  final $Res Function(Recommend) _then;

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? id = null,Object? title = null,Object? cover = null,Object? extension = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ComicImage,extension: null == extension ? _self.extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get cover {
  
  return $ComicImageCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}


/// Adds pattern-matching-related methods to [Recommend].
extension RecommendPatterns on Recommend {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recommend value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recommend() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recommend value)  $default,){
final _that = this;
switch (_that) {
case _Recommend():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recommend value)?  $default,){
final _that = this;
switch (_that) {
case _Recommend() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'source')  String source, @JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'cover')  ComicImage cover, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recommend() when $default != null:
return $default(_that.source,_that.id,_that.title,_that.cover,_that.extension);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'source')  String source, @JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'cover')  ComicImage cover, @JsonKey(name: 'extension')  Map<String, dynamic> extension)  $default,) {final _that = this;
switch (_that) {
case _Recommend():
return $default(_that.source,_that.id,_that.title,_that.cover,_that.extension);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'source')  String source, @JsonKey(name: 'id')  String id, @JsonKey(name: 'title')  String title, @JsonKey(name: 'cover')  ComicImage cover, @JsonKey(name: 'extension')  Map<String, dynamic> extension)?  $default,) {final _that = this;
switch (_that) {
case _Recommend() when $default != null:
return $default(_that.source,_that.id,_that.title,_that.cover,_that.extension);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recommend implements Recommend {
  const _Recommend({@JsonKey(name: 'source') required this.source, @JsonKey(name: 'id') required this.id, @JsonKey(name: 'title') required this.title, @JsonKey(name: 'cover') required this.cover, @JsonKey(name: 'extension') final  Map<String, dynamic> extension = const {}}): _extension = extension;
  factory _Recommend.fromJson(Map<String, dynamic> json) => _$RecommendFromJson(json);

@override@JsonKey(name: 'source') final  String source;
@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'title') final  String title;
@override@JsonKey(name: 'cover') final  ComicImage cover;
 final  Map<String, dynamic> _extension;
@override@JsonKey(name: 'extension') Map<String, dynamic> get extension {
  if (_extension is EqualUnmodifiableMapView) return _extension;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extension);
}


/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendCopyWith<_Recommend> get copyWith => __$RecommendCopyWithImpl<_Recommend>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recommend&&(identical(other.source, source) || other.source == source)&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&const DeepCollectionEquality().equals(other._extension, _extension));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,source,id,title,cover,const DeepCollectionEquality().hash(_extension));

@override
String toString() {
  return 'Recommend(source: $source, id: $id, title: $title, cover: $cover, extension: $extension)';
}


}

/// @nodoc
abstract mixin class _$RecommendCopyWith<$Res> implements $RecommendCopyWith<$Res> {
  factory _$RecommendCopyWith(_Recommend value, $Res Function(_Recommend) _then) = __$RecommendCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'source') String source,@JsonKey(name: 'id') String id,@JsonKey(name: 'title') String title,@JsonKey(name: 'cover') ComicImage cover,@JsonKey(name: 'extension') Map<String, dynamic> extension
});


@override $ComicImageCopyWith<$Res> get cover;

}
/// @nodoc
class __$RecommendCopyWithImpl<$Res>
    implements _$RecommendCopyWith<$Res> {
  __$RecommendCopyWithImpl(this._self, this._then);

  final _Recommend _self;
  final $Res Function(_Recommend) _then;

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? id = null,Object? title = null,Object? cover = null,Object? extension = null,}) {
  return _then(_Recommend(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as ComicImage,extension: null == extension ? _self._extension : extension // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of Recommend
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ComicImageCopyWith<$Res> get cover {
  
  return $ComicImageCopyWith<$Res>(_self.cover, (value) {
    return _then(_self.copyWith(cover: value));
  });
}
}

// dart format on
