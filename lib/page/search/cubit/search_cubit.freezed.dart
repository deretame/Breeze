// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchStates {

 From get from; String get searchKeyword; int get sortBy; Map<String, bool> get categories; Map<String, bool> get categoriesBlock; bool get brevity;
/// Create a copy of SearchStates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStatesCopyWith<SearchStates> get copyWith => _$SearchStatesCopyWithImpl<SearchStates>(this as SearchStates, _$identity);

  /// Serializes this SearchStates to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStates&&(identical(other.from, from) || other.from == from)&&(identical(other.searchKeyword, searchKeyword) || other.searchKeyword == searchKeyword)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.categoriesBlock, categoriesBlock)&&(identical(other.brevity, brevity) || other.brevity == brevity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,searchKeyword,sortBy,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(categoriesBlock),brevity);

@override
String toString() {
  return 'SearchStates(from: $from, searchKeyword: $searchKeyword, sortBy: $sortBy, categories: $categories, categoriesBlock: $categoriesBlock, brevity: $brevity)';
}


}

/// @nodoc
abstract mixin class $SearchStatesCopyWith<$Res>  {
  factory $SearchStatesCopyWith(SearchStates value, $Res Function(SearchStates) _then) = _$SearchStatesCopyWithImpl;
@useResult
$Res call({
 From from, String searchKeyword, int sortBy, Map<String, bool> categories, Map<String, bool> categoriesBlock, bool brevity
});




}
/// @nodoc
class _$SearchStatesCopyWithImpl<$Res>
    implements $SearchStatesCopyWith<$Res> {
  _$SearchStatesCopyWithImpl(this._self, this._then);

  final SearchStates _self;
  final $Res Function(SearchStates) _then;

/// Create a copy of SearchStates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? searchKeyword = null,Object? sortBy = null,Object? categories = null,Object? categoriesBlock = null,Object? brevity = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as From,searchKeyword: null == searchKeyword ? _self.searchKeyword : searchKeyword // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,categoriesBlock: null == categoriesBlock ? _self.categoriesBlock : categoriesBlock // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,brevity: null == brevity ? _self.brevity : brevity // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchStates].
extension SearchStatesPatterns on SearchStates {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchStates value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchStates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchStates value)  $default,){
final _that = this;
switch (_that) {
case _SearchStates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchStates value)?  $default,){
final _that = this;
switch (_that) {
case _SearchStates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( From from,  String searchKeyword,  int sortBy,  Map<String, bool> categories,  Map<String, bool> categoriesBlock,  bool brevity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchStates() when $default != null:
return $default(_that.from,_that.searchKeyword,_that.sortBy,_that.categories,_that.categoriesBlock,_that.brevity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( From from,  String searchKeyword,  int sortBy,  Map<String, bool> categories,  Map<String, bool> categoriesBlock,  bool brevity)  $default,) {final _that = this;
switch (_that) {
case _SearchStates():
return $default(_that.from,_that.searchKeyword,_that.sortBy,_that.categories,_that.categoriesBlock,_that.brevity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( From from,  String searchKeyword,  int sortBy,  Map<String, bool> categories,  Map<String, bool> categoriesBlock,  bool brevity)?  $default,) {final _that = this;
switch (_that) {
case _SearchStates() when $default != null:
return $default(_that.from,_that.searchKeyword,_that.sortBy,_that.categories,_that.categoriesBlock,_that.brevity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchStates implements SearchStates {
  const _SearchStates({this.from = From.jm, this.searchKeyword = "", this.sortBy = 1, final  Map<String, bool> categories = const {}, final  Map<String, bool> categoriesBlock = const {}, this.brevity = false}): _categories = categories,_categoriesBlock = categoriesBlock;
  factory _SearchStates.fromJson(Map<String, dynamic> json) => _$SearchStatesFromJson(json);

@override@JsonKey() final  From from;
@override@JsonKey() final  String searchKeyword;
@override@JsonKey() final  int sortBy;
 final  Map<String, bool> _categories;
@override@JsonKey() Map<String, bool> get categories {
  if (_categories is EqualUnmodifiableMapView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categories);
}

 final  Map<String, bool> _categoriesBlock;
@override@JsonKey() Map<String, bool> get categoriesBlock {
  if (_categoriesBlock is EqualUnmodifiableMapView) return _categoriesBlock;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoriesBlock);
}

@override@JsonKey() final  bool brevity;

/// Create a copy of SearchStates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchStatesCopyWith<_SearchStates> get copyWith => __$SearchStatesCopyWithImpl<_SearchStates>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchStatesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchStates&&(identical(other.from, from) || other.from == from)&&(identical(other.searchKeyword, searchKeyword) || other.searchKeyword == searchKeyword)&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._categoriesBlock, _categoriesBlock)&&(identical(other.brevity, brevity) || other.brevity == brevity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,searchKeyword,sortBy,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_categoriesBlock),brevity);

@override
String toString() {
  return 'SearchStates(from: $from, searchKeyword: $searchKeyword, sortBy: $sortBy, categories: $categories, categoriesBlock: $categoriesBlock, brevity: $brevity)';
}


}

/// @nodoc
abstract mixin class _$SearchStatesCopyWith<$Res> implements $SearchStatesCopyWith<$Res> {
  factory _$SearchStatesCopyWith(_SearchStates value, $Res Function(_SearchStates) _then) = __$SearchStatesCopyWithImpl;
@override @useResult
$Res call({
 From from, String searchKeyword, int sortBy, Map<String, bool> categories, Map<String, bool> categoriesBlock, bool brevity
});




}
/// @nodoc
class __$SearchStatesCopyWithImpl<$Res>
    implements _$SearchStatesCopyWith<$Res> {
  __$SearchStatesCopyWithImpl(this._self, this._then);

  final _SearchStates _self;
  final $Res Function(_SearchStates) _then;

/// Create a copy of SearchStates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? searchKeyword = null,Object? sortBy = null,Object? categories = null,Object? categoriesBlock = null,Object? brevity = null,}) {
  return _then(_SearchStates(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as From,searchKeyword: null == searchKeyword ? _self.searchKeyword : searchKeyword // ignore: cast_nullable_to_non_nullable
as String,sortBy: null == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as int,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,categoriesBlock: null == categoriesBlock ? _self._categoriesBlock : categoriesBlock // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,brevity: null == brevity ? _self.brevity : brevity // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
