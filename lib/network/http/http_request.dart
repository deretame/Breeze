import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'http_request_build.dart';

Future<Map<String, dynamic>> login(
  String username,
  String password,
) async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/auth/sign-in',
    'POST',
    body: json.encode({'email': username, 'password': password}),
  );
  debugPrint(data.toString());

  if (data['code'] != 200) {
    throw data;
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
    "question3": "3"
  };

  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/auth/register',
    'POST',
    body: json.encode(jsonMap),
  );
  debugPrint(data.toString());

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getCategories() async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/categories',
    'GET',
    cache: false,
  );

  if (data['code'] != 200) {
    throw data;
  }

  return data;
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

  final Map<String, dynamic> data = await request(
    url,
    'GET',
    cache: true,
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
  final Map<String, dynamic> jsonMap = {"sort": sort};

  if (keyword.isNotEmpty) {
    jsonMap["keyword"] = keyword;
  }

  if (categories.isNotEmpty) {
    jsonMap["categories"] = categories;
  }

  debugPrint(jsonMap.toString());
  late Map<String, dynamic> data;

  if (url.isNotEmpty) {
    // 用来判断是不是根据作者来搜索
    if (url.contains('comics?ca=')) {
      var temp = url.split("&s")[0];
      url = "$temp&s=$sort&page=$pageCount";

      data = await request(
        url,
        'GET',
      );
    } else if (url == 'https://picaapi.picacomic.com/comics/random') {
      data = await request(
        url,
        'GET',
      );
    } else if (url.contains("%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B")) {
      url =
          'https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E5%AE%B6%E9%83%BD%E5%9C%A8%E7%9C%8B&s=$sort';
      data = await request(
        url,
        'GET',
      );
    } else if (url ==
        'https://picaapi.picacomic.com/comics?page=1&c=%E5%A4%A7%E6%BF%95%E6%8E%A8%E8%96%A6&s=$sort') {
      data = await request(
        url,
        'GET',
      );
    } else if (url.contains('%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9')) {
      data = await request(
        'https://picaapi.picacomic.com/comics?page=$pageCount&c=%E9%82%A3%E5%B9%B4%E4%BB%8A%E5%A4%A9&s=$sort',
        'GET',
      );
    } else if (url.contains('%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B')) {
      data = await request(
        'https://picaapi.picacomic.com/comics?page=$pageCount&c=%E5%AE%98%E6%96%B9%E9%83%BD%E5%9C%A8%E7%9C%8B&s=$sort',
        'GET',
      );
    } else if (url == 'https://picaapi.picacomic.com/comics/random') {
      data = await request(
        url,
        'GET',
      );
    }
  } else {
    data = await request(
      'https://picaapi.picacomic.com/comics/advanced-search?page=$pageCount',
      'POST',
      body: json.encode(jsonMap),
    );
  }

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getSearchKeywords() async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/keywords',
    'GET',
    cache: true,
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getComicInfo(
  String comicId,
) async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/comics/$comicId',
    'GET',
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> collect(
  String comicId,
) async {
  final Map<String, dynamic> data = await request(
      'https://picaapi.picacomic.com/comics/$comicId/favourite', 'POST');

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> like(
  String comicId,
) async {
  final Map<String, dynamic> data = await request(
      'https://picaapi.picacomic.com/comics/$comicId/like', 'POST');

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getEps(
  String comicId,
  int pageCount,
) async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/comics/$comicId/eps?page=$pageCount',
    'GET',
    cache: true,
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getPages(
  String comicId,
  int epId,
  int pageCount,
) async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/comics/$comicId/order/$epId/pages?page=$pageCount',
    'GET',
    cache: true,
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getUserProfile() async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/users/profile',
    'GET',
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> getFavorites(
  int pageCount,
) async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/users/favourite?s=dd&page=$pageCount',
    'GET',
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    throw data;
  }

  return data;
}

Future<Map<String, dynamic>> signIn() async {
  final Map<String, dynamic> data =
      await request('https://picaapi.picacomic.com/users/punch-in', 'POST');
  debugPrint(data.toString());

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    return data;
  }

  if (data['data']['message'] == 'success' &&
      data['data']['res']['status'] == 'fail') {
    return {"success": "已签到"};
  } else {
    throw '未知错误';
  }
}
