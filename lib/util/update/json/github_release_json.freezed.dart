// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_release_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GithubReleaseJson _$GithubReleaseJsonFromJson(Map<String, dynamic> json) {
  return _GithubReleaseJson.fromJson(json);
}

/// @nodoc
mixin _$GithubReleaseJson {
  @JsonKey(name: "url")
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: "assets_url")
  String get assetsUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "upload_url")
  String get uploadUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "html_url")
  String get htmlUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "id")
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: "author")
  Author get author => throw _privateConstructorUsedError;
  @JsonKey(name: "node_id")
  String get nodeId => throw _privateConstructorUsedError;
  @JsonKey(name: "tag_name")
  String get tagName => throw _privateConstructorUsedError;
  @JsonKey(name: "target_commitish")
  String get targetCommitish => throw _privateConstructorUsedError;
  @JsonKey(name: "name")
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: "draft")
  bool get draft => throw _privateConstructorUsedError;
  @JsonKey(name: "prerelease")
  bool get prerelease => throw _privateConstructorUsedError;
  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: "published_at")
  DateTime get publishedAt => throw _privateConstructorUsedError;
  @JsonKey(name: "assets")
  List<Asset> get assets => throw _privateConstructorUsedError;
  @JsonKey(name: "tarball_url")
  String get tarballUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "zipball_url")
  String get zipballUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "body")
  String get body => throw _privateConstructorUsedError;

  /// Serializes this GithubReleaseJson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GithubReleaseJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GithubReleaseJsonCopyWith<GithubReleaseJson> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GithubReleaseJsonCopyWith<$Res> {
  factory $GithubReleaseJsonCopyWith(
    GithubReleaseJson value,
    $Res Function(GithubReleaseJson) then,
  ) = _$GithubReleaseJsonCopyWithImpl<$Res, GithubReleaseJson>;
  @useResult
  $Res call({
    @JsonKey(name: "url") String url,
    @JsonKey(name: "assets_url") String assetsUrl,
    @JsonKey(name: "upload_url") String uploadUrl,
    @JsonKey(name: "html_url") String htmlUrl,
    @JsonKey(name: "id") int id,
    @JsonKey(name: "author") Author author,
    @JsonKey(name: "node_id") String nodeId,
    @JsonKey(name: "tag_name") String tagName,
    @JsonKey(name: "target_commitish") String targetCommitish,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "draft") bool draft,
    @JsonKey(name: "prerelease") bool prerelease,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "published_at") DateTime publishedAt,
    @JsonKey(name: "assets") List<Asset> assets,
    @JsonKey(name: "tarball_url") String tarballUrl,
    @JsonKey(name: "zipball_url") String zipballUrl,
    @JsonKey(name: "body") String body,
  });

  $AuthorCopyWith<$Res> get author;
}

/// @nodoc
class _$GithubReleaseJsonCopyWithImpl<$Res, $Val extends GithubReleaseJson>
    implements $GithubReleaseJsonCopyWith<$Res> {
  _$GithubReleaseJsonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GithubReleaseJson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? assetsUrl = null,
    Object? uploadUrl = null,
    Object? htmlUrl = null,
    Object? id = null,
    Object? author = null,
    Object? nodeId = null,
    Object? tagName = null,
    Object? targetCommitish = null,
    Object? name = null,
    Object? draft = null,
    Object? prerelease = null,
    Object? createdAt = null,
    Object? publishedAt = null,
    Object? assets = null,
    Object? tarballUrl = null,
    Object? zipballUrl = null,
    Object? body = null,
  }) {
    return _then(
      _value.copyWith(
            url:
                null == url
                    ? _value.url
                    : url // ignore: cast_nullable_to_non_nullable
                        as String,
            assetsUrl:
                null == assetsUrl
                    ? _value.assetsUrl
                    : assetsUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            uploadUrl:
                null == uploadUrl
                    ? _value.uploadUrl
                    : uploadUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            htmlUrl:
                null == htmlUrl
                    ? _value.htmlUrl
                    : htmlUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int,
            author:
                null == author
                    ? _value.author
                    : author // ignore: cast_nullable_to_non_nullable
                        as Author,
            nodeId:
                null == nodeId
                    ? _value.nodeId
                    : nodeId // ignore: cast_nullable_to_non_nullable
                        as String,
            tagName:
                null == tagName
                    ? _value.tagName
                    : tagName // ignore: cast_nullable_to_non_nullable
                        as String,
            targetCommitish:
                null == targetCommitish
                    ? _value.targetCommitish
                    : targetCommitish // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            draft:
                null == draft
                    ? _value.draft
                    : draft // ignore: cast_nullable_to_non_nullable
                        as bool,
            prerelease:
                null == prerelease
                    ? _value.prerelease
                    : prerelease // ignore: cast_nullable_to_non_nullable
                        as bool,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            publishedAt:
                null == publishedAt
                    ? _value.publishedAt
                    : publishedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            assets:
                null == assets
                    ? _value.assets
                    : assets // ignore: cast_nullable_to_non_nullable
                        as List<Asset>,
            tarballUrl:
                null == tarballUrl
                    ? _value.tarballUrl
                    : tarballUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            zipballUrl:
                null == zipballUrl
                    ? _value.zipballUrl
                    : zipballUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            body:
                null == body
                    ? _value.body
                    : body // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }

  /// Create a copy of GithubReleaseJson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthorCopyWith<$Res> get author {
    return $AuthorCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GithubReleaseJsonImplCopyWith<$Res>
    implements $GithubReleaseJsonCopyWith<$Res> {
  factory _$$GithubReleaseJsonImplCopyWith(
    _$GithubReleaseJsonImpl value,
    $Res Function(_$GithubReleaseJsonImpl) then,
  ) = __$$GithubReleaseJsonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "url") String url,
    @JsonKey(name: "assets_url") String assetsUrl,
    @JsonKey(name: "upload_url") String uploadUrl,
    @JsonKey(name: "html_url") String htmlUrl,
    @JsonKey(name: "id") int id,
    @JsonKey(name: "author") Author author,
    @JsonKey(name: "node_id") String nodeId,
    @JsonKey(name: "tag_name") String tagName,
    @JsonKey(name: "target_commitish") String targetCommitish,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "draft") bool draft,
    @JsonKey(name: "prerelease") bool prerelease,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "published_at") DateTime publishedAt,
    @JsonKey(name: "assets") List<Asset> assets,
    @JsonKey(name: "tarball_url") String tarballUrl,
    @JsonKey(name: "zipball_url") String zipballUrl,
    @JsonKey(name: "body") String body,
  });

  @override
  $AuthorCopyWith<$Res> get author;
}

