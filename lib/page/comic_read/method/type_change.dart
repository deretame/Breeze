import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/models/all_info.dart';

import '../../../object_box/model.dart';

BikaComicHistory comicToBikaComicHistory(Comic comic) {
  String creatorCharactersString = "";
  for (var character in comic.creator.characters) {
    creatorCharactersString += character;
  }

  String categoriesString = "";
  for (var category in comic.categories) {
    categoriesString += category;
  }

  String tagsString = "";
  for (var tag in comic.tags) {
    tagsString += tag;
  }

  return BikaComicHistory(
    comicId: comic.id,
    creatorId: comic.creator.id,
    creatorGender: comic.creator.gender,
    creatorName: comic.creator.name,
    creatorVerified: comic.creator.verified,
    creatorExp: comic.creator.exp,
    creatorLevel: comic.creator.level,
    creatorCharacters: comic.creator.characters,
    creatorCharactersString: creatorCharactersString,
    creatorRole: comic.creator.role,
    creatorTitle: comic.creator.title,
    creatorAvatarOriginalName: comic.creator.avatar.originalName,
    creatorAvatarPath: comic.creator.avatar.path,
    creatorAvatarFileServer: comic.creator.avatar.fileServer,
    creatorSlogan: comic.creator.slogan,
    title: comic.title,
    description: comic.description,
    thumbOriginalName: comic.thumb.originalName,
    thumbPath: comic.thumb.path,
    thumbFileServer: comic.thumb.fileServer,
    author: comic.author,
    chineseTeam: comic.chineseTeam,
    categories: comic.categories,
    categoriesString: categoriesString,
    tags: comic.tags,
    tagsString: tagsString,
    pagesCount: comic.pagesCount,
    epsCount: comic.epsCount,
    finished: comic.finished,
    updatedAt: comic.updatedAt,
    createdAt: comic.createdAt,
    allowDownload: comic.allowDownload,
    allowComment: comic.allowComment,
    totalLikes: comic.totalLikes,
    totalViews: comic.totalViews,
    totalComments: comic.totalComments,
    viewsCount: comic.viewsCount,
    likesCount: comic.likesCount,
    commentsCount: comic.commentsCount,
    isFavourite: comic.isFavourite,
    isLiked: comic.isLiked,
    history: DateTime.now().toUtc(),
    epTitle: "",
    order: 0,
    epPageCount: 0,
    epId: "",
    deleted: false,
  );
}

JmHistory jmToJmHistory(JmComicInfoJson jmComic) {
  return JmHistory(
    comicId: jmComic.id.toString(),
    name: jmComic.name,
    addtime: jmComic.addtime,
    description: jmComic.description,
    totalViews: jmComic.totalViews,
    likes: jmComic.likes,
    seriesId: jmComic.seriesId,
    commentTotal: jmComic.commentTotal,
    author: jmComic.author,
    tags: jmComic.tags,
    works: jmComic.works,
    actors: jmComic.actors,
    liked: jmComic.liked,
    isFavorite: jmComic.isFavorite,
    isAids: jmComic.isAids,
    price: jmComic.price,
    purchased: jmComic.purchased,
    order: 0,
    epTitle: "",
    epPageCount: 0,
    epId: "",
    deleted: false,
    history: DateTime.now().toUtc(),
  );
}

BikaComicHistory pluginDetailToBikaHistory(PluginComicDetailSource source) {
  return comicToBikaComicHistory(Comic.fromJson(source.rawComicInfo));
}

JmHistory pluginDetailToJmHistory(PluginComicDetailSource source) {
  final raw = source.rawComicInfo;
  return JmHistory(
    comicId: source.comicId,
    name: raw['name']?.toString() ?? source.normalInfo.comicInfo.title,
    addtime: raw['addtime']?.toString() ?? '0',
    description:
        raw['description']?.toString() ?? source.normalInfo.comicInfo.description,
    totalViews: raw['total_views']?.toString() ?? '0',
    likes: raw['likes']?.toString() ?? '0',
    seriesId: raw['series_id']?.toString() ?? '',
    commentTotal: raw['comment_total']?.toString() ?? '0',
    author: List<String>.from(raw['author'] as List? ?? const <String>[]),
    tags: List<String>.from(raw['tags'] as List? ?? const <String>[]),
    works: List<String>.from(raw['works'] as List? ?? const <String>[]),
    actors: List<String>.from(raw['actors'] as List? ?? const <String>[]),
    liked: raw['liked'] == true,
    isFavorite: raw['is_favorite'] == true,
    isAids: raw['is_aids'] == true,
    price: raw['price']?.toString() ?? '0',
    purchased: raw['purchased']?.toString() ?? '0',
    order: 0,
    epTitle: "",
    epPageCount: 0,
    epId: "",
    deleted: false,
    history: DateTime.now().toUtc(),
  );
}

BikaComicHistory bikaHistoryFromAny(dynamic comicInfo) {
  if (comicInfo is PluginComicDetailSource) {
    return pluginDetailToBikaHistory(comicInfo);
  }
  return comicToBikaComicHistory((comicInfo as AllInfo).comicInfo);
}

JmHistory jmHistoryFromAny(dynamic comicInfo) {
  if (comicInfo is PluginComicDetailSource) {
    return pluginDetailToJmHistory(comicInfo);
  }
  return jmToJmHistory(comicInfo as JmComicInfoJson);
}

bool isJmSeriesEmptyFromAny(dynamic comicInfo) {
  if (comicInfo is PluginComicDetailSource) {
    return comicInfo.isJmSeriesEmpty;
  }
  return (comicInfo as JmComicInfoJson).series.isEmpty;
}

normal.ComicInfo bikaNormalComicInfoFromAny(dynamic comicInfo) {
  if (comicInfo is PluginComicDetailSource) {
    return comicInfo.normalInfo.comicInfo;
  }

  final legacy = (comicInfo as AllInfo).comicInfo;
  return normal.ComicInfo(
    id: legacy.id,
    creator: normal.Creator(
      id: legacy.creator.id,
      name: legacy.creator.name,
      avatar: normal.Cover(
        url: legacy.creator.avatar.fileServer,
        path: legacy.creator.avatar.path,
        name: legacy.creator.avatar.originalName,
      ),
    ),
    title: legacy.title,
    description: legacy.description,
    cover: normal.Cover(
      url: legacy.thumb.fileServer,
      path: legacy.thumb.path,
      name: legacy.thumb.originalName,
    ),
    categories: legacy.categories,
    tags: legacy.tags,
    author: legacy.author.isEmpty ? const <String>[] : [legacy.author],
    works: const <String>[],
    actors: const <String>[],
    chineseTeam: legacy.chineseTeam.isEmpty
        ? const <String>[]
        : [legacy.chineseTeam],
    pagesCount: legacy.pagesCount,
    epsCount: legacy.epsCount,
    updatedAt: legacy.updatedAt,
    allowComment: legacy.allowComment,
    totalViews: legacy.totalViews,
    totalLikes: legacy.totalLikes,
    totalComments: legacy.totalComments,
    isFavourite: legacy.isFavourite,
    isLiked: legacy.isLiked,
  );
}
