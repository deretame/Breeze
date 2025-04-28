import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart' as encrypt;

import '../../../config/jm/config.dart';
import 'http_request_build.dart';

getTime() => (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

Future<Map<String, dynamic>> decodeRespData(
  String data,
  String ts, [
  String? secret,
]) {
  final actualSecret = secret ?? JmConfig.kJmSecret;

  // 1. Base64解码
  final dataB64 = base64.decode(data);

  // 2. AES-ECB解密
  final key = md5.convert(utf8.encode('$ts$actualSecret')).toString();
  final encrypter = encrypt.Encrypter(
    encrypt.AES(encrypt.Key(utf8.encode(key)), mode: encrypt.AESMode.ecb),
  );
  final dataAes = encrypter.decryptBytes(encrypt.Encrypted(dataB64));

  // 3. 解码为字符串 (json)并转化为Map
  return json.decode(utf8.decode(dataAes));
}

Future<Map<String, dynamic>> search(String keyword, String sort) async {
  final timestamp = getTime();

  var pragma = {"search_query": keyword, "sort_by": sort};

  final response = await request(timestamp, JmConfig.baseUrl, params: pragma);

  return decodeRespData(response['data'], timestamp);
}
