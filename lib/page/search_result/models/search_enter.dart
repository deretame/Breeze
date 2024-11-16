// 这个用来更新搜索的关键词
import 'package:equatable/equatable.dart';

class SearchEnter {
  String url; // 用来对应特殊情况
  String from; // 用来判断是从哪里进行的搜索
  String keyword; // 关键词，用来放入搜索的关键词或者作者的名字之类的
  String type; // 用来判断是搜索书籍还是作者
  String state; // 更新状态
  String sort; // 排序方式
  List<String> categories; // 分类
  int pageCount; // 页数
  String refresh; // 用来强制更新状态

  SearchEnter({
    this.url = '',
    this.from = '',
    this.keyword = '',
    this.type = 'comic',
    this.state = '',
    this.sort = 'dd',
    this.categories = const [],
    this.pageCount = 1,
    this.refresh = '',
  });

  // 添加一个 getter
  String get searchEnter {
    return 'Keyword: $keyword, Type: $type, State: $state, Sort: $sort, Categories: ${categories.join(', ')}, Page Count: $pageCount, Refresh: $refresh';
  }

  // 重载 == 运算符
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true; // 检查是否是同一个对象
    if (other is! SearchEnter) return false; // 检查类型

    return url == other.url &&
        from == other.from &&
        keyword == other.keyword &&
        type == other.type &&
        state == other.state &&
        sort == other.sort &&
        categories == other.categories &&
        pageCount == other.pageCount &&
        refresh == other.refresh;
    // 比较所有字段
  }

  // 重写 hashCode
  @override
  int get hashCode {
    return url.hashCode ^
        from.hashCode ^
        keyword.hashCode ^
        type.hashCode ^
        state.hashCode ^
        sort.hashCode ^
        categories.hashCode ^
        pageCount.hashCode ^
        refresh.hashCode; // 计算哈希值
  }

  // 添加一个从 SearchEnterConst 的构造函数
  SearchEnter.fromConst(SearchEnterConst searchEnterConst)
      : url = searchEnterConst.url,
        from = searchEnterConst.from,
        keyword = searchEnterConst.keyword,
        type = searchEnterConst.type,
        state = searchEnterConst.state,
        sort = searchEnterConst.sort,
        categories = searchEnterConst.categories,
        pageCount = searchEnterConst.pageCount,
        refresh = searchEnterConst.refresh;
}

class SearchEnterConst extends Equatable {
  final String url; // 用来对应特殊情况
  final String from; // 用来判断是从哪里进行的搜索
  final String keyword; // 关键词，用来放入搜索的关键词或者作者的名字之类的
  final String type; // 用来判断是搜索书籍还是作者，或者说分类还是标签啥的
  final String state; // 更新状态
  final String sort; // 排序方式
  final List<String> categories; // 分类
  final int pageCount; // 页数
  final String refresh; // 用来强制更新状态

  const SearchEnterConst({
    this.url = '',
    this.from = '',
    this.keyword = '',
    this.type = 'comic',
    this.state = '',
    this.sort = 'dd',
    this.categories = const [],
    this.pageCount = 1,
    this.refresh = '',
  });

  @override
  List<Object> get props =>
      [url, from, keyword, type, state, sort, categories, pageCount, refresh];

  // 添加一个从 SearchEnter 的构造函数
  SearchEnterConst.from(SearchEnter searchEnter)
      : url = searchEnter.url,
        from = searchEnter.from,
        keyword = searchEnter.keyword,
        type = searchEnter.type,
        state = searchEnter.state,
        sort = searchEnter.sort,
        categories = searchEnter.categories,
        pageCount = searchEnter.pageCount,
        refresh = searchEnter.refresh;
}
