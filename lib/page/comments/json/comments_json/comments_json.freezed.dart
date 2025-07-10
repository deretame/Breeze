// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comments_json.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommentsJson {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsJsonCopyWith<CommentsJson> get copyWith => _$CommentsJsonCopyWithImpl<CommentsJson>(this as CommentsJson, _$identity);

  /// Serializes this CommentsJson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsJson&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'CommentsJson(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $CommentsJsonCopyWith<$Res>  {
  factory $CommentsJsonCopyWith(CommentsJson value, $Res Function(CommentsJson) _then) = _$CommentsJsonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$CommentsJsonCopyWithImpl<$Res>
    implements $CommentsJsonCopyWith<$Res> {
  _$CommentsJsonCopyWithImpl(this._self, this._then);

  final CommentsJson _self;
  final $Res Function(CommentsJson) _then;

/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [CommentsJson].
extension CommentsJsonPatterns on CommentsJson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommentsJson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommentsJson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommentsJson value)  $default,){
final _that = this;
switch (_that) {
case _CommentsJson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommentsJson value)?  $default,){
final _that = this;
switch (_that) {
case _CommentsJson() when $default != null:
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
case _CommentsJson() when $default != null:
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
case _CommentsJson():
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
case _CommentsJson() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommentsJson implements CommentsJson {
  const _CommentsJson({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _CommentsJson.fromJson(Map<String, dynamic> json) => _$CommentsJsonFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsJsonCopyWith<_CommentsJson> get copyWith => __$CommentsJsonCopyWithImpl<_CommentsJson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentsJsonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommentsJson&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'CommentsJson(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$CommentsJsonCopyWith<$Res> implements $CommentsJsonCopyWith<$Res> {
  factory _$CommentsJsonCopyWith(_CommentsJson value, $Res Function(_CommentsJson) _then) = __$CommentsJsonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$CommentsJsonCopyWithImpl<$Res>
    implements _$CommentsJsonCopyWith<$Res> {
  __$CommentsJsonCopyWithImpl(this._self, this._then);

  final _CommentsJson _self;
  final $Res Function(_CommentsJson) _then;

/// Create a copy of CommentsJson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_CommentsJson(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of CommentsJson
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

@JsonKey(name: "comments") Comments get comments;@JsonKey(name: "topComments") List<TopComment> get topComments;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&(identical(other.comments, comments) || other.comments == comments)&&const DeepCollectionEquality().equals(other.topComments, topComments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments,const DeepCollectionEquality().hash(topComments));

@override
String toString() {
  return 'Data(comments: $comments, topComments: $topComments)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comments") Comments comments,@JsonKey(name: "topComments") List<TopComment> topComments
});


$CommentsCopyWith<$Res> get comments;

}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comments = null,Object? topComments = null,}) {
  return _then(_self.copyWith(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as Comments,topComments: null == topComments ? _self.topComments : topComments // ignore: cast_nullable_to_non_nullable
as List<TopComment>,
  ));
}
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentsCopyWith<$Res> get comments {
  
  return $CommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "comments")  Comments comments, @JsonKey(name: "topComments")  List<TopComment> topComments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.comments,_that.topComments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "comments")  Comments comments, @JsonKey(name: "topComments")  List<TopComment> topComments)  $default,) {final _that = this;
switch (_that) {
case _Data():
return $default(_that.comments,_that.topComments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "comments")  Comments comments, @JsonKey(name: "topComments")  List<TopComment> topComments)?  $default,) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.comments,_that.topComments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "comments") required this.comments, @JsonKey(name: "topComments") required final  List<TopComment> topComments}): _topComments = topComments;
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

@override@JsonKey(name: "comments") final  Comments comments;
 final  List<TopComment> _topComments;
@override@JsonKey(name: "topComments") List<TopComment> get topComments {
  if (_topComments is EqualUnmodifiableListView) return _topComments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topComments);
}


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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&(identical(other.comments, comments) || other.comments == comments)&&const DeepCollectionEquality().equals(other._topComments, _topComments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,comments,const DeepCollectionEquality().hash(_topComments));

@override
String toString() {
  return 'Data(comments: $comments, topComments: $topComments)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comments") Comments comments,@JsonKey(name: "topComments") List<TopComment> topComments
});


