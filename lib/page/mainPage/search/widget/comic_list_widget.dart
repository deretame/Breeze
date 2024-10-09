import 'dart:async';

import 'package:flutter/material.dart';
import 'package:realm/realm.dart';
import 'package:zephyr/json/search_bar/search_result.dart';

import '../../../../config/global.dart';
import '../../../../network/http/http_request.dart';
import '../../../../realm/shield_categories.dart';
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
  bool _hasMorePages = true; // 添加一个标志来跟踪是否还有更多页
  late Timer _throttleTimer;

  SearchEnter get enter => widget.enter;

  late Realm _realm;
  Map<String, bool> _shieldedCategories = {};

  int _oldPage = 1;
  late List<int> pageCountInfo;

  @override
  void initState() {
    super.initState();
    _loadData(enter); // 传递初始查询参数
    _scrollController.addListener(_scrollListener);
    _throttleTimer =
        Timer(Duration(milliseconds: 0), () {}); // 初始化 _throttleTimer
    _throttleTimer.cancel(); // 确保定时器被取消，因为我们只是初始化它
    _page = enter.pageCount;
    debugPrint("newWidget: ${widget.enter.keyword}");
    final shieldedCategories = Configuration.local([ShieldedCategories.schema]);
    _realm = Realm(shieldedCategories);

    // 查询以确保获取最新的对象
    var temp = _realm.find<ShieldedCategories>("ShieldedCategories");

    // 将RealmMap转换为Dart Map
    _shieldedCategories = {
      for (var key in temp!.map.keys) key: temp.map[key] as bool
    };

    pageCountInfo = [0, enter.pageCount];
  }

  @override
  void didUpdateWidget(ComicListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enter != oldWidget.enter) {
      // 查询已更改，重置状态并重新加载数据
      setState(() {
        _docInfos.clear();
        _page = enter.pageCount;
        _hasMorePages = true;
      });
      _loadData(widget.enter);
    }
    // 查询以确保获取最新的对象
    var temp = _realm.find<ShieldedCategories>("ShieldedCategories");

    // 将RealmMap转换为Dart Map
    _shieldedCategories = {
      for (var key in temp!.map.keys) key: temp.map[key] as bool
    };
    pageCountInfo[1] = enter.pageCount;
    widget.updatePageCount(pageCountInfo);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _throttleTimer.cancel(); // 确保定时器被取消
    _realm.close();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMorePages) {
      // 只有当还有更多页时，才加载数据
      _page++; // 增加页码
      _loadData(enter);
    }

    // 如果有定时器正在运行，则不执行任何操作
    if (_throttleTimer.isActive) return;

    // 设置定时器，以便每10毫秒最多执行一次计算
    _throttleTimer = Timer(
      Duration(milliseconds: 10),
      () {
        // 每个列表项的高度是固定的，我们称之为itemHeight
        double itemHeight = 180.0 + ((screenHeight / 10) * 0.1);

        // 获取当前滚动的位置
        double currentScrollPosition = _scrollController.position.pixels;

        // 计算屏幕垂直中心位置对应的滚动位置
        double middlePosition = currentScrollPosition + (screenHeight / 3);

        // 计算屏幕垂直中心位置对应的列表项索引
        // 注意：这里需要考虑ListView的起始偏移量，如果没有偏移量则可以忽略
        double listViewStartOffset = 0.0; // 如果ListView不是从屏幕顶部开始，需要调整这个值
        int itemIndex =
            ((middlePosition - listViewStartOffset) / itemHeight).floor();

        // 确保索引在列表的有效范围内
        if (itemIndex >= 0 && itemIndex < _docInfos.length) {
          Doc currentDoc = _docInfos[itemIndex].doc;
          int buildNumber = _docInfos[itemIndex].buildNumber;
          // 显示当前中线的条目
          debugPrint("当前中线位置的 Doc: ${currentDoc.title} itemIndex$buildNumber");
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
    if (_isLoading) return; // 如果正在加载，直接返回
    setState(() {
      _isLoading = true;
    });
    try {
      var result = await search(
        keyword: enter.keyword,
        sort: enter.sort,
        categories: enter.categories,
        pageCount: _page,
      );
      if (result['error'] != null) {
        // 如果有错误，显示对话框
        if (!mounted) return;
        _showErrorDialog(context, result.toString());
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // 部分漫画的部分内容可能为空，这里做一下处理
      for (var doc in result['comics']['docs']) {
        if (doc['description'] == null) {
          doc['description'] = "";
        }
        if (doc['chineseTeam'] == null) {
          doc['chineseTeam'] = "";
        }
        if (doc['likesCount'] is String) {
          doc['likesCount'] = int.parse(doc['likesCount']);
        }
        if (doc['totalLikes'] is String) {
          doc['totalLikes'] = int.parse(doc['totalLikes']);
        }
      }

      var results = SearchResult.fromJson(result);

      pageCountInfo[0] = results.comics.pages.toInt();
      widget.updatePageCount(pageCountInfo);
      List<DocInfo> newDocInfos = [];
      // 将 _shieldedCategories 转换为一个只包含值为 true 的键的列表
      List<String> shieldedCategoriesList = _shieldedCategories.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
      for (var doc in results.comics.docs) {
        // 如果文档的分类包含在屏蔽列表中，则跳过
        if (shieldedCategoriesList
            .any((category) => doc.categories.contains(category))) {
          continue;
        }
        DocInfo docInfo = DocInfo(
          buildNumber: _page,
          doc: doc,
        );
        newDocInfos.add(docInfo);
      }

      // 如果数据足够或没有更多页，则更新状态
      if (mounted) {
        setState(() {
          _docInfos.addAll(newDocInfos);
          _isLoading = false;
          _hasMorePages = results.comics.page.toInt() <
              results.comics.pages.toInt(); // 更新是否有更多页
          enter.pageCount = _page;
        });
      }
      while (_docInfos.length <= 10 &&
          results.comics.page.toInt() < results.comics.pages.toInt()) {
        _page++;
        enter.pageCount = _page;
        await _loadData(SearchEnter(
          keyword: enter.keyword,
          sort: enter.sort,
          categories: enter.categories,
          pageCount: _page,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(context, e.toString());
      setState(() {
        _isLoading = false;
      });
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
                _hasMorePages = true; // 重置是否有更多页
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
    return ListView.builder(
      controller: _scrollController,
      itemCount:
          _docInfos.length + (_isLoading ? 1 : 0) + (_hasMorePages ? 0 : 1),
      // 如果没有更多页面，则增加一项
      itemBuilder: (context, index) {
        if (index < _docInfos.length) {
          // 正常显示列表项
          return ComicEntryWidget(doc: _docInfos[index].doc);
        } else if (index == _docInfos.length && _isLoading) {
          // 显示加载指示器
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          // 显示“没有更多了”的信息
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
      },
    );
  }
}
