import 'package:flutter/foundation.dart';

class SearchEnter {
  String keyword;
  String sort;
  List<String> categories;
  int pageCount;
  int refresh;

  SearchEnter({
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
        other.keyword == keyword &&
        other.sort == sort &&
        listEquals(other.categories, categories) &&
        other.pageCount == pageCount &&
        other.refresh == refresh;
  }

  @override
  int get hashCode {
    return Object.hash(
        keyword, sort, Object.hashAll(categories), pageCount, refresh);
  }
}
