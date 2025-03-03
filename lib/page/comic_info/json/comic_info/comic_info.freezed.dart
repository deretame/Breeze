// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comic_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ComicInfo _$ComicInfoFromJson(Map<String, dynamic> json) {
  return _ComicInfo.fromJson(json);
}

/// @nodoc
mixin _$ComicInfo {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;
  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this ComicInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ComicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ComicInfoCopyWith<ComicInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComicInfoCopyWith<$Res> {
  factory $ComicInfoCopyWith(ComicInfo value, $Res Function(ComicInfo) then) =
      _$ComicInfoCopyWithImpl<$Res, ComicInfo>;
  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$ComicInfoCopyWithImpl<$Res, $Val extends ComicInfo>
    implements $ComicInfoCopyWith<$Res> {
  _$ComicInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ComicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _value.copyWith(
            code:
                null == code
                    ? _value.code
                    : code // ignore: cast_nullable_to_non_nullable
                        as int,
            message:
                null == message
                    ? _value.message
                    : message // ignore: cast_nullable_to_non_nullable
                        as String,
            data:
                null == data
                    ? _value.data
                    : data // ignore: cast_nullable_to_non_nullable
                        as Data,
          )
          as $Val,
    );
  }

  /// Create a copy of ComicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DataCopyWith<$Res> get data {
    return $DataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ComicInfoImplCopyWith<$Res>
    implements $ComicInfoCopyWith<$Res> {
  factory _$$ComicInfoImplCopyWith(
    _$ComicInfoImpl value,
    $Res Function(_$ComicInfoImpl) then,
  ) = __$$ComicInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  @override
  $DataCopyWith<$Res> get data;
}

/// @nodoc
class __$$ComicInfoImplCopyWithImpl<$Res>
    extends _$ComicInfoCopyWithImpl<$Res, _$ComicInfoImpl>
    implements _$$ComicInfoImplCopyWith<$Res> {
  __$$ComicInfoImplCopyWithImpl(
    _$ComicInfoImpl _value,
    $Res Function(_$ComicInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ComicInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _$ComicInfoImpl(
        code:
            null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                    as int,
        message:
            null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                    as String,
        data:
            null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                    as Data,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ComicInfoImpl implements _ComicInfo {
  const _$ComicInfoImpl({
    @JsonKey(name: "code") required this.code,
    @JsonKey(name: "message") required this.message,
    @JsonKey(name: "data") required this.data,
  });

  factory _$ComicInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComicInfoImplFromJson(json);

  @override
  @JsonKey(name: "code")
  final int code;
  @override
  @JsonKey(name: "message")
  final String message;
  @override
  @JsonKey(name: "data")
  final Data data;

  @override
  String toString() {
    return 'ComicInfo(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComicInfoImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of ComicInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ComicInfoImplCopyWith<_$ComicInfoImpl> get copyWith =>
      __$$ComicInfoImplCopyWithImpl<_$ComicInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ComicInfoImplToJson(this);
  }
}

abstract class _ComicInfo implements ComicInfo {
  const factory _ComicInfo({
    @JsonKey(name: "code") required final int code,
    @JsonKey(name: "message") required final String message,
    @JsonKey(name: "data") required final Data data,
  }) = _$ComicInfoImpl;

  factory _ComicInfo.fromJson(Map<String, dynamic> json) =
      _$ComicInfoImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;
  @override
  @JsonKey(name: "message")
  String get message;
  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of ComicInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ComicInfoImplCopyWith<_$ComicInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "comic")
  Comic get comic => throw _privateConstructorUsedError;

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DataCopyWith<Data> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DataCopyWith<$Res> {
  factory $DataCopyWith(Data value, $Res Function(Data) then) =
      _$DataCopyWithImpl<$Res, Data>;
  @useResult
  $Res call({@JsonKey(name: "comic") Comic comic});

  $ComicCopyWith<$Res> get comic;
}

/// @nodoc
class _$DataCopyWithImpl<$Res, $Val extends Data>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? comic = null}) {
    return _then(
      _value.copyWith(
            comic:
                null == comic
                    ? _value.comic
                    : comic // ignore: cast_nullable_to_non_nullable
                        as Comic,
          )
          as $Val,
    );
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ComicCopyWith<$Res> get comic {
    return $ComicCopyWith<$Res>(_value.comic, (value) {
      return _then(_value.copyWith(comic: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DataImplCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$$DataImplCopyWith(
    _$DataImpl value,
    $Res Function(_$DataImpl) then,
  ) = __$$DataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: "comic") Comic comic});

  @override
  $ComicCopyWith<$Res> get comic;
}

/// @nodoc
class __$$DataImplCopyWithImpl<$Res>
    extends _$DataCopyWithImpl<$Res, _$DataImpl>
    implements _$$DataImplCopyWith<$Res> {
  __$$DataImplCopyWithImpl(_$DataImpl _value, $Res Function(_$DataImpl) _then)
    : super(_value, _then);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? comic = null}) {
    return _then(
      _$DataImpl(
        comic:
            null == comic
                ? _value.comic
                : comic // ignore: cast_nullable_to_non_nullable
                    as Comic,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl({@JsonKey(name: "comic") required this.comic});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  @JsonKey(name: "comic")
  final Comic comic;

  @override
  String toString() {
    return 'Data(comic: $comic)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.comic, comic) || other.comic == comic));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, comic);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      __$$DataImplCopyWithImpl<_$DataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataImplToJson(this);
  }
}

abstract class _Data implements Data {
  const factory _Data({@JsonKey(name: "comic") required final Comic comic}) =
      _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "comic")
  Comic get comic;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Comic _$ComicFromJson(Map<String, dynamic> json) {
  return _Comic.fromJson(json);
}

/// @nodoc
mixin _$Comic {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: "_creator")
  Creator get creator => throw _privateConstructorUsedError;
  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: "description")
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: "thumb")
  Thumb get thumb => throw _privateConstructorUsedError;
  @JsonKey(name: "author")
  String get author => throw _privateConstructorUsedError;
  @JsonKey(name: "chineseTeam")
  String get chineseTeam => throw _privateConstructorUsedError;
  @JsonKey(name: "categories")
  List<String> get categories => throw _privateConstructorUsedError;
  @JsonKey(name: "tags")
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: "pagesCount")
  int get pagesCount => throw _privateConstructorUsedError;
  @JsonKey(name: "epsCount")
  int get epsCount => throw _privateConstructorUsedError;
  @JsonKey(name: "finished")
  bool get finished => throw _privateConstructorUsedError;
  @JsonKey(name: "updated_at")
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: "allowDownload")
  bool get allowDownload => throw _privateConstructorUsedError;
  @JsonKey(name: "allowComment")
  bool get allowComment => throw _privateConstructorUsedError;
  @JsonKey(name: "totalLikes")
  int get totalLikes => throw _privateConstructorUsedError;
  @JsonKey(name: "totalViews")
  int get totalViews => throw _privateConstructorUsedError;
  @JsonKey(name: "totalComments")
  int get totalComments => throw _privateConstructorUsedError;
  @JsonKey(name: "viewsCount")
  int get viewsCount => throw _privateConstructorUsedError;
  @JsonKey(name: "likesCount")
  int get likesCount => throw _privateConstructorUsedError;
  @JsonKey(name: "commentsCount")
  int get commentsCount => throw _privateConstructorUsedError;
  @JsonKey(name: "isFavourite")
  bool get isFavourite => throw _privateConstructorUsedError;
  @JsonKey(name: "isLiked")
  bool get isLiked => throw _privateConstructorUsedError;

  /// Serializes this Comic to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ComicCopyWith<Comic> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComicCopyWith<$Res> {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) then) =
      _$ComicCopyWithImpl<$Res, Comic>;
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "_creator") Creator creator,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "description") String description,
    @JsonKey(name: "thumb") Thumb thumb,
    @JsonKey(name: "author") String author,
    @JsonKey(name: "chineseTeam") String chineseTeam,
    @JsonKey(name: "categories") List<String> categories,
    @JsonKey(name: "tags") List<String> tags,
    @JsonKey(name: "pagesCount") int pagesCount,
    @JsonKey(name: "epsCount") int epsCount,
    @JsonKey(name: "finished") bool finished,
    @JsonKey(name: "updated_at") DateTime updatedAt,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "allowDownload") bool allowDownload,
    @JsonKey(name: "allowComment") bool allowComment,
    @JsonKey(name: "totalLikes") int totalLikes,
    @JsonKey(name: "totalViews") int totalViews,
    @JsonKey(name: "totalComments") int totalComments,
    @JsonKey(name: "viewsCount") int viewsCount,
    @JsonKey(name: "likesCount") int likesCount,
    @JsonKey(name: "commentsCount") int commentsCount,
    @JsonKey(name: "isFavourite") bool isFavourite,
    @JsonKey(name: "isLiked") bool isLiked,
  });

  $CreatorCopyWith<$Res> get creator;
  $ThumbCopyWith<$Res> get thumb;
}