@override $CommentsCopyWith<$Res> get comments;

}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comments = null,Object? topComments = null,}) {
  return _then(_Data(
comments: null == comments ? _self.comments : comments // ignore: cast_nullable_to_non_nullable
as Comments,topComments: null == topComments ? _self._topComments : topComments // ignore: cast_nullable_to_non_nullable
as List<TopComment>,
  ));
}

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CommentsCopyWith<$Res> get comments {
  
  return $CommentsCopyWith<$Res>(_self.comments, (value) {
    return _then(_self.copyWith(comments: value));
  });
}
}


/// @nodoc
mixin _$Comments {

@JsonKey(name: "docs") List<Doc> get docs;@JsonKey(name: "total") int get total;@JsonKey(name: "limit") int get limit;@JsonKey(name: "page") String get page;@JsonKey(name: "pages") int get pages;
/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsCopyWith<Comments> get copyWith => _$CommentsCopyWithImpl<Comments>(this as Comments, _$identity);

  /// Serializes this Comments to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comments&&const DeepCollectionEquality().equals(other.docs, docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(docs),total,limit,page,pages);

@override
String toString() {
  return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $CommentsCopyWith<$Res>  {
  factory $CommentsCopyWith(Comments value, $Res Function(Comments) _then) = _$CommentsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") String page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class _$CommentsCopyWithImpl<$Res>
    implements $CommentsCopyWith<$Res> {
  _$CommentsCopyWithImpl(this._self, this._then);

  final Comments _self;
  final $Res Function(Comments) _then;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_self.copyWith(
docs: null == docs ? _self.docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Comments].
extension CommentsPatterns on Comments {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comments value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comments() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comments value)  $default,){
final _that = this;
switch (_that) {
case _Comments():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comments value)?  $default,){
final _that = this;
switch (_that) {
case _Comments() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<Doc> docs, @JsonKey(name: "total")  int total, @JsonKey(name: "limit")  int limit, @JsonKey(name: "page")  String page, @JsonKey(name: "pages")  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comments() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "docs")  List<Doc> docs, @JsonKey(name: "total")  int total, @JsonKey(name: "limit")  int limit, @JsonKey(name: "page")  String page, @JsonKey(name: "pages")  int pages)  $default,) {final _that = this;
switch (_that) {
case _Comments():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "docs")  List<Doc> docs, @JsonKey(name: "total")  int total, @JsonKey(name: "limit")  int limit, @JsonKey(name: "page")  String page, @JsonKey(name: "pages")  int pages)?  $default,) {final _that = this;
switch (_that) {
case _Comments() when $default != null:
return $default(_that.docs,_that.total,_that.limit,_that.page,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comments implements Comments {
  const _Comments({@JsonKey(name: "docs") required final  List<Doc> docs, @JsonKey(name: "total") required this.total, @JsonKey(name: "limit") required this.limit, @JsonKey(name: "page") required this.page, @JsonKey(name: "pages") required this.pages}): _docs = docs;
  factory _Comments.fromJson(Map<String, dynamic> json) => _$CommentsFromJson(json);

 final  List<Doc> _docs;
@override@JsonKey(name: "docs") List<Doc> get docs {
  if (_docs is EqualUnmodifiableListView) return _docs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_docs);
}

@override@JsonKey(name: "total") final  int total;
@override@JsonKey(name: "limit") final  int limit;
@override@JsonKey(name: "page") final  String page;
@override@JsonKey(name: "pages") final  int pages;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommentsCopyWith<_Comments> get copyWith => __$CommentsCopyWithImpl<_Comments>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommentsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comments&&const DeepCollectionEquality().equals(other._docs, _docs)&&(identical(other.total, total) || other.total == total)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.page, page) || other.page == page)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_docs),total,limit,page,pages);

