import 'dart:convert';

import 'package:zephyr/src/rust/api/bika.dart';

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  dynamic body,
  bool cache = false,
  String? imageQuality,
  String? authorization,
}) async {
  final bodyJson = body == null
      ? null
      : (body is String ? body : json.encode(body));

  final raw = await bikaRequestRaw(
    url: url,
    method: method,
    bodyJson: bodyJson,
    imageQuality: imageQuality,
    authorization: authorization,
  );

  final decoded = json.decode(raw);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  return {'code': -1, 'message': 'invalid response', 'data': decoded};
}