/// @nodoc
class _$ComicCopyWithImpl<$Res, $Val extends Comic>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creator = null,
    Object? title = null,
    Object? description = null,
    Object? thumb = null,
    Object? author = null,
    Object? chineseTeam = null,
    Object? categories = null,
    Object? tags = null,
    Object? pagesCount = null,
    Object? epsCount = null,
    Object? finished = null,
    Object? updatedAt = null,
    Object? createdAt = null,
    Object? allowDownload = null,
    Object? allowComment = null,
    Object? totalLikes = null,
    Object? totalViews = null,
    Object? totalComments = null,
    Object? viewsCount = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isFavourite = null,
    Object? isLiked = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            creator:
                null == creator
                    ? _value.creator
                    : creator // ignore: cast_nullable_to_non_nullable
                        as Creator,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            thumb:
                null == thumb
                    ? _value.thumb
                    : thumb // ignore: cast_nullable_to_non_nullable
                        as Thumb,
            author:
                null == author
                    ? _value.author
                    : author // ignore: cast_nullable_to_non_nullable
                        as String,
            chineseTeam:
                null == chineseTeam
                    ? _value.chineseTeam
                    : chineseTeam // ignore: cast_nullable_to_non_nullable
                        as String,
            categories:
                null == categories
                    ? _value.categories
                    : categories // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            tags:
                null == tags
                    ? _value.tags
                    : tags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            pagesCount:
                null == pagesCount
                    ? _value.pagesCount
                    : pagesCount // ignore: cast_nullable_to_non_nullable
                        as int,
            epsCount:
                null == epsCount
                    ? _value.epsCount
                    : epsCount // ignore: cast_nullable_to_non_nullable
                        as int,
            finished:
                null == finished
                    ? _value.finished
                    : finished // ignore: cast_nullable_to_non_nullable
                        as bool,
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            allowDownload:
                null == allowDownload
                    ? _value.allowDownload
                    : allowDownload // ignore: cast_nullable_to_non_nullable
                        as bool,
            allowComment:
                null == allowComment
                    ? _value.allowComment
                    : allowComment // ignore: cast_nullable_to_non_nullable
                        as bool,
            totalLikes:
                null == totalLikes
                    ? _value.totalLikes
                    : totalLikes // ignore: cast_nullable_to_non_nullable
                        as int,
            totalViews:
                null == totalViews
                    ? _value.totalViews
                    : totalViews // ignore: cast_nullable_to_non_nullable
                        as int,
            totalComments:
                null == totalComments
                    ? _value.totalComments
                    : totalComments // ignore: cast_nullable_to_non_nullable
                        as int,
            viewsCount:
                null == viewsCount
                    ? _value.viewsCount
                    : viewsCount // ignore: cast_nullable_to_non_nullable
                        as int,
            likesCount:
                null == likesCount
                    ? _value.likesCount
                    : likesCount // ignore: cast_nullable_to_non_nullable
                        as int,
            commentsCount:
                null == commentsCount
                    ? _value.commentsCount
                    : commentsCount // ignore: cast_nullable_to_non_nullable
                        as int,
            isFavourite:
                null == isFavourite
                    ? _value.isFavourite
                    : isFavourite // ignore: cast_nullable_to_non_nullable
                        as bool,
            isLiked:
                null == isLiked
                    ? _value.isLiked
                    : isLiked // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CreatorCopyWith<$Res> get creator {
    return $CreatorCopyWith<$Res>(_value.creator, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThumbCopyWith<$Res> get thumb {
    return $ThumbCopyWith<$Res>(_value.thumb, (value) {
      return _then(_value.copyWith(thumb: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ComicImplCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$$ComicImplCopyWith(
    _$ComicImpl value,
    $Res Function(_$ComicImpl) then,
  ) = __$$ComicImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "_creator") Creator creator,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "description") String description,
    @JsonKey(name: "thumb") Thumb thumb,
    @JsonKey(name: "author") String author,
    @JsonKey(name: "chineseTeam") String chineseTeam,
    @JsonKey(name: "categories") List<String> categories,
    @JsonKey(name: "tags") List<String> tags,
    @JsonKey(name: "pagesCount") int pagesCount,
    @JsonKey(name: "epsCount") int epsCount,
    @JsonKey(name: "finished") bool finished,
    @JsonKey(name: "updated_at") DateTime updatedAt,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "allowDownload") bool allowDownload,
    @JsonKey(name: "allowComment") bool allowComment,
    @JsonKey(name: "totalLikes") int totalLikes,
    @JsonKey(name: "totalViews") int totalViews,
    @JsonKey(name: "totalComments") int totalComments,
    @JsonKey(name: "viewsCount") int viewsCount,
    @JsonKey(name: "likesCount") int likesCount,
    @JsonKey(name: "commentsCount") int commentsCount,
    @JsonKey(name: "isFavourite") bool isFavourite,
    @JsonKey(name: "isLiked") bool isLiked,
  });

  @override
  $CreatorCopyWith<$Res> get creator;
  @override
  $ThumbCopyWith<$Res> get thumb;
}