@override
String toString() {
  return 'Comments(docs: $docs, total: $total, limit: $limit, page: $page, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$CommentsCopyWith<$Res> implements $CommentsCopyWith<$Res> {
  factory _$CommentsCopyWith(_Comments value, $Res Function(_Comments) _then) = __$CommentsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "docs") List<Doc> docs,@JsonKey(name: "total") int total,@JsonKey(name: "limit") int limit,@JsonKey(name: "page") String page,@JsonKey(name: "pages") int pages
});




}
/// @nodoc
class __$CommentsCopyWithImpl<$Res>
    implements _$CommentsCopyWith<$Res> {
  __$CommentsCopyWithImpl(this._self, this._then);

  final _Comments _self;
  final $Res Function(_Comments) _then;

/// Create a copy of Comments
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? docs = null,Object? total = null,Object? limit = null,Object? page = null,Object? pages = null,}) {
  return _then(_Comments(
docs: null == docs ? _self._docs : docs // ignore: cast_nullable_to_non_nullable
as List<Doc>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as String,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Doc {

@JsonKey(name: "_id") String get id;@JsonKey(name: "content") String get content;@JsonKey(name: "_user") User get user;@JsonKey(name: "_comic") String get comic;@JsonKey(name: "totalComments") int get totalComments;@JsonKey(name: "isTop") bool get isTop;@JsonKey(name: "hide") bool get hide;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "id") String get docId;@JsonKey(name: "likesCount") int get likesCount;@JsonKey(name: "commentsCount") int get commentsCount;@JsonKey(name: "isLiked") bool get isLiked;
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocCopyWith<Doc> get copyWith => _$DocCopyWithImpl<Doc>(this as Doc, _$identity);

  /// Serializes this Doc to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.user, user) || other.user == user)&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.isTop, isTop) || other.isTop == isTop)&&(identical(other.hide, hide) || other.hide == hide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.docId, docId) || other.docId == docId)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,user,comic,totalComments,isTop,hide,createdAt,docId,likesCount,commentsCount,isLiked);

@override
String toString() {
  return 'Doc(id: $id, content: $content, user: $user, comic: $comic, totalComments: $totalComments, isTop: $isTop, hide: $hide, createdAt: $createdAt, docId: $docId, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class $DocCopyWith<$Res>  {
  factory $DocCopyWith(Doc value, $Res Function(Doc) _then) = _$DocCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "content") String content,@JsonKey(name: "_user") User user,@JsonKey(name: "_comic") String comic,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "isTop") bool isTop,@JsonKey(name: "hide") bool hide,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "id") String docId,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isLiked") bool isLiked
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$DocCopyWithImpl<$Res>
    implements $DocCopyWith<$Res> {
  _$DocCopyWithImpl(this._self, this._then);

  final Doc _self;
  final $Res Function(Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? user = null,Object? comic = null,Object? totalComments = null,Object? isTop = null,Object? hide = null,Object? createdAt = null,Object? docId = null,Object? likesCount = null,Object? commentsCount = null,Object? isLiked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as String,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,isTop: null == isTop ? _self.isTop : isTop // ignore: cast_nullable_to_non_nullable
as bool,hide: null == hide ? _self.hide : hide // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "content")  String content, @JsonKey(name: "_user")  User user, @JsonKey(name: "_comic")  String comic, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "isTop")  bool isTop, @JsonKey(name: "hide")  bool hide, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "id")  String docId, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isLiked")  bool isLiked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Doc() when $default != null:
return $default(_that.id,_that.content,_that.user,_that.comic,_that.totalComments,_that.isTop,_that.hide,_that.createdAt,_that.docId,_that.likesCount,_that.commentsCount,_that.isLiked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "content")  String content, @JsonKey(name: "_user")  User user, @JsonKey(name: "_comic")  String comic, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "isTop")  bool isTop, @JsonKey(name: "hide")  bool hide, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "id")  String docId, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isLiked")  bool isLiked)  $default,) {final _that = this;
switch (_that) {
case _Doc():
return $default(_that.id,_that.content,_that.user,_that.comic,_that.totalComments,_that.isTop,_that.hide,_that.createdAt,_that.docId,_that.likesCount,_that.commentsCount,_that.isLiked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "content")  String content, @JsonKey(name: "_user")  User user, @JsonKey(name: "_comic")  String comic, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "isTop")  bool isTop, @JsonKey(name: "hide")  bool hide, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "id")  String docId, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isLiked")  bool isLiked)?  $default,) {final _that = this;
switch (_that) {
case _Doc() when $default != null:
return $default(_that.id,_that.content,_that.user,_that.comic,_that.totalComments,_that.isTop,_that.hide,_that.createdAt,_that.docId,_that.likesCount,_that.commentsCount,_that.isLiked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Doc implements Doc {
  const _Doc({@JsonKey(name: "_id") required this.id, @JsonKey(name: "content") required this.content, @JsonKey(name: "_user") required this.user, @JsonKey(name: "_comic") required this.comic, @JsonKey(name: "totalComments") required this.totalComments, @JsonKey(name: "isTop") required this.isTop, @JsonKey(name: "hide") required this.hide, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "id") required this.docId, @JsonKey(name: "likesCount") required this.likesCount, @JsonKey(name: "commentsCount") required this.commentsCount, @JsonKey(name: "isLiked") required this.isLiked});
  factory _Doc.fromJson(Map<String, dynamic> json) => _$DocFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "content") final  String content;
@override@JsonKey(name: "_user") final  User user;
@override@JsonKey(name: "_comic") final  String comic;
@override@JsonKey(name: "totalComments") final  int totalComments;
@override@JsonKey(name: "isTop") final  bool isTop;
@override@JsonKey(name: "hide") final  bool hide;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "id") final  String docId;
@override@JsonKey(name: "likesCount") final  int likesCount;
@override@JsonKey(name: "commentsCount") final  int commentsCount;
@override@JsonKey(name: "isLiked") final  bool isLiked;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Doc&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.user, user) || other.user == user)&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.isTop, isTop) || other.isTop == isTop)&&(identical(other.hide, hide) || other.hide == hide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.docId, docId) || other.docId == docId)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,user,comic,totalComments,isTop,hide,createdAt,docId,likesCount,commentsCount,isLiked);

