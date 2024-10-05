import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zephyr/network/http/http_request.dart';

import '../../../../config/global.dart';
import '../../../../json/comic/comic_info.dart';
import '../../../../util/router.dart';
import '../widget/comic_info/comic_operation_widget.dart';
import '../widget/comic_info/comic_particulars_widget.dart';
import '../widget/comic_info/creator_info_widget.dart';
import '../widget/comic_info/eps_widget.dart';
import '../widget/comic_info/synopsis_widget.dart';
import '../widget/comic_info/tags_categories_widget.dart';

class ComicInfoPage extends StatefulWidget {
  final String comicId;

  const ComicInfoPage({super.key, required this.comicId});

  @override
  State<StatefulWidget> createState() => _ComicInfoPageState();
}

class _ComicInfoPageState extends State<ComicInfoPage>
    with AutomaticKeepAliveClientMixin<ComicInfoPage> {
  late Future<Map<String, dynamic>> _comicInfoFuture;

  String get comicId => widget.comicId;
  late ComicInfo comicInfo;
  late Map<String, dynamic> result;
  bool isLoading = true; // 用于显示加载状态的标志

  Future<Map<String, dynamic>> _loadComicInfo() async {
    return await getComicInfo(comicId);
  }

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  @override
  void initState() {
    super.initState();
    _comicInfoFuture = _loadComicInfo();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            navigatePop(context);
          },
        ),
        actions: <Widget>[
          const SizedBox(width: 50),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              navigateToNoReturn(context, "/main");
            },
          ),
          Expanded(child: Container()),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _comicInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // 如果有错误，显示错误信息和重新加载按钮
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () async {
                        // 重新加载数据
                        setState(() {
                          isLoading = true;
                          _comicInfoFuture = _loadComicInfo(); // 重新调用异步函数
                        });
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.data != null &&
                snapshot.data!['error'] != null) {
              // 如果返回的数据中包含错误信息
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.data}'),
                    ElevatedButton(
                      onPressed: () async {
                        // 重新加载数据
                        setState(() {
                          isLoading = true;
                          _comicInfoFuture = _loadComicInfo(); // 重新调用异步函数
                        });
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              );
            } else {
              // 如果数据正确，显示漫画信息
              // 打补丁
              // 部分作者可能没有 slogan，这里做个判断，防止报错
              if (snapshot.data!['comic']['_creator']['slogan'] == null) {
                snapshot.data!['comic']['_creator']['slogan'] = "";
              }
              // 部分上传者没有verified，这里做个判断，防止报错
              if (snapshot.data!['comic']['_creator']['verified'] == null) {
                snapshot.data!['comic']['_creator']['verified'] = false;
              }
              // 部分漫画没有chineseTeam，这里做个判断，防止报错
              if (snapshot.data!['comic']['chineseTeam'] == null) {
                snapshot.data!['comic']['chineseTeam'] = "";
              }
              //  部分漫画没有totalComments，这里做个判断，防止报错
              if (snapshot.data!['comic']['totalComments'] == null) {
                snapshot.data!['comic']['totalComments'] =
                    snapshot.data!['comic']['commentsCount'] = 0;
              }
              comicInfo = ComicInfo.fromJson(snapshot.data!);
              return SingleChildScrollView(
                // 添加滚动视图
                physics: const ClampingScrollPhysics(), // 滚动物理，根据需要可以调整
                child: ComicInfoWidget(comicInfo: comicInfo),
              );
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // 按钮点击事件
      //     debugPrint('Floating Action Button Pressed');
      //   },
      //   label: Text('Action'),
      //   icon: Icon(Icons.add),
      //   // backgroundColor: Colors.blue, // 自定义背景颜色
      // ),
      // // floatingActionButtonLocation:
      // //     FloatingActionButtonLocation.endDocked, // 自定义位置
    );
  }
}

class ComicInfoWidget extends ConsumerStatefulWidget {
  final ComicInfo comicInfo;

  const ComicInfoWidget({super.key, required this.comicInfo});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ComicInfoWidgetState();
}

class _ComicInfoWidgetState extends ConsumerState<ComicInfoWidget> {
  ComicInfo get comicInfo => widget.comicInfo;

  @override
  Widget build(BuildContext context) {
    // 使用 comicInfo 的数据来构建界面
    return LimitedBox(
      maxWidth: screenWidth,
      child: SizedBox(
        width: screenWidth,
        child: Row(
          mainAxisSize: MainAxisSize.min, // 使 Row 尽可能小,
          mainAxisAlignment: MainAxisAlignment.start, // 子组件之间的间距平均分布
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在交叉轴（垂直轴）上靠起始位置对齐
          children: <Widget>[
            SizedBox(
              width: screenWidth / 50, // 左边的空白空间
            ),
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                // Column 用于垂直排列子组件
                crossAxisAlignment: CrossAxisAlignment.start,
                // 子组件在交叉轴（水平轴）上靠起始位置对齐，即左对齐
                children: <Widget>[
                  const SizedBox(
                    height: 10,
                  ),
                  ComicParticularsWidget(comicInfo: comicInfo),
                  // 漫画详细信息组件
                  const SizedBox(
                    height: 10,
                  ),
                  TagsAndCategoriesWidget(
                    comicInfo: comicInfo,
                    type: 'categories',
                  ),
                  // 分类组件
                  const SizedBox(
                    height: 3,
                  ),
                  if (comicInfo.comic.tags.isNotEmpty) ...[
                    TagsAndCategoriesWidget(
                      comicInfo: comicInfo,
                      type: 'tags',
                    ),
                    // 标签组件
                    const SizedBox(
                      height: 3,
                    ),
                  ],
                  if (comicInfo.comic.description != '') ...[
                    SynopsisWidget(comicInfo: comicInfo), // 简介组件
                    // 描述文本，左对齐
                  ],
                  const SizedBox(
                    height: 10,
                  ),
                  CreatorInfoWidget(comicInfo: comicInfo),
                  // 创作者信息组件
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ComicOperationWidget(comicInfo: comicInfo),
                  // 操作按钮组件
                  const SizedBox(
                    height: 10,
                  ),
                  EpsWidget(comicInfo: comicInfo), // 章节列表组件
                  const SizedBox(
                    height: 85,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: screenWidth / 50, // 右边的空白空间
            ),
          ],
        ),
      ),
    );
  }
}
