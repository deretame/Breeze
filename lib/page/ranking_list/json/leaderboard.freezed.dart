// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'leaderboard.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Leaderboard {

@JsonKey(name: "code") int get code;@JsonKey(name: "message") String get message;@JsonKey(name: "data") Data get data;
/// Create a copy of Leaderboard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaderboardCopyWith<Leaderboard> get copyWith => _$LeaderboardCopyWithImpl<Leaderboard>(this as Leaderboard, _$identity);

  /// Serializes this Leaderboard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Leaderboard&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'Leaderboard(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $LeaderboardCopyWith<$Res>  {
  factory $LeaderboardCopyWith(Leaderboard value, $Res Function(Leaderboard) _then) = _$LeaderboardCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


$DataCopyWith<$Res> get data;

}
/// @nodoc
class _$LeaderboardCopyWithImpl<$Res>
    implements $LeaderboardCopyWith<$Res> {
  _$LeaderboardCopyWithImpl(this._self, this._then);

  final Leaderboard _self;
  final $Res Function(Leaderboard) _then;

/// Create a copy of Leaderboard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}
/// Create a copy of Leaderboard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DataCopyWith<$Res> get data {
  
  return $DataCopyWith<$Res>(_self.data, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [Leaderboard].
extension LeaderboardPatterns on Leaderboard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Leaderboard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Leaderboard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Leaderboard value)  $default,){
final _that = this;
switch (_that) {
case _Leaderboard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Leaderboard value)?  $default,){
final _that = this;
switch (_that) {
case _Leaderboard() when $default != null:
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
case _Leaderboard() when $default != null:
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
case _Leaderboard():
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
case _Leaderboard() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Leaderboard implements Leaderboard {
  const _Leaderboard({@JsonKey(name: "code") required this.code, @JsonKey(name: "message") required this.message, @JsonKey(name: "data") required this.data});
  factory _Leaderboard.fromJson(Map<String, dynamic> json) => _$LeaderboardFromJson(json);

@override@JsonKey(name: "code") final  int code;
@override@JsonKey(name: "message") final  String message;
@override@JsonKey(name: "data") final  Data data;

/// Create a copy of Leaderboard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaderboardCopyWith<_Leaderboard> get copyWith => __$LeaderboardCopyWithImpl<_Leaderboard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LeaderboardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Leaderboard&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'Leaderboard(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$LeaderboardCopyWith<$Res> implements $LeaderboardCopyWith<$Res> {
  factory _$LeaderboardCopyWith(_Leaderboard value, $Res Function(_Leaderboard) _then) = __$LeaderboardCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "code") int code,@JsonKey(name: "message") String message,@JsonKey(name: "data") Data data
});


@override $DataCopyWith<$Res> get data;

}
/// @nodoc
class __$LeaderboardCopyWithImpl<$Res>
    implements _$LeaderboardCopyWith<$Res> {
  __$LeaderboardCopyWithImpl(this._self, this._then);

  final _Leaderboard _self;
  final $Res Function(_Leaderboard) _then;

/// Create a copy of Leaderboard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? data = null,}) {
  return _then(_Leaderboard(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Data,
  ));
}

/// Create a copy of Leaderboard
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

@JsonKey(name: "comics") List<Comic> get comics;
/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataCopyWith<Data> get copyWith => _$DataCopyWithImpl<Data>(this as Data, _$identity);

  /// Serializes this Data to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Data&&const DeepCollectionEquality().equals(other.comics, comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(comics));

@override
String toString() {
  return 'Data(comics: $comics)';
}


}

