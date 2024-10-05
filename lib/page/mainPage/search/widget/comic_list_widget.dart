import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zephyr/json/search_bar/search_result.dart';

import '../../../../config/global.dart';
import '../../../../network/http/http_request.dart';
import 'comic_entry_widget.dart';

class ComicListWidget extends StatefulWidget {
  final String query;

  const ComicListWidget({
    super.key,
    required this.query,
  });

  @override
  State<StatefulWidget> createState() => _ComicListWidgetState();
}

class _ComicListWidgetState extends State<ComicListWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<Doc> _docs = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMorePages = true; // 添加一个标志来跟踪是否还有更多页
  late Timer _throttleTimer;

  String get query => widget.query;

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMorePages) {
      // 只有当还有更多页时，才加载数据
      _page++; // 增加页码
      _loadData(query);
    }

    // 如果有定时器正在运行，则不执行任何操作
    if (_throttleTimer.isActive) return;

    // 设置定时器，以便每10毫秒最多执行一次计算
    _throttleTimer = Timer(
      Duration(milliseconds: 100),
      () {
        // 每个列表项的高度是固定的，我们称之为itemHeight
        double itemHeight = 180.0 + ((screenHeight / 10) * 0.1);

        // 获取当前滚动的位置
        double currentScrollPosition = _scrollController.position.pixels;

        // 计算屏幕垂直中心位置对应的滚动位置
        double middlePosition = currentScrollPosition + (screenHeight / 2);

        // 计算屏幕垂直中心位置对应的列表项索引
        // 注意：这里需要考虑ListView的起始偏移量，如果没有偏移量则可以忽略
        double listViewStartOffset = 0.0; // 如果ListView不是从屏幕顶部开始，需要调整这个值
        int itemIndex =
            ((middlePosition - listViewStartOffset) / itemHeight).floor();

        // 确保索引在列表的有效范围内
        if (itemIndex >= 0 && itemIndex < _docs.length) {
          Doc currentDoc = _docs[itemIndex];
          // 显示当前中线的条目
          debugPrint("当前中线位置的 Doc: ${currentDoc.title} itemIndex$itemIndex");
        }
      },
    );
  }

  Future<void> _loadData(String query) async {
    if (_isLoading) return; // 如果正在加载，直接返回
    setState(() {
      _isLoading = true;
    });
    try {
      Map<String, dynamic> result =
          await search(keyword: query, pageCount: _page);
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
      }

      var results = SearchResult.fromJson(result);
      List<Doc> newDocs = [];
      for (var doc in results.comics.docs) {
        newDocs.add(doc);
      }
      if (mounted) {
        setState(() {
          _docs.addAll(newDocs);
          _isLoading = false;
          _hasMorePages = results.comics.page.toInt() <
              results.comics.pages.toInt(); // 更新是否有更多页
        });
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
                _loadData(widget.query);
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
  void initState() {
    super.initState();
    _loadData(query); // 传递初始查询参数
    _scrollController.addListener(_scrollListener);
    _throttleTimer =
        Timer(Duration(milliseconds: 0), () {}); // 初始化 _throttleTimer
    _throttleTimer.cancel(); // 确保定时器被取消，因为我们只是初始化它
  }

  @override
  void didUpdateWidget(ComicListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query) {
      // 查询已更改，重置状态并重新加载数据
      setState(() {
        _docs.clear();
        _page = 1;
        _hasMorePages = true;
      });
      _loadData(widget.query);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _throttleTimer.cancel(); // 确保定时器被取消
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _docs.length + (_isLoading ? 1 : 0) + (_hasMorePages ? 0 : 1),
      // 如果没有更多页面，则增加一项
      itemBuilder: (context, index) {
        if (index < _docs.length) {
          // 正常显示列表项
          return ComicEntryWidget(doc: _docs[index]);
        } else if (index == _docs.length && _isLoading) {
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
              padding: EdgeInsets.all(20.0),
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
