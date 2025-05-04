import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../config/global/global.dart';
import '../../../../main.dart';
import '../json/jm_comic_info/jm_comic_info_json.dart';

class EpsWidget extends StatelessWidget {
  final String comicId;
  final List<Series> seriesList;

  const EpsWidget({super.key, required this.comicId, required this.seriesList});

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
                    maxWidth:
                        (MediaQuery.of(context).size.width -
                            screenWidth / 25 -
                            8) /
                        2,
                  ),
                  child: EpWidget(comicId: comicId, series: e),
                ),
              )
              .toList(),
    );
  }
}

class EpWidget extends StatelessWidget {
  final String comicId;
  final Series series;

  const EpWidget({super.key, required this.comicId, required this.series});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // AutoRouter.of(context).push(
        //   ComicReadRoute(
        //     comicInfo: comicInfo,
        //     epsInfo: epsInfo,
        //     doc: doc,
        //     comicId: comicInfo.id,
        //     type: type,
        //   ),
        // );
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
