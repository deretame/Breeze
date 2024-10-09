import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../config/authorization.dart';
import 'http_request_build.dart';

Future<String> login(String username, String password) async {
  final Map<String, dynamic> data = await request(
      'https://picaapi.picacomic.com/auth/sign-in',
      'POST',
      json.encode({'email': username, 'password': password}));
  debugPrint(data.toString());

  if (data['code'] != 200) {
    return data.toString();
  }

  if (data['data'] != null && data['data']['token'] != null) {
    final String token = data['data']['token'];
    setAuthorization(token);
    debugPrint('Authorization is set to $token');
    return "true";
  } else {
    debugPrint('Authorization is not set');
    throw Exception('未知错误');
  }
}

Future<Map<String, dynamic>> search(
    {String keyword = '',
    String sort = 'dd',
    List<String> categories = const [],
    int pageCount = 1}) async {
  final Map<String, dynamic> jsonMap = {"sort": sort};

  if (keyword.isNotEmpty) {
    jsonMap["keyword"] = keyword;
  }

  if (categories.isNotEmpty) {
    jsonMap["categories"] = categories;
  }

  debugPrint(jsonMap.toString());

  final Map<String, dynamic> data = await request(
      'https://picaapi.picacomic.com/comics/advanced-search?page=$pageCount',
      'POST',
      json.encode(jsonMap));

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    throw Exception('未知错误');
  }
}

Future<Map<String, dynamic>> getComicInfo(
  String comicId,
) async {
  final Map<String, dynamic> data =
      await request('https://picaapi.picacomic.com/comics/$comicId', 'GET');

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    throw Exception('未知错误');
  }
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
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    throw Exception('未知错误');
  }
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
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    throw Exception('未知错误');
  }
}

Future<Map<String, dynamic>> getEps(
  String comicId,
  int pageCount,
) async {
  final Map<String, dynamic> data = await request(
      'https://picaapi.picacomic.com/comics/$comicId/eps?page=$pageCount',
      'GET');

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    throw Exception('未知错误');
  }
}

Future<Map<String, dynamic>> getComic(
  String comicId,
  int epId,
  int pageCount,
) async {
  final Map<String, dynamic> data = await request(
      'https://picaapi.picacomic.com/comics/$comicId/order/$epId/pages?page=$pageCount',
      'GET');

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    throw Exception('未知错误');
  }
}

Future<Map<String, dynamic>> getPersonalInfo() async {
  final Map<String, dynamic> data = await request(
    'https://picaapi.picacomic.com/users/profile',
    'GET',
  );

  String limitString(String str, int maxLength) {
    return str.substring(0, min(str.length, maxLength));
  }

  debugPrint(limitString(data.toString(), 150));

  if (data['code'] != 200) {
    return data;
  }

  if (data['data'] != null) {
    return data['data'];
  } else {
    debugPrint('Search result is null');
    return ({"error": '未知错误'});
  }
}

Future<Map<String, dynamic>> punchIn() async {
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

  if (data['message'] == 'success' && data['data']['res']['status'] == 'fail') {
    return {"success": "已签到"};
  } else {
    debugPrint('Search result is null');
    return ({"error": '未知错误'});
  }
}
