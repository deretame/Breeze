// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Page {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageCopyWith<Page> get copyWith => _$PageCopyWithImpl<Page>(this as Page, _$identity);

  /// Serializes this Page to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Page&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'Page(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $PageCopyWith<$Res>  {
  factory $PageCopyWith(Page value, $Res Function(Page) _then) = _$PageCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$PageCopyWithImpl<$Res>
    implements $PageCopyWith<$Res> {
  _$PageCopyWithImpl(this._self, this._then);

  final Page _self;
  final $Res Function(Page) _then;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [Page].
extension PagePatterns on Page {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Page value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Page() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Page value)  $default,){
final _that = this;
switch (_that) {
case _Page():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Page value)?  $default,){
final _that = this;
switch (_that) {
case _Page() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "code")  int code, @JsonKey(name: "message")  String message, @JsonKey(name: "data")  Data data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Page() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "code")  int code, @JsonKey(name: "message")  String message, @JsonKey(name: "data")  Data data)  $default,) {final _that = this;
switch (_that) {
case _Page():
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "code")  int code, @JsonKey(name: "message")  String message, @JsonKey(name: "data")  Data data)?  $default,) {final _that = this;
switch (_that) {
case _Page() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Page implements Page {
  const _Page({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _Page.fromJson(Map<String, dynamic> json) => _$PageFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageCopyWith<_Page> get copyWith => __$PageCopyWithImpl<_Page>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Page&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'Page(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$PageCopyWith<$Res> implements $PageCopyWith<$Res> {
  factory _$PageCopyWith(_Page value, $Res Function(_Page) _then) = __$PageCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$PageCopyWithImpl<$Res>
    implements _$PageCopyWith<$Res> {
  __$PageCopyWithImpl(this._self, this._then);

  final _Page _self;
  final $Res Function(_Page) _then;

/// Create a copy of Page
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_Page(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of Page
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

@JsonKey(name: "pages") Pages get pages;@JsonKey(name: "ep") Ep get ep;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.ep, ep) || other.ep == ep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pages,ep);

@override
String toString() {
  return 'Data(pages: $pages, ep: $ep)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "pages") Pages pages,@JsonKey(name: "ep") Ep ep
});


$PagesCopyWith<$Res> get pages;$EpCopyWith<$Res> get ep;

}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pages = null,Object? ep = null,}) {
  return _then(_self.copyWith(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Pages,ep: null == ep ? _self.ep : ep // ignore: cast_nullable_to_non_nullable
as Ep,
  ));
}
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PagesCopyWith<$Res> get pages {
  
  return $PagesCopyWith<$Res>(_self.pages, (value) {
    return _then(_self.copyWith(pages: value));
  });
}/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpCopyWith<$Res> get ep {
  
  return $EpCopyWith<$Res>(_self.ep, (value) {
    return _then(_self.copyWith(ep: value));
  });
}
}


/// Adds pattern-matching-related methods to [Data].
extension DataPatterns on Data {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Data value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Data() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Data value)  $default,){
final _that = this;
switch (_that) {
case _Data():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Data value)?  $default,){
final _that = this;
switch (_that) {
case _Data() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "pages")  Pages pages, @JsonKey(name: "ep")  Ep ep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.pages,_that.ep);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "pages")  Pages pages, @JsonKey(name: "ep")  Ep ep)  $default,) {final _that = this;
switch (_that) {
case _Data():
return $default(_that.pages,_that.ep);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "pages")  Pages pages, @JsonKey(name: "ep")  Ep ep)?  $default,) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.pages,_that.ep);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "pages") required this.pages, @JsonKey(name: "ep") required this.ep});
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

@override@JsonKey(name: "pages") final  Pages pages;
@override@JsonKey(name: "ep") final  Ep ep;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.ep, ep) || other.ep == ep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pages,ep);

@override
String toString() {
  return 'Data(pages: $pages, ep: $ep)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "pages") Pages pages,@JsonKey(name: "ep") Ep ep
});


@override $PagesCopyWith<$Res> get pages;@override $EpCopyWith<$Res> get ep;

}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pages = null,Object? ep = null,}) {
  return _then(_Data(
pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as Pages,ep: null == ep ? _self.ep : ep // ignore: cast_nullable_to_non_nullable
as Ep,
  ));
}

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PagesCopyWith<$Res> get pages {
  
  return $PagesCopyWith<$Res>(_self.pages, (value) {
    return _then(_self.copyWith(pages: value));
  });
}/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EpCopyWith<$Res> get ep {
  
  return $EpCopyWith<$Res>(_self.ep, (value) {
    return _then(_self.copyWith(ep: value));
  });
}
}