/// @nodoc
class __$$ComicImplCopyWithImpl<$Res>
    extends _$ComicCopyWithImpl<$Res, _$ComicImpl>
    implements _$$ComicImplCopyWith<$Res> {
  __$$ComicImplCopyWithImpl(
    _$ComicImpl _value,
    $Res Function(_$ComicImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? creator = null,
    Object? title = null,
    Object? description = null,
    Object? thumb = null,
    Object? author = null,
    Object? chineseTeam = null,
    Object? categories = null,
    Object? tags = null,
    Object? pagesCount = null,
    Object? epsCount = null,
    Object? finished = null,
    Object? updatedAt = null,
    Object? createdAt = null,
    Object? allowDownload = null,
    Object? allowComment = null,
    Object? totalLikes = null,
    Object? totalViews = null,
    Object? totalComments = null,
    Object? viewsCount = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isFavourite = null,
    Object? isLiked = null,
  }) {
    return _then(
      _$ComicImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        creator:
            null == creator
                ? _value.creator
                : creator // ignore: cast_nullable_to_non_nullable
                    as Creator,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        thumb:
            null == thumb
                ? _value.thumb
                : thumb // ignore: cast_nullable_to_non_nullable
                    as Thumb,
        author:
            null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                    as String,
        chineseTeam:
            null == chineseTeam
                ? _value.chineseTeam
                : chineseTeam // ignore: cast_nullable_to_non_nullable
                    as String,
        categories:
            null == categories
                ? _value._categories
                : categories // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        tags:
            null == tags
                ? _value._tags
                : tags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        pagesCount:
            null == pagesCount
                ? _value.pagesCount
                : pagesCount // ignore: cast_nullable_to_non_nullable
                    as int,
        epsCount:
            null == epsCount
                ? _value.epsCount
                : epsCount // ignore: cast_nullable_to_non_nullable
                    as int,
        finished:
            null == finished
                ? _value.finished
                : finished // ignore: cast_nullable_to_non_nullable
                    as bool,
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        allowDownload:
            null == allowDownload
                ? _value.allowDownload
                : allowDownload // ignore: cast_nullable_to_non_nullable
                    as bool,
        allowComment:
            null == allowComment
                ? _value.allowComment
                : allowComment // ignore: cast_nullable_to_non_nullable
                    as bool,
        totalLikes:
            null == totalLikes
                ? _value.totalLikes
                : totalLikes // ignore: cast_nullable_to_non_nullable
                    as int,
        totalViews:
            null == totalViews
                ? _value.totalViews
                : totalViews // ignore: cast_nullable_to_non_nullable
                    as int,
        totalComments:
            null == totalComments
                ? _value.totalComments
                : totalComments // ignore: cast_nullable_to_non_nullable
                    as int,
        viewsCount:
            null == viewsCount
                ? _value.viewsCount
                : viewsCount // ignore: cast_nullable_to_non_nullable
                    as int,
        likesCount:
            null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                    as int,
        commentsCount:
            null == commentsCount
                ? _value.commentsCount
                : commentsCount // ignore: cast_nullable_to_non_nullable
                    as int,
        isFavourite:
            null == isFavourite
                ? _value.isFavourite
                : isFavourite // ignore: cast_nullable_to_non_nullable
                    as bool,
        isLiked:
            null == isLiked
                ? _value.isLiked
                : isLiked // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ComicImpl implements _Comic {
  const _$ComicImpl({
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "_creator") required this.creator,
    @JsonKey(name: "title") required this.title,
    @JsonKey(name: "description") required this.description,
    @JsonKey(name: "thumb") required this.thumb,
    @JsonKey(name: "author") required this.author,
    @JsonKey(name: "chineseTeam") required this.chineseTeam,
    @JsonKey(name: "categories") required final List<String> categories,
    @JsonKey(name: "tags") required final List<String> tags,
    @JsonKey(name: "pagesCount") required this.pagesCount,
    @JsonKey(name: "epsCount") required this.epsCount,
    @JsonKey(name: "finished") required this.finished,
    @JsonKey(name: "updated_at") required this.updatedAt,
    @JsonKey(name: "created_at") required this.createdAt,
    @JsonKey(name: "allowDownload") required this.allowDownload,
    @JsonKey(name: "allowComment") required this.allowComment,
    @JsonKey(name: "totalLikes") required this.totalLikes,
    @JsonKey(name: "totalViews") required this.totalViews,
    @JsonKey(name: "totalComments") required this.totalComments,
    @JsonKey(name: "viewsCount") required this.viewsCount,
    @JsonKey(name: "likesCount") required this.likesCount,
    @JsonKey(name: "commentsCount") required this.commentsCount,
    @JsonKey(name: "isFavourite") required this.isFavourite,
    @JsonKey(name: "isLiked") required this.isLiked,
  }) : _categories = categories,
       _tags = tags;

  factory _$ComicImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComicImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "_creator")
  final Creator creator;
  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "description")
  final String description;
  @override
  @JsonKey(name: "thumb")
  final Thumb thumb;
  @override
  @JsonKey(name: "author")
  final String author;
  @override
  @JsonKey(name: "chineseTeam")
  final String chineseTeam;
  final List<String> _categories;
  @override
  @JsonKey(name: "categories")
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<String> _tags;
  @override
  @JsonKey(name: "tags")
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: "pagesCount")
  final int pagesCount;
  @override
  @JsonKey(name: "epsCount")
  final int epsCount;
  @override
  @JsonKey(name: "finished")
  final bool finished;
  @override
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;
  @override
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "allowDownload")
  final bool allowDownload;
  @override
  @JsonKey(name: "allowComment")
  final bool allowComment;
  @override
  @JsonKey(name: "totalLikes")
  final int totalLikes;
  @override
  @JsonKey(name: "totalViews")
  final int totalViews;
  @override
  @JsonKey(name: "totalComments")
  final int totalComments;
  @override
  @JsonKey(name: "viewsCount")
  final int viewsCount;
  @override
  @JsonKey(name: "likesCount")
  final int likesCount;
  @override
  @JsonKey(name: "commentsCount")
  final int commentsCount;
  @override
  @JsonKey(name: "isFavourite")
  final bool isFavourite;
  @override
  @JsonKey(name: "isLiked")
  final bool isLiked;

  @override
  String toString() {
    return 'Comic(id: $id, creator: $creator, title: $title, description: $description, thumb: $thumb, author: $author, chineseTeam: $chineseTeam, categories: $categories, tags: $tags, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, updatedAt: $updatedAt, createdAt: $createdAt, allowDownload: $allowDownload, allowComment: $allowComment, totalLikes: $totalLikes, totalViews: $totalViews, totalComments: $totalComments, viewsCount: $viewsCount, likesCount: $likesCount, commentsCount: $commentsCount, isFavourite: $isFavourite, isLiked: $isLiked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComicImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.chineseTeam, chineseTeam) ||
                other.chineseTeam == chineseTeam) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.pagesCount, pagesCount) ||
                other.pagesCount == pagesCount) &&
            (identical(other.epsCount, epsCount) ||
                other.epsCount == epsCount) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.allowDownload, allowDownload) ||
                other.allowDownload == allowDownload) &&
            (identical(other.allowComment, allowComment) ||
                other.allowComment == allowComment) &&
            (identical(other.totalLikes, totalLikes) ||
                other.totalLikes == totalLikes) &&
            (identical(other.totalViews, totalViews) ||
                other.totalViews == totalViews) &&
            (identical(other.totalComments, totalComments) ||
                other.totalComments == totalComments) &&
            (identical(other.viewsCount, viewsCount) ||
                other.viewsCount == viewsCount) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.isFavourite, isFavourite) ||
                other.isFavourite == isFavourite) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    creator,
    title,
    description,
    thumb,
    author,
    chineseTeam,
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_tags),
    pagesCount,
    epsCount,
    finished,
    updatedAt,
    createdAt,
    allowDownload,
    allowComment,
    totalLikes,
    totalViews,
    totalComments,
    viewsCount,
    likesCount,
    commentsCount,
    isFavourite,
    isLiked,
  ]);

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ComicImplCopyWith<_$ComicImpl> get copyWith =>
      __$$ComicImplCopyWithImpl<_$ComicImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ComicImplToJson(this);
  }
}

