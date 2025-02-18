// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comments_children_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

CommentsChildrenJson _$CommentsChildrenJsonFromJson(Map<String, dynamic> json) {
  return _CommentsChildrenJson.fromJson(json);
}

/// @nodoc
mixin _$CommentsChildrenJson {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;

  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;

  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this CommentsChildrenJson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CommentsChildrenJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentsChildrenJsonCopyWith<CommentsChildrenJson> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentsChildrenJsonCopyWith<$Res> {
  factory $CommentsChildrenJsonCopyWith(
    CommentsChildrenJson value,
    $Res Function(CommentsChildrenJson) then,
  ) = _$CommentsChildrenJsonCopyWithImpl<$Res, CommentsChildrenJson>;

  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$CommentsChildrenJsonCopyWithImpl<
  $Res,
  $Val extends CommentsChildrenJson
>
    implements $CommentsChildrenJsonCopyWith<$Res> {
  _$CommentsChildrenJsonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CommentsChildrenJson
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

  /// Create a copy of CommentsChildrenJson
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
abstract class _$$CommentsChildrenJsonImplCopyWith<$Res>
    implements $CommentsChildrenJsonCopyWith<$Res> {
  factory _$$CommentsChildrenJsonImplCopyWith(
    _$CommentsChildrenJsonImpl value,
    $Res Function(_$CommentsChildrenJsonImpl) then,
  ) = __$$CommentsChildrenJsonImplCopyWithImpl<$Res>;

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
class __$$CommentsChildrenJsonImplCopyWithImpl<$Res>
    extends _$CommentsChildrenJsonCopyWithImpl<$Res, _$CommentsChildrenJsonImpl>
    implements _$$CommentsChildrenJsonImplCopyWith<$Res> {
  __$$CommentsChildrenJsonImplCopyWithImpl(
    _$CommentsChildrenJsonImpl _value,
    $Res Function(_$CommentsChildrenJsonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CommentsChildrenJson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _$CommentsChildrenJsonImpl(
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
class _$CommentsChildrenJsonImpl implements _CommentsChildrenJson {
  const _$CommentsChildrenJsonImpl({
    @JsonKey(name: "code") required this.code,
    @JsonKey(name: "message") required this.message,
    @JsonKey(name: "data") required this.data,
  });

  factory _$CommentsChildrenJsonImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentsChildrenJsonImplFromJson(json);

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
    return 'CommentsChildrenJson(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentsChildrenJsonImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of CommentsChildrenJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentsChildrenJsonImplCopyWith<_$CommentsChildrenJsonImpl>
  get copyWith =>
      __$$CommentsChildrenJsonImplCopyWithImpl<_$CommentsChildrenJsonImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentsChildrenJsonImplToJson(this);
  }
}

abstract class _CommentsChildrenJson implements CommentsChildrenJson {
  const factory _CommentsChildrenJson({
    @JsonKey(name: "code") required final int code,
    @JsonKey(name: "message") required final String message,
    @JsonKey(name: "data") required final Data data,
  }) = _$CommentsChildrenJsonImpl;

  factory _CommentsChildrenJson.fromJson(Map<String, dynamic> json) =
      _$CommentsChildrenJsonImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;

  @override
  @JsonKey(name: "message")
  String get message;

  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of CommentsChildrenJson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentsChildrenJsonImplCopyWith<_$CommentsChildrenJsonImpl>
  get copyWith => throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "comments")
  Comments get comments => throw _privateConstructorUsedError;

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
  $Res call({@JsonKey(name: "comments") Comments comments});

  $CommentsCopyWith<$Res> get comments;
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
  $Res call({Object? comments = null}) {
    return _then(
      _value.copyWith(
            comments:
                null == comments
                    ? _value.comments
                    : comments // ignore: cast_nullable_to_non_nullable
                        as Comments,
          )
          as $Val,
    );
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CommentsCopyWith<$Res> get comments {
    return $CommentsCopyWith<$Res>(_value.comments, (value) {
      return _then(_value.copyWith(comments: value) as $Val);
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
  $Res call({@JsonKey(name: "comments") Comments comments});

  @override
  $CommentsCopyWith<$Res> get comments;
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
  $Res call({Object? comments = null}) {
    return _then(
      _$DataImpl(
        comments:
            null == comments
                ? _value.comments
                : comments // ignore: cast_nullable_to_non_nullable
                    as Comments,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl({@JsonKey(name: "comments") required this.comments});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  @JsonKey(name: "comments")
  final Comments comments;

  @override
  String toString() {
    return 'Data(comments: $comments)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.comments, comments) ||
                other.comments == comments));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, comments);

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
  const factory _Data({
    @JsonKey(name: "comments") required final Comments comments,
  }) = _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "comments")
  Comments get comments;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Comments _$CommentsFromJson(Map<String, dynamic> json) {
  return _Comments.fromJson(json);
}

/// @nodoc
mixin _$Comments {
  @JsonKey(name: "docs")
  List<Doc> get docs => throw _privateConstructorUsedError;

  @JsonKey(name: "total")
  int get total => throw _privateConstructorUsedError;

  @JsonKey(name: "limit")
  int get limit => throw _privateConstructorUsedError;

  @JsonKey(name: "page")
  String get page => throw _privateConstructorUsedError;

  @JsonKey(name: "pages")
  int get pages => throw _privateConstructorUsedError;

  /// Serializes this Comments to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Comments
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CommentsCopyWith<Comments> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentsCopyWith<$Res> {
  factory $CommentsCopyWith(Comments value, $Res Function(Comments) then) =
      _$CommentsCopyWithImpl<$Res, Comments>;

  @useResult
  $Res call({
    @JsonKey(name: "docs") List<Doc> docs,
    @JsonKey(name: "total") int total,
    @JsonKey(name: "limit") int limit,
    @JsonKey(name: "page") String page,
    @JsonKey(name: "pages") int pages,
  });
}

/// @nodoc
class _$CommentsCopyWithImpl<$Res, $Val extends Comments>
    implements $CommentsCopyWith<$Res> {
  _$CommentsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Comments
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docs = null,
    Object? total = null,
    Object? limit = null,
    Object? page = null,
    Object? pages = null,
  }) {
    return _then(
      _value.copyWith(
            docs:
                null == docs
                    ? _value.docs
                    : docs // ignore: cast_nullable_to_non_nullable
                        as List<Doc>,
            total:
                null == total
                    ? _value.total
                    : total // ignore: cast_nullable_to_non_nullable
                        as int,
            limit:
                null == limit
                    ? _value.limit
                    : limit // ignore: cast_nullable_to_non_nullable
                        as int,
            page:
                null == page
                    ? _value.page
                    : page // ignore: cast_nullable_to_non_nullable
                        as String,
            pages:
                null == pages
                    ? _value.pages
                    : pages // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CommentsImplCopyWith<$Res>
    implements $CommentsCopyWith<$Res> {
  factory _$$CommentsImplCopyWith(
    _$CommentsImpl value,
    $Res Function(_$CommentsImpl) then,
  ) = __$$CommentsImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "docs") List<Doc> docs,
    @JsonKey(name: "total") int total,
    @JsonKey(name: "limit") int limit,
    @JsonKey(name: "page") String page,
    @JsonKey(name: "pages") int pages,
  });
}

/// @nodoc
class __$$CommentsImplCopyWithImpl<$Res>
    extends _$CommentsCopyWithImpl<$Res, _$CommentsImpl>
    implements _$$CommentsImplCopyWith<$Res> {
  __$$CommentsImplCopyWithImpl(
    _$CommentsImpl _value,
    $Res Function(_$CommentsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Comments
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? docs = null,
    Object? total = null,
    Object? limit = null,
    Object? page = null,
    Object? pages = null,
  }) {
    return _then(
      _$CommentsImpl(
        docs:
            null == docs
                ? _value._docs
                : docs // ignore: cast_nullable_to_non_nullable
                    as List<Doc>,
        total:
            null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                    as int,
        limit:
            null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                    as int,
        page:
            null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                    as String,
        pages:
            null == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentsImpl implements _Comments {
  const _$CommentsImpl({
    @JsonKey(name: "docs") required final List<Doc> docs,
    @JsonKey(name: "total") required this.total,
    @JsonKey(name: "limit") required this.limit,
    @JsonKey(name: "page") required this.page,
    @JsonKey(name: "pages") required this.pages,
  }) : _docs = docs;

  factory _$CommentsImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentsImplFromJson(json);

  final List<Doc> _docs;

  @override
  @JsonKey(name: "docs")
  List<Doc> get docs {
    if (_docs is EqualUnmodifiableListView) return _docs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_docs);
  }

  @override
  @JsonKey(name: "total")
  final int total;
  @override
  @JsonKey(name: "limit")
  final int limit;
  @override
  @JsonKey(name: "page")
  final String page;
  @override
  @JsonKey(name: "pages")
  final int pages;

  @override
  String toString() {
    return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentsImpl &&
            const DeepCollectionEquality().equals(other._docs, _docs) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pages, pages) || other.pages == pages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_docs),
    total,
    limit,
    page,
    pages,
  );

  /// Create a copy of Comments
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentsImplCopyWith<_$CommentsImpl> get copyWith =>
      __$$CommentsImplCopyWithImpl<_$CommentsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentsImplToJson(this);
  }
}

abstract class _Comments implements Comments {
  const factory _Comments({
    @JsonKey(name: "docs") required final List<Doc> docs,
    @JsonKey(name: "total") required final int total,
    @JsonKey(name: "limit") required final int limit,
    @JsonKey(name: "page") required final String page,
    @JsonKey(name: "pages") required final int pages,
  }) = _$CommentsImpl;

  factory _Comments.fromJson(Map<String, dynamic> json) =
      _$CommentsImpl.fromJson;

  @override
  @JsonKey(name: "docs")
  List<Doc> get docs;

  @override
  @JsonKey(name: "total")
  int get total;

  @override
  @JsonKey(name: "limit")
  int get limit;

  @override
  @JsonKey(name: "page")
  String get page;

  @override
  @JsonKey(name: "pages")
  int get pages;

  /// Create a copy of Comments
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CommentsImplCopyWith<_$CommentsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Doc _$DocFromJson(Map<String, dynamic> json) {
  return _Doc.fromJson(json);
}

/// @nodoc
mixin _$Doc {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "content")
  String get content => throw _privateConstructorUsedError;

  @JsonKey(name: "_user")
  User get user => throw _privateConstructorUsedError;

  @JsonKey(name: "_parent")
  String get parent => throw _privateConstructorUsedError;

  @JsonKey(name: "_comic")
  String get comic => throw _privateConstructorUsedError;

  @JsonKey(name: "totalComments")
  int get totalComments => throw _privateConstructorUsedError;

  @JsonKey(name: "isTop")
  bool get isTop => throw _privateConstructorUsedError;

  @JsonKey(name: "hide")
  bool get hide => throw _privateConstructorUsedError;

  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;

  @JsonKey(name: "id")
  String get docId => throw _privateConstructorUsedError;

  @JsonKey(name: "likesCount")
  int get likesCount => throw _privateConstructorUsedError;

  @JsonKey(name: "isLiked")
  bool get isLiked => throw _privateConstructorUsedError;

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DocCopyWith<Doc> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DocCopyWith<$Res> {
  factory $DocCopyWith(Doc value, $Res Function(Doc) then) =
      _$DocCopyWithImpl<$Res, Doc>;

  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "content") String content,
    @JsonKey(name: "_user") User user,
    @JsonKey(name: "_parent") String parent,
    @JsonKey(name: "_comic") String comic,
    @JsonKey(name: "totalComments") int totalComments,
    @JsonKey(name: "isTop") bool isTop,
    @JsonKey(name: "hide") bool hide,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "id") String docId,
    @JsonKey(name: "likesCount") int likesCount,
    @JsonKey(name: "isLiked") bool isLiked,
  });

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$DocCopyWithImpl<$Res, $Val extends Doc> implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? user = null,
    Object? parent = null,
    Object? comic = null,
    Object? totalComments = null,
    Object? isTop = null,
    Object? hide = null,
    Object? createdAt = null,
    Object? docId = null,
    Object? likesCount = null,
    Object? isLiked = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            content:
                null == content
                    ? _value.content
                    : content // ignore: cast_nullable_to_non_nullable
                        as String,
            user:
                null == user
                    ? _value.user
                    : user // ignore: cast_nullable_to_non_nullable
                        as User,
            parent:
                null == parent
                    ? _value.parent
                    : parent // ignore: cast_nullable_to_non_nullable
                        as String,
            comic:
                null == comic
                    ? _value.comic
                    : comic // ignore: cast_nullable_to_non_nullable
                        as String,
            totalComments:
                null == totalComments
                    ? _value.totalComments
                    : totalComments // ignore: cast_nullable_to_non_nullable
                        as int,
            isTop:
                null == isTop
                    ? _value.isTop
                    : isTop // ignore: cast_nullable_to_non_nullable
                        as bool,
            hide:
                null == hide
                    ? _value.hide
                    : hide // ignore: cast_nullable_to_non_nullable
                        as bool,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            docId:
                null == docId
                    ? _value.docId
                    : docId // ignore: cast_nullable_to_non_nullable
                        as String,
            likesCount:
                null == likesCount
                    ? _value.likesCount
                    : likesCount // ignore: cast_nullable_to_non_nullable
                        as int,
            isLiked:
                null == isLiked
                    ? _value.isLiked
                    : isLiked // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DocImplCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$$DocImplCopyWith(_$DocImpl value, $Res Function(_$DocImpl) then) =
      __$$DocImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "content") String content,
    @JsonKey(name: "_user") User user,
    @JsonKey(name: "_parent") String parent,
    @JsonKey(name: "_comic") String comic,
    @JsonKey(name: "totalComments") int totalComments,
    @JsonKey(name: "isTop") bool isTop,
    @JsonKey(name: "hide") bool hide,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "id") String docId,
    @JsonKey(name: "likesCount") int likesCount,
    @JsonKey(name: "isLiked") bool isLiked,
  });

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$$DocImplCopyWithImpl<$Res> extends _$DocCopyWithImpl<$Res, _$DocImpl>
    implements _$$DocImplCopyWith<$Res> {
  __$$DocImplCopyWithImpl(_$DocImpl _value, $Res Function(_$DocImpl) _then)
    : super(_value, _then);

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? user = null,
    Object? parent = null,
    Object? comic = null,
    Object? totalComments = null,
    Object? isTop = null,
    Object? hide = null,
    Object? createdAt = null,
    Object? docId = null,
    Object? likesCount = null,
    Object? isLiked = null,
  }) {
    return _then(
      _$DocImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        content:
            null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                    as String,
        user:
            null == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                    as User,
        parent:
            null == parent
                ? _value.parent
                : parent // ignore: cast_nullable_to_non_nullable
                    as String,
        comic:
            null == comic
                ? _value.comic
                : comic // ignore: cast_nullable_to_non_nullable
                    as String,
        totalComments:
            null == totalComments
                ? _value.totalComments
                : totalComments // ignore: cast_nullable_to_non_nullable
                    as int,
        isTop:
            null == isTop
                ? _value.isTop
                : isTop // ignore: cast_nullable_to_non_nullable
                    as bool,
        hide:
            null == hide
                ? _value.hide
                : hide // ignore: cast_nullable_to_non_nullable
                    as bool,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        docId:
            null == docId
                ? _value.docId
                : docId // ignore: cast_nullable_to_non_nullable
                    as String,
        likesCount:
            null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                    as int,
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
class _$DocImpl implements _Doc {
  const _$DocImpl({
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "content") required this.content,
    @JsonKey(name: "_user") required this.user,
    @JsonKey(name: "_parent") required this.parent,
    @JsonKey(name: "_comic") required this.comic,
    @JsonKey(name: "totalComments") required this.totalComments,
    @JsonKey(name: "isTop") required this.isTop,
    @JsonKey(name: "hide") required this.hide,
    @JsonKey(name: "created_at") required this.createdAt,
    @JsonKey(name: "id") required this.docId,
    @JsonKey(name: "likesCount") required this.likesCount,
    @JsonKey(name: "isLiked") required this.isLiked,
  });

  factory _$DocImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "content")
  final String content;
  @override
  @JsonKey(name: "_user")
  final User user;
  @override
  @JsonKey(name: "_parent")
  final String parent;
  @override
  @JsonKey(name: "_comic")
  final String comic;
  @override
  @JsonKey(name: "totalComments")
  final int totalComments;
  @override
  @JsonKey(name: "isTop")
  final bool isTop;
  @override
  @JsonKey(name: "hide")
  final bool hide;
  @override
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "id")
  final String docId;
  @override
  @JsonKey(name: "likesCount")
  final int likesCount;
  @override
  @JsonKey(name: "isLiked")
  final bool isLiked;

  @override
  String toString() {
    return 'Doc(id: $id, content: $content, user: $user, parent: $parent, comic: $comic, totalComments: $totalComments, isTop: $isTop, hide: $hide, createdAt: $createdAt, docId: $docId, likesCount: $likesCount, isLiked: $isLiked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.parent, parent) || other.parent == parent) &&
            (identical(other.comic, comic) || other.comic == comic) &&
            (identical(other.totalComments, totalComments) ||
                other.totalComments == totalComments) &&
            (identical(other.isTop, isTop) || other.isTop == isTop) &&
            (identical(other.hide, hide) || other.hide == hide) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.docId, docId) || other.docId == docId) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    user,
    parent,
    comic,
    totalComments,
    isTop,
    hide,
    createdAt,
    docId,
    likesCount,
    isLiked,
  );

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocImplCopyWith<_$DocImpl> get copyWith =>
      __$$DocImplCopyWithImpl<_$DocImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DocImplToJson(this);
  }
}