/// @nodoc
class __$$GithubReleaseJsonImplCopyWithImpl<$Res>
    extends _$GithubReleaseJsonCopyWithImpl<$Res, _$GithubReleaseJsonImpl>
    implements _$$GithubReleaseJsonImplCopyWith<$Res> {
  __$$GithubReleaseJsonImplCopyWithImpl(
    _$GithubReleaseJsonImpl _value,
    $Res Function(_$GithubReleaseJsonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GithubReleaseJson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? assetsUrl = null,
    Object? uploadUrl = null,
    Object? htmlUrl = null,
    Object? id = null,
    Object? author = null,
    Object? nodeId = null,
    Object? tagName = null,
    Object? targetCommitish = null,
    Object? name = null,
    Object? draft = null,
    Object? prerelease = null,
    Object? createdAt = null,
    Object? publishedAt = null,
    Object? assets = null,
    Object? tarballUrl = null,
    Object? zipballUrl = null,
    Object? body = null,
  }) {
    return _then(
      _$GithubReleaseJsonImpl(
        url:
            null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                    as String,
        assetsUrl:
            null == assetsUrl
                ? _value.assetsUrl
                : assetsUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        uploadUrl:
            null == uploadUrl
                ? _value.uploadUrl
                : uploadUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        htmlUrl:
            null == htmlUrl
                ? _value.htmlUrl
                : htmlUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int,
        author:
            null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                    as Author,
        nodeId:
            null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                    as String,
        tagName:
            null == tagName
                ? _value.tagName
                : tagName // ignore: cast_nullable_to_non_nullable
                    as String,
        targetCommitish:
            null == targetCommitish
                ? _value.targetCommitish
                : targetCommitish // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        draft:
            null == draft
                ? _value.draft
                : draft // ignore: cast_nullable_to_non_nullable
                    as bool,
        prerelease:
            null == prerelease
                ? _value.prerelease
                : prerelease // ignore: cast_nullable_to_non_nullable
                    as bool,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        publishedAt:
            null == publishedAt
                ? _value.publishedAt
                : publishedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        assets:
            null == assets
                ? _value._assets
                : assets // ignore: cast_nullable_to_non_nullable
                    as List<Asset>,
        tarballUrl:
            null == tarballUrl
                ? _value.tarballUrl
                : tarballUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        zipballUrl:
            null == zipballUrl
                ? _value.zipballUrl
                : zipballUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        body:
            null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GithubReleaseJsonImpl implements _GithubReleaseJson {
  const _$GithubReleaseJsonImpl({
    @JsonKey(name: "url") required this.url,
    @JsonKey(name: "assets_url") required this.assetsUrl,
    @JsonKey(name: "upload_url") required this.uploadUrl,
    @JsonKey(name: "html_url") required this.htmlUrl,
    @JsonKey(name: "id") required this.id,
    @JsonKey(name: "author") required this.author,
    @JsonKey(name: "node_id") required this.nodeId,
    @JsonKey(name: "tag_name") required this.tagName,
    @JsonKey(name: "target_commitish") required this.targetCommitish,
    @JsonKey(name: "name") required this.name,
    @JsonKey(name: "draft") required this.draft,
    @JsonKey(name: "prerelease") required this.prerelease,
    @JsonKey(name: "created_at") required this.createdAt,
    @JsonKey(name: "published_at") required this.publishedAt,
    @JsonKey(name: "assets") required final List<Asset> assets,
    @JsonKey(name: "tarball_url") required this.tarballUrl,
    @JsonKey(name: "zipball_url") required this.zipballUrl,
    @JsonKey(name: "body") required this.body,
  }) : _assets = assets;

  factory _$GithubReleaseJsonImpl.fromJson(Map<String, dynamic> json) =>
      _$$GithubReleaseJsonImplFromJson(json);

  @override
  @JsonKey(name: "url")
  final String url;
  @override
  @JsonKey(name: "assets_url")
  final String assetsUrl;
  @override
  @JsonKey(name: "upload_url")
  final String uploadUrl;
  @override
  @JsonKey(name: "html_url")
  final String htmlUrl;
  @override
  @JsonKey(name: "id")
  final int id;
  @override
  @JsonKey(name: "author")
  final Author author;
  @override
  @JsonKey(name: "node_id")
  final String nodeId;
  @override
  @JsonKey(name: "tag_name")
  final String tagName;
  @override
  @JsonKey(name: "target_commitish")
  final String targetCommitish;
  @override
  @JsonKey(name: "name")
  final String name;
  @override
  @JsonKey(name: "draft")
  final bool draft;
  @override
  @JsonKey(name: "prerelease")
  final bool prerelease;
  @override
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "published_at")
  final DateTime publishedAt;
  final List<Asset> _assets;
  @override
  @JsonKey(name: "assets")
  List<Asset> get assets {
    if (_assets is EqualUnmodifiableListView) return _assets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assets);
  }

  @override
  @JsonKey(name: "tarball_url")
  final String tarballUrl;
  @override
  @JsonKey(name: "zipball_url")
  final String zipballUrl;
  @override
  @JsonKey(name: "body")
  final String body;

  @override
  String toString() {
    return 'GithubReleaseJson(url: $url, assetsUrl: $assetsUrl, uploadUrl: $uploadUrl, htmlUrl: $htmlUrl, id: $id, author: $author, nodeId: $nodeId, tagName: $tagName, targetCommitish: $targetCommitish, name: $name, draft: $draft, prerelease: $prerelease, createdAt: $createdAt, publishedAt: $publishedAt, assets: $assets, tarballUrl: $tarballUrl, zipballUrl: $zipballUrl, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GithubReleaseJsonImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.assetsUrl, assetsUrl) ||
                other.assetsUrl == assetsUrl) &&
            (identical(other.uploadUrl, uploadUrl) ||
                other.uploadUrl == uploadUrl) &&
            (identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.tagName, tagName) || other.tagName == tagName) &&
            (identical(other.targetCommitish, targetCommitish) ||
                other.targetCommitish == targetCommitish) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.draft, draft) || other.draft == draft) &&
            (identical(other.prerelease, prerelease) ||
                other.prerelease == prerelease) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.publishedAt, publishedAt) ||
                other.publishedAt == publishedAt) &&
            const DeepCollectionEquality().equals(other._assets, _assets) &&
            (identical(other.tarballUrl, tarballUrl) ||
                other.tarballUrl == tarballUrl) &&
            (identical(other.zipballUrl, zipballUrl) ||
                other.zipballUrl == zipballUrl) &&
            (identical(other.body, body) || other.body == body));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    assetsUrl,
    uploadUrl,
    htmlUrl,
    id,
    author,
    nodeId,
    tagName,
    targetCommitish,
    name,
    draft,
    prerelease,
    createdAt,
    publishedAt,
    const DeepCollectionEquality().hash(_assets),
    tarballUrl,
    zipballUrl,
    body,
  );

  /// Create a copy of GithubReleaseJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GithubReleaseJsonImplCopyWith<_$GithubReleaseJsonImpl> get copyWith =>
      __$$GithubReleaseJsonImplCopyWithImpl<_$GithubReleaseJsonImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GithubReleaseJsonImplToJson(this);
  }
}

