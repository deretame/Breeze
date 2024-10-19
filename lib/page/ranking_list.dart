import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/json/creator_ranking.dart';

import '../config/global.dart';
import '../json/search_bar/hot_list.dart';
import '../network/http/http_request.dart';
import '../network/http/picture.dart';
import '../type/search_enter.dart';
import '../util/router.dart';
import '../util/state_management.dart';
import '../widgets/full_screen_image_view.dart';

class RankingListPage extends ConsumerStatefulWidget {
  const RankingListPage({super.key});

  @override
  ConsumerState<RankingListPage> createState() => _RankingListPageState();
}

class _RankingListPageState extends ConsumerState<RankingListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔排行榜'),
      ),
      body: const HotTabBar(),
    );
  }
}

class HotTabBar extends StatefulWidget {
  const HotTabBar({super.key});

  @override
  State<HotTabBar> createState() => _HotTabBarState();
}

class _HotTabBarState extends State<HotTabBar> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: '日榜'),
            Tab(text: '周榜'),
            Tab(text: '月榜'),
            Tab(text: '骑士榜'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              SingleChildScrollView(
                child: RankingListWidget(type: "H24"),
              ),
              SingleChildScrollView(
                child: RankingListWidget(type: "D7"),
              ),
              SingleChildScrollView(
                child: RankingListWidget(type: "D30"),
              ),
              SingleChildScrollView(
                child: _CreatorRankingsWidget(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RankingListWidget extends ConsumerStatefulWidget {
  final String type;

  const RankingListWidget({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<RankingListWidget> createState() => _RankingListWidgetState();
}

class _RankingListWidgetState extends ConsumerState<RankingListWidget> {
  String get type => widget.type;

  late Future<List<Comic>> _fetchRankings;

  @override
  void initState() {
    super.initState();
    _fetchRankings = fetchRankings();
  }

  // 获取章节列表并正序
  Future<List<Comic>> fetchRankings() async {
    var result = await getRankingList(days: type, 'comic');
    if (result['error'] != null) {
      throw Exception(result);
    }
    if (result['code'] != null) {
      throw Exception(result);
    }
    var temp = HotList.fromJson(result);
    List<Comic> comicList = [];
    for (var item in temp.comics) {
      comicList.add(item);
    }

    return comicList;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FutureBuilder<List<Comic>>(
          future: _fetchRankings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _fetchRankings =
                              fetchRankings(); // 触发 FutureBuilder 重建
                        });
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              List<Comic> comics = snapshot.data!;
              return Column(
                children: [
                  // 使用 map 和 Padding 创建 ComicEntryWidget 列表
                  ...comics.map(
                    (comic) => _ComicEntryWidget(
                      comic: comic,
                      type: type,
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('No Episodes Found'));
            }
          },
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Container(),
          ),
        )
      ],
    );
  }
}

class _ComicEntryWidget extends ConsumerStatefulWidget {
  final String type;
  final Comic comic;

  const _ComicEntryWidget({
    required this.type,
    required this.comic,
  });

  @override
  ConsumerState<_ComicEntryWidget> createState() => _ComicEntryWidgetState();
}

class _ComicEntryWidgetState extends ConsumerState<_ComicEntryWidget> {
  String get type => widget.type;

  late String _type;

  Comic get comic => widget.comic;

  @override
  initState() {
    if (type == "H24") {
      _type = "过去24小时观看量";
    } else if (type == "D7") {
      _type = "过去一周观看量";
    } else if (type == "D30") {
      _type = "过去一月观看量";
    }
    super.initState();
  }

  String _getCategories(List<String>? categories) {
    int count = 0;
    int mainCount = 8;
    if (categories == null) {
      return "";
    } else {
      String temp = "";
      for (var category in categories) {
        temp += "$category ";
        count++;
        if (count == mainCount) {
          break;
        }
      }
      return "分类: $temp";
    }
  }

  // 截断过长的标题
  String _getLimitedTitle(String title, int maxLength) {
    if (title.length > maxLength) {
      return '${title.substring(0, maxLength)}...';
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return InkWell(
      onTap: () {
        // 跳转到漫画详情页
        navigateTo(context, '/comicInfo', extra: comic.id);
      },
      child: Column(
        children: <Widget>[
          SizedBox(height: (screenHeight / 10) * 0.1),
          Container(
            height: 180,
            width: ((screenWidth / 10) * 9.5),
            margin: EdgeInsets.symmetric(horizontal: (screenWidth / 10) * 0.25),
            decoration: BoxDecoration(
              color: colorNotifier.defaultBackgroundColor,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: colorNotifier.themeType
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                _ImageWidget(
                  fileServer: comic.thumb.fileServer,
                  path: comic.thumb.path,
                  id: comic.id,
                  pictureType: "cover",
                ),
                SizedBox(width: screenWidth / 60),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: screenWidth / 200),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: _getLimitedTitle(comic.title, 30),
                              style: TextStyle(
                                color: colorNotifier.defaultTextColor,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: comic.finished ? "(完)" : "",
                              style: TextStyle(
                                color: colorNotifier.themeType
                                    ? Colors.red
                                    : Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (comic.author.toString() != '') ...[
                        const SizedBox(height: 5),
                        Text(
                          _getLimitedTitle(comic.author.toString(), 40),
                          style: TextStyle(
                            color: colorNotifier.themeType
                                ? Colors.red
                                : Colors.yellow,
                          ),
                        ),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        _getCategories(comic.categories),
                        style: TextStyle(
                          color: colorNotifier.defaultTextColor,
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24.0,
                          ),
                          // const SizedBox(width: 10.0),
                          Text(
                            "$_type：${comic.leaderboardCount.toString()}",
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth / 200),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth / 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageWidget extends ConsumerStatefulWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const _ImageWidget({
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  ConsumerState<_ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends ConsumerState<_ImageWidget> {
  late Future<String> _getCachePicture;

  @override
  void initState() {
    super.initState();
    _refreshCachePicture();
  }

  void _refreshCachePicture() {
    // 重新初始化 _getCachePicture，以触发 FutureBuilder 重建
    setState(() {
      _getCachePicture = getCachePicture(
        widget.fileServer,
        widget.path,
        widget.id,
        pictureType: widget.pictureType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return SizedBox(
      width: (screenWidth / 10) * 3,
      height: 180,
      child: FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // 如果有错误，显示错误信息和一个重新加载的按钮
              // 部分图片在服务器上可能已经不存在，所以显示一个404图片
              if (snapshot.error.toString().contains('404')) {
                return Image.asset('asset/image/error_image/404.png');
              } else {
                return InkWell(
                  onTap: _refreshCachePicture, // 直接调用 _refreshCachePicture
                  child: Center(
                    child: Text(
                      '加载图片失败\n点击重新加载',
                      style: TextStyle(
                        color: colorNotifier.defaultTextColor,
                      ),
                    ),
                  ),
                );
              }
            } else {
              // 没有错误，正常显示图片
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImageView(imagePath: snapshot.data!),
                    ),
                  );
                },
                child: Hero(
                  tag: snapshot.data!,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
                    child: Image.file(
                      File(snapshot.data!),
                      fit: BoxFit.cover,
                      width: (screenWidth / 10) * 3,
                      height: 180,
                    ),
                  ),
                ),
              );
            }
          } else {
            // 图片正在加载中
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: Colors.black,
                size: 50,
              ),
            );
          }
        },
      ),
    );
  }
}

class _CreatorRankingsWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreatorRankingsWidget> createState() =>
      _CreatorRankingsWidgetState();
}

class _CreatorRankingsWidgetState
    extends ConsumerState<_CreatorRankingsWidget> {
  late Future<List<User>> _fetchRankings;

  @override
  void initState() {
    super.initState();
    _fetchRankings = fetchRankings();
  }

  // 获取章节列表并正序
  Future<List<User>> fetchRankings() async {
    var result = await getRankingList('creator');
    if (result['error'] != null) {
      throw Exception(result);
    }
    if (result['code'] != null) {
      throw Exception(result);
    }
    var temp = CreatorRanking.fromJson(result);
    List<User> creatorList = [];
    for (var item in temp.users) {
      creatorList.add(item);
    }

    return creatorList;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FutureBuilder<List<User>>(
          future: _fetchRankings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _fetchRankings =
                              fetchRankings(); // 触发 FutureBuilder 重建
                        });
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              List<User> comics = snapshot.data!;
              return Column(
                children: [
                  // 使用 map 和 Padding 创建 ComicEntryWidget 列表
                  ...comics.map(
                    (comic) => _CreatorInfoWidget(
                      user: comic,
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: Text('No Episodes Found'));
            }
          },
        ),
        Center(
          child: Padding(
            padding: EdgeInsets.all(30.0),
            child: Container(),
          ),
        )
      ],
    );
  }
}

class _CreatorInfoWidget extends ConsumerStatefulWidget {
  final User user;

  const _CreatorInfoWidget({required this.user});

  @override
  ConsumerState<_CreatorInfoWidget> createState() => _CreatorInfoWidgetState();
}

class _CreatorInfoWidgetState extends ConsumerState<_CreatorInfoWidget>
    with AutomaticKeepAliveClientMixin<_CreatorInfoWidget> {
  User get user => widget.user;

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化

    return Column(
      children: <Widget>[
        SizedBox(
          height: (screenHeight / 10) * 0.1,
        ),
        InkWell(
          onTap: () {
            navigateTo(
              context,
              '/search',
              extra: SearchEnter(
                  url:
                      "https://picaapi.picacomic.com/comics?ca=58f649a80a48790773c7017c&s=ld&page=1",
                  keyword: user.id.toString()),
            );
          },
          child: Container(
            height: 75,
            width: screenWidth * (48 / 50),
            decoration: BoxDecoration(
              color: colorNotifier.defaultBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: colorNotifier.themeType
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _CreatorImagerWidget(
                  fileServer: user.avatar.fileServer,
                  path: user.avatar.path,
                  id: user.id,
                  pictureType: "creator",
                ),
                const SizedBox(width: 15),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Text("等级：${user.level.toString()}"),
                          SizedBox(width: 30),
                          Text("总上传数：${user.comicsUploaded.toString()}"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CreatorImagerWidget extends ConsumerStatefulWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const _CreatorImagerWidget({
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  ConsumerState<_CreatorImagerWidget> createState() => _ImagerWidgetState();
}

class _ImagerWidgetState extends ConsumerState<_CreatorImagerWidget> {
  get fileServer => widget.fileServer;

  get path => widget.path;

  get id => widget.id;

  get pictureType => widget.pictureType;

  late Future<String> _getCachePicture;

  void _reloadImage() {
    // 重置 Future，以便重新加载图片
    setState(() {
      _getCachePicture = getCachePicture(
        fileServer,
        path,
        id,
        pictureType: pictureType,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _getCachePicture = getCachePicture(
      fileServer,
      path,
      id,
      pictureType: pictureType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return SizedBox(
      height: 75,
      width: 75,
      child: FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              if (snapshot.error.toString().contains('404')) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.asset(
                      'asset/image/error_image/404.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              } else {
                // 如果有错误，显示错误信息和一个重新加载的按钮
                return InkWell(
                  onTap: () {
                    _reloadImage(); // 调用 _reloadImage 方法重新加载图片
                  },
                  child: Center(
                    child: Icon(
                      Icons.refresh,
                      size: 25,
                      color: colorNotifier.defaultTextColor,
                    ),
                  ),
                );
              }
            } else {
              // 没有错误，正常显示图片
              return Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImageView(imagePath: snapshot.data!),
                      ),
                    );
                  },
                  child: Hero(
                    tag: snapshot.data!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          } else {
            // 图片正在加载中
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: colorNotifier.defaultTextColor!,
                size: 25,
              ),
            );
          }
        },
      ),
    );
  }
}
