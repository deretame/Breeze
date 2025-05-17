// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_enter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchEnter {

 String get url;// 用来对应特殊情况
 String get from;// 用来判断是从哪里进行的搜索
 String get keyword;// 关键词，用来放入搜索的关键词或者作者的名字之类的
 String get type;// 用来判断是搜索书籍还是作者，或者说分类还是标签啥的
 String get state;// 更新状态
 String get sort;// 排序方式
 List<String> get categories;// 分类
 int get pageCount;// 页数
 String get refresh;
/// Create a copy of SearchEnter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchEnterCopyWith<SearchEnter> get copyWith => _$SearchEnterCopyWithImpl<SearchEnter>(this as SearchEnter, _$identity);

  /// Serializes this SearchEnter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchEnter&&(identical(other.url, url) || other.url == url)&&(identical(other.from, from) || other.from == from)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.refresh, refresh) || other.refresh == refresh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,from,keyword,type,state,sort,const DeepCollectionEquality().hash(categories),pageCount,refresh);

@override
String toString() {
  return 'SearchEnter(url: $url, from: $from, keyword: $keyword, type: $type, state: $state, sort: $sort, categories: $categories, pageCount: $pageCount, refresh: $refresh)';
}


}

/// @nodoc
abstract mixin class $SearchEnterCopyWith<$Res>  {
  factory $SearchEnterCopyWith(SearchEnter value, $Res Function(SearchEnter) _then) = _$SearchEnterCopyWithImpl;
@useResult
$Res call({
 String url, String from, String keyword, String type, String state, String sort, List<String> categories, int pageCount, String refresh
});




}
/// @nodoc
class _$SearchEnterCopyWithImpl<$Res>
    implements $SearchEnterCopyWith<$Res> {
  _$SearchEnterCopyWithImpl(this._self, this._then);

  final SearchEnter _self;
  final $Res Function(SearchEnter) _then;

/// Create a copy of SearchEnter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? from = null,Object? keyword = null,Object? type = null,Object? state = null,Object? sort = null,Object? categories = null,Object? pageCount = null,Object? refresh = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _SearchEnter implements SearchEnter {
  const _SearchEnter({required this.url, required this.from, required this.keyword, required this.type, required this.state, required this.sort, required final  List<String> categories, required this.pageCount, required this.refresh}): _categories = categories;
  factory _SearchEnter.fromJson(Map<String, dynamic> json) => _$SearchEnterFromJson(json);

@override final  String url;
// 用来对应特殊情况
@override final  String from;
// 用来判断是从哪里进行的搜索
@override final  String keyword;
// 关键词，用来放入搜索的关键词或者作者的名字之类的
@override final  String type;
// 用来判断是搜索书籍还是作者，或者说分类还是标签啥的
@override final  String state;
// 更新状态
@override final  String sort;
// 排序方式
 final  List<String> _categories;
// 排序方式
@override List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

// 分类
@override final  int pageCount;
// 页数
@override final  String refresh;

/// Create a copy of SearchEnter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchEnterCopyWith<_SearchEnter> get copyWith => __$SearchEnterCopyWithImpl<_SearchEnter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchEnterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchEnter&&(identical(other.url, url) || other.url == url)&&(identical(other.from, from) || other.from == from)&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.type, type) || other.type == type)&&(identical(other.state, state) || other.state == state)&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.pageCount, pageCount) || other.pageCount == pageCount)&&(identical(other.refresh, refresh) || other.refresh == refresh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,from,keyword,type,state,sort,const DeepCollectionEquality().hash(_categories),pageCount,refresh);

@override
String toString() {
  return 'SearchEnter(url: $url, from: $from, keyword: $keyword, type: $type, state: $state, sort: $sort, categories: $categories, pageCount: $pageCount, refresh: $refresh)';
}


}

/// @nodoc
abstract mixin class _$SearchEnterCopyWith<$Res> implements $SearchEnterCopyWith<$Res> {
  factory _$SearchEnterCopyWith(_SearchEnter value, $Res Function(_SearchEnter) _then) = __$SearchEnterCopyWithImpl;
@override @useResult
$Res call({
 String url, String from, String keyword, String type, String state, String sort, List<String> categories, int pageCount, String refresh
});




}
/// @nodoc
class __$SearchEnterCopyWithImpl<$Res>
    implements _$SearchEnterCopyWith<$Res> {
  __$SearchEnterCopyWithImpl(this._self, this._then);

  final _SearchEnter _self;
  final $Res Function(_SearchEnter) _then;

/// Create a copy of SearchEnter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? from = null,Object? keyword = null,Object? type = null,Object? state = null,Object? sort = null,Object? categories = null,Object? pageCount = null,Object? refresh = null,}) {
  return _then(_SearchEnter(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,pageCount: null == pageCount ? _self.pageCount : pageCount // ignore: cast_nullable_to_non_nullable
as int,refresh: null == refresh ? _self.refresh : refresh // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
