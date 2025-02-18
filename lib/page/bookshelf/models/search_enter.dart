import 'package:equatable/equatable.dart';

// 这个用来更新搜索的关键词
class SearchEnter {
  String keyword; // 关键词，用来放入搜索的关键词或者作者的名字之类的
  String sort; // 排序方式
  List<String> categories; // 分类
  String refresh; // 用来强制更新状态

  SearchEnter({
    this.keyword = '',
    this.sort = 'dd',
    this.categories = const [],
    this.refresh = '',
  });

  // 添加一个 getter
  String get searchEnter {
    return 'Keyword: $keyword, Sort: $sort, Categories: ${categories.join(', ')}, Refresh: $refresh';
  }

  // 重载 == 运算符
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // 检查是否是同一个对象
    if (other is! SearchEnter) return false; // 检查类型

    return keyword == other.keyword &&
        sort == other.sort &&
        categories == other.categories &&
        refresh == other.refresh;
    // 比较所有字段
  }

  // 重写 hashCode
  @override
  int get hashCode {
    return keyword.hashCode ^
        sort.hashCode ^
        categories.hashCode ^
        refresh.hashCode; // 计算哈希值
  }

  // 添加一个从 SearchEnterConst 的构造函数
  SearchEnter.fromConst(SearchEnterConst searchEnterConst)
    : keyword = searchEnterConst.keyword,
      sort = searchEnterConst.sort,
      categories = searchEnterConst.categories,
      refresh = searchEnterConst.refresh;
}

class SearchEnterConst extends Equatable {
  final String keyword; // 关键词，用来放入搜索的关键词或者作者的名字之类的
  final String sort; // 排序方式
  final List<String> categories; // 分类
  final String refresh; // 用来强制更新状态

  const SearchEnterConst({
    this.keyword = '',
    this.sort = 'dd',
    this.categories = const [],
    this.refresh = '',
  });

  @override
  List<Object> get props => [keyword, sort, categories, refresh];

  // 添加一个从 SearchEnter 的构造函数
  SearchEnterConst.from(SearchEnter searchEnter)
    : keyword = searchEnter.keyword,
      sort = searchEnter.sort,
      categories = searchEnter.categories,
      refresh = searchEnter.refresh;
}