abstract class _Comic implements Comic {
  const factory _Comic({
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "_creator") required final Creator creator,
    @JsonKey(name: "title") required final String title,
    @JsonKey(name: "description") required final String description,
    @JsonKey(name: "thumb") required final Thumb thumb,
    @JsonKey(name: "author") required final String author,
    @JsonKey(name: "chineseTeam") required final String chineseTeam,
    @JsonKey(name: "categories") required final List<String> categories,
    @JsonKey(name: "tags") required final List<String> tags,
    @JsonKey(name: "pagesCount") required final int pagesCount,
    @JsonKey(name: "epsCount") required final int epsCount,
    @JsonKey(name: "finished") required final bool finished,
    @JsonKey(name: "updated_at") required final DateTime updatedAt,
    @JsonKey(name: "created_at") required final DateTime createdAt,
    @JsonKey(name: "allowDownload") required final bool allowDownload,
    @JsonKey(name: "allowComment") required final bool allowComment,
    @JsonKey(name: "totalLikes") required final int totalLikes,
    @JsonKey(name: "totalViews") required final int totalViews,
    @JsonKey(name: "totalComments") required final int totalComments,
    @JsonKey(name: "viewsCount") required final int viewsCount,
    @JsonKey(name: "likesCount") required final int likesCount,
    @JsonKey(name: "commentsCount") required final int commentsCount,
    @JsonKey(name: "isFavourite") required final bool isFavourite,
    @JsonKey(name: "isLiked") required final bool isLiked,
  }) = _$ComicImpl;

  factory _Comic.fromJson(Map<String, dynamic> json) = _$ComicImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;
  @override
  @JsonKey(name: "_creator")
  Creator get creator;
  @override
  @JsonKey(name: "title")
  String get title;
  @override
  @JsonKey(name: "description")
  String get description;
  @override
  @JsonKey(name: "thumb")
  Thumb get thumb;
  @override
  @JsonKey(name: "author")
  String get author;
  @override
  @JsonKey(name: "chineseTeam")
  String get chineseTeam;
  @override
  @JsonKey(name: "categories")
  List<String> get categories;
  @override
  @JsonKey(name: "tags")
  List<String> get tags;
  @override
  @JsonKey(name: "pagesCount")
  int get pagesCount;
  @override
  @JsonKey(name: "epsCount")
  int get epsCount;
  @override
  @JsonKey(name: "finished")
  bool get finished;
  @override
  @JsonKey(name: "updated_at")
  DateTime get updatedAt;
  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;
  @override
  @JsonKey(name: "allowDownload")
  bool get allowDownload;
  @override
  @JsonKey(name: "allowComment")
  bool get allowComment;
  @override
  @JsonKey(name: "totalLikes")
  int get totalLikes;
  @override
  @JsonKey(name: "totalViews")
  int get totalViews;
  @override
  @JsonKey(name: "totalComments")
  int get totalComments;
  @override
  @JsonKey(name: "viewsCount")
  int get viewsCount;
  @override
  @JsonKey(name: "likesCount")
  int get likesCount;
  @override
  @JsonKey(name: "commentsCount")
  int get commentsCount;
  @override
  @JsonKey(name: "isFavourite")
  bool get isFavourite;
  @override
  @JsonKey(name: "isLiked")
  bool get isLiked;

  /// Create a copy of Comic
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ComicImplCopyWith<_$ComicImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Creator _$CreatorFromJson(Map<String, dynamic> json) {
  return _Creator.fromJson(json);
}

