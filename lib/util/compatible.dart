// 用来提供兼容操作的

import 'package:shared_preferences/shared_preferences.dart';

Future<void> compatibleInit() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('compatible_version', "v1");
}
