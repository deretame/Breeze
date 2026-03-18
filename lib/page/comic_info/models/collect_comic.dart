import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/widgets/toast.dart';

Future<Map<String, dynamic>> collectJmComicToLocal(
  dynamic comicInfo,
) async {
  final source = _toJmFavoriteSource(comicInfo);
  var data = objectbox.jmFavoriteBox
      .query(JmFavorite_.comicId.equals(source.comicId))
      .build()
      .find();

  for (var item in data) {
    objectbox.jmFavoriteBox.remove(item.id);
  }

  objectbox.jmFavoriteBox.put(
    JmFavorite(
      comicId: source.comicId,
      name: source.name,
      addtime: source.addtime,
      description: source.description,
      totalViews: source.totalViews,
      likes: source.likes,
      seriesId: source.seriesId,
      commentTotal: source.commentTotal,
      author: source.author,
      tags: source.tags,
      works: source.works,
      actors: source.actors,
      liked: source.liked,
      isFavorite: source.isFavorite,
      isAids: source.isAids,
      price: source.price,
      purchased: source.purchased,
      deleted: false,
      history: DateTime.now().toUtc(),
    ),
  );

  showSuccessToast("成功收藏到本地");

  return {"error": null, "message": "收藏成功"};
}

class _JmFavoriteSource {
  const _JmFavoriteSource({
    required this.comicId,
    required this.name,
    required this.addtime,
    required this.description,
    required this.totalViews,
    required this.likes,
    required this.seriesId,
    required this.commentTotal,
    required this.author,
    required this.tags,
    required this.works,
    required this.actors,
    required this.liked,
    required this.isFavorite,
    required this.isAids,
    required this.price,
    required this.purchased,
  });

  final String comicId;
  final String name;
  final String addtime;
  final String description;
  final String totalViews;
  final String likes;
  final String seriesId;
  final String commentTotal;
  final List<String> author;
  final List<String> tags;
  final List<String> works;
  final List<String> actors;
  final bool liked;
  final bool isFavorite;
  final bool isAids;
  final String price;
  final String purchased;
}

_JmFavoriteSource _toJmFavoriteSource(dynamic comicInfo) {
  if (comicInfo is PluginComicDetailSource) {
    final raw = comicInfo.rawComicInfo;
    return _JmFavoriteSource(
      comicId: comicInfo.comicId,
      name: raw['name']?.toString() ?? comicInfo.normalInfo.comicInfo.title,
      addtime: raw['addtime']?.toString() ?? '0',
      description:
          raw['description']?.toString() ?? comicInfo.normalInfo.comicInfo.description,
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
    );
  }

  final legacy = comicInfo as JmComicInfoJson;
  return _JmFavoriteSource(
    comicId: legacy.id.toString(),
    name: legacy.name,
    addtime: legacy.addtime,
    description: legacy.description,
    totalViews: legacy.totalViews,
    likes: legacy.likes,
    seriesId: legacy.seriesId,
    commentTotal: legacy.commentTotal,
    author: legacy.author,
    tags: legacy.tags,
    works: legacy.works,
    actors: legacy.actors,
    liked: legacy.liked,
    isFavorite: legacy.isFavorite,
    isAids: legacy.isAids,
    price: legacy.price,
    purchased: legacy.purchased,
  );
}
