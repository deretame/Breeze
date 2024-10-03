import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/network/http/http_request.dart';
import 'package:zephyr/network/http/picture.dart';
import 'package:zephyr/type/comic_ep_info.dart';

import '../../../../json/comic/ep.dart' as ep;
import '../../../../util/state_management.dart';
import '../../../../widgets/full_screen_image_view.dart';

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget getImageWidget(File file) {
    try {
      return Image.file(file);
    } catch (e) {
      debugPrint('无法打开文件: $e');
      return Icon(Icons.broken_image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化
    return Scaffold(
      body: Localizations.override(
        context: context,
        locale: const Locale('zh', 'CN'),
        child: InteractiveViewer(
          boundaryMargin: EdgeInsets.all(double.infinity),
          minScale: 1.0,
          maxScale: 4.0,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _comicPages.length +
                (_isLoading ? 1 : 0) +
                (_hasMorePages ? 0 : 1),
            itemBuilder: (context, index) {
              if (index < _comicPages.length) {
                ep.Doc doc = _comicPages[index];
                return FutureBuilder(
                  future: getCachePicture(
                      doc.media.fileServer, doc.media.path, comicEpInfo.comicId,
                      pictureType: 'comic',
                      chapterId: comicEpInfo.order.toString()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox(
                        width: screenWidth, // 大空间的宽度
                        height: screenWidth, // 大空间的高度
                        child: Align(
                          alignment: Alignment.center, // 居中对齐
                          child: Padding(
                            padding: const EdgeInsets.all(20.0), // 周围的额外空间
                            child: LoadingAnimationWidget.waveDots(
                              color: colorNotifier.defaultTextColor!,
                              size: 50, // 加载动画的大小
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      // 如果有错误，显示错误信息和一个重新加载的按钮
                      return InkWell(
                        onTap: () {
                          getCachePicture(doc.media.fileServer, doc.media.path,
                                  comicEpInfo.comicId,
                                  pictureType: 'comic',
                                  chapterId: comicEpInfo.order.toString())
                              .then((value) {
                            setState(() {
                              // 更新UI
                            });
                          });
                        },
                        child: Center(
                          child: SizedBox(
                            width: screenWidth, // 大空间的宽度
                            height: screenWidth, // 大空间的高度
                            child: Align(
                              alignment: Alignment.center, // 居中对齐
                              child: Padding(
                                padding: const EdgeInsets.all(20.0), // 周围的额外空间
                                child: Text(
                                  '加载失败，点击重新加载',
                                  style: TextStyle(
                                    color: colorNotifier.defaultTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImageView(
                                imagePath: snapshot.data!,
                              ),
                            ),
                          );
                        },
                        child: KeepAliveImage(
                          imageFile: File(snapshot.data!),
                          child: ClipRRect(
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 3.0,
                              child: Image.file(
                                File(snapshot.data!),
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                );
              } else if (index == _comicPages.length && _isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      '章节结束',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class KeepAliveImage extends StatefulWidget {
  final File imageFile;
  final Widget child;

  const KeepAliveImage({
    super.key,
    required this.imageFile,
    required this.child,
  });

  @override
  State<KeepAliveImage> createState() => _KeepAliveImageState();
}

class _KeepAliveImageState extends State<KeepAliveImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用 super.build
    return widget.child;
  }
}
