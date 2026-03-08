import 'package:zephyr/network/http/bika/http_request.dart';

Future<void> runBikaQjsSmokeTest({
  required String username,
  required String password,
}) async {
  final loginResp = await login(username, password);
  final token = (loginResp['data'] as Map<String, dynamic>?)?['token'];

  if (token is! String || token.isEmpty) {
    throw Exception('登录成功但未返回 token');
  }

  final profile = await getUserProfile();
  if (profile['code'] != 200) {
    throw Exception('获取用户信息失败: ${profile['message']}');
  }
}
