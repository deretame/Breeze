// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_release_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GithubReleaseJson {

@JsonKey(name: "url") String get url;@JsonKey(name: "assets_url") String get assetsUrl;@JsonKey(name: "upload_url") String get uploadUrl;@JsonKey(name: "html_url") String get htmlUrl;@JsonKey(name: "id") int get id;@JsonKey(name: "author") Author get author;@JsonKey(name: "node_id") String get nodeId;@JsonKey(name: "tag_name") String get tagName;@JsonKey(name: "target_commitish") String get targetCommitish;@JsonKey(name: "name") String get name;@JsonKey(name: "draft") bool get draft;@JsonKey(name: "prerelease") bool get prerelease;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "published_at") DateTime get publishedAt;@JsonKey(name: "assets") List<Asset> get assets;@JsonKey(name: "tarball_url") String get tarballUrl;@JsonKey(name: "zipball_url") String get zipballUrl;@JsonKey(name: "body") String get body;
/// Create a copy of GithubReleaseJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GithubReleaseJsonCopyWith<GithubReleaseJson> get copyWith => _$GithubReleaseJsonCopyWithImpl<GithubReleaseJson>(this as GithubReleaseJson, _$identity);

  /// Serializes this GithubReleaseJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GithubReleaseJson&&(identical(other.url, url) || other.url == url)&&(identical(other.assetsUrl, assetsUrl) || other.assetsUrl == assetsUrl)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.targetCommitish, targetCommitish) || other.targetCommitish == targetCommitish)&&(identical(other.name, name) || other.name == name)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.prerelease, prerelease) || other.prerelease == prerelease)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other.assets, assets)&&(identical(other.tarballUrl, tarballUrl) || other.tarballUrl == tarballUrl)&&(identical(other.zipballUrl, zipballUrl) || other.zipballUrl == zipballUrl)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,assetsUrl,uploadUrl,htmlUrl,id,author,nodeId,tagName,targetCommitish,name,draft,prerelease,createdAt,publishedAt,const DeepCollectionEquality().hash(assets),tarballUrl,zipballUrl,body);

@override
String toString() {
  return 'GithubReleaseJson(url: $url, assetsUrl: $assetsUrl, uploadUrl: $uploadUrl, htmlUrl: $htmlUrl, id: $id, author: $author, nodeId: $nodeId, tagName: $tagName, targetCommitish: $targetCommitish, name: $name, draft: $draft, prerelease: $prerelease, createdAt: $createdAt, publishedAt: $publishedAt, assets: $assets, tarballUrl: $tarballUrl, zipballUrl: $zipballUrl, body: $body)';
}


}

/// @nodoc
abstract mixin class $GithubReleaseJsonCopyWith<$Res>  {
  factory $GithubReleaseJsonCopyWith(GithubReleaseJson value, $Res Function(GithubReleaseJson) _then) = _$GithubReleaseJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "url") String url,@JsonKey(name: "assets_url") String assetsUrl,@JsonKey(name: "upload_url") String uploadUrl,@JsonKey(name: "html_url") String htmlUrl,@JsonKey(name: "id") int id,@JsonKey(name: "author") Author author,@JsonKey(name: "node_id") String nodeId,@JsonKey(name: "tag_name") String tagName,@JsonKey(name: "target_commitish") String targetCommitish,@JsonKey(name: "name") String name,@JsonKey(name: "draft") bool draft,@JsonKey(name: "prerelease") bool prerelease,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "published_at") DateTime publishedAt,@JsonKey(name: "assets") List<Asset> assets,@JsonKey(name: "tarball_url") String tarballUrl,@JsonKey(name: "zipball_url") String zipballUrl,@JsonKey(name: "body") String body
});


