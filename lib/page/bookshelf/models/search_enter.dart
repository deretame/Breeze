import 'package:equatable/equatable.dart';

class SearchEnter extends Equatable {
  final String keyword; // 关键词，用来放入搜索的关键词或者作者的名字之类的
  final String sort; // 排序方式
  final List<String> sources; // 漫画源
  final String refresh; // 用来强制更新状态

  const SearchEnter({
    this.keyword = '',
    this.sort = 'dd',
    this.sources = const [],
    this.refresh = '',
  });

  @override
  List<Object> get props => [keyword, sort, sources, refresh];

  SearchEnter copyWith({
    String? keyword,
    String? sort,
    List<String>? sources,
    String? refresh,
  }) {
    return SearchEnter(
      keyword: keyword ?? this.keyword,
      sort: sort ?? this.sort,
      sources: sources ?? this.sources,
      refresh: refresh ?? this.refresh,
    );
  }

  @override
  String toString() {
    return 'SearchEnter(keyword: $keyword, sort: $sort, sources: $sources, refresh: $refresh)';
  }
}
