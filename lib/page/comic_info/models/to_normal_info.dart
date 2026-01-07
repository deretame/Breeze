import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart' as jm;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/models/all_info.dart' as bika;
import 'package:zephyr/type/pipe.dart';

normal.NormalComicAllInfo bika2NormalComicAllInfo(bika.AllInfo allInfo) {
  return normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: allInfo.comicInfo.id,
      creator: normal.Creator(
        id: allInfo.comicInfo.creator.id,
        name: allInfo.comicInfo.creator.name,
        avatar: normal.Cover(
          url: allInfo.comicInfo.creator.avatar.fileServer,
          path: allInfo.comicInfo.creator.avatar.path,
          name: allInfo.comicInfo.creator.avatar.originalName,
        ),
      ),
      title: allInfo.comicInfo.title,
      description: allInfo.comicInfo.description,
      cover: normal.Cover(
        url: allInfo.comicInfo.thumb.fileServer,
        path: allInfo.comicInfo.thumb.path,
        name: allInfo.comicInfo.thumb.originalName,
      ),
      categories: allInfo.comicInfo.categories,
      tags: allInfo.comicInfo.tags,
      author: allInfo.comicInfo.author.isNotEmpty
          ? [allInfo.comicInfo.author]
          : [],
      works: [],
      actors: [],
      chineseTeam: allInfo.comicInfo.chineseTeam.isNotEmpty
          ? [allInfo.comicInfo.chineseTeam]
          : [],
      pagesCount: allInfo.comicInfo.pagesCount,
      epsCount: allInfo.comicInfo.epsCount,
      updatedAt: allInfo.comicInfo.updatedAt,
      allowComment: allInfo.comicInfo.allowComment,
      totalViews: allInfo.comicInfo.totalViews,
      totalLikes: allInfo.comicInfo.totalLikes,
      totalComments: allInfo.comicInfo.totalComments,
      isFavourite: allInfo.comicInfo.isFavourite,
      isLiked: allInfo.comicInfo.isLiked,
    ),
    eps: allInfo.eps
        .map((e) => normal.Ep(id: e.id, name: e.title, order: e.order))
        .toList(),
    recommend: allInfo.recommendJson
        .map(
          (e) => normal.Recommend(
            id: e.id,
            title: e.title,
            cover: normal.Cover(
              url: e.thumb.fileServer,
              path: e.thumb.path,
              name: e.thumb.originalName,
            ),
          ),
        )
        .toList(),
  );
}

normal.NormalComicAllInfo jm2NormalComicAllInfo(jm.JmComicInfoJson allInfo) {
  return normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: allInfo.id.toString(),
      creator: normal.Creator(
        id: "",
        name: "",
        avatar: normal.Cover(url: "", path: "", name: ""),
      ),
      title: allInfo.name,
      description: allInfo.description,
      cover: normal.Cover(url: "", path: "", name: ""),
      categories: [],
      tags: allInfo.tags,
      author: allInfo.author,
      works: allInfo.works,
      actors: allInfo.actors,
      chineseTeam: [],
      pagesCount: 0,
      epsCount: allInfo.series.isEmpty ? 1 : allInfo.series.length,
      updatedAt: parseTimestamp(allInfo.addtime),
      allowComment: true,
      totalViews: allInfo.totalViews.let(toInt),
      totalLikes: allInfo.likes.let(toInt),
      totalComments: allInfo.commentTotal.let(toInt),
      isFavourite: allInfo.isFavorite,
      isLiked: allInfo.liked,
    ),
    eps: allInfo.series
        .map((e) => normal.Ep(id: e.id, name: e.name, order: e.sort.let(toInt)))
        .toList(),
    recommend: allInfo.relatedList
        .map(
          (e) => normal.Recommend(
            id: e.id,
            title: e.name,
            cover: normal.Cover(url: "", path: "", name: ""),
          ),
        )
        .toList(),
  );
}

DateTime parseTimestamp(String time) => time
    .let(toInt)
    .let(
      (timestamp) =>
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true),
    );