@override
String toString() {
  return 'Doc(id: $id, content: $content, user: $user, comic: $comic, totalComments: $totalComments, isTop: $isTop, hide: $hide, createdAt: $createdAt, docId: $docId, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class _$DocCopyWith<$Res> implements $DocCopyWith<$Res> {
  factory _$DocCopyWith(_Doc value, $Res Function(_Doc) _then) = __$DocCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "content") String content,@JsonKey(name: "_user") User user,@JsonKey(name: "_comic") String comic,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "isTop") bool isTop,@JsonKey(name: "hide") bool hide,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "id") String docId,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isLiked") bool isLiked
});


@override $UserCopyWith<$Res> get user;

}
/// @nodoc
class __$DocCopyWithImpl<$Res>
    implements _$DocCopyWith<$Res> {
  __$DocCopyWithImpl(this._self, this._then);

  final _Doc _self;
  final $Res Function(_Doc) _then;

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? user = null,Object? comic = null,Object? totalComments = null,Object? isTop = null,Object? hide = null,Object? createdAt = null,Object? docId = null,Object? likesCount = null,Object? commentsCount = null,Object? isLiked = null,}) {
  return _then(_Doc(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as String,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,isTop: null == isTop ? _self.isTop : isTop // ignore: cast_nullable_to_non_nullable
as bool,hide: null == hide ? _self.hide : hide // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,docId: null == docId ? _self.docId : docId // ignore: cast_nullable_to_non_nullable
as String,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of Doc
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$User {

@JsonKey(name: "_id") String get id;@JsonKey(name: "gender") String get gender;@JsonKey(name: "name") String get name;@JsonKey(name: "title") String get title;@JsonKey(name: "verified") bool get verified;@JsonKey(name: "exp") int get exp;@JsonKey(name: "level") int get level;@JsonKey(name: "characters") List<String> get characters;@JsonKey(name: "role") String get role;@JsonKey(name: "avatar") Avatar? get avatar;@JsonKey(name: "slogan") String? get slogan;@JsonKey(name: "character") String? get character;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other.characters, characters)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.slogan, slogan) || other.slogan == slogan)&&(identical(other.character, character) || other.character == character));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gender,name,title,verified,exp,level,const DeepCollectionEquality().hash(characters),role,avatar,slogan,character);

@override
String toString() {
  return 'User(id: $id, gender: $gender, name: $name, title: $title, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, avatar: $avatar, slogan: $slogan, character: $character)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "gender") String gender,@JsonKey(name: "name") String name,@JsonKey(name: "title") String title,@JsonKey(name: "verified") bool verified,@JsonKey(name: "exp") int exp,@JsonKey(name: "level") int level,@JsonKey(name: "characters") List<String> characters,@JsonKey(name: "role") String role,@JsonKey(name: "avatar") Avatar? avatar,@JsonKey(name: "slogan") String? slogan,@JsonKey(name: "character") String? character
});


