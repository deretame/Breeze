import '../../../config/jm/config.dart';
import 'jm_error_message.dart';
import 'http_request_build.dart';

Future<Map<String, dynamic>> _requestMap(
  String path, {
  String method = 'GET',
  Map<String, dynamic>? params,
  dynamic data,
  Map<String, dynamic>? formData,
  bool cache = false,
  bool useJwt = true,
}) async {
  final result = await request(
    path,
    method: method,
    params: params,
    data: data,
    formData: formData,
    cache: cache,
    useJwt: useJwt,
  );

  if (result is Map) {
    return Map<String, dynamic>.fromEntries(
      result.entries.map((e) => MapEntry(e.key.toString(), e.value)),
    );
  }

  if (result is String && result.trim().isNotEmpty) {
    throw Exception(
      sanitizeJmErrorMessage(result.trim(), fallback: '服务器异常，请稍后再试'),
    );
  }

  throw Exception('服务器返回异常，请稍后再试');
}

Future<Map<String, dynamic>> search(
  String keyword,
  String sort,
  int page,
) async => await _requestMap(
  '${JmConfig.baseUrl}/search',
  params: {"search_query": keyword, "page": page, "o": sort},
);

Future<Map<String, dynamic>> getComicInfo(String comicId) async =>
    await _requestMap(
      '${JmConfig.baseUrl}/album',
      params: {'id': comicId},
      // cache: true,
    );

Future<Map<String, dynamic>> getEpInfo(String epId) async => await _requestMap(
  '${JmConfig.baseUrl}/chapter',
  params: {'skip': '', 'id': epId},
  cache: true,
);

Future<Map<String, dynamic>> login(String account, String password) async {
  final Map<String, dynamic> loginData = await _requestMap(
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
  final formData = {"aid": comicId};

  final Map<String, dynamic> data = await _requestMap(
    '${JmConfig.baseUrl}/favorite',
    formData: formData,
    method: 'POST',
  );

  return data;
}

Future<Map<String, dynamic>> getFavoriteList({
  int page = 1,
  String id = '',
  String order = 'mr',
}) async => await _requestMap(
  '${JmConfig.baseUrl}/favorite',
  method: 'GET',
  params: {'page': page, 'folder_id': id, 'o': order},
);

Future<Map<String, dynamic>> favoriteMoveFolder(
  String comicId,
  String folderId,
  String folderName,
) async {
  var formData = {
    "type": "move",
    "folder_id": folderId,
    "folder_name": folderName,
    "aid": comicId,
  };

  final Map<String, dynamic> data = await _requestMap(
    '${JmConfig.baseUrl}/favorite_folder',
    formData: formData,
    method: 'POST',
  );

  return data;
}

Future<Map<String, dynamic>> like(String comicId) async => await _requestMap(
  '${JmConfig.baseUrl}/like',
  formData: {'id': comicId},
  method: 'POST',
);

Future<Map<String, dynamic>> getComments(int page, String comicId) async =>
    await _requestMap(
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

  final Map<String, dynamic> data = await _requestMap(
    '${JmConfig.baseUrl}/forum',
    data: body,
    method: 'POST',
  );

  return data;
}

Future<Map<String, dynamic>> getDailyList() async => await _requestMap(
  '${JmConfig.baseUrl}/daily_list/filter',
  formData: {'data': DateTime.now().year},
  method: 'POST',
);

Future<Map<String, dynamic>> dailyChk(String userId, String dailyId) async =>
    await _requestMap(
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
) async => await _requestMap(
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
}) async => await _requestMap(
  '${JmConfig.baseUrl}/categories/filter',
  method: 'GET',
  params: {'page': page, 'c': c, 'o': o},
  cache: true,
);