/// @nodoc
abstract mixin class $DataCopyWith<$Res>  {
  factory $DataCopyWith(Data value, $Res Function(Data) _then) = _$DataCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "comics") List<Comic> comics
});




}
/// @nodoc
class _$DataCopyWithImpl<$Res>
    implements $DataCopyWith<$Res> {
  _$DataCopyWithImpl(this._self, this._then);

  final Data _self;
  final $Res Function(Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? comics = null,}) {
  return _then(_self.copyWith(
comics: null == comics ? _self.comics : comics // ignore: cast_nullable_to_non_nullable
as List<Comic>,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "comics")  List<Comic> comics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.comics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "comics")  List<Comic> comics)  $default,) {final _that = this;
switch (_that) {
case _Data():
return $default(_that.comics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "comics")  List<Comic> comics)?  $default,) {final _that = this;
switch (_that) {
case _Data() when $default != null:
return $default(_that.comics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Data implements Data {
  const _Data({@JsonKey(name: "comics") required final  List<Comic> comics}): _comics = comics;
  factory _Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

 final  List<Comic> _comics;
@override@JsonKey(name: "comics") List<Comic> get comics {
  if (_comics is EqualUnmodifiableListView) return _comics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comics);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Data&&const DeepCollectionEquality().equals(other._comics, _comics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_comics));

@override
String toString() {
  return 'Data(comics: $comics)';
}


}

/// @nodoc
abstract mixin class _$DataCopyWith<$Res> implements $DataCopyWith<$Res> {
  factory _$DataCopyWith(_Data value, $Res Function(_Data) _then) = __$DataCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "comics") List<Comic> comics
});




}
/// @nodoc
class __$DataCopyWithImpl<$Res>
    implements _$DataCopyWith<$Res> {
  __$DataCopyWithImpl(this._self, this._then);

  final _Data _self;
  final $Res Function(_Data) _then;

/// Create a copy of Data
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? comics = null,}) {
  return _then(_Data(
comics: null == comics ? _self._comics : comics // ignore: cast_nullable_to_non_nullable
as List<Comic>,
  ));
}


}


/// @nodoc
mixin _$Comic {

@JsonKey(name: "_id") String get id;@JsonKey(name: "title") String get title;@JsonKey(name: "author") String get author;@JsonKey(name: "totalViews") int get totalViews;@JsonKey(name: "totalLikes") int get totalLikes;@JsonKey(name: "pagesCount") int get pagesCount;@JsonKey(name: "epsCount") int get epsCount;@JsonKey(name: "finished") bool get finished;@JsonKey(name: "categories") List<String> get categories;@JsonKey(name: "thumb") Thumb get thumb;@JsonKey(name: "viewsCount") int get viewsCount;@JsonKey(name: "leaderboardCount") int get leaderboardCount;
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ComicCopyWith<Comic> get copyWith => _$ComicCopyWithImpl<Comic>(this as Comic, _$identity);

  /// Serializes this Comic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.finished, finished) || other.finished == finished)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.thumb, thumb) || other.thumb == thumb)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.leaderboardCount, leaderboardCount) || other.leaderboardCount == leaderboardCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalViews,totalLikes,pagesCount,epsCount,finished,const DeepCollectionEquality().hash(categories),thumb,viewsCount,leaderboardCount);

@override
String toString() {
  return 'Comic(id: $id, title: $title, author: $author, totalViews: $totalViews, totalLikes: $totalLikes, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, categories: $categories, thumb: $thumb, viewsCount: $viewsCount, leaderboardCount: $leaderboardCount)';
}


}

/// @nodoc
abstract mixin class $ComicCopyWith<$Res>  {
  factory $ComicCopyWith(Comic value, $Res Function(Comic) _then) = _$ComicCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "author") String author,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "finished") bool finished,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "thumb") Thumb thumb,@JsonKey(name: "viewsCount") int viewsCount,@JsonKey(name: "leaderboardCount") int leaderboardCount
});


