// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eps.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Eps _$EpsFromJson(Map<String, dynamic> json) {
  return _Eps.fromJson(json);
}

/// @nodoc
mixin _$Eps {
  @JsonKey(name: "code")
  int get code => throw _privateConstructorUsedError;
  @JsonKey(name: "message")
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: "data")
  Data get data => throw _privateConstructorUsedError;

  /// Serializes this Eps to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Eps
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpsCopyWith<Eps> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpsCopyWith<$Res> {
  factory $EpsCopyWith(Eps value, $Res Function(Eps) then) =
      _$EpsCopyWithImpl<$Res, Eps>;
  @useResult
  $Res call(
      {@JsonKey(name: "code") int code,
      @JsonKey(name: "message") String message,
      @JsonKey(name: "data") Data data});

  $DataCopyWith<$Res> get data;
}

/// @nodoc
class _$EpsCopyWithImpl<$Res, $Val extends Eps> implements $EpsCopyWith<$Res> {
  _$EpsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Eps
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

  /// Create a copy of Eps
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
abstract class _$$EpsImplCopyWith<$Res> implements $EpsCopyWith<$Res> {
  factory _$$EpsImplCopyWith(_$EpsImpl value, $Res Function(_$EpsImpl) then) =
      __$$EpsImplCopyWithImpl<$Res>;
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
class __$$EpsImplCopyWithImpl<$Res> extends _$EpsCopyWithImpl<$Res, _$EpsImpl>
    implements _$$EpsImplCopyWith<$Res> {
  __$$EpsImplCopyWithImpl(_$EpsImpl _value, $Res Function(_$EpsImpl) _then)
      : super(_value, _then);

  /// Create a copy of Eps
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? message = null,
    Object? data = null,
  }) {
    return _then(_$EpsImpl(
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
class _$EpsImpl implements _Eps {
  const _$EpsImpl(
      {@JsonKey(name: "code") required this.code,
      @JsonKey(name: "message") required this.message,
      @JsonKey(name: "data") required this.data});

  factory _$EpsImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpsImplFromJson(json);

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
    return 'Eps(code: $code, message: $message, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpsImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.data, data) || other.data == data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, code, message, data);

  /// Create a copy of Eps
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpsImplCopyWith<_$EpsImpl> get copyWith =>
      __$$EpsImplCopyWithImpl<_$EpsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpsImplToJson(
      this,
    );
  }
}

abstract class _Eps implements Eps {
  const factory _Eps(
      {@JsonKey(name: "code") required final int code,
      @JsonKey(name: "message") required final String message,
      @JsonKey(name: "data") required final Data data}) = _$EpsImpl;

  factory _Eps.fromJson(Map<String, dynamic> json) = _$EpsImpl.fromJson;

  @override
  @JsonKey(name: "code")
  int get code;
  @override
  @JsonKey(name: "message")
  String get message;
  @override
  @JsonKey(name: "data")
  Data get data;

  /// Create a copy of Eps
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpsImplCopyWith<_$EpsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Data _$DataFromJson(Map<String, dynamic> json) {
  return _Data.fromJson(json);
}

/// @nodoc
mixin _$Data {
  @JsonKey(name: "eps")
  EpsClass get eps => throw _privateConstructorUsedError;

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
  $Res call({@JsonKey(name: "eps") EpsClass eps});

  $EpsClassCopyWith<$Res> get eps;
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
    Object? eps = null,
  }) {
    return _then(_value.copyWith(
      eps: null == eps
          ? _value.eps
          : eps // ignore: cast_nullable_to_non_nullable
              as EpsClass,
    ) as $Val);
  }

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EpsClassCopyWith<$Res> get eps {
    return $EpsClassCopyWith<$Res>(_value.eps, (value) {
      return _then(_value.copyWith(eps: value) as $Val);
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
  $Res call({@JsonKey(name: "eps") EpsClass eps});

  @override
  $EpsClassCopyWith<$Res> get eps;
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
    Object? eps = null,
  }) {
    return _then(_$DataImpl(
      eps: null == eps
          ? _value.eps
          : eps // ignore: cast_nullable_to_non_nullable
              as EpsClass,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DataImpl implements _Data {
  const _$DataImpl({@JsonKey(name: "eps") required this.eps});

  factory _$DataImpl.fromJson(Map<String, dynamic> json) =>
      _$$DataImplFromJson(json);

  @override
  @JsonKey(name: "eps")
  final EpsClass eps;

  @override
  String toString() {
    return 'Data(eps: $eps)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DataImpl &&
            (identical(other.eps, eps) || other.eps == eps));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, eps);

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
  const factory _Data({@JsonKey(name: "eps") required final EpsClass eps}) =
      _$DataImpl;

  factory _Data.fromJson(Map<String, dynamic> json) = _$DataImpl.fromJson;

  @override
  @JsonKey(name: "eps")
  EpsClass get eps;

  /// Create a copy of Data
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DataImplCopyWith<_$DataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EpsClass _$EpsClassFromJson(Map<String, dynamic> json) {
  return _EpsClass.fromJson(json);
}

/// @nodoc
mixin _$EpsClass {
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

  /// Serializes this EpsClass to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EpsClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpsClassCopyWith<EpsClass> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpsClassCopyWith<$Res> {
  factory $EpsClassCopyWith(EpsClass value, $Res Function(EpsClass) then) =
      _$EpsClassCopyWithImpl<$Res, EpsClass>;
  @useResult
  $Res call(
      {@JsonKey(name: "docs") List<Doc> docs,
      @JsonKey(name: "total") int total,
      @JsonKey(name: "limit") int limit,
      @JsonKey(name: "page") int page,
      @JsonKey(name: "pages") int pages});
}

/// @nodoc
class _$EpsClassCopyWithImpl<$Res, $Val extends EpsClass>
    implements $EpsClassCopyWith<$Res> {
  _$EpsClassCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpsClass
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
abstract class _$$EpsClassImplCopyWith<$Res>
    implements $EpsClassCopyWith<$Res> {
  factory _$$EpsClassImplCopyWith(
          _$EpsClassImpl value, $Res Function(_$EpsClassImpl) then) =
      __$$EpsClassImplCopyWithImpl<$Res>;
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
class __$$EpsClassImplCopyWithImpl<$Res>
    extends _$EpsClassCopyWithImpl<$Res, _$EpsClassImpl>
    implements _$$EpsClassImplCopyWith<$Res> {
  __$$EpsClassImplCopyWithImpl(
      _$EpsClassImpl _value, $Res Function(_$EpsClassImpl) _then)
      : super(_value, _then);

  /// Create a copy of EpsClass
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
    return _then(_$EpsClassImpl(
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
class _$EpsClassImpl implements _EpsClass {
  const _$EpsClassImpl(
      {@JsonKey(name: "docs") required final List<Doc> docs,
      @JsonKey(name: "total") required this.total,
      @JsonKey(name: "limit") required this.limit,
      @JsonKey(name: "page") required this.page,
      @JsonKey(name: "pages") required this.pages})
      : _docs = docs;

  factory _$EpsClassImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpsClassImplFromJson(json);

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
    return 'EpsClass(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpsClassImpl &&
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

  /// Create a copy of EpsClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpsClassImplCopyWith<_$EpsClassImpl> get copyWith =>
      __$$EpsClassImplCopyWithImpl<_$EpsClassImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpsClassImplToJson(
      this,
    );
  }
}

abstract class _EpsClass implements EpsClass {
  const factory _EpsClass(
      {@JsonKey(name: "docs") required final List<Doc> docs,
      @JsonKey(name: "total") required final int total,
      @JsonKey(name: "limit") required final int limit,
      @JsonKey(name: "page") required final int page,
      @JsonKey(name: "pages") required final int pages}) = _$EpsClassImpl;

  factory _EpsClass.fromJson(Map<String, dynamic> json) =
      _$EpsClassImpl.fromJson;

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

  /// Create a copy of EpsClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpsClassImplCopyWith<_$EpsClassImpl> get copyWith =>
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
  @JsonKey(name: "order")
  int get order => throw _privateConstructorUsedError;
  @JsonKey(name: "updated_at")
  DateTime get updatedAt => throw _privateConstructorUsedError;
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
      @JsonKey(name: "title") String title,
      @JsonKey(name: "order") int order,
      @JsonKey(name: "updated_at") DateTime updatedAt,
      @JsonKey(name: "id") String docId});
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
    Object? order = null,
    Object? updatedAt = null,
    Object? docId = null,
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
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      docId: null == docId
          ? _value.docId
          : docId // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
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
      @JsonKey(name: "title") String title,
      @JsonKey(name: "order") int order,
      @JsonKey(name: "updated_at") DateTime updatedAt,
      @JsonKey(name: "id") String docId});
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
    Object? order = null,
    Object? updatedAt = null,
    Object? docId = null,
  }) {
    return _then(_$DocImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
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
      @JsonKey(name: "title") required this.title,
      @JsonKey(name: "order") required this.order,
      @JsonKey(name: "updated_at") required this.updatedAt,
      @JsonKey(name: "id") required this.docId});

  factory _$DocImpl.fromJson(Map<String, dynamic> json) =>
      _$$DocImplFromJson(json);

  @override
  @JsonKey(name: "_id")
  final String id;
  @override
  @JsonKey(name: "title")
  final String title;
  @override
  @JsonKey(name: "order")
  final int order;
  @override
  @JsonKey(name: "updated_at")
  final DateTime updatedAt;
  @override
  @JsonKey(name: "id")
  final String docId;

  @override
  String toString() {
    return 'Doc(id: $id, title: $title, order: $order, updatedAt: $updatedAt, docId: $docId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DocImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.docId, docId) || other.docId == docId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, order, updatedAt, docId);

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
      @JsonKey(name: "title") required final String title,
      @JsonKey(name: "order") required final int order,
      @JsonKey(name: "updated_at") required final DateTime updatedAt,
      @JsonKey(name: "id") required final String docId}) = _$DocImpl;

  factory _Doc.fromJson(Map<String, dynamic> json) = _$DocImpl.fromJson;

  @override
  @JsonKey(name: "_id")
  String get id;
  @override
  @JsonKey(name: "title")
  String get title;
  @override
  @JsonKey(name: "order")
  int get order;
  @override
  @JsonKey(name: "updated_at")
  DateTime get updatedAt;
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