abstract class _GithubReleaseJson implements GithubReleaseJson {
  const factory _GithubReleaseJson({
    @JsonKey(name: "url") required final String url,
    @JsonKey(name: "assets_url") required final String assetsUrl,
    @JsonKey(name: "upload_url") required final String uploadUrl,
    @JsonKey(name: "html_url") required final String htmlUrl,
    @JsonKey(name: "id") required final int id,
    @JsonKey(name: "author") required final Author author,
    @JsonKey(name: "node_id") required final String nodeId,
    @JsonKey(name: "tag_name") required final String tagName,
    @JsonKey(name: "target_commitish") required final String targetCommitish,
    @JsonKey(name: "name") required final String name,
    @JsonKey(name: "draft") required final bool draft,
    @JsonKey(name: "prerelease") required final bool prerelease,
    @JsonKey(name: "created_at") required final DateTime createdAt,
    @JsonKey(name: "published_at") required final DateTime publishedAt,
    @JsonKey(name: "assets") required final List<Asset> assets,
    @JsonKey(name: "tarball_url") required final String tarballUrl,
    @JsonKey(name: "zipball_url") required final String zipballUrl,
    @JsonKey(name: "body") required final String body,
  }) = _$GithubReleaseJsonImpl;

  factory _GithubReleaseJson.fromJson(Map<String, dynamic> json) =
      _$GithubReleaseJsonImpl.fromJson;

  @override
  @JsonKey(name: "url")
  String get url;
  @override
  @JsonKey(name: "assets_url")
  String get assetsUrl;
  @override
  @JsonKey(name: "upload_url")
  String get uploadUrl;
  @override
  @JsonKey(name: "html_url")
  String get htmlUrl;
  @override
  @JsonKey(name: "id")
  int get id;
  @override
  @JsonKey(name: "author")
  Author get author;
  @override
  @JsonKey(name: "node_id")
  String get nodeId;
  @override
  @JsonKey(name: "tag_name")
  String get tagName;
  @override
  @JsonKey(name: "target_commitish")
  String get targetCommitish;
  @override
  @JsonKey(name: "name")
  String get name;
  @override
  @JsonKey(name: "draft")
  bool get draft;
  @override
  @JsonKey(name: "prerelease")
  bool get prerelease;
  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;
  @override
  @JsonKey(name: "published_at")
  DateTime get publishedAt;
  @override
  @JsonKey(name: "assets")
  List<Asset> get assets;
  @override
  @JsonKey(name: "tarball_url")
  String get tarballUrl;
  @override
  @JsonKey(name: "zipball_url")
  String get zipballUrl;
  @override
  @JsonKey(name: "body")
  String get body;

  /// Create a copy of GithubReleaseJson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GithubReleaseJsonImplCopyWith<_$GithubReleaseJsonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Asset _$AssetFromJson(Map<String, dynamic> json) {
  return _Asset.fromJson(json);
}