$AuthorCopyWith<$Res> get author;

}
/// @nodoc
class _$GithubReleaseJsonCopyWithImpl<$Res>
    implements $GithubReleaseJsonCopyWith<$Res> {
  _$GithubReleaseJsonCopyWithImpl(this._self, this._then);

  final GithubReleaseJson _self;
  final $Res Function(GithubReleaseJson) _then;

/// Create a copy of GithubReleaseJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? assetsUrl = null,Object? uploadUrl = null,Object? htmlUrl = null,Object? id = null,Object? author = null,Object? nodeId = null,Object? tagName = null,Object? targetCommitish = null,Object? name = null,Object? draft = null,Object? prerelease = null,Object? createdAt = null,Object? publishedAt = null,Object? assets = null,Object? tarballUrl = null,Object? zipballUrl = null,Object? body = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,assetsUrl: null == assetsUrl ? _self.assetsUrl : assetsUrl // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as Author,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,tagName: null == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String,targetCommitish: null == targetCommitish ? _self.targetCommitish : targetCommitish // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as bool,prerelease: null == prerelease ? _self.prerelease : prerelease // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,assets: null == assets ? _self.assets : assets // ignore: cast_nullable_to_non_nullable
as List<Asset>,tarballUrl: null == tarballUrl ? _self.tarballUrl : tarballUrl // ignore: cast_nullable_to_non_nullable
as String,zipballUrl: null == zipballUrl ? _self.zipballUrl : zipballUrl // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of GithubReleaseJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorCopyWith<$Res> get author {
  
  return $AuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [GithubReleaseJson].
extension GithubReleaseJsonPatterns on GithubReleaseJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GithubReleaseJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GithubReleaseJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GithubReleaseJson value)  $default,){
final _that = this;
switch (_that) {
case _GithubReleaseJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GithubReleaseJson value)?  $default,){
final _that = this;
switch (_that) {
case _GithubReleaseJson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "url")  String url, @JsonKey(name: "assets_url")  String assetsUrl, @JsonKey(name: "upload_url")  String uploadUrl, @JsonKey(name: "html_url")  String htmlUrl, @JsonKey(name: "id")  int id, @JsonKey(name: "author")  Author author, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "tag_name")  String tagName, @JsonKey(name: "target_commitish")  String targetCommitish, @JsonKey(name: "name")  String name, @JsonKey(name: "draft")  bool draft, @JsonKey(name: "prerelease")  bool prerelease, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "published_at")  DateTime publishedAt, @JsonKey(name: "assets")  List<Asset> assets, @JsonKey(name: "tarball_url")  String tarballUrl, @JsonKey(name: "zipball_url")  String zipballUrl, @JsonKey(name: "body")  String body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GithubReleaseJson() when $default != null:
return $default(_that.url,_that.assetsUrl,_that.uploadUrl,_that.htmlUrl,_that.id,_that.author,_that.nodeId,_that.tagName,_that.targetCommitish,_that.name,_that.draft,_that.prerelease,_that.createdAt,_that.publishedAt,_that.assets,_that.tarballUrl,_that.zipballUrl,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "url")  String url, @JsonKey(name: "assets_url")  String assetsUrl, @JsonKey(name: "upload_url")  String uploadUrl, @JsonKey(name: "html_url")  String htmlUrl, @JsonKey(name: "id")  int id, @JsonKey(name: "author")  Author author, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "tag_name")  String tagName, @JsonKey(name: "target_commitish")  String targetCommitish, @JsonKey(name: "name")  String name, @JsonKey(name: "draft")  bool draft, @JsonKey(name: "prerelease")  bool prerelease, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "published_at")  DateTime publishedAt, @JsonKey(name: "assets")  List<Asset> assets, @JsonKey(name: "tarball_url")  String tarballUrl, @JsonKey(name: "zipball_url")  String zipballUrl, @JsonKey(name: "body")  String body)  $default,) {final _that = this;
switch (_that) {
case _GithubReleaseJson():
return $default(_that.url,_that.assetsUrl,_that.uploadUrl,_that.htmlUrl,_that.id,_that.author,_that.nodeId,_that.tagName,_that.targetCommitish,_that.name,_that.draft,_that.prerelease,_that.createdAt,_that.publishedAt,_that.assets,_that.tarballUrl,_that.zipballUrl,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "url")  String url, @JsonKey(name: "assets_url")  String assetsUrl, @JsonKey(name: "upload_url")  String uploadUrl, @JsonKey(name: "html_url")  String htmlUrl, @JsonKey(name: "id")  int id, @JsonKey(name: "author")  Author author, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "tag_name")  String tagName, @JsonKey(name: "target_commitish")  String targetCommitish, @JsonKey(name: "name")  String name, @JsonKey(name: "draft")  bool draft, @JsonKey(name: "prerelease")  bool prerelease, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "published_at")  DateTime publishedAt, @JsonKey(name: "assets")  List<Asset> assets, @JsonKey(name: "tarball_url")  String tarballUrl, @JsonKey(name: "zipball_url")  String zipballUrl, @JsonKey(name: "body")  String body)?  $default,) {final _that = this;
switch (_that) {
case _GithubReleaseJson() when $default != null:
return $default(_that.url,_that.assetsUrl,_that.uploadUrl,_that.htmlUrl,_that.id,_that.author,_that.nodeId,_that.tagName,_that.targetCommitish,_that.name,_that.draft,_that.prerelease,_that.createdAt,_that.publishedAt,_that.assets,_that.tarballUrl,_that.zipballUrl,_that.body);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GithubReleaseJson implements GithubReleaseJson {
  const _GithubReleaseJson({@JsonKey(name: "url") required this.url, @JsonKey(name: "assets_url") required this.assetsUrl, @JsonKey(name: "upload_url") required this.uploadUrl, @JsonKey(name: "html_url") required this.htmlUrl, @JsonKey(name: "id") required this.id, @JsonKey(name: "author") required this.author, @JsonKey(name: "node_id") required this.nodeId, @JsonKey(name: "tag_name") required this.tagName, @JsonKey(name: "target_commitish") required this.targetCommitish, @JsonKey(name: "name") required this.name, @JsonKey(name: "draft") required this.draft, @JsonKey(name: "prerelease") required this.prerelease, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "published_at") required this.publishedAt, @JsonKey(name: "assets") required final  List<Asset> assets, @JsonKey(name: "tarball_url") required this.tarballUrl, @JsonKey(name: "zipball_url") required this.zipballUrl, @JsonKey(name: "body") required this.body}): _assets = assets;
  factory _GithubReleaseJson.fromJson(Map<String, dynamic> json) => _$GithubReleaseJsonFromJson(json);

@override@JsonKey(name: "url") final  String url;
@override@JsonKey(name: "assets_url") final  String assetsUrl;
@override@JsonKey(name: "upload_url") final  String uploadUrl;
@override@JsonKey(name: "html_url") final  String htmlUrl;
@override@JsonKey(name: "id") final  int id;
@override@JsonKey(name: "author") final  Author author;
@override@JsonKey(name: "node_id") final  String nodeId;
@override@JsonKey(name: "tag_name") final  String tagName;
@override@JsonKey(name: "target_commitish") final  String targetCommitish;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "draft") final  bool draft;
@override@JsonKey(name: "prerelease") final  bool prerelease;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "published_at") final  DateTime publishedAt;
 final  List<Asset> _assets;
@override@JsonKey(name: "assets") List<Asset> get assets {
  if (_assets is EqualUnmodifiableListView) return _assets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assets);
}