/// @nodoc
mixin _$Creator {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: "gender")
  String get gender => throw _privateConstructorUsedError;
  @JsonKey(name: "name")
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: "verified")
  bool get verified => throw _privateConstructorUsedError;
  @JsonKey(name: "exp")
  int get exp => throw _privateConstructorUsedError;
  @JsonKey(name: "level")
  int get level => throw _privateConstructorUsedError;
  @JsonKey(name: "characters")
  List<String> get characters => throw _privateConstructorUsedError;
  @JsonKey(name: "role")
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: "avatar")
  Thumb get avatar => throw _privateConstructorUsedError;
  @JsonKey(name: "slogan")
  String get slogan => throw _privateConstructorUsedError;

  /// Serializes this Creator to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatorCopyWith<Creator> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatorCopyWith<$Res> {
  factory $CreatorCopyWith(Creator value, $Res Function(Creator) then) =
      _$CreatorCopyWithImpl<$Res, Creator>;
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "gender") String gender,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "verified") bool verified,
    @JsonKey(name: "exp") int exp,
    @JsonKey(name: "level") int level,
    @JsonKey(name: "characters") List<String> characters,
    @JsonKey(name: "role") String role,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "avatar") Thumb avatar,
    @JsonKey(name: "slogan") String slogan,
  });

  $ThumbCopyWith<$Res> get avatar;
}