$AvatarCopyWith<$Res>? get avatar;

}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? gender = null,Object? name = null,Object? title = null,Object? verified = null,Object? exp = null,Object? level = null,Object? characters = null,Object? role = null,Object? avatar = freezed,Object? slogan = freezed,Object? character = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self.characters : characters // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Avatar?,slogan: freezed == slogan ? _self.slogan : slogan // ignore: cast_nullable_to_non_nullable
as String?,character: freezed == character ? _self.character : character // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AvatarCopyWith<$Res>? get avatar {
    if (_self.avatar == null) {
    return null;
  }

  return $AvatarCopyWith<$Res>(_self.avatar!, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _User value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _User value)  $default,){
final _that = this;
switch (_that) {
case _User():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _User value)?  $default,){
final _that = this;
switch (_that) {
case _User() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "title")  String title, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "avatar")  Avatar? avatar, @JsonKey(name: "slogan")  String? slogan, @JsonKey(name: "character")  String? character)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.gender,_that.name,_that.title,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.avatar,_that.slogan,_that.character);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "title")  String title, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "avatar")  Avatar? avatar, @JsonKey(name: "slogan")  String? slogan, @JsonKey(name: "character")  String? character)  $default,) {final _that = this;
switch (_that) {
case _User():
return $default(_that.id,_that.gender,_that.name,_that.title,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.avatar,_that.slogan,_that.character);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "gender")  String gender, @JsonKey(name: "name")  String name, @JsonKey(name: "title")  String title, @JsonKey(name: "verified")  bool verified, @JsonKey(name: "exp")  int exp, @JsonKey(name: "level")  int level, @JsonKey(name: "characters")  List<String> characters, @JsonKey(name: "role")  String role, @JsonKey(name: "avatar")  Avatar? avatar, @JsonKey(name: "slogan")  String? slogan, @JsonKey(name: "character")  String? character)?  $default,) {final _that = this;
switch (_that) {
case _User() when $default != null:
return $default(_that.id,_that.gender,_that.name,_that.title,_that.verified,_that.exp,_that.level,_that.characters,_that.role,_that.avatar,_that.slogan,_that.character);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _User implements User {
  const _User({@JsonKey(name: "_id") required this.id, @JsonKey(name: "gender") required this.gender, @JsonKey(name: "name") required this.name, @JsonKey(name: "title") required this.title, @JsonKey(name: "verified") required this.verified, @JsonKey(name: "exp") required this.exp, @JsonKey(name: "level") required this.level, @JsonKey(name: "characters") required final  List<String> characters, @JsonKey(name: "role") required this.role, @JsonKey(name: "avatar") this.avatar, @JsonKey(name: "slogan") this.slogan, @JsonKey(name: "character") this.character}): _characters = characters;
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "gender") final  String gender;
@override@JsonKey(name: "name") final  String name;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "verified") final  bool verified;
@override@JsonKey(name: "exp") final  int exp;
@override@JsonKey(name: "level") final  int level;
 final  List<String> _characters;
@override@JsonKey(name: "characters") List<String> get characters {
  if (_characters is EqualUnmodifiableListView) return _characters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_characters);
}

@override@JsonKey(name: "role") final  String role;
@override@JsonKey(name: "avatar") final  Avatar? avatar;
@override@JsonKey(name: "slogan") final  String? slogan;
@override@JsonKey(name: "character") final  String? character;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.name, name) || other.name == name)&&(identical(other.title, title) || other.title == title)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.exp, exp) || other.exp == exp)&&(identical(other.level, level) || other.level == level)&&const DeepCollectionEquality().equals(other._characters, _characters)&&(identical(other.role, role) || other.role == role)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.slogan, slogan) || other.slogan == slogan)&&(identical(other.character, character) || other.character == character));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,gender,name,title,verified,exp,level,const DeepCollectionEquality().hash(_characters),role,avatar,slogan,character);

