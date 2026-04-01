import 'package:equatable/equatable.dart';
import 'package:zephyr/plugin/plugin_constants.dart';

class SearchEnter extends Equatable {
  final String keyword; // 关键词，用来放入搜索的关键词或者作者的名字之类的
  final String sort; // 排序方式
  final List<String> categories; // 分类
  final List<String> sources; // 漫画源
  final String refresh; // 用来强制更新状态

  const SearchEnter({
    this.keyword = '',
    this.sort = 'dd',
    this.categories = const [],
    this.sources = const [kBikaPluginUuid, kJmPluginUuid],
    this.refresh = '',
  });

  @override
  List<Object> get props => [keyword, sort, categories, sources, refresh];

  SearchEnter copyWith({
    String? keyword,
    String? sort,
    List<String>? categories,
    List<String>? sources,
    String? refresh,
  }) {
    return SearchEnter(
      keyword: keyword ?? this.keyword,
      sort: sort ?? this.sort,
      categories: categories ?? this.categories,
      sources: sources ?? this.sources,
      refresh: refresh ?? this.refresh,
    );
  }

  @override
  String toString() {
    return 'SearchEnter(keyword: $keyword, sort: $sort, categories: $categories, sources: $sources, refresh: $refresh)';
  }
}
