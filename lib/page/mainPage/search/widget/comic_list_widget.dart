import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/json/search_bar/search_result.dart';
import 'package:zephyr/main.dart';

import '../../../../config/global.dart';
import '../../../../network/http/http_request.dart';
import '../../../../type/search_enter.dart';
import 'comic_entry_widget.dart';

// 定义一个DocInfo类，用于保存每一页的搜索结果
class DocInfo {
  final int buildNumber;
  final Doc doc;

  DocInfo({
    required this.buildNumber,
    required this.doc,
  });
}

// 显示搜索结果的列表
class ComicListWidget extends StatefulWidget {
  final SearchEnter enter;

  // 用来通知父组件更新页数
  final Function(List<int>) updatePageCount;

  const ComicListWidget({
    super.key,
    required this.enter,
    required this.updatePageCount,
  });

  @override
  State<StatefulWidget> createState() => _ComicListWidgetState();
}

class _ComicListWidgetState extends State<ComicListWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<DocInfo> _docInfos = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMorePages = true;
  late Timer _throttleTimer;

  SearchEnter get enter => widget.enter;

  Map<String, bool> _shieldedCategories = {};

  int _oldPage = 1;
  late List<int> pageCountInfo;

  @override
  void initState() {
    super.initState();
    _loadData(enter);
    _scrollController.addListener(_scrollListener);
    _throttleTimer = Timer(Duration(milliseconds: 0), () {});
    _throttleTimer.cancel();
    _page = enter.pageCount;
    _shieldedCategories = bikaSetting.getShieldCategoryMap();

    pageCountInfo = [0, enter.pageCount];
  }

  @override
  void didUpdateWidget(ComicListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enter != oldWidget.enter) {
      setState(() {
        _docInfos.clear();
        _page = enter.pageCount;
        _hasMorePages = true;
      });
      _loadData(widget.enter);
    }
    _shieldedCategories = bikaSetting.getShieldCategoryMap();
    pageCountInfo[1] = enter.pageCount;
    widget.updatePageCount(pageCountInfo);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _throttleTimer.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMorePages) {
      _page++;
      _loadData(enter);
    }

    if (_throttleTimer.isActive) return;

    _throttleTimer = Timer(
      Duration(milliseconds: 10),
      () {
        double itemHeight = 180.0 + ((screenHeight / 10) * 0.1);
        double currentScrollPosition = _scrollController.position.pixels;
        double middlePosition = currentScrollPosition + (screenHeight / 3);
        double listViewStartOffset = 0.0;
        int itemIndex =
            ((middlePosition - listViewStartOffset) / itemHeight).floor();

        if (itemIndex >= 0 && itemIndex < _docInfos.length) {
          // Doc currentDoc = _docInfos[itemIndex].doc;
          int buildNumber = _docInfos[itemIndex].buildNumber;
          if (buildNumber != _oldPage) {
            _oldPage = buildNumber;
            pageCountInfo[1] = buildNumber;
            widget.updatePageCount(pageCountInfo);
          }
        }
      },
    );
  }

  Future<void> _loadData(SearchEnter enter) async {
    if (_isLoading || !_hasMorePages) return;
    setState(() {
      _isLoading = true;
    });

    try {
      var result = await search(
        url: enter.url,
        keyword: enter.keyword,
        sort: enter.sort,
        categories: enter.categories,
        pageCount: _page,
      );

      if (result['error'] != null) {
        if (!mounted) return;
        _showErrorDialog(context, result.toString());
        return;
      }

      final processedResult = await compute(_processSearchResult, {
        'result': result,
        'shieldedCategories': _shieldedCategories,
        'page': _page,
      });

      if (!mounted) return;

      setState(() {
        _docInfos.addAll(processedResult.newDocInfos);
        _isLoading = false;
        _hasMorePages = processedResult.hasMorePages;
        enter.pageCount = _page;
        pageCountInfo[0] = processedResult.totalPages;
        pageCountInfo[1] = _page;
      });

      widget.updatePageCount(pageCountInfo);

      // 如果处理后的结果少于6个项目，继续加载下一页
      if (processedResult.newDocInfos.length < 6 && _hasMorePages) {
        setState(() {});
        _page++;
        _loadData(enter);
      } else {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加载失败'),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('重新加载'),
              onPressed: () {
                _hasMorePages = true;
                _loadData(enter);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 确保在列表末尾总是有一个额外的项目用于显示加载指示器或结束文本
    int itemCount = _docInfos.length + 1;
    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < _docInfos.length) {
          return ComicEntryWidget(doc: _docInfos[index].doc);
        } else {
          // 当没有更多数据加载时，显示结束文本
          if (!_isLoading && !_hasMorePages) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Text(
                  '你来到了未知领域呢~',
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            );
          }
          // 否则显示加载指示器
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

// 用于在后台线程处理数据的类
class ProcessedResult {
  final List<DocInfo> newDocInfos;
  final bool hasMorePages;
  final int totalPages;

  ProcessedResult(this.newDocInfos, this.hasMorePages, this.totalPages);
}

// 在后台线程处理数据的方法
ProcessedResult _processSearchResult(Map<String, dynamic> params) {
  var result = params['result'];
  var shieldedCategories = params['shieldedCategories'] as Map<String, bool>;
  int page = params['page'];

  // 处理特殊搜索结果
  if (result['comics'] is List) {
    result = {
      "comics": {"docs": result["comics"]}
    };
  }

  // 设置默认值
  result['comics']['limit'] ??= 20;
  result['comics']['page'] ??= 1;
  result['comics']['pages'] ??= 1;
  result['comics']['total'] ??= 40;

  // 处理每个文档
  for (var doc in result['comics']['docs']) {
    doc['id'] ??= doc['_id'];
    doc['updated_at'] ??= '1970-01-01T00:00:00.000Z';
    doc['created_at'] ??= '1970-01-01T00:00:00.000Z';
    doc['description'] ??= '';
    doc['chineseTeam'] ??= '';
    doc['tags'] ??= [];
    doc['author'] ??= "";
    if (doc['likesCount'] is String) {
      doc['likesCount'] = int.parse(doc['likesCount']);
    }
    if (doc['totalLikes'] is String) {
      doc['totalLikes'] = int.parse(doc['totalLikes']);
    }
  }

  var results = SearchResult.fromJson(result);

  List<DocInfo> newDocInfos = [];
  List<String> shieldedCategoriesList = shieldedCategories.entries
      .where((entry) => entry.value == true)
      .map((entry) => entry.key)
      .toList();

  for (var doc in results.comics.docs) {
    if (shieldedCategoriesList
        .any((category) => doc.categories.contains(category))) {
      continue;
    }
    DocInfo docInfo = DocInfo(
      buildNumber: page,
      doc: doc,
    );
    newDocInfos.add(docInfo);
  }

  bool hasMorePages =
      results.comics.page.toInt() < results.comics.pages.toInt();

  return ProcessedResult(
      newDocInfos, hasMorePages, results.comics.pages.toInt());
}
