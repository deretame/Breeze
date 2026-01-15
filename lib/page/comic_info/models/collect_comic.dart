import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/widgets/toast.dart';

Future<Map<String, dynamic>> collectJmComicToLocal(
  JmComicInfoJson comicInfo,
) async {
  var data = objectbox.jmFavoriteBox
      .query(JmFavorite_.comicId.equals(comicInfo.id.toString()))
      .build()
      .find();

  for (var item in data) {
    objectbox.jmFavoriteBox.remove(item.id);
  }

  objectbox.jmFavoriteBox.put(
    JmFavorite(
      comicId: comicInfo.id.toString(),
      name: comicInfo.name,
      addtime: comicInfo.addtime,
      description: comicInfo.description,
      totalViews: comicInfo.totalViews,
      likes: comicInfo.likes,
      seriesId: comicInfo.seriesId,
      commentTotal: comicInfo.commentTotal,
      author: comicInfo.author,
      tags: comicInfo.tags,
      works: comicInfo.works,
      actors: comicInfo.actors,
      liked: comicInfo.liked,
      isFavorite: comicInfo.isFavorite,
      isAids: comicInfo.isAids,
      price: comicInfo.price,
      purchased: comicInfo.purchased,
      deleted: false,
      history: DateTime.now().toUtc(),
    ),
  );

  showSuccessToast("成功收藏到本地");

  return {"error": null, "message": "收藏成功"};
}