@override
String toString() {
  return 'User(id: $id, gender: $gender, name: $name, title: $title, verified: $verified, exp: $exp, level: $level, characters: $characters, role: $role, avatar: $avatar, slogan: $slogan, character: $character)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "gender") String gender,@JsonKey(name: "name") String name,@JsonKey(name: "title") String title,@JsonKey(name: "verified") bool verified,@JsonKey(name: "exp") int exp,@JsonKey(name: "level") int level,@JsonKey(name: "characters") List<String> characters,@JsonKey(name: "role") String role,@JsonKey(name: "avatar") Avatar? avatar,@JsonKey(name: "slogan") String? slogan,@JsonKey(name: "character") String? character
});


@override $AvatarCopyWith<$Res>? get avatar;

}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? gender = null,Object? name = null,Object? title = null,Object? verified = null,Object? exp = null,Object? level = null,Object? characters = null,Object? role = null,Object? avatar = freezed,Object? slogan = freezed,Object? character = freezed,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,exp: null == exp ? _self.exp : exp // ignore: cast_nullable_to_non_nullable
as int,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,characters: null == characters ? _self._characters : characters // ignore: cast_nullable_to_non_nullable
as List<String>,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Avatar?,slogan: freezed == slogan ? _self.slogan : slogan // ignore: cast_nullable_to_non_nullable
as String?,character: freezed == character ? _self.character : character // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AvatarCopyWith<$Res>? get avatar {
    if (_self.avatar == null) {
    return null;
  }

  return $AvatarCopyWith<$Res>(_self.avatar!, (value) {
    return _then(_self.copyWith(avatar: value));
  });
}
}


/// @nodoc
mixin _$Avatar {

@JsonKey(name: "originalName") String get originalName;@JsonKey(name: "path") String get path;@JsonKey(name: "fileServer") String get fileServer;
/// Create a copy of Avatar
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvatarCopyWith<Avatar> get copyWith => _$AvatarCopyWithImpl<Avatar>(this as Avatar, _$identity);

  /// Serializes this Avatar to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Avatar&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer);

@override
String toString() {
  return 'Avatar(originalName: $originalName, path: $path, fileServer: $fileServer)';
}


}