@override@JsonKey(name: "tarball_url") final  String tarballUrl;
@override@JsonKey(name: "zipball_url") final  String zipballUrl;
@override@JsonKey(name: "body") final  String body;

/// Create a copy of GithubReleaseJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GithubReleaseJsonCopyWith<_GithubReleaseJson> get copyWith => __$GithubReleaseJsonCopyWithImpl<_GithubReleaseJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GithubReleaseJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GithubReleaseJson&&(identical(other.url, url) || other.url == url)&&(identical(other.assetsUrl, assetsUrl) || other.assetsUrl == assetsUrl)&&(identical(other.uploadUrl, uploadUrl) || other.uploadUrl == uploadUrl)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.author, author) || other.author == author)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.targetCommitish, targetCommitish) || other.targetCommitish == targetCommitish)&&(identical(other.name, name) || other.name == name)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.prerelease, prerelease) || other.prerelease == prerelease)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&const DeepCollectionEquality().equals(other._assets, _assets)&&(identical(other.tarballUrl, tarballUrl) || other.tarballUrl == tarballUrl)&&(identical(other.zipballUrl, zipballUrl) || other.zipballUrl == zipballUrl)&&(identical(other.body, body) || other.body == body));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,assetsUrl,uploadUrl,htmlUrl,id,author,nodeId,tagName,targetCommitish,name,draft,prerelease,createdAt,publishedAt,const DeepCollectionEquality().hash(_assets),tarballUrl,zipballUrl,body);

@override
String toString() {
  return 'GithubReleaseJson(url: $url, assetsUrl: $assetsUrl, uploadUrl: $uploadUrl, htmlUrl: $htmlUrl, id: $id, author: $author, nodeId: $nodeId, tagName: $tagName, targetCommitish: $targetCommitish, name: $name, draft: $draft, prerelease: $prerelease, createdAt: $createdAt, publishedAt: $publishedAt, assets: $assets, tarballUrl: $tarballUrl, zipballUrl: $zipballUrl, body: $body)';
}


}

/// @nodoc
abstract mixin class _$GithubReleaseJsonCopyWith<$Res> implements $GithubReleaseJsonCopyWith<$Res> {
  factory _$GithubReleaseJsonCopyWith(_GithubReleaseJson value, $Res Function(_GithubReleaseJson) _then) = __$GithubReleaseJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "url") String url,@JsonKey(name: "assets_url") String assetsUrl,@JsonKey(name: "upload_url") String uploadUrl,@JsonKey(name: "html_url") String htmlUrl,@JsonKey(name: "id") int id,@JsonKey(name: "author") Author author,@JsonKey(name: "node_id") String nodeId,@JsonKey(name: "tag_name") String tagName,@JsonKey(name: "target_commitish") String targetCommitish,@JsonKey(name: "name") String name,@JsonKey(name: "draft") bool draft,@JsonKey(name: "prerelease") bool prerelease,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "published_at") DateTime publishedAt,@JsonKey(name: "assets") List<Asset> assets,@JsonKey(name: "tarball_url") String tarballUrl,@JsonKey(name: "zipball_url") String zipballUrl,@JsonKey(name: "body") String body
});


@override $AuthorCopyWith<$Res> get author;

}
/// @nodoc
class __$GithubReleaseJsonCopyWithImpl<$Res>
    implements _$GithubReleaseJsonCopyWith<$Res> {
  __$GithubReleaseJsonCopyWithImpl(this._self, this._then);

  final _GithubReleaseJson _self;
  final $Res Function(_GithubReleaseJson) _then;

/// Create a copy of GithubReleaseJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? assetsUrl = null,Object? uploadUrl = null,Object? htmlUrl = null,Object? id = null,Object? author = null,Object? nodeId = null,Object? tagName = null,Object? targetCommitish = null,Object? name = null,Object? draft = null,Object? prerelease = null,Object? createdAt = null,Object? publishedAt = null,Object? assets = null,Object? tarballUrl = null,Object? zipballUrl = null,Object? body = null,}) {
  return _then(_GithubReleaseJson(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,assetsUrl: null == assetsUrl ? _self.assetsUrl : assetsUrl // ignore: cast_nullable_to_non_nullable
as String,uploadUrl: null == uploadUrl ? _self.uploadUrl : uploadUrl // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as Author,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,tagName: null == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String,targetCommitish: null == targetCommitish ? _self.targetCommitish : targetCommitish // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as bool,prerelease: null == prerelease ? _self.prerelease : prerelease // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime,assets: null == assets ? _self._assets : assets // ignore: cast_nullable_to_non_nullable
as List<Asset>,tarballUrl: null == tarballUrl ? _self.tarballUrl : tarballUrl // ignore: cast_nullable_to_non_nullable
as String,zipballUrl: null == zipballUrl ? _self.zipballUrl : zipballUrl // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of GithubReleaseJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorCopyWith<$Res> get author {
  
  return $AuthorCopyWith<$Res>(_self.author, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// @nodoc
mixin _$Asset {

@JsonKey(name: "url") String get url;@JsonKey(name: "id") int get id;@JsonKey(name: "node_id") String get nodeId;@JsonKey(name: "name") String get name;@JsonKey(name: "label") dynamic get label;@JsonKey(name: "uploader") Author get uploader;@JsonKey(name: "content_type") String get contentType;@JsonKey(name: "state") String get state;@JsonKey(name: "size") int get size;@JsonKey(name: "download_count") int get downloadCount;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "updated_at") DateTime get updatedAt;@JsonKey(name: "browser_download_url") String get browserDownloadUrl;
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssetCopyWith<Asset> get copyWith => _$AssetCopyWithImpl<Asset>(this as Asset, _$identity);

  /// Serializes this Asset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Asset&&(identical(other.url, url) || other.url == url)&&(identical(other.id, id) || other.id == id)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.label, label)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.state, state) || other.state == state)&&(identical(other.size, size) || other.size == size)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.browserDownloadUrl, browserDownloadUrl) || other.browserDownloadUrl == browserDownloadUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,id,nodeId,name,const DeepCollectionEquality().hash(label),uploader,contentType,state,size,downloadCount,createdAt,updatedAt,browserDownloadUrl);

@override
String toString() {
  return 'Asset(url: $url, id: $id, nodeId: $nodeId, name: $name, label: $label, uploader: $uploader, contentType: $contentType, state: $state, size: $size, downloadCount: $downloadCount, createdAt: $createdAt, updatedAt: $updatedAt, browserDownloadUrl: $browserDownloadUrl)';
}


}

/// @nodoc
abstract mixin class $AssetCopyWith<$Res>  {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) _then) = _$AssetCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "url") String url,@JsonKey(name: "id") int id,@JsonKey(name: "node_id") String nodeId,@JsonKey(name: "name") String name,@JsonKey(name: "label") dynamic label,@JsonKey(name: "uploader") Author uploader,@JsonKey(name: "content_type") String contentType,@JsonKey(name: "state") String state,@JsonKey(name: "size") int size,@JsonKey(name: "download_count") int downloadCount,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "browser_download_url") String browserDownloadUrl
});