/// @nodoc
mixin _$Asset {
  @JsonKey(name: "url")
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: "id")
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: "node_id")
  String get nodeId => throw _privateConstructorUsedError;
  @JsonKey(name: "name")
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: "label")
  dynamic get label => throw _privateConstructorUsedError;
  @JsonKey(name: "uploader")
  Author get uploader => throw _privateConstructorUsedError;
  @JsonKey(name: "content_type")
  String get contentType => throw _privateConstructorUsedError;
  @JsonKey(name: "state")
  String get state => throw _privateConstructorUsedError;
  @JsonKey(name: "size")
  int get size => throw _privateConstructorUsedError;
  @JsonKey(name: "download_count")
  int get downloadCount => throw _privateConstructorUsedError;
  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: "updated_at")
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: "browser_download_url")
  String get browserDownloadUrl => throw _privateConstructorUsedError;

  /// Serializes this Asset to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssetCopyWith<Asset> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssetCopyWith<$Res> {
  factory $AssetCopyWith(Asset value, $Res Function(Asset) then) =
      _$AssetCopyWithImpl<$Res, Asset>;
  @useResult
  $Res call({
    @JsonKey(name: "url") String url,
    @JsonKey(name: "id") int id,
    @JsonKey(name: "node_id") String nodeId,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "label") dynamic label,
    @JsonKey(name: "uploader") Author uploader,
    @JsonKey(name: "content_type") String contentType,
    @JsonKey(name: "state") String state,
    @JsonKey(name: "size") int size,
    @JsonKey(name: "download_count") int downloadCount,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "updated_at") DateTime updatedAt,
    @JsonKey(name: "browser_download_url") String browserDownloadUrl,
  });

  $AuthorCopyWith<$Res> get uploader;
}

