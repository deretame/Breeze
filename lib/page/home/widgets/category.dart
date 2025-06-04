import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/search_result/models/search_enter.dart'
    show SearchEnter;
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

List<Widget> buildCategoriesWidget(List<HomeCategory> data) {
  List<Widget> widgets = List.generate(
    data.length,
    (index) => SizedBox(
      width: screenWidth / 4,
      height: screenWidth / 4 + 50,
      child: CategoryLineWidget(category: data[index]),
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
        (index) => SizedBox(width: screenWidth / 4, height: screenWidth / 4),
      ),
    );
  }

  // 将列表分成每三个一组
  List<Widget> rows = [];
  for (var i = 0; i < rowsCount; i++) {
    rows.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [widgets[i * 3], widgets[i * 3 + 1], widgets[i * 3 + 2]],
      ),
    );
  }

  return rows;
}

class CategoryLineWidget extends StatelessWidget {
  final HomeCategory category;

  const CategoryLineWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              PictureBloc()..add(
                GetPicture(
                  PictureInfo(
                    from: "bika",
                    url: category.homeThumb.fileServer,
                    path: category.homeThumb.path,
                    pictureType: "category",
                  ),
                ),
              ),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          if (category.homeThumb.path.isEmpty) {
            return _buildDefaultImage(context);
          }

          switch (state.status) {
            case PictureLoadStatus.initial:
              return Center(
                child: LoadingAnimationWidget.waveDots(
                  color: materialColorScheme.primaryFixedDim,
                  size: 25,
                ),
              );
            case PictureLoadStatus.success:
              return GestureDetector(
                onTap: () => _navigateBasedOnTitle(context),
                child: Column(
                  children: <Widget>[
                    _buildImage(state.imagePath!),
                    SizedBox(height: 5),
                    Observer(
                      builder: (context) {
                        return Text(
                          category.title.let(t2s),
                          style: TextStyle(
                            color: globalSetting.textColor,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            case PictureLoadStatus.failure:
              return InkWell(
                onTap: () {
                  context.read<PictureBloc>().add(
                    GetPicture(
                      PictureInfo(
                        from: "bika",
                        url: category.homeThumb.fileServer,
                        path: category.homeThumb.path,
                        pictureType: "category",
                      ),
                    ),
                  );
                },
                child: Icon(Icons.refresh),
              );
          }
        },
      ),
    );
  }

  Widget _buildDefaultImage(BuildContext context) {
    final router = AutoRouter.of(context);
    return GestureDetector(
      onTap: () {
        // 根据类别处理点击事件
        if (category.title == '最近更新') {
          router.push(SearchResultRoute(searchEnter: SearchEnter.initial()));
        } else if (category.title == '随机本子') {
          router.push(
            SearchResultRoute(
              searchEnter: SearchEnter.initial().copyWith(
                from: "bika",
                url: "https://picaapi.picacomic.com/comics/random",
              ),
            ),
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
              child: Image.asset(category.link, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 5),
          Observer(
            builder: (context) {
              return Text(
                category.title,
                style: TextStyle(color: globalSetting.textColor, fontSize: 14),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: SizedBox(
        width: screenWidth / 4,
        height: screenWidth / 4,
        child: Image.file(File(imagePath), fit: BoxFit.cover),
      ),
    );
  }

  void _navigateBasedOnTitle(BuildContext context) {
    final router = AutoRouter.of(context);
    // 处理不同标题的导航操作
    if (category.title == '大家都在看') {
      router.push(
        SearchResultRoute(
          searchEnter: SearchEnter.initial().copyWith(
            url:
                "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B&s=dd",
          ),
        ),
      );
    } else if (category.title == '大濕推薦') {
      router.push(
        SearchResultRoute(
          searchEnter: SearchEnter.initial().copyWith(
            url:
                "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E6%BF%95%E6%8E%A8%E8%96%A6&s=dd",
          ),
        ),
      );
    } else if (category.title == '那年今天') {
      router.push(
        SearchResultRoute(
          searchEnter: SearchEnter.initial().copyWith(
            url:
                "https://picaapi.picacomic.com/comics?page=1&c=%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9&s=dd",
          ),
        ),
      );
    } else if (category.title == '官方都在看') {
      router.push(
        SearchResultRoute(
          searchEnter: SearchEnter.initial().copyWith(
            url:
                "https://picaapi.picacomic.com/comics?page=1&c=%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B&s=dd",
          ),
        ),
      );
    } else if (category.isWeb) {
      List<String> info = [category.title, category.link];
      router.push(WebViewRoute(info: info));
    } else {
      router.push(
        SearchResultRoute(
          searchEnter: SearchEnter.initial().copyWith(
            categories: [category.title],
          ),
        ),
      );
    }
  }
}