/// @nodoc
mixin _$Ep {

@JsonKey(name: "_id") String get id;@JsonKey(name: "title") String get title;
/// Create a copy of Ep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EpCopyWith<Ep> get copyWith => _$EpCopyWithImpl<Ep>(this as Ep, _$identity);

  /// Serializes this Ep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ep&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'Ep(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class $EpCopyWith<$Res>  {
  factory $EpCopyWith(Ep value, $Res Function(Ep) _then) = _$EpCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ep() when $default != null:
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title)  $default,) {final _that = this;
switch (_that) {
case _Ep():
return $default(_that.id,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title)?  $default,) {final _that = this;
switch (_that) {
case _Ep() when $default != null:
return $default(_that.id,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ep implements Ep {
  const _Ep({@JsonKey(name: "_id") required this.id, @JsonKey(name: "title") required this.title});
  factory _Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "title") final  String title;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ep&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title);

@override
String toString() {
  return 'Ep(id: $id, title: $title)';
}


}

/// @nodoc
abstract mixin class _$EpCopyWith<$Res> implements $EpCopyWith<$Res> {
  factory _$EpCopyWith(_Ep value, $Res Function(_Ep) _then) = __$EpCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,}) {
  return _then(_Ep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Pages {

@JsonKey(name: "docs") List<Doc> get docs;@JsonKey(name: "total") int get total;@JsonKey(name: "limit") int get limit;@JsonKey(name: "page") int get page;@JsonKey(name: "pages") int get pages;
/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagesCopyWith<Pages> get copyWith => _$PagesCopyWithImpl<Pages>(this as Pages, _$identity);

  /// Serializes this Pages to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pages&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'Pages(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $PagesCopyWith<$Res>  {
  factory $PagesCopyWith(Pages value, $Res Function(Pages) _then) = _$PagesCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") int page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class _$PagesCopyWithImpl<$Res>
    implements $PagesCopyWith<$Res> {
  _$PagesCopyWithImpl(this._self, this._then);

  final Pages _self;
  final $Res Function(Pages) _then;

/// Create a copy of Pages
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


/// Adds pattern-matching-related methods to [Pages].
extension PagesPatterns on Pages {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pages value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pages() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pages value)  $default,){
final _that = this;
switch (_that) {
case _Pages():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pages value)?  $default,){
final _that = this;
switch (_that) {
case _Pages() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<Doc> docs, @JsonKey(name: "total")  int total, @JsonKey(name: "limit")  int limit, @JsonKey(name: "page")  int page, @JsonKey(name: "pages")  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pages() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<Doc> docs, @JsonKey(name: "total")  int total, @JsonKey(name: "limit")  int limit, @JsonKey(name: "page")  int page, @JsonKey(name: "pages")  int pages)  $default,) {final _that = this;
switch (_that) {
case _Pages():
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "docs")  List<Doc> docs, @JsonKey(name: "total")  int total, @JsonKey(name: "limit")  int limit, @JsonKey(name: "page")  int page, @JsonKey(name: "pages")  int pages)?  $default,) {final _that = this;
switch (_that) {
case _Pages() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pages implements Pages {
  const _Pages({@JsonKey(name: "docs") required final  List<Doc> docs, @JsonKey(name: "total") required this.total, @JsonKey(name: "limit") required this.limit, @JsonKey(name: "page") required this.page, @JsonKey(name: "pages") required this.pages}): _docs = docs;
  factory _Pages.fromJson(Map<String, dynamic> json) => _$PagesFromJson(json);

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

/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagesCopyWith<_Pages> get copyWith => __$PagesCopyWithImpl<_Pages>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PagesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pages&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'Pages(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$PagesCopyWith<$Res> implements $PagesCopyWith<$Res> {
  factory _$PagesCopyWith(_Pages value, $Res Function(_Pages) _then) = __$PagesCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") int page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class __$PagesCopyWithImpl<$Res>
    implements _$PagesCopyWith<$Res> {
  __$PagesCopyWithImpl(this._self, this._then);

  final _Pages _self;
  final $Res Function(_Pages) _then;

/// Create a copy of Pages
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_Pages(
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

@JsonKey(name: "_id") String get id;@JsonKey(name: "media") Media get media;@JsonKey(name: "id") String get docId;
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocCopyWith<Doc> get copyWith => _$DocCopyWithImpl<Doc>(this as Doc, _$identity);

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.media, media) || other.media == media)&&(identical(other.docId, docId) || other.docId == docId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,media,docId);

@override
String toString() {
  return 'Doc(id: $id, media: $media, docId: $docId)';
}


}

/// @nodoc
abstract mixin class $DocCopyWith<$Res>  {
  factory $DocCopyWith(Doc value, $Res Function(Doc) _then) = _$DocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "media") Media media,@JsonKey(name: "id") String docId
});


$MediaCopyWith<$Res> get media;

}
/// @nodoc
class _$DocCopyWithImpl<$Res>
    implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._self, this._then);

  final Doc _self;
  final $Res Function(Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? media = null,Object? docId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Media,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaCopyWith<$Res> get media {
  
  return $MediaCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// Adds pattern-matching-related methods to [Doc].
extension DocPatterns on Doc {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Doc value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Doc() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Doc value)  $default,){
final _that = this;
switch (_that) {
case _Doc():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Doc value)?  $default,){
final _that = this;
switch (_that) {
case _Doc() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "media")  Media media, @JsonKey(name: "id")  String docId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Doc() when $default != null:
return $default(_that.id,_that.media,_that.docId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "media")  Media media, @JsonKey(name: "id")  String docId)  $default,) {final _that = this;
switch (_that) {
case _Doc():
return $default(_that.id,_that.media,_that.docId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "media")  Media media, @JsonKey(name: "id")  String docId)?  $default,) {final _that = this;
switch (_that) {
case _Doc() when $default != null:
return $default(_that.id,_that.media,_that.docId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Doc implements Doc {
  const _Doc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "media") required this.media, @JsonKey(name: "id") required this.docId});
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "media") final  Media media;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.media, media) || other.media == media)&&(identical(other.docId, docId) || other.docId == docId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,media,docId);

