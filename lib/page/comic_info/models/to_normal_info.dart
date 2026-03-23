import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart' as jm;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/models/all_info.dart' as bika;
import 'package:zephyr/type/pipe.dart';

normal.NormalComicAllInfo bika2NormalComicAllInfo(bika.AllInfo allInfo) {
  return normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: allInfo.comicInfo.id,
      title: allInfo.comicInfo.title,
      titleMeta: [
        _actionItem('更新时间：${allInfo.comicInfo.updatedAt.toLocal()}'),
        if (allInfo.comicInfo.pagesCount > 0)
          _actionItem('页数：${allInfo.comicInfo.pagesCount}'),
        _actionItem('章节数：${allInfo.comicInfo.epsCount}'),
      ],
      creator: normal.Creator(
        id: allInfo.comicInfo.creator.id,
        name: allInfo.comicInfo.creator.name,
        avatar: _image(
          id: allInfo.comicInfo.creator.id,
          url: '',
          name: allInfo.comicInfo.creator.avatar.originalName,
          extension: {
            'path': allInfo.comicInfo.creator.avatar.path,
            'fileServer': allInfo.comicInfo.creator.avatar.fileServer,
          },
        ),
      ),
      description: allInfo.comicInfo.description,
      cover: _image(
        id: allInfo.comicInfo.id,
        url: '',
        name: allInfo.comicInfo.thumb.originalName,
        extension: {
          'path': allInfo.comicInfo.thumb.path,
          'fileServer': allInfo.comicInfo.thumb.fileServer,
        },
      ),
      metadata: [
        _meta('author', '作者', [allInfo.comicInfo.author]),
        _meta('chineseTeam', '汉化', [allInfo.comicInfo.chineseTeam]),
        _meta('categories', '分类', allInfo.comicInfo.categories),
        _meta('tags', '标签', allInfo.comicInfo.tags),
      ].where((m) => m.value.isNotEmpty).toList(),
    ),
    eps: allInfo.eps
        .map(
          (e) => normal.Ep(
            id: e.id,
            name: e.title,
            order: e.order,
          ),
        )
        .toList(),
    recommend: allInfo.recommendJson
        .map(
          (e) => normal.Recommend(
            source: 'bika',
            id: e.id,
            title: e.title,
            cover: _image(
              id: e.id,
              url: '',
              name: e.thumb.originalName,
              extension: {
                'path': e.thumb.path,
                'fileServer': e.thumb.fileServer,
              },
            ),
          ),
        )
        .toList(),
    totalViews: allInfo.comicInfo.totalViews,
    totalLikes: allInfo.comicInfo.totalLikes,
    totalComments: allInfo.comicInfo.totalComments,
    isFavourite: allInfo.comicInfo.isFavourite,
    isLiked: allInfo.comicInfo.isLiked,
    allowComment: allInfo.comicInfo.allowComment,
    allowLike: true,
    allowFavorite: true,
    allowDownload: true,
  );
}

normal.NormalComicAllInfo jm2NormalComicAllInfo(jm.JmComicInfoJson allInfo) {
  final epsCount = allInfo.series.isEmpty ? 1 : allInfo.series.length;
  return normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: allInfo.id.toString(),
      title: allInfo.name,
      titleMeta: [
        _actionItem('更新时间：${parseTimestamp(allInfo.addtime).toLocal()}'),
        _actionItem('章节数：$epsCount'),
        _actionItem('禁漫车：jm${allInfo.id}'),
      ],
      creator: normal.Creator(
        id: '',
        name: '',
        avatar: _image(id: '', url: '', name: ''),
      ),
      description: allInfo.description,
      cover: _image(
        id: allInfo.id.toString(),
        url: '',
        name: '',
        extension: {'path': '${allInfo.id}.jpg'},
      ),
      metadata: [
        _meta('author', '作者', allInfo.author),
        _meta('tags', '标签', allInfo.tags),
        _meta('actors', '角色', allInfo.actors),
        _meta('works', '原作', allInfo.works),
      ].where((m) => m.value.isNotEmpty).toList(),
    ),
    eps: allInfo.series
        .map(
          (e) => normal.Ep(
            id: e.id,
            name: e.name,
            order: e.sort.let(toInt),
          ),
        )
        .toList(),
    recommend: allInfo.relatedList
        .map(
          (e) => normal.Recommend(
            source: 'jm',
            id: e.id,
            title: e.name,
            cover: _image(
              id: e.id,
              url: '',
              name: '',
              extension: {'path': '${e.id}.jpg'},
            ),
          ),
        )
        .toList(),
    totalViews: allInfo.totalViews.let(toInt),
    totalLikes: allInfo.likes.let(toInt),
    totalComments: allInfo.commentTotal.let(toInt),
    isFavourite: allInfo.isFavorite,
    isLiked: allInfo.liked,
    allowComment: true,
    allowLike: true,
    allowFavorite: true,
    allowDownload: true,
  );
}

normal.ComicInfoMetadata _meta(
  String type,
  String name,
  List<dynamic> values,
) {
  return normal.ComicInfoMetadata(
    type: type,
    name: name,
    value: values
        .where((v) => v != null && v.toString().trim().isNotEmpty)
        .map((v) => _actionItem(v.toString()))
        .toList(),
  );
}

normal.ComicInfoActionItem _actionItem(
  String name, {
  Map<String, dynamic> onTap = const {},
  Map<String, dynamic> extension = const {},
}) {
  return normal.ComicInfoActionItem(
    name: name,
    onTap: onTap,
    extension: extension,
  );
}

normal.ComicImage _image({
  required String id,
  required String url,
  required String name,
  Map<String, dynamic> extension = const {},
}) {
  return normal.ComicImage(
    id: id,
    url: url,
    name: name,
    extension: extension,
  );
}

DateTime parseTimestamp(String time) => time
    .let(toInt)
    .let(
      (timestamp) =>
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true),
    );