$ThumbCopyWith<$Res> get thumb;

}
/// @nodoc
class _$ComicCopyWithImpl<$Res>
    implements $ComicCopyWith<$Res> {
  _$ComicCopyWithImpl(this._self, this._then);

  final Comic _self;
  final $Res Function(Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalViews = null,Object? totalLikes = null,Object? pagesCount = null,Object? epsCount = null,Object? finished = null,Object? categories = null,Object? thumb = null,Object? viewsCount = null,Object? leaderboardCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,thumb: null == thumb ? _self.thumb : thumb // ignore: cast_nullable_to_non_nullable
as Thumb,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,leaderboardCount: null == leaderboardCount ? _self.leaderboardCount : leaderboardCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get thumb {
  
  return $ThumbCopyWith<$Res>(_self.thumb, (value) {
    return _then(_self.copyWith(thumb: value));
  });
}
}


/// Adds pattern-matching-related methods to [Comic].
extension ComicPatterns on Comic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Comic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Comic value)  $default,){
final _that = this;
switch (_that) {
case _Comic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Comic value)?  $default,){
final _that = this;
switch (_that) {
case _Comic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "author")  String author, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "finished")  bool finished, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "thumb")  Thumb thumb, @JsonKey(name: "viewsCount")  int viewsCount, @JsonKey(name: "leaderboardCount")  int leaderboardCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.totalViews,_that.totalLikes,_that.pagesCount,_that.epsCount,_that.finished,_that.categories,_that.thumb,_that.viewsCount,_that.leaderboardCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "author")  String author, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "finished")  bool finished, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "thumb")  Thumb thumb, @JsonKey(name: "viewsCount")  int viewsCount, @JsonKey(name: "leaderboardCount")  int leaderboardCount)  $default,) {final _that = this;
switch (_that) {
case _Comic():
return $default(_that.id,_that.title,_that.author,_that.totalViews,_that.totalLikes,_that.pagesCount,_that.epsCount,_that.finished,_that.categories,_that.thumb,_that.viewsCount,_that.leaderboardCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "_id")  String id, @JsonKey(name: "title")  String title, @JsonKey(name: "author")  String author, @JsonKey(name: "totalViews")  int totalViews, @JsonKey(name: "totalLikes")  int totalLikes, @JsonKey(name: "pagesCount")  int pagesCount, @JsonKey(name: "epsCount")  int epsCount, @JsonKey(name: "finished")  bool finished, @JsonKey(name: "categories")  List<String> categories, @JsonKey(name: "thumb")  Thumb thumb, @JsonKey(name: "viewsCount")  int viewsCount, @JsonKey(name: "leaderboardCount")  int leaderboardCount)?  $default,) {final _that = this;
switch (_that) {
case _Comic() when $default != null:
return $default(_that.id,_that.title,_that.author,_that.totalViews,_that.totalLikes,_that.pagesCount,_that.epsCount,_that.finished,_that.categories,_that.thumb,_that.viewsCount,_that.leaderboardCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Comic implements Comic {
  const _Comic({@JsonKey(name: "_id") required this.id, @JsonKey(name: "title") required this.title, @JsonKey(name: "author") required this.author, @JsonKey(name: "totalViews") required this.totalViews, @JsonKey(name: "totalLikes") required this.totalLikes, @JsonKey(name: "pagesCount") required this.pagesCount, @JsonKey(name: "epsCount") required this.epsCount, @JsonKey(name: "finished") required this.finished, @JsonKey(name: "categories") required final  List<String> categories, @JsonKey(name: "thumb") required this.thumb, @JsonKey(name: "viewsCount") required this.viewsCount, @JsonKey(name: "leaderboardCount") required this.leaderboardCount}): _categories = categories;
  factory _Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);

@override@JsonKey(name: "_id") final  String id;
@override@JsonKey(name: "title") final  String title;
@override@JsonKey(name: "author") final  String author;
@override@JsonKey(name: "totalViews") final  int totalViews;
@override@JsonKey(name: "totalLikes") final  int totalLikes;
@override@JsonKey(name: "pagesCount") final  int pagesCount;
@override@JsonKey(name: "epsCount") final  int epsCount;
@override@JsonKey(name: "finished") final  bool finished;
 final  List<String> _categories;
@override@JsonKey(name: "categories") List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override@JsonKey(name: "thumb") final  Thumb thumb;
@override@JsonKey(name: "viewsCount") final  int viewsCount;
@override@JsonKey(name: "leaderboardCount") final  int leaderboardCount;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ComicCopyWith<_Comic> get copyWith => __$ComicCopyWithImpl<_Comic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ComicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Comic&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.author, author) || other.author == author)&&(identical(other.totalViews, totalViews) || other.totalViews == totalViews)&&(identical(other.totalLikes, totalLikes) || other.totalLikes == totalLikes)&&(identical(other.pagesCount, pagesCount) || other.pagesCount == pagesCount)&&(identical(other.epsCount, epsCount) || other.epsCount == epsCount)&&(identical(other.finished, finished) || other.finished == finished)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.thumb, thumb) || other.thumb == thumb)&&(identical(other.viewsCount, viewsCount) || other.viewsCount == viewsCount)&&(identical(other.leaderboardCount, leaderboardCount) || other.leaderboardCount == leaderboardCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,author,totalViews,totalLikes,pagesCount,epsCount,finished,const DeepCollectionEquality().hash(_categories),thumb,viewsCount,leaderboardCount);

