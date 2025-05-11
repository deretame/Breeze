import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/dialog.dart';
import 'package:zephyr/widgets/toast.dart';

import '../network/http/bika/http_request.dart';
import '../network/http/jm/http_request.dart' as jm;
import '../util/router/router.gr.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  final From? from;

  const LoginPage({super.key, this.from});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _account = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final ButtonStyle style = ElevatedButton.styleFrom(
    minimumSize: const Size(200, 40),
  );

  String title = "";
  late From from;

  @override
  void initState() {
    super.initState();
    from = widget.from ?? From.bika;
    _account.text =
        from == From.bika ? bikaSetting.getAccount() : jmSetting.getAccount();
    _password.text =
        from == From.bika ? bikaSetting.getPassword() : jmSetting.getPassword();

    if (from == From.bika) {
      title = "哔咔登录";
    } else if (from == From.jm) {
      title = "禁漫登录";
    }
  }

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _showDialog(String title, String message) async {
    if (message.contains("invalid email or password")) {
      message = "用户名或密码错误，请重新输入";
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(children: <Widget>[Text(message)]),
          ),
          actions: <Widget>[
            TextButton(child: const Text('确定'), onPressed: () => context.pop()),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (!mounted) return;
    showInfoToast("正在登录，请耐心等待...");

    try {
      Map<String, dynamic> result = {};

      if (from == From.bika) {
        result = await login(_account.text, _password.text);
      } else if (from == From.jm) {
        result = await jm.login(_account.text, _password.text);
      }

      logger.d(result.toString());

      if (from == From.bika) {
        bikaSetting.setAccount(_account.text);
        bikaSetting.setPassword(_password.text);
        bikaSetting.setAuthorization(result['data']['token']);
      } else if (from == From.jm) {
        jmSetting.setAccount(_account.text);
        jmSetting.setPassword(_password.text);
      }
      showSuccessToast("登录成功");

      if (!mounted) return;
      context.maybePop();
    } catch (e) {
      _showDialog("登录失败", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在水平方向上靠左对齐
          children: <Widget>[
            // 账号输入框
            TextField(
              controller: _account,
              decoration: InputDecoration(
                labelText: from == From.bika ? '账号' : '用户名',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // 用于添加空间
            // 密码输入框
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // 隐藏输入内容
            ),
            const SizedBox(height: 10), // 用于添加空间
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 设置Row中的内容水平居中
              children: [
                ElevatedButton(
                  style: style,
                  onPressed: _submitForm,
                  child: const Text('登录'),
                ),
              ],
            ),
            const SizedBox(height: 10), // 用于添加空间
            Expanded(
              child: Container(), // 占据剩余空间
            ),
            // 注册和找回密码链接
            Container(
              alignment: AlignmentDirectional.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed:
                        from == From.bika
                            ? () => context.pushRoute(RegisterRoute())
                            : null,
                    child: const Text('注册账号'),
                  ),
                  TextButton(
                    onPressed:
                        from == From.bika
                            ? () {
                              commonDialog(
                                context,
                                "找回密码",
                                "哔咔实际上已经无法找回密码，所以这个功能实际上不存在。",
                              );
                            }
                            : null,
                    child: const Text('找回密码'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
