import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_enter.freezed.dart';
part 'search_enter.g.dart';

// 这个用来更新搜索的关键词
@freezed
abstract class SearchEnter with _$SearchEnter {
  const factory SearchEnter({
    required String url, // 用来对应特殊情况
    required String from, // 用来判断是从哪里进行的搜索
    required String keyword, // 关键词，用来放入搜索的关键词或者作者的名字之类的
    required String type, // 用来判断是搜索书籍还是作者，或者说分类还是标签啥的
    required String state, // 更新状态
    required String sort, // 排序方式
    required List<String> categories, // 分类
    required int pageCount, // 页数
    required String refresh, // 用来强制更新状态
  }) = _SearchEnter;

  factory SearchEnter.initial() {
    return SearchEnter(
      url: '',
      from: '',
      keyword: '',
      type: 'comic',
      state: '',
      sort: 'dd',
      categories: const [],
      pageCount: 1,
      refresh: '',
    );
  }

  factory SearchEnter.fromJson(Map<String, dynamic> json) =>
      _$SearchEnterFromJson(json);
}
