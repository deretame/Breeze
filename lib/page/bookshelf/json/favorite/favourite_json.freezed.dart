// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favourite_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FavouriteJson _$FavouriteJsonFromJson(Map<String, dynamic> json) {
  return _FavouriteJson.fromJson(json);
}

/// @nodoc
mixin _$FavouriteJson {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;

  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;

  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this FavouriteJson to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FavouriteJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FavouriteJsonCopyWith<FavouriteJson> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavouriteJsonCopyWith<$Res> {
  factory $FavouriteJsonCopyWith(
    FavouriteJson value,
    $Res Function(FavouriteJson) then,
  ) = _$FavouriteJsonCopyWithImpl<$Res, FavouriteJson>;

  @useResult
  $Res call({
    @JsonKey(name: "code") int code,
    @JsonKey(name: "message") String message,
    @JsonKey(name: "data") Data data,
  });

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$FavouriteJsonCopyWithImpl<$Res, $Val extends FavouriteJson>
    implements $FavouriteJsonCopyWith<$Res> {
  _$FavouriteJsonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FavouriteJson
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

  /// Create a copy of FavouriteJson
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
abstract class _$$FavouriteJsonImplCopyWith<$Res>
    implements $FavouriteJsonCopyWith<$Res> {
  factory _$$FavouriteJsonImplCopyWith(
    _$FavouriteJsonImpl value,
    $Res Function(_$FavouriteJsonImpl) then,
  ) = __$$FavouriteJsonImplCopyWithImpl<$Res>;

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
class __$$FavouriteJsonImplCopyWithImpl<$Res>
    extends _$FavouriteJsonCopyWithImpl<$Res, _$FavouriteJsonImpl>
    implements _$$FavouriteJsonImplCopyWith<$Res> {
  __$$FavouriteJsonImplCopyWithImpl(
    _$FavouriteJsonImpl _value,
    $Res Function(_$FavouriteJsonImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FavouriteJson
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(
      _$FavouriteJsonImpl(
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
class _$FavouriteJsonImpl implements _FavouriteJson {
  const _$FavouriteJsonImpl({
    @JsonKey(name: "code") required this.code,
    @JsonKey(name: "message") required this.message,
    @JsonKey(name: "data") required this.data,
  });

  factory _$FavouriteJsonImpl.fromJson(Map<String, dynamic> json) =>
      _$$FavouriteJsonImplFromJson(json);

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
    return 'FavouriteJson(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavouriteJsonImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of FavouriteJson
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FavouriteJsonImplCopyWith<_$FavouriteJsonImpl> get copyWith =>
      __$$FavouriteJsonImplCopyWithImpl<_$FavouriteJsonImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FavouriteJsonImplToJson(this);
  }
}

abstract class _FavouriteJson implements FavouriteJson {
  const factory _FavouriteJson({
    @JsonKey(name: "code") required final int code,
    @JsonKey(name: "message") required final String message,
    @JsonKey(name: "data") required final Data data,
  }) = _$FavouriteJsonImpl;

  factory _FavouriteJson.fromJson(Map<String, dynamic> json) =
      _$FavouriteJsonImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;

  @override
  @JsonKey(name: "message")
  String get message;

  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of FavouriteJson
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FavouriteJsonImplCopyWith<_$FavouriteJsonImpl> get copyWith =>
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
  @JsonKey(name: "pages")
  int get pages => throw _privateConstructorUsedError;

  @JsonKey(name: "total")
  int get total => throw _privateConstructorUsedError;

  @JsonKey(name: "docs")
  List<Doc> get docs => throw _privateConstructorUsedError;

  @JsonKey(name: "page")
  int get page => throw _privateConstructorUsedError;

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
    @JsonKey(name: "pages") int pages,
    @JsonKey(name: "total") int total,
    @JsonKey(name: "docs") List<Doc> docs,
    @JsonKey(name: "page") int page,
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
    Object? pages = null,
    Object? total = null,
    Object? docs = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(
      _value.copyWith(
            pages:
                null == pages
                    ? _value.pages
                    : pages // ignore: cast_nullable_to_non_nullable
                        as int,
            total:
                null == total
                    ? _value.total
                    : total // ignore: cast_nullable_to_non_nullable
                        as int,
            docs:
                null == docs
                    ? _value.docs
                    : docs // ignore: cast_nullable_to_non_nullable
                        as List<Doc>,
            page:
                null == page
                    ? _value.page
                    : page // ignore: cast_nullable_to_non_nullable
                        as int,
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
    @JsonKey(name: "pages") int pages,
    @JsonKey(name: "total") int total,
    @JsonKey(name: "docs") List<Doc> docs,
    @JsonKey(name: "page") int page,
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
    Object? pages = null,
    Object? total = null,
    Object? docs = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(
      _$ComicsImpl(
        pages:
            null == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                    as int,
        total:
            null == total
                ? _value.total
                : total // ignore: cast_nullable_to_non_nullable
                    as int,
        docs:
            null == docs
                ? _value._docs
                : docs // ignore: cast_nullable_to_non_nullable
                    as List<Doc>,
        page:
            null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                    as int,
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
    @JsonKey(name: "pages") required this.pages,
    @JsonKey(name: "total") required this.total,
    @JsonKey(name: "docs") required final List<Doc> docs,
    @JsonKey(name: "page") required this.page,
    @JsonKey(name: "limit") required this.limit,
  }) : _docs = docs;

  factory _$ComicsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ComicsImplFromJson(json);

  @override
  @JsonKey(name: "pages")
  final int pages;
  @override
  @JsonKey(name: "total")
  final int total;
  final List<Doc> _docs;

  @override
  @JsonKey(name: "docs")
  List<Doc> get docs {
    if (_docs is EqualUnmodifiableListView) return _docs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_docs);
  }

  @override
  @JsonKey(name: "page")
  final int page;
  @override
  @JsonKey(name: "limit")
  final int limit;

  @override
  String toString() {
    return 'Comics(pages: $pages, total: $total, docs: $docs, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ComicsImpl &&
            (identical(other.pages, pages) || other.pages == pages) &&
            (identical(other.total, total) || other.total == total) &&
            const DeepCollectionEquality().equals(other._docs, _docs) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pages,
    total,
    const DeepCollectionEquality().hash(_docs),
    page,
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
    @JsonKey(name: "pages") required final int pages,
    @JsonKey(name: "total") required final int total,
    @JsonKey(name: "docs") required final List<Doc> docs,
    @JsonKey(name: "page") required final int page,
    @JsonKey(name: "limit") required final int limit,
  }) = _$ComicsImpl;

  factory _Comics.fromJson(Map<String, dynamic> json) = _$ComicsImpl.fromJson;

  @override
  @JsonKey(name: "pages")
  int get pages;

  @override
  @JsonKey(name: "total")
  int get total;

  @override
  @JsonKey(name: "docs")
  List<Doc> get docs;

  @override
  @JsonKey(name: "page")
  int get page;

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
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;

  @JsonKey(name: "author")
  String get author => throw _privateConstructorUsedError;

  @JsonKey(name: "totalViews")
  int get totalViews => throw _privateConstructorUsedError;

  @JsonKey(name: "totalLikes")
  int get totalLikes => throw _privateConstructorUsedError;

  @JsonKey(name: "pagesCount")
  int get pagesCount => throw _privateConstructorUsedError;

  @JsonKey(name: "epsCount")
  int get epsCount => throw _privateConstructorUsedError;

  @JsonKey(name: "finished")
  bool get finished => throw _privateConstructorUsedError;

  @JsonKey(name: "categories")
  List<String> get categories => throw _privateConstructorUsedError;

  @JsonKey(name: "thumb")
  Thumb get thumb => throw _privateConstructorUsedError;

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
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "author") String author,
    @JsonKey(name: "totalViews") int totalViews,
    @JsonKey(name: "totalLikes") int totalLikes,
    @JsonKey(name: "pagesCount") int pagesCount,
    @JsonKey(name: "epsCount") int epsCount,
    @JsonKey(name: "finished") bool finished,
    @JsonKey(name: "categories") List<String> categories,
    @JsonKey(name: "thumb") Thumb thumb,
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
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? totalViews = null,
    Object? totalLikes = null,
    Object? pagesCount = null,
    Object? epsCount = null,
    Object? finished = null,
    Object? categories = null,
    Object? thumb = null,
    Object? likesCount = null,
  }) {
    return _then(
      _value.copyWith(
            id:
                null == id
                    ? _value.id
                    : id // ignore: cast_nullable_to_non_nullable
                        as String,
            title:
                null == title
                    ? _value.title
                    : title // ignore: cast_nullable_to_non_nullable
                        as String,
            author:
                null == author
                    ? _value.author
                    : author // ignore: cast_nullable_to_non_nullable
                        as String,
            totalViews:
                null == totalViews
                    ? _value.totalViews
                    : totalViews // ignore: cast_nullable_to_non_nullable
                        as int,
            totalLikes:
                null == totalLikes
                    ? _value.totalLikes
                    : totalLikes // ignore: cast_nullable_to_non_nullable
                        as int,
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
            categories:
                null == categories
                    ? _value.categories
                    : categories // ignore: cast_nullable_to_non_nullable
                        as List<String>,
            thumb:
                null == thumb
                    ? _value.thumb
                    : thumb // ignore: cast_nullable_to_non_nullable
                        as Thumb,
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
    @JsonKey(name: "_id") String id,
    @JsonKey(name: "title") String title,
    @JsonKey(name: "author") String author,
    @JsonKey(name: "totalViews") int totalViews,
    @JsonKey(name: "totalLikes") int totalLikes,
    @JsonKey(name: "pagesCount") int pagesCount,
    @JsonKey(name: "epsCount") int epsCount,
    @JsonKey(name: "finished") bool finished,
    @JsonKey(name: "categories") List<String> categories,
    @JsonKey(name: "thumb") Thumb thumb,
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
    Object? id = null,
    Object? title = null,
    Object? author = null,
    Object? totalViews = null,
    Object? totalLikes = null,
    Object? pagesCount = null,
    Object? epsCount = null,
    Object? finished = null,
    Object? categories = null,
    Object? thumb = null,
    Object? likesCount = null,
  }) {
    return _then(
      _$DocImpl(
        id:
            null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                    as String,
        title:
            null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                    as String,
        author:
            null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                    as String,
        totalViews:
            null == totalViews
                ? _value.totalViews
                : totalViews // ignore: cast_nullable_to_non_nullable
                    as int,
        totalLikes:
            null == totalLikes
                ? _value.totalLikes
                : totalLikes // ignore: cast_nullable_to_non_nullable
                    as int,
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
        categories:
            null == categories
                ? _value._categories
                : categories // ignore: cast_nullable_to_non_nullable
                    as List<String>,
        thumb:
            null == thumb
                ? _value.thumb
                : thumb // ignore: cast_nullable_to_non_nullable
                    as Thumb,
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
    @JsonKey(name: "_id") required this.id,
    @JsonKey(name: "title") required this.title,
    @JsonKey(name: "author") required this.author,
    @JsonKey(name: "totalViews") required this.totalViews,
    @JsonKey(name: "totalLikes") required this.totalLikes,
    @JsonKey(name: "pagesCount") required this.pagesCount,
    @JsonKey(name: "epsCount") required this.epsCount,
    @JsonKey(name: "finished") required this.finished,
    @JsonKey(name: "categories") required final List<String> categories,
    @JsonKey(name: "thumb") required this.thumb,
    @JsonKey(name: "likesCount") required this.likesCount,
  }) : _categories = categories;

  factory _$DocImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "author")
  final String author;
  @override
  @JsonKey(name: "totalViews")
  final int totalViews;
  @override
  @JsonKey(name: "totalLikes")
  final int totalLikes;
  @override
  @JsonKey(name: "pagesCount")
  final int pagesCount;
  @override
  @JsonKey(name: "epsCount")
  final int epsCount;
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
  @JsonKey(name: "thumb")
  final Thumb thumb;
  @override
  @JsonKey(name: "likesCount")
  final int likesCount;

  @override
  String toString() {
    return 'Doc(id: $id, title: $title, author: $author, totalViews: $totalViews, totalLikes: $totalLikes, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, categories: $categories, thumb: $thumb, likesCount: $likesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.totalViews, totalViews) ||
                other.totalViews == totalViews) &&
            (identical(other.totalLikes, totalLikes) ||
                other.totalLikes == totalLikes) &&
            (identical(other.pagesCount, pagesCount) ||
                other.pagesCount == pagesCount) &&
            (identical(other.epsCount, epsCount) ||
                other.epsCount == epsCount) &&
            (identical(other.finished, finished) ||
                other.finished == finished) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    author,
    totalViews,
    totalLikes,
    pagesCount,
    epsCount,
    finished,
    const DeepCollectionEquality().hash(_categories),
    thumb,
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
    @JsonKey(name: "_id") required final String id,
    @JsonKey(name: "title") required final String title,
    @JsonKey(name: "author") required final String author,
    @JsonKey(name: "totalViews") required final int totalViews,
    @JsonKey(name: "totalLikes") required final int totalLikes,
    @JsonKey(name: "pagesCount") required final int pagesCount,
    @JsonKey(name: "epsCount") required final int epsCount,
    @JsonKey(name: "finished") required final bool finished,
    @JsonKey(name: "categories") required final List<String> categories,
    @JsonKey(name: "thumb") required final Thumb thumb,
    @JsonKey(name: "likesCount") required final int likesCount,
  }) = _$DocImpl;

  factory _Doc.fromJson(Map<String, dynamic> json) = _$DocImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;

  @override
  @JsonKey(name: "title")
  String get title;

  @override
  @JsonKey(name: "author")
  String get author;

  @override
  @JsonKey(name: "totalViews")
  int get totalViews;

  @override
  @JsonKey(name: "totalLikes")
  int get totalLikes;

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
  @JsonKey(name: "categories")
  List<String> get categories;

  @override
  @JsonKey(name: "thumb")
  Thumb get thumb;

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
  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;

  @JsonKey(name: "originalName")
  String get originalName => throw _privateConstructorUsedError;

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
    @JsonKey(name: "fileServer") String fileServer,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "originalName") String originalName,
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
    Object? fileServer = null,
    Object? path = null,
    Object? originalName = null,
  }) {
    return _then(
      _value.copyWith(
            fileServer:
                null == fileServer
                    ? _value.fileServer
                    : fileServer // ignore: cast_nullable_to_non_nullable
                        as String,
            path:
                null == path
                    ? _value.path
                    : path // ignore: cast_nullable_to_non_nullable
                        as String,
            originalName:
                null == originalName
                    ? _value.originalName
                    : originalName // ignore: cast_nullable_to_non_nullable
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
    @JsonKey(name: "fileServer") String fileServer,
    @JsonKey(name: "path") String path,
    @JsonKey(name: "originalName") String originalName,
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
    Object? fileServer = null,
    Object? path = null,
    Object? originalName = null,
  }) {
    return _then(
      _$ThumbImpl(
        fileServer:
            null == fileServer
                ? _value.fileServer
                : fileServer // ignore: cast_nullable_to_non_nullable
                    as String,
        path:
            null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                    as String,
        originalName:
            null == originalName
                ? _value.originalName
                : originalName // ignore: cast_nullable_to_non_nullable
                    as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ThumbImpl implements _Thumb {
  const _$ThumbImpl({
    @JsonKey(name: "fileServer") required this.fileServer,
    @JsonKey(name: "path") required this.path,
    @JsonKey(name: "originalName") required this.originalName,
  });

  factory _$ThumbImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThumbImplFromJson(json);

  @override
  @JsonKey(name: "fileServer")
  final String fileServer;
  @override
  @JsonKey(name: "path")
  final String path;
  @override
  @JsonKey(name: "originalName")
  final String originalName;

  @override
  String toString() {
    return 'Thumb(fileServer: $fileServer, path: $path, originalName: $originalName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThumbImpl &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, fileServer, path, originalName);

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
    @JsonKey(name: "fileServer") required final String fileServer,
    @JsonKey(name: "path") required final String path,
    @JsonKey(name: "originalName") required final String originalName,
  }) = _$ThumbImpl;

  factory _Thumb.fromJson(Map<String, dynamic> json) = _$ThumbImpl.fromJson;

  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  @override
  @JsonKey(name: "path")
  String get path;

  @override
  @JsonKey(name: "originalName")
  String get originalName;

  /// Create a copy of Thumb
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThumbImplCopyWith<_$ThumbImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
