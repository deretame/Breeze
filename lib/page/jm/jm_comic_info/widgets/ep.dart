import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../../config/global/global.dart';
import '../../../../main.dart';
import '../../../../type/enum.dart';
import '../../../../util/router/router.gr.dart';
import '../json/jm_comic_info/jm_comic_info_json.dart';

class EpsWidget extends StatelessWidget {
  final String comicId;
  final List<Series> seriesList;
  final JmComicInfoJson comicInfo;

  const EpsWidget({
    super.key,
    required this.comicId,
    required this.seriesList,
    required this.comicInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 12.0,
      children:
          seriesList
              .map(
                (e) => ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: (screenWidth * 24 / 25 - 8) / 2,
                  ),
                  child: EpWidget(
                    comicId: comicId,
                    series: e,
                    comicInfo: comicInfo,
                  ),
                ),
              )
              .toList(),
    );
  }
}

class EpWidget extends StatelessWidget {
  final String comicId;
  final Series series;
  final JmComicInfoJson comicInfo;

  const EpWidget({
    super.key,
    required this.comicId,
    required this.series,
    required this.comicInfo,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.pushRoute(
          ComicReadRoute(
            comicId: comicId,
            order: series.id.let(int.parse),
            epsNumber: 0,
            from: From.jm,
            type: ComicEntryType.normal,
            comicInfo: comicInfo,
          ),
        );
      },
      child: Observer(
        builder: (context) {
          return Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 0),
            // Add horizontal margin
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: materialColorScheme.secondaryFixedDim,
                  spreadRadius: 0,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(series.name, style: TextStyle(fontSize: 16)),
          );
        },
      ),
    );
  }
}