@override
String toString() {
  return 'Comic(id: $id, title: $title, author: $author, totalViews: $totalViews, totalLikes: $totalLikes, pagesCount: $pagesCount, epsCount: $epsCount, finished: $finished, categories: $categories, thumb: $thumb, viewsCount: $viewsCount, leaderboardCount: $leaderboardCount)';
}


}

/// @nodoc
abstract mixin class _$ComicCopyWith<$Res> implements $ComicCopyWith<$Res> {
  factory _$ComicCopyWith(_Comic value, $Res Function(_Comic) _then) = __$ComicCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "_id") String id,@JsonKey(name: "title") String title,@JsonKey(name: "author") String author,@JsonKey(name: "totalViews") int totalViews,@JsonKey(name: "totalLikes") int totalLikes,@JsonKey(name: "pagesCount") int pagesCount,@JsonKey(name: "epsCount") int epsCount,@JsonKey(name: "finished") bool finished,@JsonKey(name: "categories") List<String> categories,@JsonKey(name: "thumb") Thumb thumb,@JsonKey(name: "viewsCount") int viewsCount,@JsonKey(name: "leaderboardCount") int leaderboardCount
});


@override $ThumbCopyWith<$Res> get thumb;

}
/// @nodoc
class __$ComicCopyWithImpl<$Res>
    implements _$ComicCopyWith<$Res> {
  __$ComicCopyWithImpl(this._self, this._then);

  final _Comic _self;
  final $Res Function(_Comic) _then;

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? author = null,Object? totalViews = null,Object? totalLikes = null,Object? pagesCount = null,Object? epsCount = null,Object? finished = null,Object? categories = null,Object? thumb = null,Object? viewsCount = null,Object? leaderboardCount = null,}) {
  return _then(_Comic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,totalViews: null == totalViews ? _self.totalViews : totalViews // ignore: cast_nullable_to_non_nullable
as int,totalLikes: null == totalLikes ? _self.totalLikes : totalLikes // ignore: cast_nullable_to_non_nullable
as int,pagesCount: null == pagesCount ? _self.pagesCount : pagesCount // ignore: cast_nullable_to_non_nullable
as int,epsCount: null == epsCount ? _self.epsCount : epsCount // ignore: cast_nullable_to_non_nullable
as int,finished: null == finished ? _self.finished : finished // ignore: cast_nullable_to_non_nullable
as bool,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,thumb: null == thumb ? _self.thumb : thumb // ignore: cast_nullable_to_non_nullable
as Thumb,viewsCount: null == viewsCount ? _self.viewsCount : viewsCount // ignore: cast_nullable_to_non_nullable
as int,leaderboardCount: null == leaderboardCount ? _self.leaderboardCount : leaderboardCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Comic
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThumbCopyWith<$Res> get thumb {
  
  return $ThumbCopyWith<$Res>(_self.thumb, (value) {
    return _then(_self.copyWith(thumb: value));
  });
}
}


/// @nodoc
mixin _$Thumb {

@JsonKey(name: "fileServer") String get fileServer;@JsonKey(name: "path") String get path;@JsonKey(name: "originalName") String get originalName;
/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThumbCopyWith<Thumb> get copyWith => _$ThumbCopyWithImpl<Thumb>(this as Thumb, _$identity);

  /// Serializes this Thumb to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Thumb&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.path, path) || other.path == path)&&(identical(other.originalName, originalName) || other.originalName == originalName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileServer,path,originalName);

@override
String toString() {
  return 'Thumb(fileServer: $fileServer, path: $path, originalName: $originalName)';
}


}

/// @nodoc
abstract mixin class $ThumbCopyWith<$Res>  {
  factory $ThumbCopyWith(Thumb value, $Res Function(Thumb) _then) = _$ThumbCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "originalName") String originalName
});




}
/// @nodoc
class _$ThumbCopyWithImpl<$Res>
    implements $ThumbCopyWith<$Res> {
  _$ThumbCopyWithImpl(this._self, this._then);

  final Thumb _self;
  final $Res Function(Thumb) _then;

/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileServer = null,Object? path = null,Object? originalName = null,}) {
  return _then(_self.copyWith(
fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Thumb].
extension ThumbPatterns on Thumb {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Thumb value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Thumb() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Thumb value)  $default,){
final _that = this;
switch (_that) {
case _Thumb():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Thumb value)?  $default,){
final _that = this;
switch (_that) {
case _Thumb() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "fileServer")  String fileServer, @JsonKey(name: "path")  String path, @JsonKey(name: "originalName")  String originalName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Thumb() when $default != null:
return $default(_that.fileServer,_that.path,_that.originalName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "fileServer")  String fileServer, @JsonKey(name: "path")  String path, @JsonKey(name: "originalName")  String originalName)  $default,) {final _that = this;
switch (_that) {
case _Thumb():
return $default(_that.fileServer,_that.path,_that.originalName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "fileServer")  String fileServer, @JsonKey(name: "path")  String path, @JsonKey(name: "originalName")  String originalName)?  $default,) {final _that = this;
switch (_that) {
case _Thumb() when $default != null:
return $default(_that.fileServer,_that.path,_that.originalName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Thumb implements Thumb {
  const _Thumb({@JsonKey(name: "fileServer") required this.fileServer, @JsonKey(name: "path") required this.path, @JsonKey(name: "originalName") required this.originalName});
  factory _Thumb.fromJson(Map<String, dynamic> json) => _$ThumbFromJson(json);

@override@JsonKey(name: "fileServer") final  String fileServer;
@override@JsonKey(name: "path") final  String path;
@override@JsonKey(name: "originalName") final  String originalName;

/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThumbCopyWith<_Thumb> get copyWith => __$ThumbCopyWithImpl<_Thumb>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ThumbToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Thumb&&(identical(other.fileServer, fileServer) || other.fileServer == fileServer)&&(identical(other.path, path) || other.path == path)&&(identical(other.originalName, originalName) || other.originalName == originalName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileServer,path,originalName);

@override
String toString() {
  return 'Thumb(fileServer: $fileServer, path: $path, originalName: $originalName)';
}


}

/// @nodoc
abstract mixin class _$ThumbCopyWith<$Res> implements $ThumbCopyWith<$Res> {
  factory _$ThumbCopyWith(_Thumb value, $Res Function(_Thumb) _then) = __$ThumbCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "fileServer") String fileServer,@JsonKey(name: "path") String path,@JsonKey(name: "originalName") String originalName
});




}
/// @nodoc
class __$ThumbCopyWithImpl<$Res>
    implements _$ThumbCopyWith<$Res> {
  __$ThumbCopyWithImpl(this._self, this._then);

  final _Thumb _self;
  final $Res Function(_Thumb) _then;

/// Create a copy of Thumb
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileServer = null,Object? path = null,Object? originalName = null,}) {
  return _then(_Thumb(
fileServer: null == fileServer ? _self.fileServer : fileServer // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,originalName: null == originalName ? _self.originalName : originalName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