/// @nodoc
class _$CreatorCopyWithImpl<$Res, $Val extends Creator>
    implements $CreatorCopyWith<$Res> {
  _$CreatorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gender = null,
    Object? name = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? role = null,
    Object? title = null,
    Object? avatar = null,
    Object? slogan = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            gender:
                null == gender
                    ? _value.gender
                    : gender // ignore: cast_nullable_to_non_nullable
                        as String,
            name:
                null == name
                    ? _value.name
                    : name // ignore: cast_nullable_to_non_nullable
                        as String,
            verified:
                null == verified
                    ? _value.verified
                    : verified // ignore: cast_nullable_to_non_nullable
                        as bool,
            exp:
                null == exp
                    ? _value.exp
                    : exp // ignore: cast_nullable_to_non_nullable
                        as int,
            level:
                null == level
                    ? _value.level
                    : level // ignore: cast_nullable_to_non_nullable
                        as int,
            characters:
                null == characters
                    ? _value.characters
                    : characters // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            role:
                null == role
                    ? _value.role
                    : role // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            avatar:
                null == avatar
                    ? _value.avatar
                    : avatar // ignore: cast_nullable_to_non_nullable
                        as Thumb,
            slogan:
                null == slogan
                    ? _value.slogan
                    : slogan // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ThumbCopyWith<$Res> get avatar {
    return $ThumbCopyWith<$Res>(_value.avatar, (value) {
      return _then(_value.copyWith(avatar: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CreatorImplCopyWith<$Res> implements $CreatorCopyWith<$Res> {
  factory _$$CreatorImplCopyWith(
    _$CreatorImpl value,
    $Res Function(_$CreatorImpl) then,
  ) = __$$CreatorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "gender") String gender,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "verified") bool verified,
    @JsonKey(name: "exp") int exp,
    @JsonKey(name: "level") int level,
    @JsonKey(name: "characters") List<String> characters,
    @JsonKey(name: "role") String role,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "avatar") Thumb avatar,
    @JsonKey(name: "slogan") String slogan,
  });

  @override
  $ThumbCopyWith<$Res> get avatar;
}