$AuthorCopyWith<$Res> get uploader;

}
/// @nodoc
class _$AssetCopyWithImpl<$Res>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._self, this._then);

  final Asset _self;
  final $Res Function(Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? id = null,Object? nodeId = null,Object? name = null,Object? label = freezed,Object? uploader = null,Object? contentType = null,Object? state = null,Object? size = null,Object? downloadCount = null,Object? createdAt = null,Object? updatedAt = null,Object? browserDownloadUrl = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as dynamic,uploader: null == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as Author,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,downloadCount: null == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,browserDownloadUrl: null == browserDownloadUrl ? _self.browserDownloadUrl : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorCopyWith<$Res> get uploader {
  
  return $AuthorCopyWith<$Res>(_self.uploader, (value) {
    return _then(_self.copyWith(uploader: value));
  });
}
}


/// Adds pattern-matching-related methods to [Asset].
extension AssetPatterns on Asset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Asset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Asset value)  $default,){
final _that = this;
switch (_that) {
case _Asset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Asset value)?  $default,){
final _that = this;
switch (_that) {
case _Asset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "url")  String url, @JsonKey(name: "id")  int id, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "name")  String name, @JsonKey(name: "label")  dynamic label, @JsonKey(name: "uploader")  Author uploader, @JsonKey(name: "content_type")  String contentType, @JsonKey(name: "state")  String state, @JsonKey(name: "size")  int size, @JsonKey(name: "download_count")  int downloadCount, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "browser_download_url")  String browserDownloadUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.url,_that.id,_that.nodeId,_that.name,_that.label,_that.uploader,_that.contentType,_that.state,_that.size,_that.downloadCount,_that.createdAt,_that.updatedAt,_that.browserDownloadUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "url")  String url, @JsonKey(name: "id")  int id, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "name")  String name, @JsonKey(name: "label")  dynamic label, @JsonKey(name: "uploader")  Author uploader, @JsonKey(name: "content_type")  String contentType, @JsonKey(name: "state")  String state, @JsonKey(name: "size")  int size, @JsonKey(name: "download_count")  int downloadCount, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "browser_download_url")  String browserDownloadUrl)  $default,) {final _that = this;
switch (_that) {
case _Asset():
return $default(_that.url,_that.id,_that.nodeId,_that.name,_that.label,_that.uploader,_that.contentType,_that.state,_that.size,_that.downloadCount,_that.createdAt,_that.updatedAt,_that.browserDownloadUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "url")  String url, @JsonKey(name: "id")  int id, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "name")  String name, @JsonKey(name: "label")  dynamic label, @JsonKey(name: "uploader")  Author uploader, @JsonKey(name: "content_type")  String contentType, @JsonKey(name: "state")  String state, @JsonKey(name: "size")  int size, @JsonKey(name: "download_count")  int downloadCount, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "updated_at")  DateTime updatedAt, @JsonKey(name: "browser_download_url")  String browserDownloadUrl)?  $default,) {final _that = this;
switch (_that) {
case _Asset() when $default != null:
return $default(_that.url,_that.id,_that.nodeId,_that.name,_that.label,_that.uploader,_that.contentType,_that.state,_that.size,_that.downloadCount,_that.createdAt,_that.updatedAt,_that.browserDownloadUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Asset implements Asset {
  const _Asset({@JsonKey(name: "url") required this.url, @JsonKey(name: "id") required this.id, @JsonKey(name: "node_id") required this.nodeId, @JsonKey(name: "name") required this.name, @JsonKey(name: "label") required this.label, @JsonKey(name: "uploader") required this.uploader, @JsonKey(name: "content_type") required this.contentType, @JsonKey(name: "state") required this.state, @JsonKey(name: "size") required this.size, @JsonKey(name: "download_count") required this.downloadCount, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "updated_at") required this.updatedAt, @JsonKey(name: "browser_download_url") required this.browserDownloadUrl});
  factory _Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);

@override@JsonKey(name: "url") final  String url;
@override@JsonKey(name: "id") final  int id;
@override@JsonKey(name: "node_id") final  String nodeId;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "label") final  dynamic label;
@override@JsonKey(name: "uploader") final  Author uploader;
@override@JsonKey(name: "content_type") final  String contentType;
@override@JsonKey(name: "state") final  String state;
@override@JsonKey(name: "size") final  int size;
@override@JsonKey(name: "download_count") final  int downloadCount;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "updated_at") final  DateTime updatedAt;
@override@JsonKey(name: "browser_download_url") final  String browserDownloadUrl;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssetCopyWith<_Asset> get copyWith => __$AssetCopyWithImpl<_Asset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Asset&&(identical(other.url, url) || other.url == url)&&(identical(other.id, id) || other.id == id)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.label, label)&&(identical(other.uploader, uploader) || other.uploader == uploader)&&(identical(other.contentType, contentType) || other.contentType == contentType)&&(identical(other.state, state) || other.state == state)&&(identical(other.size, size) || other.size == size)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.browserDownloadUrl, browserDownloadUrl) || other.browserDownloadUrl == browserDownloadUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,id,nodeId,name,const DeepCollectionEquality().hash(label),uploader,contentType,state,size,downloadCount,createdAt,updatedAt,browserDownloadUrl);

