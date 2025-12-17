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

Future<Map<String, dynamic>> login(String account, String password) async {
  final Map<String, dynamic> loginData = await request(
    '${JmConfig.baseUrl}/login',
    formData: {'username': account, 'password': password},
    method: 'POST',
    useJwt: false,
  );

  JmConfig.jwt = (loginData['jwttoken'] ??= JmConfig.jwt);

  return loginData;
}

Future<Map<String, dynamic>> favorite(
  String comicId, {
  String? folderId,
}) async {
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

Future<Map<String, dynamic>> like(String comicId) async => await request(
  '${JmConfig.baseUrl}/like',
  body: 'id=$comicId&',
  method: 'POST',
);

Future<Map<String, dynamic>> getComments(int page, String comicId) async =>
    await request(
      '${JmConfig.baseUrl}/forum',
      params: {'page': page, 'mode': 'manhua', 'aid': comicId},
    );

Future<Map<String, dynamic>> comment(
  String comment,
  String comicId, {
  String? commentId,
}) async {
  String body = "comment=${Uri.encodeQueryComponent(comment)}&";

  if (commentId != null) {
    body += "aid=$comicId&comment_id=$commentId&";
  } else {
    body += "status=undefined&aid=$comicId&";
  }

  final Map<String, dynamic> data = await request(
    '${JmConfig.baseUrl}/forum',
    body: body,
    method: 'POST',
  );

  return data;
}

Future<Map<String, dynamic>> getDailyList() async => await request(
  '${JmConfig.baseUrl}/daily_list/filter',
  formData: {'data': DateTime.now().year},
  method: 'POST',
);

Future<Map<String, dynamic>> dailyChk(String userId, String dailyId) async =>
    await request(
      '${JmConfig.baseUrl}/daily_chk',
      formData: {'user_id': userId, 'daily_id': dailyId},
      method: 'POST',
    );

Future<dynamic> getPromote() async => await request(
  '${JmConfig.baseUrl}/promote?page=0',
  method: 'GET',
  cache: true,
);

Future<Map<String, dynamic>> getWeekRanking(
  int date,
  String type,
  int page,
) async => await request(
  '${JmConfig.baseUrl}/serialization',
  method: 'GET',
  params: {'date': date, 'type': type, 'page': page},
  cache: true,
);

Future<dynamic> getPromoteList(int id, int page) async => await request(
  '${JmConfig.baseUrl}/promote_list',
  method: 'GET',
  params: {'id': id, 'page': page},
  cache: true,
);

Future<dynamic> getSuggestion(int page) async => await request(
  '${JmConfig.baseUrl}/latest',
  method: 'GET',
  params: {'page': page},
  cache: true,
);

Future<Map<String, dynamic>> getRanking({
  int page = 0,
  String order = '',
  String c = '',
  String o = '',
}) async => await request(
  '${JmConfig.baseUrl}/categories/filter',
  method: 'GET',
  params: {'page': page, 'c': c, 'o': o},
  cache: true,
);

Future<Map<String, dynamic>> getFavoriteList({
  int page = 1,
  String id = '',
  String order = 'mr',
}) async => await request(
  '${JmConfig.baseUrl}/favorite',
  method: 'GET',
  params: {'page': page, 'folder_id': id, 'o': order},
);