/// @nodoc
class _$AssetCopyWithImpl<$Res, $Val extends Asset>
    implements $AssetCopyWith<$Res> {
  _$AssetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? id = null,
    Object? nodeId = null,
    Object? name = null,
    Object? label = freezed,
    Object? uploader = null,
    Object? contentType = null,
    Object? state = null,
    Object? size = null,
    Object? downloadCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? browserDownloadUrl = null,
  }) {
    return _then(
      _value.copyWith(
            url:
                null == url
                    ? _value.url
                    : url // ignore: cast_nullable_to_non_nullable
                        as String,
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int,
            nodeId:
                null == nodeId
                    ? _value.nodeId
                    : nodeId // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            label:
                freezed == label
                    ? _value.label
                    : label // ignore: cast_nullable_to_non_nullable
                        as dynamic,
            uploader:
                null == uploader
                    ? _value.uploader
                    : uploader // ignore: cast_nullable_to_non_nullable
                        as Author,
            contentType:
                null == contentType
                    ? _value.contentType
                    : contentType // ignore: cast_nullable_to_non_nullable
                        as String,
            state:
                null == state
                    ? _value.state
                    : state // ignore: cast_nullable_to_non_nullable
                        as String,
            size:
                null == size
                    ? _value.size
                    : size // ignore: cast_nullable_to_non_nullable
                        as int,
            downloadCount:
                null == downloadCount
                    ? _value.downloadCount
                    : downloadCount // ignore: cast_nullable_to_non_nullable
                        as int,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            browserDownloadUrl:
                null == browserDownloadUrl
                    ? _value.browserDownloadUrl
                    : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AuthorCopyWith<$Res> get uploader {
    return $AuthorCopyWith<$Res>(_value.uploader, (value) {
      return _then(_value.copyWith(uploader: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AssetImplCopyWith<$Res> implements $AssetCopyWith<$Res> {
  factory _$$AssetImplCopyWith(
    _$AssetImpl value,
    $Res Function(_$AssetImpl) then,
  ) = __$$AssetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "url") String url,
    @JsonKey(name: "id") int id,
    @JsonKey(name: "node_id") String nodeId,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "label") dynamic label,
    @JsonKey(name: "uploader") Author uploader,
    @JsonKey(name: "content_type") String contentType,
    @JsonKey(name: "state") String state,
    @JsonKey(name: "size") int size,
    @JsonKey(name: "download_count") int downloadCount,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "updated_at") DateTime updatedAt,
    @JsonKey(name: "browser_download_url") String browserDownloadUrl,
  });

  @override
  $AuthorCopyWith<$Res> get uploader;
}

/// @nodoc
class __$$AssetImplCopyWithImpl<$Res>
    extends _$AssetCopyWithImpl<$Res, _$AssetImpl>
    implements _$$AssetImplCopyWith<$Res> {
  __$$AssetImplCopyWithImpl(
    _$AssetImpl _value,
    $Res Function(_$AssetImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? id = null,
    Object? nodeId = null,
    Object? name = null,
    Object? label = freezed,
    Object? uploader = null,
    Object? contentType = null,
    Object? state = null,
    Object? size = null,
    Object? downloadCount = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? browserDownloadUrl = null,
  }) {
    return _then(
      _$AssetImpl(
        url:
            null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                    as String,
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int,
        nodeId:
            null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        label:
            freezed == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                    as dynamic,
        uploader:
            null == uploader
                ? _value.uploader
                : uploader // ignore: cast_nullable_to_non_nullable
                    as Author,
        contentType:
            null == contentType
                ? _value.contentType
                : contentType // ignore: cast_nullable_to_non_nullable
                    as String,
        state:
            null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                    as String,
        size:
            null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                    as int,
        downloadCount:
            null == downloadCount
                ? _value.downloadCount
                : downloadCount // ignore: cast_nullable_to_non_nullable
                    as int,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        browserDownloadUrl:
            null == browserDownloadUrl
                ? _value.browserDownloadUrl
                : browserDownloadUrl // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssetImpl implements _Asset {
  const _$AssetImpl({
    @JsonKey(name: "url") required this.url,
    @JsonKey(name: "id") required this.id,
    @JsonKey(name: "node_id") required this.nodeId,
    @JsonKey(name: "name") required this.name,
    @JsonKey(name: "label") required this.label,
    @JsonKey(name: "uploader") required this.uploader,
    @JsonKey(name: "content_type") required this.contentType,
    @JsonKey(name: "state") required this.state,
    @JsonKey(name: "size") required this.size,
    @JsonKey(name: "download_count") required this.downloadCount,
    @JsonKey(name: "created_at") required this.createdAt,
    @JsonKey(name: "updated_at") required this.updatedAt,
    @JsonKey(name: "browser_download_url") required this.browserDownloadUrl,
  });

  factory _$AssetImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssetImplFromJson(json);

  @override
  @JsonKey(name: "url")
  final String url;
  @override
  @JsonKey(name: "id")
  final int id;
  @override
  @JsonKey(name: "node_id")
  final String nodeId;
  @override
  @JsonKey(name: "name")
  final String name;
  @override
  @JsonKey(name: "label")
  final dynamic label;
  @override
  @JsonKey(name: "uploader")
  final Author uploader;
  @override
  @JsonKey(name: "content_type")
  final String contentType;
  @override
  @JsonKey(name: "state")
  final String state;
  @override
  @JsonKey(name: "size")
  final int size;
  @override
  @JsonKey(name: "download_count")
  final int downloadCount;
  @override
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;
  @override
  @JsonKey(name: "browser_download_url")
  final String browserDownloadUrl;

  @override
  String toString() {
    return 'Asset(url: $url, id: $id, nodeId: $nodeId, name: $name, label: $label, uploader: $uploader, contentType: $contentType, state: $state, size: $size, downloadCount: $downloadCount, createdAt: $createdAt, updatedAt: $updatedAt, browserDownloadUrl: $browserDownloadUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssetImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.label, label) &&
            (identical(other.uploader, uploader) ||
                other.uploader == uploader) &&
            (identical(other.contentType, contentType) ||
                other.contentType == contentType) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.downloadCount, downloadCount) ||
                other.downloadCount == downloadCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.browserDownloadUrl, browserDownloadUrl) ||
                other.browserDownloadUrl == browserDownloadUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    id,
    nodeId,
    name,
    const DeepCollectionEquality().hash(label),
    uploader,
    contentType,
    state,
    size,
    downloadCount,
    createdAt,
    updatedAt,
    browserDownloadUrl,
  );

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssetImplCopyWith<_$AssetImpl> get copyWith =>
      __$$AssetImplCopyWithImpl<_$AssetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssetImplToJson(this);
  }
}

abstract class _Asset implements Asset {
  const factory _Asset({
    @JsonKey(name: "url") required final String url,
    @JsonKey(name: "id") required final int id,
    @JsonKey(name: "node_id") required final String nodeId,
    @JsonKey(name: "name") required final String name,
    @JsonKey(name: "label") required final dynamic label,
    @JsonKey(name: "uploader") required final Author uploader,
    @JsonKey(name: "content_type") required final String contentType,
    @JsonKey(name: "state") required final String state,
    @JsonKey(name: "size") required final int size,
    @JsonKey(name: "download_count") required final int downloadCount,
    @JsonKey(name: "created_at") required final DateTime createdAt,
    @JsonKey(name: "updated_at") required final DateTime updatedAt,
    @JsonKey(name: "browser_download_url")
    required final String browserDownloadUrl,
  }) = _$AssetImpl;

  factory _Asset.fromJson(Map<String, dynamic> json) = _$AssetImpl.fromJson;

  @override
  @JsonKey(name: "url")
  String get url;
  @override
  @JsonKey(name: "id")
  int get id;
  @override
  @JsonKey(name: "node_id")
  String get nodeId;
  @override
  @JsonKey(name: "name")
  String get name;
  @override
  @JsonKey(name: "label")
  dynamic get label;
  @override
  @JsonKey(name: "uploader")
  Author get uploader;
  @override
  @JsonKey(name: "content_type")
  String get contentType;
  @override
  @JsonKey(name: "state")
  String get state;
  @override
  @JsonKey(name: "size")
  int get size;
  @override
  @JsonKey(name: "download_count")
  int get downloadCount;
  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;
  @override
  @JsonKey(name: "updated_at")
  DateTime get updatedAt;
  @override
  @JsonKey(name: "browser_download_url")
  String get browserDownloadUrl;

  /// Create a copy of Asset
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssetImplCopyWith<_$AssetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Author _$AuthorFromJson(Map<String, dynamic> json) {
  return _Author.fromJson(json);
}

/// @nodoc
mixin _$Author {
  @JsonKey(name: "login")
  String get login => throw _privateConstructorUsedError;
  @JsonKey(name: "id")
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: "node_id")
  String get nodeId => throw _privateConstructorUsedError;
  @JsonKey(name: "avatar_url")
  String get avatarUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "gravatar_id")
  String get gravatarId => throw _privateConstructorUsedError;
  @JsonKey(name: "url")
  String get url => throw _privateConstructorUsedError;
  @JsonKey(name: "html_url")
  String get htmlUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "followers_url")
  String get followersUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "following_url")
  String get followingUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "gists_url")
  String get gistsUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "starred_url")
  String get starredUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "subscriptions_url")
  String get subscriptionsUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "organizations_url")
  String get organizationsUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "repos_url")
  String get reposUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "events_url")
  String get eventsUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "received_events_url")
  String get receivedEventsUrl => throw _privateConstructorUsedError;
  @JsonKey(name: "type")
  String get type => throw _privateConstructorUsedError;
  @JsonKey(name: "user_view_type")
  String get userViewType => throw _privateConstructorUsedError;
  @JsonKey(name: "site_admin")
  bool get siteAdmin => throw _privateConstructorUsedError;

  /// Serializes this Author to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthorCopyWith<Author> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorCopyWith<$Res> {
  factory $AuthorCopyWith(Author value, $Res Function(Author) then) =
      _$AuthorCopyWithImpl<$Res, Author>;
  @useResult
  $Res call({
    @JsonKey(name: "login") String login,
    @JsonKey(name: "id") int id,
    @JsonKey(name: "node_id") String nodeId,
    @JsonKey(name: "avatar_url") String avatarUrl,
    @JsonKey(name: "gravatar_id") String gravatarId,
    @JsonKey(name: "url") String url,
    @JsonKey(name: "html_url") String htmlUrl,
    @JsonKey(name: "followers_url") String followersUrl,
    @JsonKey(name: "following_url") String followingUrl,
    @JsonKey(name: "gists_url") String gistsUrl,
    @JsonKey(name: "starred_url") String starredUrl,
    @JsonKey(name: "subscriptions_url") String subscriptionsUrl,
    @JsonKey(name: "organizations_url") String organizationsUrl,
    @JsonKey(name: "repos_url") String reposUrl,
    @JsonKey(name: "events_url") String eventsUrl,
    @JsonKey(name: "received_events_url") String receivedEventsUrl,
    @JsonKey(name: "type") String type,
    @JsonKey(name: "user_view_type") String userViewType,
    @JsonKey(name: "site_admin") bool siteAdmin,
  });
}