@override
String toString() {
  return 'Asset(url: $url, id: $id, nodeId: $nodeId, name: $name, label: $label, uploader: $uploader, contentType: $contentType, state: $state, size: $size, downloadCount: $downloadCount, createdAt: $createdAt, updatedAt: $updatedAt, browserDownloadUrl: $browserDownloadUrl)';
}


}

/// @nodoc
abstract mixin class _$AssetCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$AssetCopyWith(_Asset value, $Res Function(_Asset) _then) = __$AssetCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "url") String url,@JsonKey(name: "id") int id,@JsonKey(name: "node_id") String nodeId,@JsonKey(name: "name") String name,@JsonKey(name: "label") dynamic label,@JsonKey(name: "uploader") Author uploader,@JsonKey(name: "content_type") String contentType,@JsonKey(name: "state") String state,@JsonKey(name: "size") int size,@JsonKey(name: "download_count") int downloadCount,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "browser_download_url") String browserDownloadUrl
});


@override $AuthorCopyWith<$Res> get uploader;

}
/// @nodoc
class __$AssetCopyWithImpl<$Res>
    implements _$AssetCopyWith<$Res> {
  __$AssetCopyWithImpl(this._self, this._then);

  final _Asset _self;
  final $Res Function(_Asset) _then;

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? id = null,Object? nodeId = null,Object? name = null,Object? label = freezed,Object? uploader = null,Object? contentType = null,Object? state = null,Object? size = null,Object? downloadCount = null,Object? createdAt = null,Object? updatedAt = null,Object? browserDownloadUrl = null,}) {
  return _then(_Asset(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as dynamic,uploader: null == uploader ? _self.uploader : uploader // ignore: cast_nullable_to_non_nullable
as Author,contentType: null == contentType ? _self.contentType : contentType // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,downloadCount: null == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,browserDownloadUrl: null == browserDownloadUrl ? _self.browserDownloadUrl : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Asset
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthorCopyWith<$Res> get uploader {
  
  return $AuthorCopyWith<$Res>(_self.uploader, (value) {
    return _then(_self.copyWith(uploader: value));
  });
}
}


/// @nodoc
mixin _$Author {

@JsonKey(name: "login") String get login;@JsonKey(name: "id") int get id;@JsonKey(name: "node_id") String get nodeId;@JsonKey(name: "avatar_url") String get avatarUrl;@JsonKey(name: "gravatar_id") String get gravatarId;@JsonKey(name: "url") String get url;@JsonKey(name: "html_url") String get htmlUrl;@JsonKey(name: "followers_url") String get followersUrl;@JsonKey(name: "following_url") String get followingUrl;@JsonKey(name: "gists_url") String get gistsUrl;@JsonKey(name: "starred_url") String get starredUrl;@JsonKey(name: "subscriptions_url") String get subscriptionsUrl;@JsonKey(name: "organizations_url") String get organizationsUrl;@JsonKey(name: "repos_url") String get reposUrl;@JsonKey(name: "events_url") String get eventsUrl;@JsonKey(name: "received_events_url") String get receivedEventsUrl;@JsonKey(name: "type") String get type;@JsonKey(name: "user_view_type") String get userViewType;@JsonKey(name: "site_admin") bool get siteAdmin;
/// Create a copy of Author
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthorCopyWith<Author> get copyWith => _$AuthorCopyWithImpl<Author>(this as Author, _$identity);

  /// Serializes this Author to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Author&&(identical(other.login, login) || other.login == login)&&(identical(other.id, id) || other.id == id)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.gravatarId, gravatarId) || other.gravatarId == gravatarId)&&(identical(other.url, url) || other.url == url)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.followersUrl, followersUrl) || other.followersUrl == followersUrl)&&(identical(other.followingUrl, followingUrl) || other.followingUrl == followingUrl)&&(identical(other.gistsUrl, gistsUrl) || other.gistsUrl == gistsUrl)&&(identical(other.starredUrl, starredUrl) || other.starredUrl == starredUrl)&&(identical(other.subscriptionsUrl, subscriptionsUrl) || other.subscriptionsUrl == subscriptionsUrl)&&(identical(other.organizationsUrl, organizationsUrl) || other.organizationsUrl == organizationsUrl)&&(identical(other.reposUrl, reposUrl) || other.reposUrl == reposUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.receivedEventsUrl, receivedEventsUrl) || other.receivedEventsUrl == receivedEventsUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.userViewType, userViewType) || other.userViewType == userViewType)&&(identical(other.siteAdmin, siteAdmin) || other.siteAdmin == siteAdmin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,login,id,nodeId,avatarUrl,gravatarId,url,htmlUrl,followersUrl,followingUrl,gistsUrl,starredUrl,subscriptionsUrl,organizationsUrl,reposUrl,eventsUrl,receivedEventsUrl,type,userViewType,siteAdmin]);

@override
String toString() {
  return 'Author(login: $login, id: $id, nodeId: $nodeId, avatarUrl: $avatarUrl, gravatarId: $gravatarId, url: $url, htmlUrl: $htmlUrl, followersUrl: $followersUrl, followingUrl: $followingUrl, gistsUrl: $gistsUrl, starredUrl: $starredUrl, subscriptionsUrl: $subscriptionsUrl, organizationsUrl: $organizationsUrl, reposUrl: $reposUrl, eventsUrl: $eventsUrl, receivedEventsUrl: $receivedEventsUrl, type: $type, userViewType: $userViewType, siteAdmin: $siteAdmin)';
}


}

/// @nodoc
abstract mixin class $AuthorCopyWith<$Res>  {
  factory $AuthorCopyWith(Author value, $Res Function(Author) _then) = _$AuthorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "login") String login,@JsonKey(name: "id") int id,@JsonKey(name: "node_id") String nodeId,@JsonKey(name: "avatar_url") String avatarUrl,@JsonKey(name: "gravatar_id") String gravatarId,@JsonKey(name: "url") String url,@JsonKey(name: "html_url") String htmlUrl,@JsonKey(name: "followers_url") String followersUrl,@JsonKey(name: "following_url") String followingUrl,@JsonKey(name: "gists_url") String gistsUrl,@JsonKey(name: "starred_url") String starredUrl,@JsonKey(name: "subscriptions_url") String subscriptionsUrl,@JsonKey(name: "organizations_url") String organizationsUrl,@JsonKey(name: "repos_url") String reposUrl,@JsonKey(name: "events_url") String eventsUrl,@JsonKey(name: "received_events_url") String receivedEventsUrl,@JsonKey(name: "type") String type,@JsonKey(name: "user_view_type") String userViewType,@JsonKey(name: "site_admin") bool siteAdmin
});




}
/// @nodoc
class _$AuthorCopyWithImpl<$Res>
    implements $AuthorCopyWith<$Res> {
  _$AuthorCopyWithImpl(this._self, this._then);

  final Author _self;
  final $Res Function(Author) _then;

/// Create a copy of Author
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? login = null,Object? id = null,Object? nodeId = null,Object? avatarUrl = null,Object? gravatarId = null,Object? url = null,Object? htmlUrl = null,Object? followersUrl = null,Object? followingUrl = null,Object? gistsUrl = null,Object? starredUrl = null,Object? subscriptionsUrl = null,Object? organizationsUrl = null,Object? reposUrl = null,Object? eventsUrl = null,Object? receivedEventsUrl = null,Object? type = null,Object? userViewType = null,Object? siteAdmin = null,}) {
  return _then(_self.copyWith(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,gravatarId: null == gravatarId ? _self.gravatarId : gravatarId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,followersUrl: null == followersUrl ? _self.followersUrl : followersUrl // ignore: cast_nullable_to_non_nullable
as String,followingUrl: null == followingUrl ? _self.followingUrl : followingUrl // ignore: cast_nullable_to_non_nullable
as String,gistsUrl: null == gistsUrl ? _self.gistsUrl : gistsUrl // ignore: cast_nullable_to_non_nullable
as String,starredUrl: null == starredUrl ? _self.starredUrl : starredUrl // ignore: cast_nullable_to_non_nullable
as String,subscriptionsUrl: null == subscriptionsUrl ? _self.subscriptionsUrl : subscriptionsUrl // ignore: cast_nullable_to_non_nullable
as String,organizationsUrl: null == organizationsUrl ? _self.organizationsUrl : organizationsUrl // ignore: cast_nullable_to_non_nullable
as String,reposUrl: null == reposUrl ? _self.reposUrl : reposUrl // ignore: cast_nullable_to_non_nullable
as String,eventsUrl: null == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String,receivedEventsUrl: null == receivedEventsUrl ? _self.receivedEventsUrl : receivedEventsUrl // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,userViewType: null == userViewType ? _self.userViewType : userViewType // ignore: cast_nullable_to_non_nullable
as String,siteAdmin: null == siteAdmin ? _self.siteAdmin : siteAdmin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Author].
extension AuthorPatterns on Author {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Author value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Author() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Author value)  $default,){
final _that = this;
switch (_that) {
case _Author():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Author value)?  $default,){
final _that = this;
switch (_that) {
case _Author() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "login")  String login, @JsonKey(name: "id")  int id, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "avatar_url")  String avatarUrl, @JsonKey(name: "gravatar_id")  String gravatarId, @JsonKey(name: "url")  String url, @JsonKey(name: "html_url")  String htmlUrl, @JsonKey(name: "followers_url")  String followersUrl, @JsonKey(name: "following_url")  String followingUrl, @JsonKey(name: "gists_url")  String gistsUrl, @JsonKey(name: "starred_url")  String starredUrl, @JsonKey(name: "subscriptions_url")  String subscriptionsUrl, @JsonKey(name: "organizations_url")  String organizationsUrl, @JsonKey(name: "repos_url")  String reposUrl, @JsonKey(name: "events_url")  String eventsUrl, @JsonKey(name: "received_events_url")  String receivedEventsUrl, @JsonKey(name: "type")  String type, @JsonKey(name: "user_view_type")  String userViewType, @JsonKey(name: "site_admin")  bool siteAdmin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Author() when $default != null:
return $default(_that.login,_that.id,_that.nodeId,_that.avatarUrl,_that.gravatarId,_that.url,_that.htmlUrl,_that.followersUrl,_that.followingUrl,_that.gistsUrl,_that.starredUrl,_that.subscriptionsUrl,_that.organizationsUrl,_that.reposUrl,_that.eventsUrl,_that.receivedEventsUrl,_that.type,_that.userViewType,_that.siteAdmin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "login")  String login, @JsonKey(name: "id")  int id, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "avatar_url")  String avatarUrl, @JsonKey(name: "gravatar_id")  String gravatarId, @JsonKey(name: "url")  String url, @JsonKey(name: "html_url")  String htmlUrl, @JsonKey(name: "followers_url")  String followersUrl, @JsonKey(name: "following_url")  String followingUrl, @JsonKey(name: "gists_url")  String gistsUrl, @JsonKey(name: "starred_url")  String starredUrl, @JsonKey(name: "subscriptions_url")  String subscriptionsUrl, @JsonKey(name: "organizations_url")  String organizationsUrl, @JsonKey(name: "repos_url")  String reposUrl, @JsonKey(name: "events_url")  String eventsUrl, @JsonKey(name: "received_events_url")  String receivedEventsUrl, @JsonKey(name: "type")  String type, @JsonKey(name: "user_view_type")  String userViewType, @JsonKey(name: "site_admin")  bool siteAdmin)  $default,) {final _that = this;
switch (_that) {
case _Author():
return $default(_that.login,_that.id,_that.nodeId,_that.avatarUrl,_that.gravatarId,_that.url,_that.htmlUrl,_that.followersUrl,_that.followingUrl,_that.gistsUrl,_that.starredUrl,_that.subscriptionsUrl,_that.organizationsUrl,_that.reposUrl,_that.eventsUrl,_that.receivedEventsUrl,_that.type,_that.userViewType,_that.siteAdmin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "login")  String login, @JsonKey(name: "id")  int id, @JsonKey(name: "node_id")  String nodeId, @JsonKey(name: "avatar_url")  String avatarUrl, @JsonKey(name: "gravatar_id")  String gravatarId, @JsonKey(name: "url")  String url, @JsonKey(name: "html_url")  String htmlUrl, @JsonKey(name: "followers_url")  String followersUrl, @JsonKey(name: "following_url")  String followingUrl, @JsonKey(name: "gists_url")  String gistsUrl, @JsonKey(name: "starred_url")  String starredUrl, @JsonKey(name: "subscriptions_url")  String subscriptionsUrl, @JsonKey(name: "organizations_url")  String organizationsUrl, @JsonKey(name: "repos_url")  String reposUrl, @JsonKey(name: "events_url")  String eventsUrl, @JsonKey(name: "received_events_url")  String receivedEventsUrl, @JsonKey(name: "type")  String type, @JsonKey(name: "user_view_type")  String userViewType, @JsonKey(name: "site_admin")  bool siteAdmin)?  $default,) {final _that = this;
switch (_that) {
case _Author() when $default != null:
return $default(_that.login,_that.id,_that.nodeId,_that.avatarUrl,_that.gravatarId,_that.url,_that.htmlUrl,_that.followersUrl,_that.followingUrl,_that.gistsUrl,_that.starredUrl,_that.subscriptionsUrl,_that.organizationsUrl,_that.reposUrl,_that.eventsUrl,_that.receivedEventsUrl,_that.type,_that.userViewType,_that.siteAdmin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Author implements Author {
  const _Author({@JsonKey(name: "login") required this.login, @JsonKey(name: "id") required this.id, @JsonKey(name: "node_id") required this.nodeId, @JsonKey(name: "avatar_url") required this.avatarUrl, @JsonKey(name: "gravatar_id") required this.gravatarId, @JsonKey(name: "url") required this.url, @JsonKey(name: "html_url") required this.htmlUrl, @JsonKey(name: "followers_url") required this.followersUrl, @JsonKey(name: "following_url") required this.followingUrl, @JsonKey(name: "gists_url") required this.gistsUrl, @JsonKey(name: "starred_url") required this.starredUrl, @JsonKey(name: "subscriptions_url") required this.subscriptionsUrl, @JsonKey(name: "organizations_url") required this.organizationsUrl, @JsonKey(name: "repos_url") required this.reposUrl, @JsonKey(name: "events_url") required this.eventsUrl, @JsonKey(name: "received_events_url") required this.receivedEventsUrl, @JsonKey(name: "type") required this.type, @JsonKey(name: "user_view_type") required this.userViewType, @JsonKey(name: "site_admin") required this.siteAdmin});
  factory _Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);

@override@JsonKey(name: "login") final  String login;
@override@JsonKey(name: "id") final  int id;
@override@JsonKey(name: "node_id") final  String nodeId;
@override@JsonKey(name: "avatar_url") final  String avatarUrl;
@override@JsonKey(name: "gravatar_id") final  String gravatarId;
@override@JsonKey(name: "url") final  String url;
@override@JsonKey(name: "html_url") final  String htmlUrl;
@override@JsonKey(name: "followers_url") final  String followersUrl;
@override@JsonKey(name: "following_url") final  String followingUrl;
@override@JsonKey(name: "gists_url") final  String gistsUrl;
@override@JsonKey(name: "starred_url") final  String starredUrl;
@override@JsonKey(name: "subscriptions_url") final  String subscriptionsUrl;
@override@JsonKey(name: "organizations_url") final  String organizationsUrl;
@override@JsonKey(name: "repos_url") final  String reposUrl;
@override@JsonKey(name: "events_url") final  String eventsUrl;
@override@JsonKey(name: "received_events_url") final  String receivedEventsUrl;
@override@JsonKey(name: "type") final  String type;
@override@JsonKey(name: "user_view_type") final  String userViewType;
@override@JsonKey(name: "site_admin") final  bool siteAdmin;

/// Create a copy of Author
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthorCopyWith<_Author> get copyWith => __$AuthorCopyWithImpl<_Author>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Author&&(identical(other.login, login) || other.login == login)&&(identical(other.id, id) || other.id == id)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.gravatarId, gravatarId) || other.gravatarId == gravatarId)&&(identical(other.url, url) || other.url == url)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.followersUrl, followersUrl) || other.followersUrl == followersUrl)&&(identical(other.followingUrl, followingUrl) || other.followingUrl == followingUrl)&&(identical(other.gistsUrl, gistsUrl) || other.gistsUrl == gistsUrl)&&(identical(other.starredUrl, starredUrl) || other.starredUrl == starredUrl)&&(identical(other.subscriptionsUrl, subscriptionsUrl) || other.subscriptionsUrl == subscriptionsUrl)&&(identical(other.organizationsUrl, organizationsUrl) || other.organizationsUrl == organizationsUrl)&&(identical(other.reposUrl, reposUrl) || other.reposUrl == reposUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.receivedEventsUrl, receivedEventsUrl) || other.receivedEventsUrl == receivedEventsUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.userViewType, userViewType) || other.userViewType == userViewType)&&(identical(other.siteAdmin, siteAdmin) || other.siteAdmin == siteAdmin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,login,id,nodeId,avatarUrl,gravatarId,url,htmlUrl,followersUrl,followingUrl,gistsUrl,starredUrl,subscriptionsUrl,organizationsUrl,reposUrl,eventsUrl,receivedEventsUrl,type,userViewType,siteAdmin]);

