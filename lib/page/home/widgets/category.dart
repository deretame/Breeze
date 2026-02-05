import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';

import '../../../widgets/picture_bloc/models/picture_info.dart';

Widget buildCategoriesGrid(BuildContext context, List<HomeCategory> data) {
  double screenWidth = 0;
  int itemCount = 0;

  if (isTablet(context)) {
    screenWidth = context.screenWidth / 5;
    itemCount = 5;
  } else {
    screenWidth = context.screenWidth / 3;
    itemCount = 3;
  }

  final double itemWidth = screenWidth;
  final double itemHeight = itemWidth + 50;
  final double aspectRatio = itemWidth / itemHeight;

  const double gridSpacing = 8.0;

  return GridView.count(
    padding: const EdgeInsets.all(gridSpacing),

    crossAxisCount: itemCount,
    childAspectRatio: aspectRatio,

    mainAxisSpacing: gridSpacing,
    crossAxisSpacing: gridSpacing,

    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    children: data.map((category) {
      return CategoryLineWidget(category: category);
    }).toList(),
  );
}

class CategoryLineWidget extends StatelessWidget {
  final HomeCategory category;

  const CategoryLineWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PictureBloc()
        ..add(
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
                  color: context.theme.colorScheme.primaryFixedDim,
                  size: 25,
                ),
              );
            case PictureLoadStatus.success:
              return GestureDetector(
                onTap: () => _navigateBasedOnTitle(context),
                child: Column(
                  children: <Widget>[
                    _buildImage(context, state.imagePath!),
                    SizedBox(height: 5),
                    Text(
                      category.title.let(t2s),
                      style: TextStyle(color: context.textColor, fontSize: 14),
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
    return GestureDetector(
      onTap: () {
        // 根据类别处理点击事件
        if (category.title == '最近更新') {
          context.pushRoute(
            SearchResultRoute(
              searchEvent: SearchEvent().copyWith(
                searchStates: SearchStates.initial(
                  context,
                ).copyWith(from: From.bika),
              ),
            ),
          );
        } else if (category.title == '随机本子') {
          urlPush(
            context,
            "https://picaapi.picacomic.com/comics/random",
            category.title,
          );
        }
      },
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Builder(
              builder: (context) {
                double screenWidth = 0;

                if (isTablet(context)) {
                  screenWidth = context.screenWidth / 6;
                } else {
                  screenWidth = context.screenWidth / 4;
                }
                return SizedBox(
                  width: screenWidth,
                  height: screenWidth,
                  child: Image.asset(category.link, fit: BoxFit.cover),
                );
              },
            ),
          ),
          SizedBox(height: 5),
          Text(
            category.title,
            style: TextStyle(color: context.textColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, String imagePath) {
    double screenWidth = 0;

    if (isTablet(context)) {
      screenWidth = context.screenWidth / 6;
    } else {
      screenWidth = context.screenWidth / 4;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: SizedBox(
        width: screenWidth,
        height: screenWidth,
        child: Image.file(File(imagePath), fit: BoxFit.cover),
      ),
    );
  }

  void _navigateBasedOnTitle(BuildContext context) {
    final router = AutoRouter.of(context);
    // 处理不同标题的导航操作
    if (category.title == '大家都在看') {
      urlPush(
        context,
        "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B&s=dd",
        category.title,
      );
    } else if (category.title == '大濕推薦') {
      urlPush(
        context,
        "https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E6%BF%95%E6%8E%A8%E8%96%A6&s=dd",
        category.title,
      );
    } else if (category.title == '那年今天') {
      urlPush(
        context,
        "https://picaapi.picacomic.com/comics?page=1&c=%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9&s=dd",
        category.title,
      );
    } else if (category.title == '官方都在看') {
      urlPush(
        context,
        "https://picaapi.picacomic.com/comics?page=1&c=%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B&s=dd",
        category.title,
      );
    } else if (category.isWeb) {
      List<String> info = [category.title, category.link];
      router.push(WebViewRoute(info: info));
    } else {
      final Map<String, bool> newCategories = {
        for (var key in categoryMap.keys) key: key == category.title,
      };

      context.pushRoute(
        SearchResultRoute(
          searchEvent: SearchEvent().copyWith(
            searchStates: SearchStates.initial(
              context,
            ).copyWith(from: From.bika, categories: newCategories),
          ),
        ),
      );
    }
  }

  void urlPush(BuildContext context, String url, String title) {
    context.pushRoute(
      SearchResultRoute(
        searchEvent: SearchEvent().copyWith(
          searchStates: SearchStates.initial(
            context,
          ).copyWith(from: From.bika, searchKeyword: title),
          url: url,
        ),
      ),
    );
  }
}
