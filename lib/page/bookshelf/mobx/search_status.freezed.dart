// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchStatusState {

 BookShelfStatus get status; int get pageCount; String get refresh; String get keyword; String get sort; List<String> get categories;
/// Create a copy of SearchStatusState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStatusStateCopyWith<SearchStatusState> get copyWith => _$SearchStatusStateCopyWithImpl<SearchStatusState>(this as SearchStatusState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStatusState&&(identical(other.status, status) || other.status == status)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.refresh, refresh) || other.refresh == refresh)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other.categories, categories));
}


@override
int get hashCode => Object.hash(runtimeType,status,pageCount,refresh,keyword,sort,const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'SearchStatusState(status: $status, pageCount: $pageCount, refresh: $refresh, keyword: $keyword, sort: $sort, categories: $categories)';
}


}

/// @nodoc
abstract mixin class $SearchStatusStateCopyWith<$Res>  {
  factory $SearchStatusStateCopyWith(SearchStatusState value, $Res Function(SearchStatusState) _then) = _$SearchStatusStateCopyWithImpl;
@useResult
$Res call({
 BookShelfStatus status, int pageCount, String refresh, String keyword, String sort, List<String> categories
});




}
/// @nodoc
class _$SearchStatusStateCopyWithImpl<$Res>
    implements $SearchStatusStateCopyWith<$Res> {
  _$SearchStatusStateCopyWithImpl(this._self, this._then);

  final SearchStatusState _self;
  final $Res Function(SearchStatusState) _then;

/// Create a copy of SearchStatusState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? pageCount = null,Object? refresh = null,Object? keyword = null,Object? sort = null,Object? categories = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookShelfStatus,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as String,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchStatusState].
extension SearchStatusStatePatterns on SearchStatusState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchStatusState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchStatusState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchStatusState value)  $default,){
final _that = this;
switch (_that) {
case _SearchStatusState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchStatusState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchStatusState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BookShelfStatus status,  int pageCount,  String refresh,  String keyword,  String sort,  List<String> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchStatusState() when $default != null:
return $default(_that.status,_that.pageCount,_that.refresh,_that.keyword,_that.sort,_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BookShelfStatus status,  int pageCount,  String refresh,  String keyword,  String sort,  List<String> categories)  $default,) {final _that = this;
switch (_that) {
case _SearchStatusState():
return $default(_that.status,_that.pageCount,_that.refresh,_that.keyword,_that.sort,_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BookShelfStatus status,  int pageCount,  String refresh,  String keyword,  String sort,  List<String> categories)?  $default,) {final _that = this;
switch (_that) {
case _SearchStatusState() when $default != null:
return $default(_that.status,_that.pageCount,_that.refresh,_that.keyword,_that.sort,_that.categories);case _:
  return null;

}
}

}

/// @nodoc


class _SearchStatusState implements SearchStatusState {
  const _SearchStatusState({this.status = BookShelfStatus.favourite, this.pageCount = 0, this.refresh = "", this.keyword = "", this.sort = "dd", final  List<String> categories = const <String>[]}): _categories = categories;
  

@override@JsonKey() final  BookShelfStatus status;
@override@JsonKey() final  int pageCount;
@override@JsonKey() final  String refresh;
@override@JsonKey() final  String keyword;
@override@JsonKey() final  String sort;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of SearchStatusState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchStatusStateCopyWith<_SearchStatusState> get copyWith => __$SearchStatusStateCopyWithImpl<_SearchStatusState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchStatusState&&(identical(other.status, status) || other.status == status)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.refresh, refresh) || other.refresh == refresh)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,status,pageCount,refresh,keyword,sort,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'SearchStatusState(status: $status, pageCount: $pageCount, refresh: $refresh, keyword: $keyword, sort: $sort, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$SearchStatusStateCopyWith<$Res> implements $SearchStatusStateCopyWith<$Res> {
  factory _$SearchStatusStateCopyWith(_SearchStatusState value, $Res Function(_SearchStatusState) _then) = __$SearchStatusStateCopyWithImpl;
@override @useResult
$Res call({
 BookShelfStatus status, int pageCount, String refresh, String keyword, String sort, List<String> categories
});




}
/// @nodoc
class __$SearchStatusStateCopyWithImpl<$Res>
    implements _$SearchStatusStateCopyWith<$Res> {
  __$SearchStatusStateCopyWithImpl(this._self, this._then);

  final _SearchStatusState _self;
  final $Res Function(_SearchStatusState) _then;

/// Create a copy of SearchStatusState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? pageCount = null,Object? refresh = null,Object? keyword = null,Object? sort = null,Object? categories = null,}) {
  return _then(_SearchStatusState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookShelfStatus,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as String,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
