import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/config/debug_url_setting.dart';
import 'package:zephyr/main.dart';

import 'http_request_build_rust.dart' as rust;

Future<String> get bikaJsUrl async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('debug_bika_url') ??
      'http://localhost:7878/bika-comic.bundle.cjs';
}

Future<Map<String, dynamic>> bikaRequest(
  String url,
  String method, {
  dynamic body,
  bool cache = false,
  String? imageQuality,
  String qjsRuntimeName = 'bikaComic',
  String qjsTaskGroupKey = '',
}) async {
  url = DebugUrlSetting.replaceBikaHost(url);

  final data = await rust.request(
    url,
    method,
    body: body,
    cache: cache,
    imageQuality: imageQuality,
    qjsName: qjsRuntimeName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

String limitString(String str, int maxLength) {
  return str.substring(0, min(str.length, maxLength));
}

Future<Map<String, dynamic>> login(String username, String password) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/auth/sign-in',
    'POST',
    body: json.encode({'email': username, 'password': password}),
  );
}

Future<Map<String, dynamic>> register(
  String birthday,
  String email,
  String gender,
  String name,
  String password,
) async {
  final Map<String, dynamic> jsonMap = {
    "answer1": "4",
    "answer2": "5",
    "answer3": "6",
    "birthday": birthday,
    "email": email,
    "gender": gender,
    "name": name,
    "password": password,
    "question1": "1",
    "question2": "2",
    "question3": "3",
  };

  return bikaRequest(
    'https://picaapi.picacomic.com/auth/register',
    'POST',
    body: json.encode(jsonMap),
  );
}

Future<Map<String, dynamic>> getCategories() async {
  return bikaRequest(
    'https://picaapi.picacomic.com/categories',
    'GET',
    cache: true,
  );
}

Future<Map<String, dynamic>> getRankingList({
  String days = "H24",
  String type = '',
}) async {
  String url = '';

  if (type == 'creator') {
    url = 'https://picaapi.picacomic.com/comics/knight-leaderboard';
  } else if (type == 'comic') {
    url = 'https://picaapi.picacomic.com/comics/leaderboard?tt=$days&ct=VC';
  } else {
    throw Exception('未知类型');
  }

  return bikaRequest(url, 'GET', cache: true);
}

Future<Map<String, dynamic>> getSearchKeywords() async {
  return bikaRequest(
    'https://picaapi.picacomic.com/keywords',
    'GET',
    cache: true,
  );
}

Future<Map<String, dynamic>> getComicInfo(
  String comicId, {
  String? imageQuality,
  String qjsRuntimeName = 'bikaComic',
  String qjsTaskGroupKey = '',
}) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId',
    'GET',
    imageQuality: imageQuality,
    qjsRuntimeName: qjsRuntimeName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );
}

Future<Map<String, dynamic>> favouriteComic(String comicId) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/favourite',
    'POST',
  );
}

Future<Map<String, dynamic>> likeComic(String comicId) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/like',
    'POST',
  );
}

Future<Map<String, dynamic>> getComments(String comicId, int pageCount) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/comments?page=$pageCount',
    'GET',
  );
}

Future<Map<String, dynamic>> getCommentsChildren(
  String commentId,
  int pageCount,
) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comments/$commentId/childrens?page=$pageCount',
    'GET',
  );
}

Future<Map<String, dynamic>> likeComment(String comicId) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comments/$comicId/like',
    'POST',
  );
}

Future<Map<String, dynamic>> writeComment(
  String comicId,
  String content,
) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/comments',
    'POST',
    body: json.encode({'content': content}),
  );
}

Future<Map<String, dynamic>> writeCommentChildren(
  String commentId,
  String content,
) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comments/$commentId',
    'POST',
    body: json.encode({'content': content}),
  );
}

Future<Map<String, dynamic>> reportComments(String commentId) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comments/$commentId/report',
    'POST',
  );
}

Future<Map<String, dynamic>> getEps(
  String comicId,
  int pageCount, {
  String? imageQuality,
  String qjsRuntimeName = 'bikaComic',
  String qjsTaskGroupKey = '',
}) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/eps?page=$pageCount',
    'GET',
    cache: true,
    imageQuality: imageQuality,
    qjsRuntimeName: qjsRuntimeName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );
}

Future<Map<String, dynamic>> getRecommend(String comicId) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/recommendation',
    'GET',
    cache: true,
  );
}

Future<Map<String, dynamic>> getPages(
  String comicId,
  int epId,
  int pageCount, {
  String? imageQuality,
  String qjsRuntimeName = 'bikaComic',
  String qjsTaskGroupKey = '',
}) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/comics/$comicId/order/$epId/pages?page=$pageCount',
    'GET',
    cache: true,
    imageQuality: imageQuality,
    qjsRuntimeName: qjsRuntimeName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );
}

Future<Map<String, dynamic>> getUserProfile() async {
  return bikaRequest('https://picaapi.picacomic.com/users/profile', 'GET');
}

Future<Map<String, dynamic>> updateAvatar(String avatarBASE64String) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/users/avatar',
    'PUT',
    body: json.encode({"avatar": "data:image/jpeg;base64,$avatarBASE64String"}),
  );
}

// 更新自己的简介
Future<Map<String, dynamic>> updateProfile(String profile) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/users/profile',
    'PUT',
    body: json.encode({"slogan": profile}),
  );
}

Future<Map<String, dynamic>> updatePassword(String newPassword) async {
  final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
  return bikaRequest(
    'https://picaapi.picacomic.com/users/password',
    'PUT',
    body: json.encode({
      "new_password": newPassword,
      "old_password": settings.password,
    }),
  );
}

Future<Map<String, dynamic>> getFavorites(int pageCount) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/users/favourite?s=dd&page=$pageCount',
    'GET',
  );
}

Future<Map<String, dynamic>> getUserComments(int pageCount) async {
  return bikaRequest(
    'https://picaapi.picacomic.com/users/my-comments?page=$pageCount',
    'GET',
  );
}

Future<String> signIn() async {
  final data = await bikaRequest(
    'https://picaapi.picacomic.com/users/punch-in',
    'POST',
  );

  if (data['data']['res']['status'] == 'ok') {
    return "签到成功";
  } else if (data['data']['res']['status'] == 'fail') {
    return "已签到";
  } else {
    throw '未知错误';
  }
}