abstract class _Doc implements Doc {
  const factory _Doc({
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "content") required final String content,
    @JsonKey(name: "_user") required final User user,
    @JsonKey(name: "_parent") required final String parent,
    @JsonKey(name: "_comic") required final String comic,
    @JsonKey(name: "totalComments") required final int totalComments,
    @JsonKey(name: "isTop") required final bool isTop,
    @JsonKey(name: "hide") required final bool hide,
    @JsonKey(name: "created_at") required final DateTime createdAt,
    @JsonKey(name: "id") required final String docId,
    @JsonKey(name: "likesCount") required final int likesCount,
    @JsonKey(name: "isLiked") required final bool isLiked,
  }) = _$DocImpl;

  factory _Doc.fromJson(Map<String, dynamic> json) = _$DocImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;

  @override
  @JsonKey(name: "content")
  String get content;

  @override
  @JsonKey(name: "_user")
  User get user;

  @override
  @JsonKey(name: "_parent")
  String get parent;

  @override
  @JsonKey(name: "_comic")
  String get comic;

  @override
  @JsonKey(name: "totalComments")
  int get totalComments;

  @override
  @JsonKey(name: "isTop")
  bool get isTop;

  @override
  @JsonKey(name: "hide")
  bool get hide;

  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;

  @override
  @JsonKey(name: "id")
  String get docId;

  @override
  @JsonKey(name: "likesCount")
  int get likesCount;

  @override
  @JsonKey(name: "isLiked")
  bool get isLiked;

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocImplCopyWith<_$DocImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

