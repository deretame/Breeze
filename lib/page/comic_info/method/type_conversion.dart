import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    as comic_all_info_json;
import '../json/comic_info/comic_info.dart';

Comic comicAllInfo2Comic(
  comic_all_info_json.ComicAllInfoJson comicAllInfoJson,
) {
  var comicInfoJson = comicAllInfoJson.comic;
  return Comic(
    id: comicInfoJson.id,
    creator: Creator(
      id: comicInfoJson.creator.id,
      gender: comicInfoJson.creator.gender,
      name: comicInfoJson.creator.name,
      verified: comicInfoJson.creator.verified,
      exp: comicInfoJson.creator.exp,
      level: comicInfoJson.creator.level,
      characters: comicInfoJson.creator.characters,
      role: comicInfoJson.creator.role,
      title: comicInfoJson.creator.title,
      avatar: Thumb(
        originalName: comicInfoJson.creator.avatar.originalName,
        path: comicInfoJson.creator.avatar.path,
        fileServer: comicInfoJson.creator.avatar.fileServer,
      ),
      slogan: comicInfoJson.creator.slogan,
    ),
    title: comicInfoJson.title,
    description: comicInfoJson.description,
    thumb: Thumb(
      originalName: comicInfoJson.thumb.originalName,
      path: comicInfoJson.thumb.path,
      fileServer: comicInfoJson.thumb.fileServer,
    ),
    author: comicInfoJson.author,
    chineseTeam: comicInfoJson.chineseTeam,
    categories: comicInfoJson.categories,
    tags: comicInfoJson.tags,
    pagesCount: comicInfoJson.pagesCount,
    epsCount: comicInfoJson.epsCount,
    finished: comicInfoJson.finished,
    updatedAt: comicInfoJson.updatedAt,
    createdAt: comicInfoJson.createdAt,
    allowDownload: comicInfoJson.allowDownload,
    allowComment: comicInfoJson.allowComment,
    totalLikes: comicInfoJson.totalLikes,
    totalViews: comicInfoJson.totalViews,
    totalComments: comicInfoJson.totalComments,
    viewsCount: comicInfoJson.viewsCount,
    likesCount: comicInfoJson.likesCount,
    commentsCount: comicInfoJson.commentsCount,
    isFavourite: comicInfoJson.isFavourite,
    isLiked: comicInfoJson.isLiked,
  );
}
