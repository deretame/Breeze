import '../../../config/jm/config.dart';
import 'http_request_build.dart';

Future<Map<String, dynamic>> search(
  String keyword,
  String sort,
  int page,
) async => await request(
  '${JmConfig.baseUrl}/search',
  params: {"search_query": keyword, "page": page, "o": sort},
);

Future<Map<String, dynamic>> getComicInfo(String comicId) async =>
    await request(
      '${JmConfig.baseUrl}/album',
      params: {'id': comicId},
      // cache: true,
    );

Future<Map<String, dynamic>> getEpInfo(String epId) async => await request(
  '${JmConfig.baseUrl}/chapter',
  params: {'skip': '', 'id': epId},
  cache: true,
);

Future<Map<String, dynamic>> login(String account, String password) async =>
    await request(
      '${JmConfig.baseUrl}/login',
      body: 'username=$account&password=$password&',
      method: 'POST',
    );

Future<Map<String, dynamic>> favorite(
  String comicId, {
  String? folderId,
}) async {
  // type=move&folder_id=3711549&aid=742&
  // aid=742&
  String body = "";
  if (folderId != null) {
    body = "type=move&folder_id=$folderId&aid=$comicId&";
  } else {
    body = "aid=$comicId&";
  }

  final Map<String, dynamic> data = await request(
    '${JmConfig.baseUrl}/favorite',
    body: body,
    method: 'POST',
  );

  return data;
}

Future<Map<String, dynamic>> getComments(int page, String comicId) async =>
    await request(
      '${JmConfig.baseUrl}/forum',
      params: {'page': page, 'mode': 'manhua', 'aid': comicId},
    );
