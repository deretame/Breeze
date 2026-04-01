import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/plugin/plugin_constants.dart';

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
  String qjsRuntimeName = kBikaPluginUuid,
  String qjsTaskGroupKey = '',
}) async {
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