/// @nodoc
abstract mixin class $AvatarCopyWith<$Res>  {
  factory $AvatarCopyWith(Avatar value, $Res Function(Avatar) _then) = _$AvatarCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer
});




}
/// @nodoc
class _$AvatarCopyWithImpl<$Res>
    implements $AvatarCopyWith<$Res> {
  _$AvatarCopyWithImpl(this._self, this._then);

  final Avatar _self;
  final $Res Function(Avatar) _then;

/// Create a copy of Avatar
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


/// Adds pattern-matching-related methods to [Avatar].
extension AvatarPatterns on Avatar {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Avatar value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Avatar() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Avatar value)  $default,){
final _that = this;
switch (_that) {
case _Avatar():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Avatar value)?  $default,){
final _that = this;
switch (_that) {
case _Avatar() when $default != null:
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
case _Avatar() when $default != null:
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
case _Avatar():
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
case _Avatar() when $default != null:
return $default(_that.originalName,_that.path,_that.fileServer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Avatar implements Avatar {
  const _Avatar({@JsonKey(name: "originalName") required this.originalName, @JsonKey(name: "path") required this.path, @JsonKey(name: "fileServer") required this.fileServer});
  factory _Avatar.fromJson(Map<String, dynamic> json) => _$AvatarFromJson(json);

@override@JsonKey(name: "originalName") final  String originalName;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "fileServer") final  String fileServer;

/// Create a copy of Avatar
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvatarCopyWith<_Avatar> get copyWith => __$AvatarCopyWithImpl<_Avatar>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvatarToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Avatar&&(identical(other.originalName, originalName) || other.originalName == originalName)&&(identical(other.path, path) || other.path == path)&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,originalName,path,fileServer);

@override
String toString() {
  return 'Avatar(originalName: $originalName, path: $path, fileServer: $fileServer)';
}


}

/// @nodoc
abstract mixin class _$AvatarCopyWith<$Res> implements $AvatarCopyWith<$Res> {
  factory _$AvatarCopyWith(_Avatar value, $Res Function(_Avatar) _then) = __$AvatarCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "originalName") String originalName,@JsonKey(name: "path") String path,@JsonKey(name: "fileServer") String fileServer
});




}
/// @nodoc
class __$AvatarCopyWithImpl<$Res>
    implements _$AvatarCopyWith<$Res> {
  __$AvatarCopyWithImpl(this._self, this._then);

  final _Avatar _self;
  final $Res Function(_Avatar) _then;

/// Create a copy of Avatar
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? originalName = null,Object? path = null,Object? fileServer = null,}) {
  return _then(_Avatar(
originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TopComment {

@JsonKey(name: "_id") String get id;@JsonKey(name: "content") String get content;@JsonKey(name: "_user") User get user;@JsonKey(name: "_comic") String get comic;@JsonKey(name: "isTop") bool get isTop;@JsonKey(name: "hide") bool get hide;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "totalComments") int get totalComments;@JsonKey(name: "likesCount") int get likesCount;@JsonKey(name: "commentsCount") int get commentsCount;@JsonKey(name: "isLiked") bool get isLiked;
/// Create a copy of TopComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopCommentCopyWith<TopComment> get copyWith => _$TopCommentCopyWithImpl<TopComment>(this as TopComment, _$identity);

  /// Serializes this TopComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopComment&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.user, user) || other.user == user)&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.isTop, isTop) || other.isTop == isTop)&&(identical(other.hide, hide) || other.hide == hide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,user,comic,isTop,hide,createdAt,totalComments,likesCount,commentsCount,isLiked);

@override
String toString() {
  return 'TopComment(id: $id, content: $content, user: $user, comic: $comic, isTop: $isTop, hide: $hide, createdAt: $createdAt, totalComments: $totalComments, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class $TopCommentCopyWith<$Res>  {
  factory $TopCommentCopyWith(TopComment value, $Res Function(TopComment) _then) = _$TopCommentCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "content") String content,@JsonKey(name: "_user") User user,@JsonKey(name: "_comic") String comic,@JsonKey(name: "isTop") bool isTop,@JsonKey(name: "hide") bool hide,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isLiked") bool isLiked
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$TopCommentCopyWithImpl<$Res>
    implements $TopCommentCopyWith<$Res> {
  _$TopCommentCopyWithImpl(this._self, this._then);

  final TopComment _self;
  final $Res Function(TopComment) _then;

/// Create a copy of TopComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? user = null,Object? comic = null,Object? isTop = null,Object? hide = null,Object? createdAt = null,Object? totalComments = null,Object? likesCount = null,Object? commentsCount = null,Object? isLiked = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as String,isTop: null == isTop ? _self.isTop : isTop // ignore: cast_nullable_to_non_nullable
as bool,hide: null == hide ? _self.hide : hide // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TopComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopComment].
extension TopCommentPatterns on TopComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopComment value)  $default,){
final _that = this;
switch (_that) {
case _TopComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopComment value)?  $default,){
final _that = this;
switch (_that) {
case _TopComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "content")  String content, @JsonKey(name: "_user")  User user, @JsonKey(name: "_comic")  String comic, @JsonKey(name: "isTop")  bool isTop, @JsonKey(name: "hide")  bool hide, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isLiked")  bool isLiked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopComment() when $default != null:
return $default(_that.id,_that.content,_that.user,_that.comic,_that.isTop,_that.hide,_that.createdAt,_that.totalComments,_that.likesCount,_that.commentsCount,_that.isLiked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "content")  String content, @JsonKey(name: "_user")  User user, @JsonKey(name: "_comic")  String comic, @JsonKey(name: "isTop")  bool isTop, @JsonKey(name: "hide")  bool hide, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isLiked")  bool isLiked)  $default,) {final _that = this;
switch (_that) {
case _TopComment():
return $default(_that.id,_that.content,_that.user,_that.comic,_that.isTop,_that.hide,_that.createdAt,_that.totalComments,_that.likesCount,_that.commentsCount,_that.isLiked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "content")  String content, @JsonKey(name: "_user")  User user, @JsonKey(name: "_comic")  String comic, @JsonKey(name: "isTop")  bool isTop, @JsonKey(name: "hide")  bool hide, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "totalComments")  int totalComments, @JsonKey(name: "likesCount")  int likesCount, @JsonKey(name: "commentsCount")  int commentsCount, @JsonKey(name: "isLiked")  bool isLiked)?  $default,) {final _that = this;
switch (_that) {
case _TopComment() when $default != null:
return $default(_that.id,_that.content,_that.user,_that.comic,_that.isTop,_that.hide,_that.createdAt,_that.totalComments,_that.likesCount,_that.commentsCount,_that.isLiked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TopComment implements TopComment {
  const _TopComment({@JsonKey(name: "_id") required this.id, @JsonKey(name: "content") required this.content, @JsonKey(name: "_user") required this.user, @JsonKey(name: "_comic") required this.comic, @JsonKey(name: "isTop") required this.isTop, @JsonKey(name: "hide") required this.hide, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "totalComments") required this.totalComments, @JsonKey(name: "likesCount") required this.likesCount, @JsonKey(name: "commentsCount") required this.commentsCount, @JsonKey(name: "isLiked") required this.isLiked});
  factory _TopComment.fromJson(Map<String, dynamic> json) => _$TopCommentFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "content") final  String content;
@override@JsonKey(name: "_user") final  User user;
@override@JsonKey(name: "_comic") final  String comic;
@override@JsonKey(name: "isTop") final  bool isTop;
@override@JsonKey(name: "hide") final  bool hide;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "totalComments") final  int totalComments;
@override@JsonKey(name: "likesCount") final  int likesCount;
@override@JsonKey(name: "commentsCount") final  int commentsCount;
@override@JsonKey(name: "isLiked") final  bool isLiked;

/// Create a copy of TopComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopCommentCopyWith<_TopComment> get copyWith => __$TopCommentCopyWithImpl<_TopComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TopCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopComment&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.user, user) || other.user == user)&&(identical(other.comic, comic) || other.comic == comic)&&(identical(other.isTop, isTop) || other.isTop == isTop)&&(identical(other.hide, hide) || other.hide == hide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.totalComments, totalComments) || other.totalComments == totalComments)&&(identical(other.likesCount, likesCount) || other.likesCount == likesCount)&&(identical(other.commentsCount, commentsCount) || other.commentsCount == commentsCount)&&(identical(other.isLiked, isLiked) || other.isLiked == isLiked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,user,comic,isTop,hide,createdAt,totalComments,likesCount,commentsCount,isLiked);

@override
String toString() {
  return 'TopComment(id: $id, content: $content, user: $user, comic: $comic, isTop: $isTop, hide: $hide, createdAt: $createdAt, totalComments: $totalComments, likesCount: $likesCount, commentsCount: $commentsCount, isLiked: $isLiked)';
}


}

/// @nodoc
abstract mixin class _$TopCommentCopyWith<$Res> implements $TopCommentCopyWith<$Res> {
  factory _$TopCommentCopyWith(_TopComment value, $Res Function(_TopComment) _then) = __$TopCommentCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "content") String content,@JsonKey(name: "_user") User user,@JsonKey(name: "_comic") String comic,@JsonKey(name: "isTop") bool isTop,@JsonKey(name: "hide") bool hide,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "totalComments") int totalComments,@JsonKey(name: "likesCount") int likesCount,@JsonKey(name: "commentsCount") int commentsCount,@JsonKey(name: "isLiked") bool isLiked
});