/// @nodoc
class _$AuthorCopyWithImpl<$Res, $Val extends Author>
    implements $AuthorCopyWith<$Res> {
  _$AuthorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? login = null,
    Object? id = null,
    Object? nodeId = null,
    Object? avatarUrl = null,
    Object? gravatarId = null,
    Object? url = null,
    Object? htmlUrl = null,
    Object? followersUrl = null,
    Object? followingUrl = null,
    Object? gistsUrl = null,
    Object? starredUrl = null,
    Object? subscriptionsUrl = null,
    Object? organizationsUrl = null,
    Object? reposUrl = null,
    Object? eventsUrl = null,
    Object? receivedEventsUrl = null,
    Object? type = null,
    Object? userViewType = null,
    Object? siteAdmin = null,
  }) {
    return _then(
      _value.copyWith(
            login:
                null == login
                    ? _value.login
                    : login // ignore: cast_nullable_to_non_nullable
                        as String,
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as int,
            nodeId:
                null == nodeId
                    ? _value.nodeId
                    : nodeId // ignore: cast_nullable_to_non_nullable
                        as String,
            avatarUrl:
                null == avatarUrl
                    ? _value.avatarUrl
                    : avatarUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            gravatarId:
                null == gravatarId
                    ? _value.gravatarId
                    : gravatarId // ignore: cast_nullable_to_non_nullable
                        as String,
            url:
                null == url
                    ? _value.url
                    : url // ignore: cast_nullable_to_non_nullable
                        as String,
            htmlUrl:
                null == htmlUrl
                    ? _value.htmlUrl
                    : htmlUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            followersUrl:
                null == followersUrl
                    ? _value.followersUrl
                    : followersUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            followingUrl:
                null == followingUrl
                    ? _value.followingUrl
                    : followingUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            gistsUrl:
                null == gistsUrl
                    ? _value.gistsUrl
                    : gistsUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            starredUrl:
                null == starredUrl
                    ? _value.starredUrl
                    : starredUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            subscriptionsUrl:
                null == subscriptionsUrl
                    ? _value.subscriptionsUrl
                    : subscriptionsUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            organizationsUrl:
                null == organizationsUrl
                    ? _value.organizationsUrl
                    : organizationsUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            reposUrl:
                null == reposUrl
                    ? _value.reposUrl
                    : reposUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            eventsUrl:
                null == eventsUrl
                    ? _value.eventsUrl
                    : eventsUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            receivedEventsUrl:
                null == receivedEventsUrl
                    ? _value.receivedEventsUrl
                    : receivedEventsUrl // ignore: cast_nullable_to_non_nullable
                        as String,
            type:
                null == type
                    ? _value.type
                    : type // ignore: cast_nullable_to_non_nullable
                        as String,
            userViewType:
                null == userViewType
                    ? _value.userViewType
                    : userViewType // ignore: cast_nullable_to_non_nullable
                        as String,
            siteAdmin:
                null == siteAdmin
                    ? _value.siteAdmin
                    : siteAdmin // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthorImplCopyWith<$Res> implements $AuthorCopyWith<$Res> {
  factory _$$AuthorImplCopyWith(
    _$AuthorImpl value,
    $Res Function(_$AuthorImpl) then,
  ) = __$$AuthorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "login") String login,
    @JsonKey(name: "id") int id,
    @JsonKey(name: "node_id") String nodeId,
    @JsonKey(name: "avatar_url") String avatarUrl,
    @JsonKey(name: "gravatar_id") String gravatarId,
    @JsonKey(name: "url") String url,
    @JsonKey(name: "html_url") String htmlUrl,
    @JsonKey(name: "followers_url") String followersUrl,
    @JsonKey(name: "following_url") String followingUrl,
    @JsonKey(name: "gists_url") String gistsUrl,
    @JsonKey(name: "starred_url") String starredUrl,
    @JsonKey(name: "subscriptions_url") String subscriptionsUrl,
    @JsonKey(name: "organizations_url") String organizationsUrl,
    @JsonKey(name: "repos_url") String reposUrl,
    @JsonKey(name: "events_url") String eventsUrl,
    @JsonKey(name: "received_events_url") String receivedEventsUrl,
    @JsonKey(name: "type") String type,
    @JsonKey(name: "user_view_type") String userViewType,
    @JsonKey(name: "site_admin") bool siteAdmin,
  });
}