User _$UserFromJson(Map<String, dynamic> json) {
  return _User.fromJson(json);
}

/// @nodoc
mixin _$User {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "gender")
  String get gender => throw _privateConstructorUsedError;

  @JsonKey(name: "name")
  String get name => throw _privateConstructorUsedError;

  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;

  @JsonKey(name: "verified")
  bool get verified => throw _privateConstructorUsedError;

  @JsonKey(name: "exp")
  int get exp => throw _privateConstructorUsedError;

  @JsonKey(name: "level")
  int get level => throw _privateConstructorUsedError;

  @JsonKey(name: "characters")
  List<dynamic> get characters => throw _privateConstructorUsedError;

  @JsonKey(name: "role")
  String get role => throw _privateConstructorUsedError;

  @JsonKey(name: "avatar")
  Avatar? get avatar => throw _privateConstructorUsedError;

  @JsonKey(name: "slogan")
  String? get slogan => throw _privateConstructorUsedError;

  @JsonKey(name: "character")
  String? get character => throw _privateConstructorUsedError;

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserCopyWith<User> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) then) =
      _$UserCopyWithImpl<$Res, User>;

  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "gender") String gender,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "verified") bool verified,
    @JsonKey(name: "exp") int exp,
    @JsonKey(name: "level") int level,
    @JsonKey(name: "characters") List<dynamic> characters,
    @JsonKey(name: "role") String role,
    @JsonKey(name: "avatar") Avatar? avatar,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "character") String? character,
  });

  $AvatarCopyWith<$Res>? get avatar;
}

