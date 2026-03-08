import 'dart:convert';
import 'dart:math';

import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/bika.dart';

String limitString(String str, int maxLength) {
  return str.substring(0, min(str.length, maxLength));
}

Map<String, dynamic> _decodeMap(String raw) {
  final decoded = json.decode(raw);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  return {'code': -1, 'message': 'invalid response', 'data': decoded};
}

Future<Map<String, dynamic>> login(String username, String password) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaLogin(username: username, password: password),
  );

  if (data['code'] != 200) {
    throw data;
  }

  final token = data['data'] is Map<String, dynamic>
      ? data['data']['token']
      : null;
  if (token is String && token.isNotEmpty) {
    final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    final next = settings.copyWith(
      account: username,
      password: password,
      authorization: token,
    );
    var db = objectbox.userSettingBox.get(1)!;
    db.bikaSetting = next;
    objectbox.userSettingBox.put(db);
  }

  return data;
}

Future<Map<String, dynamic>> register(
  String birthday,
  String email,
  String gender,
  String name,
  String password,
) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaRegister(
      birthday: birthday,
      email: email,
      gender: gender,
      name: name,
      password: password,
    ),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getCategories() async {
  final Map<String, dynamic> data = _decodeMap(await bikaGetCategories());

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getRankingList({
  String days = "H24",
  String type = '',
}) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetRankingList(days: days, kind: type),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> search({
  String url = '',
  String from = '',
  String keyword = '',
  String sort = 'dd',
  List<String> categories = const [],
  int pageCount = 1,
}) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaSearch(
      url: url,
      keyword: keyword,
      sort: sort,
      categories: categories,
      pageCount: pageCount,
    ),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getSearchKeywords() async {
  final Map<String, dynamic> data = _decodeMap(await bikaGetSearchKeywords());

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getComicInfo(
  String comicId, {
  String? authorization,
  String? imageQuality,
}) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetComicInfo(
      comicId: comicId,
      authorization: authorization,
      imageQuality: imageQuality,
    ),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> favouriteComic(String comicId) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaFavouriteComic(comicId: comicId),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> likeComic(String comicId) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaLikeComic(comicId: comicId),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getComments(String comicId, int pageCount) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetComments(comicId: comicId, pageCount: pageCount),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getCommentsChildren(
  String commentId,
  int pageCount,
) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetCommentsChildren(commentId: commentId, pageCount: pageCount),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> likeComment(String comicId) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaLikeComment(commentId: comicId),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> writeComment(
  String comicId,
  String content,
) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaWriteComment(comicId: comicId, content: content),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> writeCommentChildren(
  String commentId,
  String content,
) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaWriteCommentChildren(commentId: commentId, content: content),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> reportComments(String commentId) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaReportComments(commentId: commentId),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getEps(
  String comicId,
  int pageCount, {
  String? authorization,
  String? imageQuality,
}) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetEps(
      comicId: comicId,
      pageCount: pageCount,
      authorization: authorization,
      imageQuality: imageQuality,
    ),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getRecommend(String comicId) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetRecommend(comicId: comicId),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getPages(
  String comicId,
  int epId,
  int pageCount, {
  String? authorization,
  String? imageQuality,
}) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetPages(
      comicId: comicId,
      epId: epId,
      pageCount: pageCount,
      authorization: authorization,
      imageQuality: imageQuality,
    ),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getUserProfile() async {
  final Map<String, dynamic> data = _decodeMap(await bikaGetUserProfile());

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> updateAvatar(String avatarBASE64String) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaUpdateAvatar(avatarBase64String: avatarBASE64String),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> updateProfile(String profile) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaUpdateProfile(profile: profile),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> updatePassword(String newPassword) async {
  final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
  final Map<String, dynamic> data = _decodeMap(
    await bikaUpdatePassword(
      newPassword: newPassword,
      oldPassword: settings.password,
    ),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getFavorites(int pageCount) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetFavorites(pageCount: pageCount),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getUserComments(int pageCount) async {
  final Map<String, dynamic> data = _decodeMap(
    await bikaGetUserComments(pageCount: pageCount),
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<String> signIn() async {
  final Map<String, dynamic> data = _decodeMap(await bikaSignIn());

  if (data['code'] != 200) {
    throw data;
  }

  if (data['data']['res']['status'] == 'ok') {
    return "签到成功";
  } else if (data['data']['res']['status'] == 'fail') {
    return "已签到";
  } else {
    throw '未知错误';
  }
}