/// @nodoc
class __$$AuthorImplCopyWithImpl<$Res>
    extends _$AuthorCopyWithImpl<$Res, _$AuthorImpl>
    implements _$$AuthorImplCopyWith<$Res> {
  __$$AuthorImplCopyWithImpl(
    _$AuthorImpl _value,
    $Res Function(_$AuthorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? login = null,
    Object? id = null,
    Object? nodeId = null,
    Object? avatarUrl = null,
    Object? gravatarId = null,
    Object? url = null,
    Object? htmlUrl = null,
    Object? followersUrl = null,
    Object? followingUrl = null,
    Object? gistsUrl = null,
    Object? starredUrl = null,
    Object? subscriptionsUrl = null,
    Object? organizationsUrl = null,
    Object? reposUrl = null,
    Object? eventsUrl = null,
    Object? receivedEventsUrl = null,
    Object? type = null,
    Object? userViewType = null,
    Object? siteAdmin = null,
  }) {
    return _then(
      _$AuthorImpl(
        login:
            null == login
                ? _value.login
                : login // ignore: cast_nullable_to_non_nullable
                    as String,
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as int,
        nodeId:
            null == nodeId
                ? _value.nodeId
                : nodeId // ignore: cast_nullable_to_non_nullable
                    as String,
        avatarUrl:
            null == avatarUrl
                ? _value.avatarUrl
                : avatarUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        gravatarId:
            null == gravatarId
                ? _value.gravatarId
                : gravatarId // ignore: cast_nullable_to_non_nullable
                    as String,
        url:
            null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                    as String,
        htmlUrl:
            null == htmlUrl
                ? _value.htmlUrl
                : htmlUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        followersUrl:
            null == followersUrl
                ? _value.followersUrl
                : followersUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        followingUrl:
            null == followingUrl
                ? _value.followingUrl
                : followingUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        gistsUrl:
            null == gistsUrl
                ? _value.gistsUrl
                : gistsUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        starredUrl:
            null == starredUrl
                ? _value.starredUrl
                : starredUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        subscriptionsUrl:
            null == subscriptionsUrl
                ? _value.subscriptionsUrl
                : subscriptionsUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        organizationsUrl:
            null == organizationsUrl
                ? _value.organizationsUrl
                : organizationsUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        reposUrl:
            null == reposUrl
                ? _value.reposUrl
                : reposUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        eventsUrl:
            null == eventsUrl
                ? _value.eventsUrl
                : eventsUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        receivedEventsUrl:
            null == receivedEventsUrl
                ? _value.receivedEventsUrl
                : receivedEventsUrl // ignore: cast_nullable_to_non_nullable
                    as String,
        type:
            null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                    as String,
        userViewType:
            null == userViewType
                ? _value.userViewType
                : userViewType // ignore: cast_nullable_to_non_nullable
                    as String,
        siteAdmin:
            null == siteAdmin
                ? _value.siteAdmin
                : siteAdmin // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthorImpl implements _Author {
  const _$AuthorImpl({
    @JsonKey(name: "login") required this.login,
    @JsonKey(name: "id") required this.id,
    @JsonKey(name: "node_id") required this.nodeId,
    @JsonKey(name: "avatar_url") required this.avatarUrl,
    @JsonKey(name: "gravatar_id") required this.gravatarId,
    @JsonKey(name: "url") required this.url,
    @JsonKey(name: "html_url") required this.htmlUrl,
    @JsonKey(name: "followers_url") required this.followersUrl,
    @JsonKey(name: "following_url") required this.followingUrl,
    @JsonKey(name: "gists_url") required this.gistsUrl,
    @JsonKey(name: "starred_url") required this.starredUrl,
    @JsonKey(name: "subscriptions_url") required this.subscriptionsUrl,
    @JsonKey(name: "organizations_url") required this.organizationsUrl,
    @JsonKey(name: "repos_url") required this.reposUrl,
    @JsonKey(name: "events_url") required this.eventsUrl,
    @JsonKey(name: "received_events_url") required this.receivedEventsUrl,
    @JsonKey(name: "type") required this.type,
    @JsonKey(name: "user_view_type") required this.userViewType,
    @JsonKey(name: "site_admin") required this.siteAdmin,
  });

  factory _$AuthorImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthorImplFromJson(json);

  @override
  @JsonKey(name: "login")
  final String login;
  @override
  @JsonKey(name: "id")
  final int id;
  @override
  @JsonKey(name: "node_id")
  final String nodeId;
  @override
  @JsonKey(name: "avatar_url")
  final String avatarUrl;
  @override
  @JsonKey(name: "gravatar_id")
  final String gravatarId;
  @override
  @JsonKey(name: "url")
  final String url;
  @override
  @JsonKey(name: "html_url")
  final String htmlUrl;
  @override
  @JsonKey(name: "followers_url")
  final String followersUrl;
  @override
  @JsonKey(name: "following_url")
  final String followingUrl;
  @override
  @JsonKey(name: "gists_url")
  final String gistsUrl;
  @override
  @JsonKey(name: "starred_url")
  final String starredUrl;
  @override
  @JsonKey(name: "subscriptions_url")
  final String subscriptionsUrl;
  @override
  @JsonKey(name: "organizations_url")
  final String organizationsUrl;
  @override
  @JsonKey(name: "repos_url")
  final String reposUrl;
  @override
  @JsonKey(name: "events_url")
  final String eventsUrl;
  @override
  @JsonKey(name: "received_events_url")
  final String receivedEventsUrl;
  @override
  @JsonKey(name: "type")
  final String type;
  @override
  @JsonKey(name: "user_view_type")
  final String userViewType;
  @override
  @JsonKey(name: "site_admin")
  final bool siteAdmin;

  @override
  String toString() {
    return 'Author(login: $login, id: $id, nodeId: $nodeId, avatarUrl: $avatarUrl, gravatarId: $gravatarId, url: $url, htmlUrl: $htmlUrl, followersUrl: $followersUrl, followingUrl: $followingUrl, gistsUrl: $gistsUrl, starredUrl: $starredUrl, subscriptionsUrl: $subscriptionsUrl, organizationsUrl: $organizationsUrl, reposUrl: $reposUrl, eventsUrl: $eventsUrl, receivedEventsUrl: $receivedEventsUrl, type: $type, userViewType: $userViewType, siteAdmin: $siteAdmin)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorImpl &&
            (identical(other.login, login) || other.login == login) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nodeId, nodeId) || other.nodeId == nodeId) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.gravatarId, gravatarId) ||
                other.gravatarId == gravatarId) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl) &&
            (identical(other.followersUrl, followersUrl) ||
                other.followersUrl == followersUrl) &&
            (identical(other.followingUrl, followingUrl) ||
                other.followingUrl == followingUrl) &&
            (identical(other.gistsUrl, gistsUrl) ||
                other.gistsUrl == gistsUrl) &&
            (identical(other.starredUrl, starredUrl) ||
                other.starredUrl == starredUrl) &&
            (identical(other.subscriptionsUrl, subscriptionsUrl) ||
                other.subscriptionsUrl == subscriptionsUrl) &&
            (identical(other.organizationsUrl, organizationsUrl) ||
                other.organizationsUrl == organizationsUrl) &&
            (identical(other.reposUrl, reposUrl) ||
                other.reposUrl == reposUrl) &&
            (identical(other.eventsUrl, eventsUrl) ||
                other.eventsUrl == eventsUrl) &&
            (identical(other.receivedEventsUrl, receivedEventsUrl) ||
                other.receivedEventsUrl == receivedEventsUrl) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.userViewType, userViewType) ||
                other.userViewType == userViewType) &&
            (identical(other.siteAdmin, siteAdmin) ||
                other.siteAdmin == siteAdmin));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    login,
    id,
    nodeId,
    avatarUrl,
    gravatarId,
    url,
    htmlUrl,
    followersUrl,
    followingUrl,
    gistsUrl,
    starredUrl,
    subscriptionsUrl,
    organizationsUrl,
    reposUrl,
    eventsUrl,
    receivedEventsUrl,
    type,
    userViewType,
    siteAdmin,
  ]);

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorImplCopyWith<_$AuthorImpl> get copyWith =>
      __$$AuthorImplCopyWithImpl<_$AuthorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthorImplToJson(this);
  }
}