/// @nodoc
class __$$CreatorImplCopyWithImpl<$Res>
    extends _$CreatorCopyWithImpl<$Res, _$CreatorImpl>
    implements _$$CreatorImplCopyWith<$Res> {
  __$$CreatorImplCopyWithImpl(
    _$CreatorImpl _value,
    $Res Function(_$CreatorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gender = null,
    Object? name = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? role = null,
    Object? title = null,
    Object? avatar = null,
    Object? slogan = null,
  }) {
    return _then(
      _$CreatorImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        gender:
            null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                    as String,
        name:
            null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                    as String,
        verified:
            null == verified
                ? _value.verified
                : verified // ignore: cast_nullable_to_non_nullable
                    as bool,
        exp:
            null == exp
                ? _value.exp
                : exp // ignore: cast_nullable_to_non_nullable
                    as int,
        level:
            null == level
                ? _value.level
                : level // ignore: cast_nullable_to_non_nullable
                    as int,
        characters:
            null == characters
                ? _value._characters
                : characters // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        role:
            null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        avatar:
            null == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                    as Thumb,
        slogan:
            null == slogan
                ? _value.slogan
                : slogan // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CreatorImpl implements _Creator {
  const _$CreatorImpl({
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "gender") required this.gender,
    @JsonKey(name: "name") required this.name,
    @JsonKey(name: "verified") required this.verified,
    @JsonKey(name: "exp") required this.exp,
    @JsonKey(name: "level") required this.level,
    @JsonKey(name: "characters") required final List<String> characters,
    @JsonKey(name: "role") required this.role,
    @JsonKey(name: "title") required this.title,
    @JsonKey(name: "avatar") required this.avatar,
    @JsonKey(name: "slogan") required this.slogan,
  }) : _characters = characters;

  factory _$CreatorImpl.fromJson(Map<String, dynamic> json) =>
      _$$CreatorImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "gender")
  final String gender;
  @override
  @JsonKey(name: "name")
  final String name;
  @override
  @JsonKey(name: "verified")
  final bool verified;
  @override
  @JsonKey(name: "exp")
  final int exp;
  @override
  @JsonKey(name: "level")
  final int level;
  final List<String> _characters;
  @override
  @JsonKey(name: "characters")
  List<String> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  @override
  @JsonKey(name: "role")
  final String role;
  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "avatar")
  final Thumb avatar;
  @override
  @JsonKey(name: "slogan")
  final String slogan;

  @override
  String toString() {
    return 'Creator(id: $id, gender: $gender, name: $name, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, title: $title, avatar: $avatar, slogan: $slogan)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.exp, exp) || other.exp == exp) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(
              other._characters,
              _characters,
            ) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.slogan, slogan) || other.slogan == slogan));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    gender,
    name,
    verified,
    exp,
    level,
    const DeepCollectionEquality().hash(_characters),
    role,
    title,
    avatar,
    slogan,
  );

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatorImplCopyWith<_$CreatorImpl> get copyWith =>
      __$$CreatorImplCopyWithImpl<_$CreatorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CreatorImplToJson(this);
  }
}

