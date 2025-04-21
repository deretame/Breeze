// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eps.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Eps {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpsCopyWith<Eps> get copyWith => _$EpsCopyWithImpl<Eps>(this as Eps, _$identity);

  /// Serializes this Eps to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Eps&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'Eps(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $EpsCopyWith<$Res>  {
  factory $EpsCopyWith(Eps value, $Res Function(Eps) _then) = _$EpsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$EpsCopyWithImpl<$Res>
    implements $EpsCopyWith<$Res> {
  _$EpsCopyWithImpl(this._self, this._then);

  final Eps _self;
  final $Res Function(Eps) _then;

/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _Eps implements Eps {
  const _Eps({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _Eps.fromJson(Map<String, dynamic> json) => _$EpsFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpsCopyWith<_Eps> get copyWith => __$EpsCopyWithImpl<_Eps>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Eps&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'Eps(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$EpsCopyWith<$Res> implements $EpsCopyWith<$Res> {
  factory _$EpsCopyWith(_Eps value, $Res Function(_Eps) _then) = __$EpsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$EpsCopyWithImpl<$Res>
    implements _$EpsCopyWith<$Res> {
  __$EpsCopyWithImpl(this._self, this._then);

  final _Eps _self;
  final $Res Function(_Eps) _then;

/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_Eps(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of Eps
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$Data {

@JsonKey(name: "eps") EpsClass get eps;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&(identical(other.eps, eps) || other.eps == eps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eps);

@override
String toString() {
  return 'Data(eps: $eps)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "eps") EpsClass eps
});


$EpsClassCopyWith<$Res> get eps;

}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? eps = null,}) {
  return _then(_self.copyWith(
eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as EpsClass,
  ));
}
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpsClassCopyWith<$Res> get eps {
  
  return $EpsClassCopyWith<$Res>(_self.eps, (value) {
    return _then(_self.copyWith(eps: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "eps") required this.eps});
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

@override@JsonKey(name: "eps") final  EpsClass eps;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DataCopyWith<_Data> get copyWith => __$DataCopyWithImpl<_Data>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&(identical(other.eps, eps) || other.eps == eps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,eps);

@override
String toString() {
  return 'Data(eps: $eps)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "eps") EpsClass eps
});


@override $EpsClassCopyWith<$Res> get eps;

}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? eps = null,}) {
  return _then(_Data(
eps: null == eps ? _self.eps : eps // ignore: cast_nullable_to_non_nullable
as EpsClass,
  ));
}

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpsClassCopyWith<$Res> get eps {
  
  return $EpsClassCopyWith<$Res>(_self.eps, (value) {
    return _then(_self.copyWith(eps: value));
  });
}
}


/// @nodoc
mixin _$EpsClass {

@JsonKey(name: "docs") List<Doc> get docs;@JsonKey(name: "total") int get total;@JsonKey(name: "limit") int get limit;@JsonKey(name: "page") int get page;@JsonKey(name: "pages") int get pages;
/// Create a copy of EpsClass
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpsClassCopyWith<EpsClass> get copyWith => _$EpsClassCopyWithImpl<EpsClass>(this as EpsClass, _$identity);

  /// Serializes this EpsClass to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EpsClass&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'EpsClass(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $EpsClassCopyWith<$Res>  {
  factory $EpsClassCopyWith(EpsClass value, $Res Function(EpsClass) _then) = _$EpsClassCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") int page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class _$EpsClassCopyWithImpl<$Res>
    implements $EpsClassCopyWith<$Res> {
  _$EpsClassCopyWithImpl(this._self, this._then);

  final EpsClass _self;
  final $Res Function(EpsClass) _then;

/// Create a copy of EpsClass
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _EpsClass implements EpsClass {
  const _EpsClass({@JsonKey(name: "docs") required final  List<Doc> docs, @JsonKey(name: "total") required this.total, @JsonKey(name: "limit") required this.limit, @JsonKey(name: "page") required this.page, @JsonKey(name: "pages") required this.pages}): _docs = docs;
  factory _EpsClass.fromJson(Map<String, dynamic> json) => _$EpsClassFromJson(json);

 final  List<Doc> _docs;
@override@JsonKey(name: "docs") List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override@JsonKey(name: "total") final  int total;
@override@JsonKey(name: "limit") final  int limit;
@override@JsonKey(name: "page") final  int page;
@override@JsonKey(name: "pages") final  int pages;

/// Create a copy of EpsClass
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EpsClassCopyWith<_EpsClass> get copyWith => __$EpsClassCopyWithImpl<_EpsClass>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EpsClassToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EpsClass&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'EpsClass(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$EpsClassCopyWith<$Res> implements $EpsClassCopyWith<$Res> {
  factory _$EpsClassCopyWith(_EpsClass value, $Res Function(_EpsClass) _then) = __$EpsClassCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") int page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class __$EpsClassCopyWithImpl<$Res>
    implements _$EpsClassCopyWith<$Res> {
  __$EpsClassCopyWithImpl(this._self, this._then);

  final _EpsClass _self;
  final $Res Function(_EpsClass) _then;

/// Create a copy of EpsClass
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_EpsClass(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Doc {

@JsonKey(name: "_id") String get id;@JsonKey(name: "title") String get title;@JsonKey(name: "order") int get order;@JsonKey(name: "updated_at") DateTime get updatedAt;@JsonKey(name: "id") String get docId;
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocCopyWith<Doc> get copyWith => _$DocCopyWithImpl<Doc>(this as Doc, _$identity);

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.docId, docId) || other.docId == docId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,updatedAt,docId);

@override
String toString() {
  return 'Doc(id: $id, title: $title, order: $order, updatedAt: $updatedAt, docId: $docId)';
}


}

/// @nodoc
abstract mixin class $DocCopyWith<$Res>  {
  factory $DocCopyWith(Doc value, $Res Function(Doc) _then) = _$DocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "order") int order,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "id") String docId
});




}
/// @nodoc
class _$DocCopyWithImpl<$Res>
    implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._self, this._then);

  final Doc _self;
  final $Res Function(Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? order = null,Object? updatedAt = null,Object? docId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _Doc implements Doc {
  const _Doc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "title") required this.title, @JsonKey(name: "order") required this.order, @JsonKey(name: "updated_at") required this.updatedAt, @JsonKey(name: "id") required this.docId});
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "order") final  int order;
@override@JsonKey(name: "updated_at") final  DateTime updatedAt;
@override@JsonKey(name: "id") final  String docId;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocCopyWith<_Doc> get copyWith => __$DocCopyWithImpl<_Doc>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.docId, docId) || other.docId == docId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,order,updatedAt,docId);

@override
String toString() {
  return 'Doc(id: $id, title: $title, order: $order, updatedAt: $updatedAt, docId: $docId)';
}


}

/// @nodoc
abstract mixin class _$DocCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$DocCopyWith(_Doc value, $Res Function(_Doc) _then) = __$DocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "order") int order,@JsonKey(name: "updated_at") DateTime updatedAt,@JsonKey(name: "id") String docId
});




}
/// @nodoc
class __$DocCopyWithImpl<$Res>
    implements _$DocCopyWith<$Res> {
  __$DocCopyWithImpl(this._self, this._then);

  final _Doc _self;
  final $Res Function(_Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? order = null,Object? updatedAt = null,Object? docId = null,}) {
  return _then(_Doc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