abstract class _Author implements Author {
  const factory _Author({
    @JsonKey(name: "login") required final String login,
    @JsonKey(name: "id") required final int id,
    @JsonKey(name: "node_id") required final String nodeId,
    @JsonKey(name: "avatar_url") required final String avatarUrl,
    @JsonKey(name: "gravatar_id") required final String gravatarId,
    @JsonKey(name: "url") required final String url,
    @JsonKey(name: "html_url") required final String htmlUrl,
    @JsonKey(name: "followers_url") required final String followersUrl,
    @JsonKey(name: "following_url") required final String followingUrl,
    @JsonKey(name: "gists_url") required final String gistsUrl,
    @JsonKey(name: "starred_url") required final String starredUrl,
    @JsonKey(name: "subscriptions_url") required final String subscriptionsUrl,
    @JsonKey(name: "organizations_url") required final String organizationsUrl,
    @JsonKey(name: "repos_url") required final String reposUrl,
    @JsonKey(name: "events_url") required final String eventsUrl,
    @JsonKey(name: "received_events_url")
    required final String receivedEventsUrl,
    @JsonKey(name: "type") required final String type,
    @JsonKey(name: "user_view_type") required final String userViewType,
    @JsonKey(name: "site_admin") required final bool siteAdmin,
  }) = _$AuthorImpl;

  factory _Author.fromJson(Map<String, dynamic> json) = _$AuthorImpl.fromJson;

  @override
  @JsonKey(name: "login")
  String get login;
  @override
  @JsonKey(name: "id")
  int get id;
  @override
  @JsonKey(name: "node_id")
  String get nodeId;
  @override
  @JsonKey(name: "avatar_url")
  String get avatarUrl;
  @override
  @JsonKey(name: "gravatar_id")
  String get gravatarId;
  @override
  @JsonKey(name: "url")
  String get url;
  @override
  @JsonKey(name: "html_url")
  String get htmlUrl;
  @override
  @JsonKey(name: "followers_url")
  String get followersUrl;
  @override
  @JsonKey(name: "following_url")
  String get followingUrl;
  @override
  @JsonKey(name: "gists_url")
  String get gistsUrl;
  @override
  @JsonKey(name: "starred_url")
  String get starredUrl;
  @override
  @JsonKey(name: "subscriptions_url")
  String get subscriptionsUrl;
  @override
  @JsonKey(name: "organizations_url")
  String get organizationsUrl;
  @override
  @JsonKey(name: "repos_url")
  String get reposUrl;
  @override
  @JsonKey(name: "events_url")
  String get eventsUrl;
  @override
  @JsonKey(name: "received_events_url")
  String get receivedEventsUrl;
  @override
  @JsonKey(name: "type")
  String get type;
  @override
  @JsonKey(name: "user_view_type")
  String get userViewType;
  @override
  @JsonKey(name: "site_admin")
  bool get siteAdmin;

  /// Create a copy of Author
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthorImplCopyWith<_$AuthorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
