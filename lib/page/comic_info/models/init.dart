import '../../../main.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    hide Comic;
import '../json/comic_info/comic_info.dart' show Comic;
import '../json/eps/eps.dart' show Doc;
import '../method/type_conversion.dart';

initDownloadInfo(ComicEntryType type, String comicId) {
  ComicAllInfoJson? comicAllInfo;
  BikaComicDownload? comicDownload;
  Comic? comicInfo;

  List<Doc> epsInfo = [];
  if (type == ComicEntryType.download) {
    comicDownload =
        objectbox.bikaDownloadBox
            .query(BikaComicDownload_.comicId.equals(comicId))
            .build()
            .findFirst();

    if (comicDownload != null) {
      comicAllInfo = comicAllInfoJsonFromJson(comicDownload.comicInfoAll);
      comicInfo = comicAllInfo2Comic(comicAllInfo);
    }

    var epsDoc = comicAllInfo!.eps.docs;
    for (var epDoc in epsDoc) {
      epsInfo.add(
        Doc(
          id: epDoc.id,
          title: epDoc.title,
          order: epDoc.order,
          updatedAt: epDoc.updatedAt,
          docId: epDoc.docId,
        ),
      );
    }
  }

  return (comicAllInfo, comicDownload, comicInfo, epsInfo);
}