/// @nodoc
class _$UserCopyWithImpl<$Res, $Val extends User>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gender = null,
    Object? name = null,
    Object? title = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? role = null,
    Object? avatar = freezed,
    Object? slogan = freezed,
    Object? character = freezed,
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
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
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
                        as List<dynamic>,
            role:
                null == role
                    ? _value.role
                    : role // ignore: cast_nullable_to_non_nullable
                        as String,
            avatar:
                freezed == avatar
                    ? _value.avatar
                    : avatar // ignore: cast_nullable_to_non_nullable
                        as Avatar?,
            slogan:
                freezed == slogan
                    ? _value.slogan
                    : slogan // ignore: cast_nullable_to_non_nullable
                        as String?,
            character:
                freezed == character
                    ? _value.character
                    : character // ignore: cast_nullable_to_non_nullable
                        as String?,
          )
          as $Val,
    );
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AvatarCopyWith<$Res>? get avatar {
    if (_value.avatar == null) {
      return null;
    }

    return $AvatarCopyWith<$Res>(_value.avatar!, (value) {
      return _then(_value.copyWith(avatar: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserImplCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$$UserImplCopyWith(
    _$UserImpl value,
    $Res Function(_$UserImpl) then,
  ) = __$$UserImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "gender") String gender,
    @JsonKey(name: "name") String name,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "verified") bool verified,
    @JsonKey(name: "exp") int exp,
    @JsonKey(name: "level") int level,
    @JsonKey(name: "characters") List<dynamic> characters,
    @JsonKey(name: "role") String role,
    @JsonKey(name: "avatar") Avatar? avatar,
    @JsonKey(name: "slogan") String? slogan,
    @JsonKey(name: "character") String? character,
  });

  @override
  $AvatarCopyWith<$Res>? get avatar;
}

