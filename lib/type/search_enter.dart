import 'package:flutter/foundation.dart';

// 这个用来更新搜索的关键词
class SearchEnter {
  String url;
  String title;
  String type;
  String keyword;
  String sort;
  List<String> categories;
  int pageCount;
  int refresh;

  SearchEnter({
    this.url = '',
    this.title = '',
    this.type = '',
    this.keyword = '',
    this.sort = 'dd',
    this.categories = const [],
    this.pageCount = 1,
    this.refresh = 0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchEnter &&
        other.url == url &&
        other.title == title &&
        other.type == type &&
        other.keyword == keyword &&
        other.sort == sort &&
        listEquals(other.categories, categories) &&
        other.pageCount == pageCount &&
        other.refresh == refresh;
  }

  @override
  int get hashCode {
    return Object.hash(
      url,
      title,
      type,
      keyword,
      sort,
      Object.hashAll(categories),
      pageCount,
      refresh,
    );
  }
}
