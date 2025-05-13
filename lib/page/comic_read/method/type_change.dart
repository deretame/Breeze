import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info/jm_comic_info_json.dart';

import '../../../object_box/model.dart';
import '../../comic_info/json/bika/comic_info/comic_info.dart';

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