/// @nodoc
class __$$UserImplCopyWithImpl<$Res>
    extends _$UserCopyWithImpl<$Res, _$UserImpl>
    implements _$$UserImplCopyWith<$Res> {
  __$$UserImplCopyWithImpl(_$UserImpl _value, $Res Function(_$UserImpl) _then)
    : super(_value, _then);

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? gender = null,
    Object? name = null,
    Object? title = null,
    Object? verified = null,
    Object? exp = null,
    Object? level = null,
    Object? characters = null,
    Object? role = null,
    Object? avatar = freezed,
    Object? slogan = freezed,
    Object? character = freezed,
  }) {
    return _then(
      _$UserImpl(
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
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
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
                    as List<dynamic>,
        role:
            null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                    as String,
        avatar:
            freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                    as Avatar?,
        slogan:
            freezed == slogan
                ? _value.slogan
                : slogan // ignore: cast_nullable_to_non_nullable
                    as String?,
        character:
            freezed == character
                ? _value.character
                : character // ignore: cast_nullable_to_non_nullable
                    as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserImpl implements _User {
  const _$UserImpl({
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "gender") required this.gender,
    @JsonKey(name: "name") required this.name,
    @JsonKey(name: "title") required this.title,
    @JsonKey(name: "verified") required this.verified,
    @JsonKey(name: "exp") required this.exp,
    @JsonKey(name: "level") required this.level,
    @JsonKey(name: "characters") required final List<dynamic> characters,
    @JsonKey(name: "role") required this.role,
    @JsonKey(name: "avatar") this.avatar,
    @JsonKey(name: "slogan") this.slogan,
    @JsonKey(name: "character") this.character,
  }) : _characters = characters;

  factory _$UserImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserImplFromJson(json);

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
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "verified")
  final bool verified;
  @override
  @JsonKey(name: "exp")
  final int exp;
  @override
  @JsonKey(name: "level")
  final int level;
  final List<dynamic> _characters;

  @override
  @JsonKey(name: "characters")
  List<dynamic> get characters {
    if (_characters is EqualUnmodifiableListView) return _characters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_characters);
  }

  @override
  @JsonKey(name: "role")
  final String role;
  @override
  @JsonKey(name: "avatar")
  final Avatar? avatar;
  @override
  @JsonKey(name: "slogan")
  final String? slogan;
  @override
  @JsonKey(name: "character")
  final String? character;

  @override
  String toString() {
    return 'User(id: $id, gender: $gender, name: $name, title: $title, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, avatar: $avatar, slogan: $slogan, character: $character)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.verified, verified) ||
                other.verified == verified) &&
            (identical(other.exp, exp) || other.exp == exp) &&
            (identical(other.level, level) || other.level == level) &&
            const DeepCollectionEquality().equals(
              other._characters,
              _characters,
            ) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.slogan, slogan) || other.slogan == slogan) &&
            (identical(other.character, character) ||
                other.character == character));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    gender,
    name,
    title,
    verified,
    exp,
    level,
    const DeepCollectionEquality().hash(_characters),
    role,
    avatar,
    slogan,
    character,
  );

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      __$$UserImplCopyWithImpl<_$UserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserImplToJson(this);
  }
}

