import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/network/http/http_request.dart';
import 'package:zephyr/type/comic_ep_info.dart';

import '../../../../json/comic/ep.dart' as ep;
import '../../../../util/state_management.dart';
import '../../../../widgets/image_build_widget.dart';

class ComicPage extends ConsumerStatefulWidget {
  final ComicEpInfo comicEpInfo;

  const ComicPage({
    super.key,
    required this.comicEpInfo,
  });

  @override
  ConsumerState<ComicPage> createState() => _ComicPageState();
}

class _ComicPageState extends ConsumerState<ComicPage> {
  ComicEpInfo get comicEpInfo => widget.comicEpInfo;
  final ScrollController _scrollController = ScrollController();
  final List<ep.Doc> _comicPages = [];
  bool _isLoading = false;
  int _page = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading &&
        _hasMorePages) {
      _page++;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      Map<String, dynamic> result =
          await getComic(comicEpInfo.comicId, comicEpInfo.order, _page);
      if (result['error'] != null) {
        if (!mounted) return;
        _showErrorDialog(context, result.toString());
        setState(() {
          _isLoading = false;
        });
        return;
      }
      var results = ep.Ep.fromJson(result);
      List<ep.Doc> newDocs = [];
      for (var doc in results.pages.docs) {
        newDocs.add(doc);
      }
      if (mounted) {
        setState(() {
          _comicPages.addAll(newDocs);
          _isLoading = false;
          _hasMorePages =
              results.pages.page.toInt() < results.pages.pages.toInt();
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

  Widget _loadingWidget() {
    final colorNotifier = ref.watch(defaultColorProvider);
    return SizedBox(
      width: screenWidth,
      height: screenWidth,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: LoadingAnimationWidget.waveDots(
            color: colorNotifier.defaultTextColor!,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final colorNotifier = ref.watch(defaultColorProvider);
    return SizedBox(
      width: screenWidth,
      height: screenWidth,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            '加载失败，点击重新加载',
            style: TextStyle(
              color: colorNotifier.defaultTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageFutureBuilder(ep.Doc doc) {
    final isReloading = ValueNotifier<bool>(false);
    return ImageBuildWidget(
      fileServer: doc.media.fileServer,
      path: doc.media.path,
      pictureType: "comic",
      comicId: comicEpInfo.comicId,
      chapterId: comicEpInfo.order.toString(),
      loadingWidget: _loadingWidget(),
      buildErrorWidget: _buildErrorWidget(),
      imageWidgetBuilder: (String data) => KeepAliveImage(data: data),
      isReloading: isReloading,
    );
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
                _loadData();
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
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化

    // 加载动画
    Widget loadingWidget = Center(
      child: LoadingAnimationWidget.hexagonDots(
        color: colorNotifier.defaultTextColor!,
        size: 80,
      ),
    );

    // 判断是否是首次加载，如果是则显示居中的加载动画
    Widget bodyWidget;
    if (_isLoading && _comicPages.isEmpty) {
      // 首次加载，显示居中的加载动画
      bodyWidget = Center(
        child: loadingWidget,
      );
    } else {
      // 非首次加载，显示ListView
      bodyWidget = Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _comicPages.length +
                  (_hasMorePages ? 0 : 1), // 如果没有更多页面，则增加一个项目用于显示完成提示
              itemBuilder: (context, index) {
                if (!_hasMorePages && index == _comicPages.length) {
                  // 没有更多页面可加载，可以显示一个完成提示
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      // 添加垂直方向的20 padding
                      child: Text(
                        '章节结束',
                        style: TextStyle(
                          color: colorNotifier.defaultTextColor,
                          fontSize: 18.0, // 设置字体大小为18逻辑像素
                        ),
                      ),
                    ),
                  );
                } else if (index < _comicPages.length) {
                  // 构建漫画页
                  ep.Doc doc = _comicPages[index];
                  return _buildImageFutureBuilder(doc);
                }
                // 如果都不满足，返回一个空的Container或者占位符
                return Container();
              },
            ),
          ),
          if (_isLoading) loadingWidget,
        ],
      );
    }

    return Scaffold(
      body: Localizations.override(
        context: context,
        locale: const Locale('zh', 'CN'),
        child: bodyWidget,
      ),
    );
  }
}

class KeepAliveImage extends StatefulWidget {
  final String data;

  const KeepAliveImage({
    super.key,
    required this.data,
  });

  @override
  State<KeepAliveImage> createState() => _KeepAliveImageState();
}

class _KeepAliveImageState extends State<KeepAliveImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String get data => widget.data;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用 super.build
    return Image.file(
      File(data),
      // width: screenWidth, // 图片宽度为屏幕宽度
      // fit: BoxFit.cover,
    );
  }
}
