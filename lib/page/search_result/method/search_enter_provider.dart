import 'package:flutter/cupertino.dart';

import '../models/models.dart';

class SearchEnterProvider extends InheritedWidget {
  final SearchEnter searchEnter;

  const SearchEnterProvider({
    super.key,
    required this.searchEnter,
    required super.child,
  });

  static SearchEnterProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SearchEnterProvider>();
  }

  @override
  bool updateShouldNotify(covariant SearchEnterProvider oldWidget) {
    return oldWidget.searchEnter != searchEnter;
  }
}