abstract class _User implements User {
  const factory _User({
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "gender") required final String gender,
    @JsonKey(name: "name") required final String name,
    @JsonKey(name: "title") required final String title,
    @JsonKey(name: "verified") required final bool verified,
    @JsonKey(name: "exp") required final int exp,
    @JsonKey(name: "level") required final int level,
    @JsonKey(name: "characters") required final List<dynamic> characters,
    @JsonKey(name: "role") required final String role,
    @JsonKey(name: "avatar") final Avatar? avatar,
    @JsonKey(name: "slogan") final String? slogan,
    @JsonKey(name: "character") final String? character,
  }) = _$UserImpl;

  factory _User.fromJson(Map<String, dynamic> json) = _$UserImpl.fromJson;

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
  @JsonKey(name: "title")
  String get title;

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
  List<dynamic> get characters;

  @override
  @JsonKey(name: "role")
  String get role;

  @override
  @JsonKey(name: "avatar")
  Avatar? get avatar;

  @override
  @JsonKey(name: "slogan")
  String? get slogan;

  @override
  @JsonKey(name: "character")
  String? get character;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserImplCopyWith<_$UserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Avatar _$AvatarFromJson(Map<String, dynamic> json) {
  return _Avatar.fromJson(json);
}

/// @nodoc
mixin _$Avatar {
  @JsonKey(name: "originalName")
  String get originalName => throw _privateConstructorUsedError;

  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;

  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

  /// Serializes this Avatar to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AvatarCopyWith<Avatar> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AvatarCopyWith<$Res> {
  factory $AvatarCopyWith(Avatar value, $Res Function(Avatar) then) =
      _$AvatarCopyWithImpl<$Res, Avatar>;

  @useResult
  $Res call({
    @JsonKey(name: "originalName") String originalName,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "fileServer") String fileServer,
  });
}

