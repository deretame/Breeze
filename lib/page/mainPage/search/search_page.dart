import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../config/global.dart';
import '../../../json/search_category.dart';
import '../../../network/http/http_request.dart';
import '../../../network/http/picture.dart';
import '../../../type/search_enter.dart';
import '../../../util/router.dart';
import '../../../util/state_management.dart';

// 主页的搜索页面
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({
    super.key,
  });

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late SearchEnter _localEnter;
  late Future<Map<String, dynamic>> _searchCategoryFuture;
  bool isLoading = true; // 用于显示加载状态的标志

  @override
  void initState() {
    _localEnter = SearchEnter();
    _searchCategoryFuture = _loadSearchCategory();
    super.initState();
  }

  Future<Map<String, dynamic>> _loadSearchCategory() async {
    return await getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context); // 显式初始化
    Global globalInstance = Global(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('搜索本子'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              navigateTo(context, '/search', extra: _localEnter);
            },
          ),
        ],
      ),
      body: Observer(
        builder: (_) {
          return FutureBuilder<Map<String, dynamic>>(
            future: _searchCategoryFuture,
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
                              _searchCategoryFuture =
                                  _loadSearchCategory(); // 重新调用异步函数
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
                              _searchCategoryFuture =
                                  _loadSearchCategory(); // 重新调用异步函数
                            });
                          },
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // 值里面缺胳膊少腿的比较多，需要处理一下
                  var temp = snapshot.data!['categories'];
                  for (var category in temp) {
                    category['isWeb'] = category['isWeb'] ?? false;
                    category['active'] = category['active'] ?? false;
                    category['link'] = category['link'] ?? '';
                    category['description'] = category['description'] ?? '';
                    category['_id'] = category['_id'] ?? '';
                  }
                  snapshot.data!['categories'] = temp;
                  try {
                    List<String> shieldList = shieldCategoryMapRealm.keys
                        .where((key) => shieldCategoryMapRealm[key] == true)
                        .toList();
                    var temp = SearchCategory.fromJson(snapshot.data!);
                    debugPrint(temp.toString());
                    for (var category in temp.categories) {
                      var temp = CategoryGlobal(
                        title: category.title,
                        thumb: ThumbGlobal(
                          originalName: category.thumb.originalName,
                          path: category.thumb.path,
                          fileServer: category.thumb.fileServer,
                        ),
                        isWeb: category.isWeb!,
                        active: category.active!,
                        link: category.link!,
                      );
                      if (!shieldList
                          .any((string) => string.contains(temp.title))) {
                        globalInstance.categories.categoriesGlobal.add(temp);
                      }
                    }
                    // globalInstance.categories.sortCategoriesByIsWeb(); // 把网页放在前面

                    List<Widget> widgets = List.generate(
                      globalInstance.categories.categoriesGlobal.length,
                      (index) => SizedBox(
                        width: screenWidth / 4,
                        height: screenWidth / 4 + 50,
                        // padding: EdgeInsets.all(10.0),
                        // color: Colors.blue[100 * (index % 9)],
                        child: CategoryWidget(
                            category: globalInstance
                                .categories.categoriesGlobal[index]),
                      ),
                    );

                    // 确定需要多少行，以及最后一行是否需要填充
                    int rowsCount = (widgets.length / 3).ceil();
                    int remainingItems = widgets.length % 3;

                    // 如果最后一行不足三个组件，则添加占位符
                    if (remainingItems != 0) {
                      int placeholdersToAdd = 3 - remainingItems;
                      widgets.addAll(
                        List.generate(
                          placeholdersToAdd,
                          (index) => SizedBox(
                            width: screenWidth / 4,
                            height: screenWidth / 4,
                          ),
                        ),
                      );
                    }

                    // 将列表分成每三个一组
                    List<Widget> rows = [];
                    for (var i = 0; i < rowsCount; i++) {
                      rows.add(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            widgets[i * 3],
                            widgets[i * 3 + 1],
                            widgets[i * 3 + 2],
                          ],
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Column(
                        children: rows,
                      ),
                    );
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                  return SingleChildScrollView(
                    // 添加滚动视图
                    physics: const ClampingScrollPhysics(), // 滚动物理，根据需要可以调整
                    // child: ComicInfoWidget(comicInfo: comicInfo),
                  );
                }
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class CategoryWidget extends ConsumerStatefulWidget {
  final CategoryGlobal category;

  const CategoryWidget({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends ConsumerState<CategoryWidget> {
  CategoryGlobal get category => widget.category;

  late Future<String> _getCachePicture;

  void _reloadImage() {
    // 重置 Future，以便重新加载图片
    setState(() {
      _getCachePicture = getCachePicture(
        category.thumb.fileServer,
        category.thumb.path,
        category.thumb.originalName,
        pictureType: "category",
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _getCachePicture = getCachePicture(
      category.thumb.fileServer,
      category.thumb.path,
      category.thumb.originalName,
      pictureType: "category",
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    if (category.thumb.path == '') {
      if (category.title == '哔咔排行榜') {
        return InkWell(
          highlightColor: Colors.transparent, // 移除按下时的高亮效果
          splashColor: Colors.transparent, // 移除水波纹效果
          onTap: () {
            navigateTo(context, '/rankingList');
          },
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  width: screenWidth / 4,
                  height: screenWidth / 4,
                  child: Image.asset(
                    category.link,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                category.title,
              ),
            ],
          ),
        );
      } else if (category.title == '最近更新') {
        return InkWell(
          highlightColor: Colors.transparent, // 移除按下时的高亮效果
          splashColor: Colors.transparent, // 移除水波纹效果
          onTap: () {
            navigateTo(
              context,
              '/search',
              extra: SearchEnter(),
            );
          },
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  width: screenWidth / 4,
                  height: screenWidth / 4,
                  child: Image.asset(
                    category.link,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                category.title,
              ),
            ],
          ),
        );
      } else if (category.title == '随机本子') {
        return InkWell(
          highlightColor: Colors.transparent, // 移除按下时的高亮效果
          splashColor: Colors.transparent, // 移除水波纹效果
          onTap: () {
            navigateTo(
              context,
              '/search',
              extra: SearchEnter(
                  url: "https://picaapi.picacomic.com/comics/random"),
            );
          },
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: SizedBox(
                  width: screenWidth / 4,
                  height: screenWidth / 4,
                  child: Image.asset(
                    category.link,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                category.title,
              ),
            ],
          ),
        );
      } else {
        return SizedBox.shrink();
      }
    } else {
      return FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              if (snapshot.error.toString().contains('404')) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: screenWidth / 4,
                    height: screenWidth / 4,
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
                      size: 30,
                      color: colorNotifier.defaultTextColor,
                    ),
                  ),
                );
              }
            } else {
              // 没有错误，正常显示图片
              return Center(
                child: InkWell(
                  highlightColor: Colors.transparent, // 移除按下时的高亮效果
                  splashColor: Colors.transparent, // 移除水波纹效果
                  onTap: () {
                    if (category.title == '大家都在看') {
                      navigateTo(
                        context,
                        '/search',
                        extra: SearchEnter(
                            url:
                                "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B&s=dd"),
                      );
                    } else if (category.title == '大濕推薦') {
                      navigateTo(
                        context,
                        '/search',
                        extra: SearchEnter(
                            url:
                                "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E6%BF%95%E6%8E%A8%E8%96%A6&s=dd"),
                      );
                    } else if (category.title == '那年今天') {
                      navigateTo(
                        context,
                        '/search',
                        extra: SearchEnter(
                            url:
                                "https://picaapi.picacomic.com/comics?page=1&c=%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9&s=dd"),
                      );
                    } else if (category.title == '官方都在看') {
                      navigateTo(
                        context,
                        '/search',
                        extra: SearchEnter(
                            url:
                                "https://picaapi.picacomic.com/comics?page=1&c=%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B&s=dd"),
                      );
                    } else if (category.isWeb) {
                      List<String> info = [category.title, category.link];
                      navigateTo(context, '/webview', extra: info);
                    } else {
                      navigateTo(
                        context,
                        '/search',
                        extra: SearchEnter(categories: [category.title]),
                      );
                    }
                  },
                  child: Column(
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: SizedBox(
                          width: screenWidth / 4,
                          height: screenWidth / 4,
                          child: Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        category.title,
                      ),
                    ],
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
      );
    }
  }
}
