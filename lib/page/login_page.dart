import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/dialog.dart';
import 'package:zephyr/util/router.dart';

import '../config/global.dart';
import '../network/http/http_request.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _account = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final ButtonStyle style =
      ElevatedButton.styleFrom(minimumSize: const Size(200, 40));

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                if (title == "登录成功") {
                  if (inited == false) {
                    navigateToNoReturn(context, "/main");
                  } else {
                    navigateToNoReturn(context, "/main");
                  }
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _submitForm() async {
    if (!mounted) return;
    // 显示加载动画
    showDialog(
      context: context,
      barrierDismissible: false, // 用户不能通过点击屏幕其他地方来关闭对话框
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("正在登录..."),
            ],
          ),
        );
      },
    );

    final result = await login(_account.text, _password.text);

    // 当登录逻辑完成后，关闭加载动画
    if (!mounted) return;
    Navigator.of(context).pop(); // 关闭加载对话框

    debugPrint(result.toString());

    if (result['message'] == "success") {
      bikaSetting.setAccount(_account.text);
      bikaSetting.setPassword(_password.text);
      bikaSetting.setAuthorization(result['data']['token']);
      _showDialog("登录成功", "正在跳转...");
      Future.delayed(const Duration(seconds: 2), () {
        // 检查State是否仍然挂载
        if (!mounted) return;
        if (inited == false) {
          navigateToNoReturn(context, "/main");
        } else {
          navigateToNoReturn(context, "/main");
        }
      });
    } else {
      _showDialog("登录失败", result.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在水平方向上靠左对齐
          children: <Widget>[
            // 账号输入框
            TextField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
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
                    onPressed: () {
                      navigateTo(context, '/register');
                    },
                    child: const Text('注册账号'),
                  ),
                  TextButton(
                    onPressed: () {
                      commonDialog(
                        context,
                        "找回密码",
                        "哔咔实际上已经无法找回密码，所以这个功能实际上不存在。",
                      );
                    },
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