/// @nodoc
class _$AvatarCopyWithImpl<$Res, $Val extends Avatar>
    implements $AvatarCopyWith<$Res> {
  _$AvatarCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Avatar
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
abstract class _$$AvatarImplCopyWith<$Res> implements $AvatarCopyWith<$Res> {
  factory _$$AvatarImplCopyWith(
    _$AvatarImpl value,
    $Res Function(_$AvatarImpl) then,
  ) = __$$AvatarImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({
    @JsonKey(name: "originalName") String originalName,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "fileServer") String fileServer,
  });
}

/// @nodoc
class __$$AvatarImplCopyWithImpl<$Res>
    extends _$AvatarCopyWithImpl<$Res, _$AvatarImpl>
    implements _$$AvatarImplCopyWith<$Res> {
  __$$AvatarImplCopyWithImpl(
    _$AvatarImpl _value,
    $Res Function(_$AvatarImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(
      _$AvatarImpl(
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
class _$AvatarImpl implements _Avatar {
  const _$AvatarImpl({
    @JsonKey(name: "originalName") required this.originalName,
    @JsonKey(name: "path") required this.path,
    @JsonKey(name: "fileServer") required this.fileServer,
  });

  factory _$AvatarImpl.fromJson(Map<String, dynamic> json) =>
      _$$AvatarImplFromJson(json);

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
    return 'Avatar(originalName: $originalName, path: $path, fileServer: $fileServer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AvatarImpl &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalName, path, fileServer);

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AvatarImplCopyWith<_$AvatarImpl> get copyWith =>
      __$$AvatarImplCopyWithImpl<_$AvatarImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AvatarImplToJson(this);
  }
}

abstract class _Avatar implements Avatar {
  const factory _Avatar({
    @JsonKey(name: "originalName") required final String originalName,
    @JsonKey(name: "path") required final String path,
    @JsonKey(name: "fileServer") required final String fileServer,
  }) = _$AvatarImpl;

  factory _Avatar.fromJson(Map<String, dynamic> json) = _$AvatarImpl.fromJson;

  @override
  @JsonKey(name: "originalName")
  String get originalName;

  @override
  @JsonKey(name: "path")
  String get path;

  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  /// Create a copy of Avatar
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AvatarImplCopyWith<_$AvatarImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
