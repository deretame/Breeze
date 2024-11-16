// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Page _$PageFromJson(Map<String, dynamic> json) {
  return _Page.fromJson(json);
}

/// @nodoc
mixin _$Page {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;

  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;

  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this Page to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PageCopyWith<Page> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PageCopyWith<$Res> {
  factory $PageCopyWith(Page value, $Res Function(Page) then) =
      _$PageCopyWithImpl<$Res, Page>;

  @useResult
  $Res call(
      {@JsonKey(name: "code") int code,
      @JsonKey(name: "message") String message,
      @JsonKey(name: "data") Data data});

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$PageCopyWithImpl<$Res, $Val extends Page>
    implements $PageCopyWith<$Res> {
  _$PageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Data,
    ) as $Val);
  }

  /// Create a copy of Page
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
abstract class _$$PageImplCopyWith<$Res> implements $PageCopyWith<$Res> {
  factory _$$PageImplCopyWith(
          _$PageImpl value, $Res Function(_$PageImpl) then) =
      __$$PageImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "code") int code,
      @JsonKey(name: "message") String message,
      @JsonKey(name: "data") Data data});

  @override
  $DataCopyWith<$Res> get data;
}

/// @nodoc
class __$$PageImplCopyWithImpl<$Res>
    extends _$PageCopyWithImpl<$Res, _$PageImpl>
    implements _$$PageImplCopyWith<$Res> {
  __$$PageImplCopyWithImpl(_$PageImpl _value, $Res Function(_$PageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(_$PageImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as int,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Data,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PageImpl implements _Page {
  const _$PageImpl(
      {@JsonKey(name: "code") required this.code,
      @JsonKey(name: "message") required this.message,
      @JsonKey(name: "data") required this.data});

  factory _$PageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PageImplFromJson(json);

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
    return 'Page(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PageImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PageImplCopyWith<_$PageImpl> get copyWith =>
      __$$PageImplCopyWithImpl<_$PageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PageImplToJson(
      this,
    );
  }
}

abstract class _Page implements Page {
  const factory _Page(
      {@JsonKey(name: "code") required final int code,
      @JsonKey(name: "message") required final String message,
      @JsonKey(name: "data") required final Data data}) = _$PageImpl;

  factory _Page.fromJson(Map<String, dynamic> json) = _$PageImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;

  @override
  @JsonKey(name: "message")
  String get message;

  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of Page
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PageImplCopyWith<_$PageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "pages")
  Pages get pages => throw _privateConstructorUsedError;

  @JsonKey(name: "ep")
  Ep get ep => throw _privateConstructorUsedError;

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
  $Res call({@JsonKey(name: "pages") Pages pages, @JsonKey(name: "ep") Ep ep});

  $PagesCopyWith<$Res> get pages;

  $EpCopyWith<$Res> get ep;
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
  $Res call({
    Object? pages = null,
    Object? ep = null,
  }) {
    return _then(_value.copyWith(
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as Pages,
      ep: null == ep
          ? _value.ep
          : ep // ignore: cast_nullable_to_non_nullable
              as Ep,
    ) as $Val);
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PagesCopyWith<$Res> get pages {
    return $PagesCopyWith<$Res>(_value.pages, (value) {
      return _then(_value.copyWith(pages: value) as $Val);
    });
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EpCopyWith<$Res> get ep {
    return $EpCopyWith<$Res>(_value.ep, (value) {
      return _then(_value.copyWith(ep: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DataImplCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$$DataImplCopyWith(
          _$DataImpl value, $Res Function(_$DataImpl) then) =
      __$$DataImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call({@JsonKey(name: "pages") Pages pages, @JsonKey(name: "ep") Ep ep});

  @override
  $PagesCopyWith<$Res> get pages;

  @override
  $EpCopyWith<$Res> get ep;
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
  $Res call({
    Object? pages = null,
    Object? ep = null,
  }) {
    return _then(_$DataImpl(
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as Pages,
      ep: null == ep
          ? _value.ep
          : ep // ignore: cast_nullable_to_non_nullable
              as Ep,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl(
      {@JsonKey(name: "pages") required this.pages,
      @JsonKey(name: "ep") required this.ep});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  @JsonKey(name: "pages")
  final Pages pages;
  @override
  @JsonKey(name: "ep")
  final Ep ep;

  @override
  String toString() {
    return 'Data(pages: $pages, ep: $ep)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.pages, pages) || other.pages == pages) &&
            (identical(other.ep, ep) || other.ep == ep));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, pages, ep);

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      __$$DataImplCopyWithImpl<_$DataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DataImplToJson(
      this,
    );
  }
}

abstract class _Data implements Data {
  const factory _Data(
      {@JsonKey(name: "pages") required final Pages pages,
      @JsonKey(name: "ep") required final Ep ep}) = _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "pages")
  Pages get pages;

  @override
  @JsonKey(name: "ep")
  Ep get ep;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Ep _$EpFromJson(Map<String, dynamic> json) {
  return _Ep.fromJson(json);
}

/// @nodoc
mixin _$Ep {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "title")
  String get title => throw _privateConstructorUsedError;

  /// Serializes this Ep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Ep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpCopyWith<Ep> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpCopyWith<$Res> {
  factory $EpCopyWith(Ep value, $Res Function(Ep) then) =
      _$EpCopyWithImpl<$Res, Ep>;

  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id, @JsonKey(name: "title") String title});
}

/// @nodoc
class _$EpCopyWithImpl<$Res, $Val extends Ep> implements $EpCopyWith<$Res> {
  _$EpCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Ep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EpImplCopyWith<$Res> implements $EpCopyWith<$Res> {
  factory _$$EpImplCopyWith(_$EpImpl value, $Res Function(_$EpImpl) then) =
      __$$EpImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id, @JsonKey(name: "title") String title});
}

/// @nodoc
class __$$EpImplCopyWithImpl<$Res> extends _$EpCopyWithImpl<$Res, _$EpImpl>
    implements _$$EpImplCopyWith<$Res> {
  __$$EpImplCopyWithImpl(_$EpImpl _value, $Res Function(_$EpImpl) _then)
      : super(_value, _then);

  /// Create a copy of Ep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
  }) {
    return _then(_$EpImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EpImpl implements _Ep {
  const _$EpImpl(
      {@JsonKey(name: "_id") required this.id,
      @JsonKey(name: "title") required this.title});

  factory _$EpImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "title")
  final String title;

  @override
  String toString() {
    return 'Ep(id: $id, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, title);

  /// Create a copy of Ep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpImplCopyWith<_$EpImpl> get copyWith =>
      __$$EpImplCopyWithImpl<_$EpImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpImplToJson(
      this,
    );
  }
}

abstract class _Ep implements Ep {
  const factory _Ep(
      {@JsonKey(name: "_id") required final String id,
      @JsonKey(name: "title") required final String title}) = _$EpImpl;

  factory _Ep.fromJson(Map<String, dynamic> json) = _$EpImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;

  @override
  @JsonKey(name: "title")
  String get title;

  /// Create a copy of Ep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpImplCopyWith<_$EpImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Pages _$PagesFromJson(Map<String, dynamic> json) {
  return _Pages.fromJson(json);
}

/// @nodoc
mixin _$Pages {
  @JsonKey(name: "docs")
  List<Doc> get docs => throw _privateConstructorUsedError;

  @JsonKey(name: "total")
  int get total => throw _privateConstructorUsedError;

  @JsonKey(name: "limit")
  int get limit => throw _privateConstructorUsedError;

  @JsonKey(name: "page")
  int get page => throw _privateConstructorUsedError;

  @JsonKey(name: "pages")
  int get pages => throw _privateConstructorUsedError;

  /// Serializes this Pages to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Pages
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PagesCopyWith<Pages> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PagesCopyWith<$Res> {
  factory $PagesCopyWith(Pages value, $Res Function(Pages) then) =
      _$PagesCopyWithImpl<$Res, Pages>;

  @useResult
  $Res call(
      {@JsonKey(name: "docs") List<Doc> docs,
      @JsonKey(name: "total") int total,
      @JsonKey(name: "limit") int limit,
      @JsonKey(name: "page") int page,
      @JsonKey(name: "pages") int pages});
}

/// @nodoc
class _$PagesCopyWithImpl<$Res, $Val extends Pages>
    implements $PagesCopyWith<$Res> {
  _$PagesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Pages
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
    return _then(_value.copyWith(
      docs: null == docs
          ? _value.docs
          : docs // ignore: cast_nullable_to_non_nullable
              as List<Doc>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PagesImplCopyWith<$Res> implements $PagesCopyWith<$Res> {
  factory _$$PagesImplCopyWith(
          _$PagesImpl value, $Res Function(_$PagesImpl) then) =
      __$$PagesImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "docs") List<Doc> docs,
      @JsonKey(name: "total") int total,
      @JsonKey(name: "limit") int limit,
      @JsonKey(name: "page") int page,
      @JsonKey(name: "pages") int pages});
}

/// @nodoc
class __$$PagesImplCopyWithImpl<$Res>
    extends _$PagesCopyWithImpl<$Res, _$PagesImpl>
    implements _$$PagesImplCopyWith<$Res> {
  __$$PagesImplCopyWithImpl(
      _$PagesImpl _value, $Res Function(_$PagesImpl) _then)
      : super(_value, _then);

  /// Create a copy of Pages
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
    return _then(_$PagesImpl(
      docs: null == docs
          ? _value._docs
          : docs // ignore: cast_nullable_to_non_nullable
              as List<Doc>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pages: null == pages
          ? _value.pages
          : pages // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PagesImpl implements _Pages {
  const _$PagesImpl(
      {@JsonKey(name: "docs") required final List<Doc> docs,
      @JsonKey(name: "total") required this.total,
      @JsonKey(name: "limit") required this.limit,
      @JsonKey(name: "page") required this.page,
      @JsonKey(name: "pages") required this.pages})
      : _docs = docs;

  factory _$PagesImpl.fromJson(Map<String, dynamic> json) =>
      _$$PagesImplFromJson(json);

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
  final int page;
  @override
  @JsonKey(name: "pages")
  final int pages;

  @override
  String toString() {
    return 'Pages(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PagesImpl &&
            const DeepCollectionEquality().equals(other._docs, _docs) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.limit, limit) || other.limit == limit) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pages, pages) || other.pages == pages));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_docs), total, limit, page, pages);

  /// Create a copy of Pages
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PagesImplCopyWith<_$PagesImpl> get copyWith =>
      __$$PagesImplCopyWithImpl<_$PagesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PagesImplToJson(
      this,
    );
  }
}

abstract class _Pages implements Pages {
  const factory _Pages(
      {@JsonKey(name: "docs") required final List<Doc> docs,
      @JsonKey(name: "total") required final int total,
      @JsonKey(name: "limit") required final int limit,
      @JsonKey(name: "page") required final int page,
      @JsonKey(name: "pages") required final int pages}) = _$PagesImpl;

  factory _Pages.fromJson(Map<String, dynamic> json) = _$PagesImpl.fromJson;

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
  int get page;

  @override
  @JsonKey(name: "pages")
  int get pages;

  /// Create a copy of Pages
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PagesImplCopyWith<_$PagesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Doc _$DocFromJson(Map<String, dynamic> json) {
  return _Doc.fromJson(json);
}

/// @nodoc
mixin _$Doc {
  @JsonKey(name: "_id")
  String get id => throw _privateConstructorUsedError;

  @JsonKey(name: "media")
  Media get media => throw _privateConstructorUsedError;

  @JsonKey(name: "id")
  String get docId => throw _privateConstructorUsedError;

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
  $Res call(
      {@JsonKey(name: "_id") String id,
      @JsonKey(name: "media") Media media,
      @JsonKey(name: "id") String docId});

  $MediaCopyWith<$Res> get media;
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
    Object? media = null,
    Object? docId = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      media: null == media
          ? _value.media
          : media // ignore: cast_nullable_to_non_nullable
              as Media,
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MediaCopyWith<$Res> get media {
    return $MediaCopyWith<$Res>(_value.media, (value) {
      return _then(_value.copyWith(media: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DocImplCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$$DocImplCopyWith(_$DocImpl value, $Res Function(_$DocImpl) then) =
      __$$DocImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "_id") String id,
      @JsonKey(name: "media") Media media,
      @JsonKey(name: "id") String docId});

  @override
  $MediaCopyWith<$Res> get media;
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
    Object? media = null,
    Object? docId = null,
  }) {
    return _then(_$DocImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      media: null == media
          ? _value.media
          : media // ignore: cast_nullable_to_non_nullable
              as Media,
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DocImpl implements _Doc {
  const _$DocImpl(
      {@JsonKey(name: "_id") required this.id,
      @JsonKey(name: "media") required this.media,
      @JsonKey(name: "id") required this.docId});

  factory _$DocImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "media")
  final Media media;
  @override
  @JsonKey(name: "id")
  final String docId;

  @override
  String toString() {
    return 'Doc(id: $id, media: $media, docId: $docId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.media, media) || other.media == media) &&
            (identical(other.docId, docId) || other.docId == docId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, media, docId);

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DocImplCopyWith<_$DocImpl> get copyWith =>
      __$$DocImplCopyWithImpl<_$DocImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DocImplToJson(
      this,
    );
  }
}

abstract class _Doc implements Doc {
  const factory _Doc(
      {@JsonKey(name: "_id") required final String id,
      @JsonKey(name: "media") required final Media media,
      @JsonKey(name: "id") required final String docId}) = _$DocImpl;

  factory _Doc.fromJson(Map<String, dynamic> json) = _$DocImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;

  @override
  @JsonKey(name: "media")
  Media get media;

  @override
  @JsonKey(name: "id")
  String get docId;

  /// Create a copy of Doc
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DocImplCopyWith<_$DocImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Media _$MediaFromJson(Map<String, dynamic> json) {
  return _Media.fromJson(json);
}

/// @nodoc
mixin _$Media {
  @JsonKey(name: "originalName")
  String get originalName => throw _privateConstructorUsedError;

  @JsonKey(name: "path")
  String get path => throw _privateConstructorUsedError;

  @JsonKey(name: "fileServer")
  String get fileServer => throw _privateConstructorUsedError;

  /// Serializes this Media to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Media
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaCopyWith<Media> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaCopyWith<$Res> {
  factory $MediaCopyWith(Media value, $Res Function(Media) then) =
      _$MediaCopyWithImpl<$Res, Media>;

  @useResult
  $Res call(
      {@JsonKey(name: "originalName") String originalName,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "fileServer") String fileServer});
}

/// @nodoc
class _$MediaCopyWithImpl<$Res, $Val extends Media>
    implements $MediaCopyWith<$Res> {
  _$MediaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;

  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Media
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(_value.copyWith(
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      fileServer: null == fileServer
          ? _value.fileServer
          : fileServer // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaImplCopyWith<$Res> implements $MediaCopyWith<$Res> {
  factory _$$MediaImplCopyWith(
          _$MediaImpl value, $Res Function(_$MediaImpl) then) =
      __$$MediaImplCopyWithImpl<$Res>;

  @override
  @useResult
  $Res call(
      {@JsonKey(name: "originalName") String originalName,
      @JsonKey(name: "path") String path,
      @JsonKey(name: "fileServer") String fileServer});
}

/// @nodoc
class __$$MediaImplCopyWithImpl<$Res>
    extends _$MediaCopyWithImpl<$Res, _$MediaImpl>
    implements _$$MediaImplCopyWith<$Res> {
  __$$MediaImplCopyWithImpl(
      _$MediaImpl _value, $Res Function(_$MediaImpl) _then)
      : super(_value, _then);

  /// Create a copy of Media
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalName = null,
    Object? path = null,
    Object? fileServer = null,
  }) {
    return _then(_$MediaImpl(
      originalName: null == originalName
          ? _value.originalName
          : originalName // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      fileServer: null == fileServer
          ? _value.fileServer
          : fileServer // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaImpl implements _Media {
  const _$MediaImpl(
      {@JsonKey(name: "originalName") required this.originalName,
      @JsonKey(name: "path") required this.path,
      @JsonKey(name: "fileServer") required this.fileServer});

  factory _$MediaImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaImplFromJson(json);

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
    return 'Media(originalName: $originalName, path: $path, fileServer: $fileServer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaImpl &&
            (identical(other.originalName, originalName) ||
                other.originalName == originalName) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.fileServer, fileServer) ||
                other.fileServer == fileServer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalName, path, fileServer);

  /// Create a copy of Media
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaImplCopyWith<_$MediaImpl> get copyWith =>
      __$$MediaImplCopyWithImpl<_$MediaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaImplToJson(
      this,
    );
  }
}

abstract class _Media implements Media {
  const factory _Media(
          {@JsonKey(name: "originalName") required final String originalName,
          @JsonKey(name: "path") required final String path,
          @JsonKey(name: "fileServer") required final String fileServer}) =
      _$MediaImpl;

  factory _Media.fromJson(Map<String, dynamic> json) = _$MediaImpl.fromJson;

  @override
  @JsonKey(name: "originalName")
  String get originalName;

  @override
  @JsonKey(name: "path")
  String get path;

  @override
  @JsonKey(name: "fileServer")
  String get fileServer;

  /// Create a copy of Media
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaImplCopyWith<_$MediaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
