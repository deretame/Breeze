// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_status.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SearchStatusStore on _SearchStatusStore, Store {
  late final _$statusAtom = Atom(
    name: '_SearchStatusStore.status',
    context: context,
  );

  @override
  BookShelfStatus get status {
    _$statusAtom.reportRead();
    return super.status;
  }

  @override
  set status(BookShelfStatus value) {
    _$statusAtom.reportWrite(value, super.status, () {
      super.status = value;
    });
  }

  late final _$pageCountAtom = Atom(
    name: '_SearchStatusStore.pageCount',
    context: context,
  );

  @override
  int get pageCount {
    _$pageCountAtom.reportRead();
    return super.pageCount;
  }

  @override
  set pageCount(int value) {
    _$pageCountAtom.reportWrite(value, super.pageCount, () {
      super.pageCount = value;
    });
  }

  late final _$refreshAtom = Atom(
    name: '_SearchStatusStore.refresh',
    context: context,
  );

  @override
  String get refresh {
    _$refreshAtom.reportRead();
    return super.refresh;
  }

  @override
  set refresh(String value) {
    _$refreshAtom.reportWrite(value, super.refresh, () {
      super.refresh = value;
    });
  }

  late final _$keywordAtom = Atom(
    name: '_SearchStatusStore.keyword',
    context: context,
  );

  @override
  String get keyword {
    _$keywordAtom.reportRead();
    return super.keyword;
  }

  @override
  set keyword(String value) {
    _$keywordAtom.reportWrite(value, super.keyword, () {
      super.keyword = value;
    });
  }

  late final _$sortAtom = Atom(
    name: '_SearchStatusStore.sort',
    context: context,
  );

  @override
  String get sort {
    _$sortAtom.reportRead();
    return super.sort;
  }

  @override
  set sort(String value) {
    _$sortAtom.reportWrite(value, super.sort, () {
      super.sort = value;
    });
  }

  late final _$categoriesAtom = Atom(
    name: '_SearchStatusStore.categories',
    context: context,
  );

  @override
  List<String> get categories {
    _$categoriesAtom.reportRead();
    return super.categories;
  }

  @override
  set categories(List<String> value) {
    _$categoriesAtom.reportWrite(value, super.categories, () {
      super.categories = value;
    });
  }

  late final _$_SearchStatusStoreActionController = ActionController(
    name: '_SearchStatusStore',
    context: context,
  );

  @override
  void setStatus(BookShelfStatus status) {
    final _$actionInfo = _$_SearchStatusStoreActionController.startAction(
      name: '_SearchStatusStore.setStatus',
    );
    try {
      return super.setStatus(status);
    } finally {
      _$_SearchStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPageCount(int pageCount) {
    final _$actionInfo = _$_SearchStatusStoreActionController.startAction(
      name: '_SearchStatusStore.setPageCount',
    );
    try {
      return super.setPageCount(pageCount);
    } finally {
      _$_SearchStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setRefresh(String refresh) {
    final _$actionInfo = _$_SearchStatusStoreActionController.startAction(
      name: '_SearchStatusStore.setRefresh',
    );
    try {
      return super.setRefresh(refresh);
    } finally {
      _$_SearchStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setKeyword(String keyword) {
    final _$actionInfo = _$_SearchStatusStoreActionController.startAction(
      name: '_SearchStatusStore.setKeyword',
    );
    try {
      return super.setKeyword(keyword);
    } finally {
      _$_SearchStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSort(String sort) {
    final _$actionInfo = _$_SearchStatusStoreActionController.startAction(
      name: '_SearchStatusStore.setSort',
    );
    try {
      return super.setSort(sort);
    } finally {
      _$_SearchStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCategories(List<String> categories) {
    final _$actionInfo = _$_SearchStatusStoreActionController.startAction(
      name: '_SearchStatusStore.setCategories',
    );
    try {
      return super.setCategories(categories);
    } finally {
      _$_SearchStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
status: ${status},
pageCount: ${pageCount},
refresh: ${refresh},
keyword: ${keyword},
sort: ${sort},
categories: ${categories}
    ''';
  }
}