abstract class _Creator implements Creator {
  const factory _Creator({
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "gender") required final String gender,
    @JsonKey(name: "name") required final String name,
    @JsonKey(name: "verified") required final bool verified,
    @JsonKey(name: "exp") required final int exp,
    @JsonKey(name: "level") required final int level,
    @JsonKey(name: "characters") required final List<String> characters,
    @JsonKey(name: "role") required final String role,
    @JsonKey(name: "title") required final String title,
    @JsonKey(name: "avatar") required final Thumb avatar,
    @JsonKey(name: "slogan") required final String slogan,
  }) = _$CreatorImpl;

  factory _Creator.fromJson(Map<String, dynamic> json) = _$CreatorImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;
  @override
  @JsonKey(name: "gender")
  String get gender;
  @override
  @JsonKey(name: "name")
  String get name;
  @override
  @JsonKey(name: "verified")
  bool get verified;
  @override
  @JsonKey(name: "exp")
  int get exp;
  @override
  @JsonKey(name: "level")
  int get level;
  @override
  @JsonKey(name: "characters")
  List<String> get characters;
  @override
  @JsonKey(name: "role")
  String get role;
  @override
  @JsonKey(name: "title")
  String get title;
  @override
  @JsonKey(name: "avatar")
  Thumb get avatar;
  @override
  @JsonKey(name: "slogan")
  String get slogan;

  /// Create a copy of Creator
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatorImplCopyWith<_$CreatorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Thumb _$ThumbFromJson(Map<String, dynamic> json) {
  return _Thumb.fromJson(json);
}

/// @nodoc
mixin _$Thumb {
  @JsonKey(name: "originalName")
  String get originalName => throw _privateConstructorUsedError;
  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;
  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

  /// Serializes this Thumb to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThumbCopyWith<Thumb> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThumbCopyWith<$Res> {
  factory $ThumbCopyWith(Thumb value, $Res Function(Thumb) then) =
      _$ThumbCopyWithImpl<$Res, Thumb>;
  @useResult
  $Res call({
    @JsonKey(name: "originalName") String originalName,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "fileServer") String fileServer,
  });
}

/// @nodoc
class _$ThumbCopyWithImpl<$Res, $Val extends Thumb>
    implements $ThumbCopyWith<$Res> {
  _$ThumbCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(
      _value.copyWith(
            originalName:
                null == originalName
                    ? _value.originalName
                    : originalName // ignore: cast_nullable_to_non_nullable
                        as String,
            path:
                null == path
                    ? _value.path
                    : path // ignore: cast_nullable_to_non_nullable
                        as String,
            fileServer:
                null == fileServer
                    ? _value.fileServer
                    : fileServer // ignore: cast_nullable_to_non_nullable
                        as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ThumbImplCopyWith<$Res> implements $ThumbCopyWith<$Res> {
  factory _$$ThumbImplCopyWith(
    _$ThumbImpl value,
    $Res Function(_$ThumbImpl) then,
  ) = __$$ThumbImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "originalName") String originalName,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "fileServer") String fileServer,
  });
}

/// @nodoc
class __$$ThumbImplCopyWithImpl<$Res>
    extends _$ThumbCopyWithImpl<$Res, _$ThumbImpl>
    implements _$$ThumbImplCopyWith<$Res> {
  __$$ThumbImplCopyWithImpl(
    _$ThumbImpl _value,
    $Res Function(_$ThumbImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(
      _$ThumbImpl(
        originalName:
            null == originalName
                ? _value.originalName
                : originalName // ignore: cast_nullable_to_non_nullable
                    as String,
        path:
            null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                    as String,
        fileServer:
            null == fileServer
                ? _value.fileServer
                : fileServer // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ThumbImpl implements _Thumb {
  const _$ThumbImpl({
    @JsonKey(name: "originalName") required this.originalName,
    @JsonKey(name: "path") required this.path,
    @JsonKey(name: "fileServer") required this.fileServer,
  });

  factory _$ThumbImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThumbImplFromJson(json);

  @override
  @JsonKey(name: "originalName")
  final String originalName;
  @override
  @JsonKey(name: "path")
  final String path;
  @override
  @JsonKey(name: "fileServer")
  final String fileServer;

  @override
  String toString() {
    return 'Thumb(originalName: $originalName, path: $path, fileServer: $fileServer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThumbImpl &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalName, path, fileServer);

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThumbImplCopyWith<_$ThumbImpl> get copyWith =>
      __$$ThumbImplCopyWithImpl<_$ThumbImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThumbImplToJson(this);
  }
}

abstract class _Thumb implements Thumb {
  const factory _Thumb({
    @JsonKey(name: "originalName") required final String originalName,
    @JsonKey(name: "path") required final String path,
    @JsonKey(name: "fileServer") required final String fileServer,
  }) = _$ThumbImpl;

  factory _Thumb.fromJson(Map<String, dynamic> json) = _$ThumbImpl.fromJson;

  @override
  @JsonKey(name: "originalName")
  String get originalName;
  @override
  @JsonKey(name: "path")
  String get path;
  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThumbImplCopyWith<_$ThumbImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
