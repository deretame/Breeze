import '../json/comments_json/comments_json.dart';

Doc topCommentToDoc(TopComment topComment) {
  return Doc(
    id: topComment.id,
    content: topComment.content,
    user: topComment.user,
    comic: topComment.comic,
    totalComments: topComment.totalComments,
    isTop: topComment.isTop,
    hide: topComment.hide,
    createdAt: topComment.createdAt,
    docId: topComment.id,
    likesCount: topComment.likesCount,
    commentsCount: topComment.commentsCount,
    isLiked: topComment.isLiked,
  );
}
