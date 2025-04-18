// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'advanced_search.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AdvancedSearch _$AdvancedSearchFromJson(Map<String, dynamic> json) {
  return _AdvancedSearch.fromJson(json);
}

/// @nodoc
mixin _$AdvancedSearch {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;
  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this AdvancedSearch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AdvancedSearch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AdvancedSearchCopyWith<AdvancedSearch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AdvancedSearchCopyWith<$Res> {
  factory $AdvancedSearchCopyWith(
    AdvancedSearch value,
    $Res Function(AdvancedSearch) then,
  ) = _$AdvancedSearchCopyWithImpl<$Res, AdvancedSearch>;
  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$AdvancedSearchCopyWithImpl<$Res, $Val extends AdvancedSearch>
    implements $AdvancedSearchCopyWith<$Res> {
  _$AdvancedSearchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AdvancedSearch
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

  /// Create a copy of AdvancedSearch
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
abstract class _$$AdvancedSearchImplCopyWith<$Res>
    implements $AdvancedSearchCopyWith<$Res> {
  factory _$$AdvancedSearchImplCopyWith(
    _$AdvancedSearchImpl value,
    $Res Function(_$AdvancedSearchImpl) then,
  ) = __$$AdvancedSearchImplCopyWithImpl<$Res>;
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
class __$$AdvancedSearchImplCopyWithImpl<$Res>
    extends _$AdvancedSearchCopyWithImpl<$Res, _$AdvancedSearchImpl>
    implements _$$AdvancedSearchImplCopyWith<$Res> {
  __$$AdvancedSearchImplCopyWithImpl(
    _$AdvancedSearchImpl _value,
    $Res Function(_$AdvancedSearchImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AdvancedSearch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _$AdvancedSearchImpl(
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
class _$AdvancedSearchImpl implements _AdvancedSearch {
  const _$AdvancedSearchImpl({
    @JsonKey(name: "code") required this.code,
    @JsonKey(name: "message") required this.message,
    @JsonKey(name: "data") required this.data,
  });

  factory _$AdvancedSearchImpl.fromJson(Map<String, dynamic> json) =>
      _$$AdvancedSearchImplFromJson(json);

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
    return 'AdvancedSearch(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AdvancedSearchImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of AdvancedSearch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AdvancedSearchImplCopyWith<_$AdvancedSearchImpl> get copyWith =>
      __$$AdvancedSearchImplCopyWithImpl<_$AdvancedSearchImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AdvancedSearchImplToJson(this);
  }
}

abstract class _AdvancedSearch implements AdvancedSearch {
  const factory _AdvancedSearch({
    @JsonKey(name: "code") required final int code,
    @JsonKey(name: "message") required final String message,
    @JsonKey(name: "data") required final Data data,
  }) = _$AdvancedSearchImpl;

  factory _AdvancedSearch.fromJson(Map<String, dynamic> json) =
      _$AdvancedSearchImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;
  @override
  @JsonKey(name: "message")
  String get message;
  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of AdvancedSearch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AdvancedSearchImplCopyWith<_$AdvancedSearchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "comics")
  Comics get comics => throw _privateConstructorUsedError;

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
  $Res call({@JsonKey(name: "comics") Comics comics});

  $ComicsCopyWith<$Res> get comics;
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
  $Res call({Object? comics = null}) {
    return _then(
      _value.copyWith(
            comics:
                null == comics
                    ? _value.comics
                    : comics // ignore: cast_nullable_to_non_nullable
                        as Comics,
          )
          as $Val,
    );
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ComicsCopyWith<$Res> get comics {
    return $ComicsCopyWith<$Res>(_value.comics, (value) {
      return _then(_value.copyWith(comics: value) as $Val);
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
  $Res call({@JsonKey(name: "comics") Comics comics});

  @override
  $ComicsCopyWith<$Res> get comics;
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
  $Res call({Object? comics = null}) {
    return _then(
      _$DataImpl(
        comics:
            null == comics
                ? _value.comics
                : comics // ignore: cast_nullable_to_non_nullable
                    as Comics,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl({@JsonKey(name: "comics") required this.comics});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  @JsonKey(name: "comics")
  final Comics comics;

  @override
  String toString() {
    return 'Data(comics: $comics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.comics, comics) || other.comics == comics));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, comics);

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
  const factory _Data({@JsonKey(name: "comics") required final Comics comics}) =
      _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "comics")
  Comics get comics;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Comics _$ComicsFromJson(Map<String, dynamic> json) {
  return _Comics.fromJson(json);
}

/// @nodoc
mixin _$Comics {
  @JsonKey(name: "total")
  int get total => throw _privateConstructorUsedError;
  @JsonKey(name: "page")
  int get page => throw _privateConstructorUsedError;
  @JsonKey(name: "pages")
  int get pages => throw _privateConstructorUsedError;
  @JsonKey(name: "docs")
  List<Doc> get docs => throw _privateConstructorUsedError;
  @JsonKey(name: "limit")
  int get limit => throw _privateConstructorUsedError;

  /// Serializes this Comics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Comics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ComicsCopyWith<Comics> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ComicsCopyWith<$Res> {
  factory $ComicsCopyWith(Comics value, $Res Function(Comics) then) =
      _$ComicsCopyWithImpl<$Res, Comics>;
  @useResult
  $Res call({
    @JsonKey(name: "total") int total,
    @JsonKey(name: "page") int page,
    @JsonKey(name: "pages") int pages,
    @JsonKey(name: "docs") List<Doc> docs,
    @JsonKey(name: "limit") int limit,
  });
}

/// @nodoc
class _$ComicsCopyWithImpl<$Res, $Val extends Comics>
    implements $ComicsCopyWith<$Res> {
  _$ComicsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Comics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? pages = null,
    Object? docs = null,
    Object? limit = null,
  }) {
    return _then(
      _value.copyWith(
            total:
                null == total
                    ? _value.total
                    : total // ignore: cast_nullable_to_non_nullable
                        as int,
            page:
                null == page
                    ? _value.page
                    : page // ignore: cast_nullable_to_non_nullable
                        as int,
            pages:
                null == pages
                    ? _value.pages
                    : pages // ignore: cast_nullable_to_non_nullable
                        as int,
            docs:
                null == docs
                    ? _value.docs
                    : docs // ignore: cast_nullable_to_non_nullable
                        as List<Doc>,
            limit:
                null == limit
                    ? _value.limit
                    : limit // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ComicsImplCopyWith<$Res> implements $ComicsCopyWith<$Res> {
  factory _$$ComicsImplCopyWith(
    _$ComicsImpl value,
    $Res Function(_$ComicsImpl) then,
  ) = __$$ComicsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "total") int total,
    @JsonKey(name: "page") int page,
    @JsonKey(name: "pages") int pages,
    @JsonKey(name: "docs") List<Doc> docs,
    @JsonKey(name: "limit") int limit,
  });
}

/// @nodoc
class __$$ComicsImplCopyWithImpl<$Res>
    extends _$ComicsCopyWithImpl<$Res, _$ComicsImpl>
    implements _$$ComicsImplCopyWith<$Res> {
  __$$ComicsImplCopyWithImpl(
    _$ComicsImpl _value,
    $Res Function(_$ComicsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Comics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? total = null,
    Object? page = null,
    Object? pages = null,
    Object? docs = null,
    Object? limit = null,
  }) {
    return _then(
      _$ComicsImpl(
        total:
            null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                    as int,
        page:
            null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                    as int,
        pages:
            null == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                    as int,
        docs:
            null == docs
                ? _value._docs
                : docs // ignore: cast_nullable_to_non_nullable
                    as List<Doc>,
        limit:
            null == limit
                ? _value.limit
                : limit // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ComicsImpl implements _Comics {
  const _$ComicsImpl({
    @JsonKey(name: "total") required this.total,
    @JsonKey(name: "page") required this.page,
    @JsonKey(name: "pages") required this.pages,
    @JsonKey(name: "docs") required final List<Doc> docs,
    @JsonKey(name: "limit") required this.limit,
  }) : _docs = docs;

  factory _$ComicsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComicsImplFromJson(json);

  @override
  @JsonKey(name: "total")
  final int total;
  @override
  @JsonKey(name: "page")
  final int page;
  @override
  @JsonKey(name: "pages")
  final int pages;
  final List<Doc> _docs;
  @override
  @JsonKey(name: "docs")
  List<Doc> get docs {
    if (_docs is EqualUnmodifiableListView) return _docs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_docs);
  }

  @override
  @JsonKey(name: "limit")
  final int limit;

  @override
  String toString() {
    return 'Comics(total: $total, page: $page, pages: $pages, docs: $docs, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComicsImpl &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pages, pages) || other.pages == pages) &&
            const DeepCollectionEquality().equals(other._docs, _docs) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    total,
    page,
    pages,
    const DeepCollectionEquality().hash(_docs),
    limit,
  );

  /// Create a copy of Comics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ComicsImplCopyWith<_$ComicsImpl> get copyWith =>
      __$$ComicsImplCopyWithImpl<_$ComicsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ComicsImplToJson(this);
  }
}

abstract class _Comics implements Comics {
  const factory _Comics({
    @JsonKey(name: "total") required final int total,
    @JsonKey(name: "page") required final int page,
    @JsonKey(name: "pages") required final int pages,
    @JsonKey(name: "docs") required final List<Doc> docs,
    @JsonKey(name: "limit") required final int limit,
  }) = _$ComicsImpl;

  factory _Comics.fromJson(Map<String, dynamic> json) = _$ComicsImpl.fromJson;

  @override
  @JsonKey(name: "total")
  int get total;
  @override
  @JsonKey(name: "page")
  int get page;
  @override
  @JsonKey(name: "pages")
  int get pages;
  @override
  @JsonKey(name: "docs")
  List<Doc> get docs;
  @override
  @JsonKey(name: "limit")
  int get limit;

  /// Create a copy of Comics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ComicsImplCopyWith<_$ComicsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Doc _$DocFromJson(Map<String, dynamic> json) {
  return _Doc.fromJson(json);
}

/// @nodoc
mixin _$Doc {
  @JsonKey(name: "updated_at")
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: "thumb")
  Thumb get thumb => throw _privateConstructorUsedError;
  @JsonKey(name: "author")
  String get author => throw _privateConstructorUsedError;
  @JsonKey(name: "description")
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: "chineseTeam")
  String get chineseTeam => throw _privateConstructorUsedError;
  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: "finished")
  bool get finished => throw _privateConstructorUsedError;
  @JsonKey(name: "categories")
  List<String> get categories => throw _privateConstructorUsedError;
  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;
  @JsonKey(name: "tags")
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: "likesCount")
  int get likesCount => throw _privateConstructorUsedError;

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
    @JsonKey(name: "updated_at") DateTime updatedAt,
    @JsonKey(name: "thumb") Thumb thumb,
    @JsonKey(name: "author") String author,
    @JsonKey(name: "description") String description,
    @JsonKey(name: "chineseTeam") String chineseTeam,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "finished") bool finished,
    @JsonKey(name: "categories") List<String> categories,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "tags") List<String> tags,
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "likesCount") int likesCount,
  });

  $ThumbCopyWith<$Res> get thumb;
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
    Object? updatedAt = null,
    Object? thumb = null,
    Object? author = null,
    Object? description = null,
    Object? chineseTeam = null,
    Object? createdAt = null,
    Object? finished = null,
    Object? categories = null,
    Object? title = null,
    Object? tags = null,
    Object? id = null,
    Object? likesCount = null,
  }) {
    return _then(
      _value.copyWith(
            updatedAt:
                null == updatedAt
                    ? _value.updatedAt
                    : updatedAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
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
            description:
                null == description
                    ? _value.description
                    : description // ignore: cast_nullable_to_non_nullable
                        as String,
            chineseTeam:
                null == chineseTeam
                    ? _value.chineseTeam
                    : chineseTeam // ignore: cast_nullable_to_non_nullable
                        as String,
            createdAt:
                null == createdAt
                    ? _value.createdAt
                    : createdAt // ignore: cast_nullable_to_non_nullable
                        as DateTime,
            finished:
                null == finished
                    ? _value.finished
                    : finished // ignore: cast_nullable_to_non_nullable
                        as bool,
            categories:
                null == categories
                    ? _value.categories
                    : categories // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            tags:
                null == tags
                    ? _value.tags
                    : tags // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            likesCount:
                null == likesCount
                    ? _value.likesCount
                    : likesCount // ignore: cast_nullable_to_non_nullable
                        as int,
          )
          as $Val,
    );
  }

  /// Create a copy of Doc
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
abstract class _$$DocImplCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$$DocImplCopyWith(_$DocImpl value, $Res Function(_$DocImpl) then) =
      __$$DocImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: "updated_at") DateTime updatedAt,
    @JsonKey(name: "thumb") Thumb thumb,
    @JsonKey(name: "author") String author,
    @JsonKey(name: "description") String description,
    @JsonKey(name: "chineseTeam") String chineseTeam,
    @JsonKey(name: "created_at") DateTime createdAt,
    @JsonKey(name: "finished") bool finished,
    @JsonKey(name: "categories") List<String> categories,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "tags") List<String> tags,
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "likesCount") int likesCount,
  });

  @override
  $ThumbCopyWith<$Res> get thumb;
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
    Object? updatedAt = null,
    Object? thumb = null,
    Object? author = null,
    Object? description = null,
    Object? chineseTeam = null,
    Object? createdAt = null,
    Object? finished = null,
    Object? categories = null,
    Object? title = null,
    Object? tags = null,
    Object? id = null,
    Object? likesCount = null,
  }) {
    return _then(
      _$DocImpl(
        updatedAt:
            null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
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
        description:
            null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                    as String,
        chineseTeam:
            null == chineseTeam
                ? _value.chineseTeam
                : chineseTeam // ignore: cast_nullable_to_non_nullable
                    as String,
        createdAt:
            null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                    as DateTime,
        finished:
            null == finished
                ? _value.finished
                : finished // ignore: cast_nullable_to_non_nullable
                    as bool,
        categories:
            null == categories
                ? _value._categories
                : categories // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        tags:
            null == tags
                ? _value._tags
                : tags // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        likesCount:
            null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                    as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DocImpl implements _Doc {
  const _$DocImpl({
    @JsonKey(name: "updated_at") required this.updatedAt,
    @JsonKey(name: "thumb") required this.thumb,
    @JsonKey(name: "author") required this.author,
    @JsonKey(name: "description") required this.description,
    @JsonKey(name: "chineseTeam") required this.chineseTeam,
    @JsonKey(name: "created_at") required this.createdAt,
    @JsonKey(name: "finished") required this.finished,
    @JsonKey(name: "categories") required final List<String> categories,
    @JsonKey(name: "title") required this.title,
    @JsonKey(name: "tags") required final List<String> tags,
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "likesCount") required this.likesCount,
  }) : _categories = categories,
       _tags = tags;

  factory _$DocImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocImplFromJson(json);

  @override
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;
  @override
  @JsonKey(name: "thumb")
  final Thumb thumb;
  @override
  @JsonKey(name: "author")
  final String author;
  @override
  @JsonKey(name: "description")
  final String description;
  @override
  @JsonKey(name: "chineseTeam")
  final String chineseTeam;
  @override
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "finished")
  final bool finished;
  final List<String> _categories;
  @override
  @JsonKey(name: "categories")
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  @JsonKey(name: "title")
  final String title;
  final List<String> _tags;
  @override
  @JsonKey(name: "tags")
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "likesCount")
  final int likesCount;

  @override
  String toString() {
    return 'Doc(updatedAt: $updatedAt, thumb: $thumb, author: $author, description: $description, chineseTeam: $chineseTeam, createdAt: $createdAt, finished: $finished, categories: $categories, title: $title, tags: $tags, id: $id, likesCount: $likesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImpl &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.chineseTeam, chineseTeam) ||
                other.chineseTeam == chineseTeam) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    updatedAt,
    thumb,
    author,
    description,
    chineseTeam,
    createdAt,
    finished,
    const DeepCollectionEquality().hash(_categories),
    title,
    const DeepCollectionEquality().hash(_tags),
    id,
    likesCount,
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
    @JsonKey(name: "updated_at") required final DateTime updatedAt,
    @JsonKey(name: "thumb") required final Thumb thumb,
    @JsonKey(name: "author") required final String author,
    @JsonKey(name: "description") required final String description,
    @JsonKey(name: "chineseTeam") required final String chineseTeam,
    @JsonKey(name: "created_at") required final DateTime createdAt,
    @JsonKey(name: "finished") required final bool finished,
    @JsonKey(name: "categories") required final List<String> categories,
    @JsonKey(name: "title") required final String title,
    @JsonKey(name: "tags") required final List<String> tags,
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "likesCount") required final int likesCount,
  }) = _$DocImpl;

  factory _Doc.fromJson(Map<String, dynamic> json) = _$DocImpl.fromJson;

  @override
  @JsonKey(name: "updated_at")
  DateTime get updatedAt;
  @override
  @JsonKey(name: "thumb")
  Thumb get thumb;
  @override
  @JsonKey(name: "author")
  String get author;
  @override
  @JsonKey(name: "description")
  String get description;
  @override
  @JsonKey(name: "chineseTeam")
  String get chineseTeam;
  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;
  @override
  @JsonKey(name: "finished")
  bool get finished;
  @override
  @JsonKey(name: "categories")
  List<String> get categories;
  @override
  @JsonKey(name: "title")
  String get title;
  @override
  @JsonKey(name: "tags")
  List<String> get tags;
  @override
  @JsonKey(name: "_id")
  String get id;
  @override
  @JsonKey(name: "likesCount")
  int get likesCount;

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocImplCopyWith<_$DocImpl> get copyWith =>
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
