import 'package:zephyr/src/rust/api/simple.dart';

Future<String> runRustCallsDartDemo() async {
  final result = await rustCallsDart(
    dartCallback: (name) async => '你好, $name! 这是 Dart 的回调返回',
  );
  return result;
}
