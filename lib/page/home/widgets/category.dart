import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/page/search_result/bloc/search_bloc.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';

import '../../../widgets/picture_bloc/models/picture_info.dart';

class CategoriesGrid extends StatelessWidget {
  final List<HomeCategory> data;

  const CategoriesGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    const double gridSpacing = 12.0;

    return GridView.builder(
      padding: const EdgeInsets.all(gridSpacing),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        childAspectRatio: 0.8,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: data.length,
      itemBuilder: (context, index) {
        return CategoryLineWidget(category: data[index]);
      },
    );
  }
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
              from: From.bika,
              url: category.homeThumb.fileServer,
              path: category.homeThumb.path,
              pictureType: PictureType.category,
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
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: _buildImage(context, state.imagePath!),
                    ),
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
                        from: From.bika,
                        url: category.homeThumb.fileServer,
                        path: category.homeThumb.path,
                        pictureType: PictureType.category,
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
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.asset(
                category.link,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
      var url = category.link;
      if (category.title == '嗶咔畫廊') {
        final bikaState = context.read<BikaSettingCubit>().state;
        var authorization = bikaState.authorization;
        url = "$url?token=$authorization";
      }
      List<String> info = [category.title, url];
      if (Platform.isLinux) {
        lunchBrow(url);
      } else {
        router.push(WebViewRoute(info: info));
      }
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

  Future<void> lunchBrow(String url) async {
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('launchUrl return false');
      }
    } catch (e) {
      if (Platform.isLinux) {
        try {
          await Process.start('cmd.exe', [
            '/c',
            'start',
            '',
            url,
          ], mode: ProcessStartMode.detached);
        } catch (wslError) {
          logger.e("WSL Fallback failed: $wslError");
        }
      }
    }
  }
}