@override
String toString() {
  return 'Author(login: $login, id: $id, nodeId: $nodeId, avatarUrl: $avatarUrl, gravatarId: $gravatarId, url: $url, htmlUrl: $htmlUrl, followersUrl: $followersUrl, followingUrl: $followingUrl, gistsUrl: $gistsUrl, starredUrl: $starredUrl, subscriptionsUrl: $subscriptionsUrl, organizationsUrl: $organizationsUrl, reposUrl: $reposUrl, eventsUrl: $eventsUrl, receivedEventsUrl: $receivedEventsUrl, type: $type, userViewType: $userViewType, siteAdmin: $siteAdmin)';
}


}

/// @nodoc
abstract mixin class _$AuthorCopyWith<$Res> implements $AuthorCopyWith<$Res> {
  factory _$AuthorCopyWith(_Author value, $Res Function(_Author) _then) = __$AuthorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "login") String login,@JsonKey(name: "id") int id,@JsonKey(name: "node_id") String nodeId,@JsonKey(name: "avatar_url") String avatarUrl,@JsonKey(name: "gravatar_id") String gravatarId,@JsonKey(name: "url") String url,@JsonKey(name: "html_url") String htmlUrl,@JsonKey(name: "followers_url") String followersUrl,@JsonKey(name: "following_url") String followingUrl,@JsonKey(name: "gists_url") String gistsUrl,@JsonKey(name: "starred_url") String starredUrl,@JsonKey(name: "subscriptions_url") String subscriptionsUrl,@JsonKey(name: "organizations_url") String organizationsUrl,@JsonKey(name: "repos_url") String reposUrl,@JsonKey(name: "events_url") String eventsUrl,@JsonKey(name: "received_events_url") String receivedEventsUrl,@JsonKey(name: "type") String type,@JsonKey(name: "user_view_type") String userViewType,@JsonKey(name: "site_admin") bool siteAdmin
});




}
/// @nodoc
class __$AuthorCopyWithImpl<$Res>
    implements _$AuthorCopyWith<$Res> {
  __$AuthorCopyWithImpl(this._self, this._then);

  final _Author _self;
  final $Res Function(_Author) _then;

/// Create a copy of Author
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? login = null,Object? id = null,Object? nodeId = null,Object? avatarUrl = null,Object? gravatarId = null,Object? url = null,Object? htmlUrl = null,Object? followersUrl = null,Object? followingUrl = null,Object? gistsUrl = null,Object? starredUrl = null,Object? subscriptionsUrl = null,Object? organizationsUrl = null,Object? reposUrl = null,Object? eventsUrl = null,Object? receivedEventsUrl = null,Object? type = null,Object? userViewType = null,Object? siteAdmin = null,}) {
  return _then(_Author(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,gravatarId: null == gravatarId ? _self.gravatarId : gravatarId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,followersUrl: null == followersUrl ? _self.followersUrl : followersUrl // ignore: cast_nullable_to_non_nullable
as String,followingUrl: null == followingUrl ? _self.followingUrl : followingUrl // ignore: cast_nullable_to_non_nullable
as String,gistsUrl: null == gistsUrl ? _self.gistsUrl : gistsUrl // ignore: cast_nullable_to_non_nullable
as String,starredUrl: null == starredUrl ? _self.starredUrl : starredUrl // ignore: cast_nullable_to_non_nullable
as String,subscriptionsUrl: null == subscriptionsUrl ? _self.subscriptionsUrl : subscriptionsUrl // ignore: cast_nullable_to_non_nullable
as String,organizationsUrl: null == organizationsUrl ? _self.organizationsUrl : organizationsUrl // ignore: cast_nullable_to_non_nullable
as String,reposUrl: null == reposUrl ? _self.reposUrl : reposUrl // ignore: cast_nullable_to_non_nullable
as String,eventsUrl: null == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String,receivedEventsUrl: null == receivedEventsUrl ? _self.receivedEventsUrl : receivedEventsUrl // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,userViewType: null == userViewType ? _self.userViewType : userViewType // ignore: cast_nullable_to_non_nullable
as String,siteAdmin: null == siteAdmin ? _self.siteAdmin : siteAdmin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