@override $UserCopyWith<$Res> get user;

}
/// @nodoc
class __$TopCommentCopyWithImpl<$Res>
    implements _$TopCommentCopyWith<$Res> {
  __$TopCommentCopyWithImpl(this._self, this._then);

  final _TopComment _self;
  final $Res Function(_TopComment) _then;

/// Create a copy of TopComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? user = null,Object? comic = null,Object? isTop = null,Object? hide = null,Object? createdAt = null,Object? totalComments = null,Object? likesCount = null,Object? commentsCount = null,Object? isLiked = null,}) {
  return _then(_TopComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,comic: null == comic ? _self.comic : comic // ignore: cast_nullable_to_non_nullable
as String,isTop: null == isTop ? _self.isTop : isTop // ignore: cast_nullable_to_non_nullable
as bool,hide: null == hide ? _self.hide : hide // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,totalComments: null == totalComments ? _self.totalComments : totalComments // ignore: cast_nullable_to_non_nullable
as int,likesCount: null == likesCount ? _self.likesCount : likesCount // ignore: cast_nullable_to_non_nullable
as int,commentsCount: null == commentsCount ? _self.commentsCount : commentsCount // ignore: cast_nullable_to_non_nullable
as int,isLiked: null == isLiked ? _self.isLiked : isLiked // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TopComment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