@override
String toString() {
  return 'Doc(id: $id, media: $media, docId: $docId)';
}


}

/// @nodoc
abstract mixin class _$DocCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$DocCopyWith(_Doc value, $Res Function(_Doc) _then) = __$DocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "media") Media media,@JsonKey(name: "id") String docId
});


@override $MediaCopyWith<$Res> get media;

}
/// @nodoc
class __$DocCopyWithImpl<$Res>
    implements _$DocCopyWith<$Res> {
  __$DocCopyWithImpl(this._self, this._then);

  final _Doc _self;
  final $Res Function(_Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? media = null,Object? docId = null,}) {
  return _then(_Doc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,media: null == media ? _self.media : media // ignore: cast_nullable_to_non_nullable
as Media,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MediaCopyWith<$Res> get media {
  
  return $MediaCopyWith<$Res>(_self.media, (value) {
    return _then(_self.copyWith(media: value));
  });
}
}


/// @nodoc
mixin _$Media {

@JsonKey(name: "originalName") String get originalName;@JsonKey(name: "path") String get path;@JsonKey(name: "fileServer") String get fileServer;
/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaCopyWith<Media> get copyWith => _$MediaCopyWithImpl<Media>(this as Media, _$identity);

  /// Serializes this Media to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Media&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer);

@override
String toString() {
  return 'Media(originalName: $originalName, path: $path, fileServer: $fileServer)';
}


}

/// @nodoc
abstract mixin class $MediaCopyWith<$Res>  {
  factory $MediaCopyWith(Media value, $Res Function(Media) _then) = _$MediaCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer
});




}
/// @nodoc
class _$MediaCopyWithImpl<$Res>
    implements $MediaCopyWith<$Res> {
  _$MediaCopyWithImpl(this._self, this._then);

  final Media _self;
  final $Res Function(Media) _then;

/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,}) {
  return _then(_self.copyWith(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Media].
extension MediaPatterns on Media {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Media value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Media() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Media value)  $default,){
final _that = this;
switch (_that) {
case _Media():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Media value)?  $default,){
final _that = this;
switch (_that) {
case _Media() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "originalName")  String originalName, @JsonKey(name: "path")  String path, @JsonKey(name: "fileServer")  String fileServer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Media() when $default != null:
return $default(_that.originalName,_that.path,_that.fileServer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "originalName")  String originalName, @JsonKey(name: "path")  String path, @JsonKey(name: "fileServer")  String fileServer)  $default,) {final _that = this;
switch (_that) {
case _Media():
return $default(_that.originalName,_that.path,_that.fileServer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "originalName")  String originalName, @JsonKey(name: "path")  String path, @JsonKey(name: "fileServer")  String fileServer)?  $default,) {final _that = this;
switch (_that) {
case _Media() when $default != null:
return $default(_that.originalName,_that.path,_that.fileServer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Media implements Media {
  const _Media({@JsonKey(name: "originalName") required this.originalName, @JsonKey(name: "path") required this.path, @JsonKey(name: "fileServer") required this.fileServer});
  factory _Media.fromJson(Map<String, dynamic> json) => _$MediaFromJson(json);

@override@JsonKey(name: "originalName") final  String originalName;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "fileServer") final  String fileServer;

/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaCopyWith<_Media> get copyWith => __$MediaCopyWithImpl<_Media>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MediaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Media&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer);

@override
String toString() {
  return 'Media(originalName: $originalName, path: $path, fileServer: $fileServer)';
}


}

/// @nodoc
abstract mixin class _$MediaCopyWith<$Res> implements $MediaCopyWith<$Res> {
  factory _$MediaCopyWith(_Media value, $Res Function(_Media) _then) = __$MediaCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer
});




}
/// @nodoc
class __$MediaCopyWithImpl<$Res>
    implements _$MediaCopyWith<$Res> {
  __$MediaCopyWithImpl(this._self, this._then);

  final _Media _self;
  final $Res Function(_Media) _then;

/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,}) {
  return _then(_Media(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
