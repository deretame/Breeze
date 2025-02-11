import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/mobx/string_select.dart';

import '../network/http/http_request.dart';
import '../util/dialog.dart';
import 'main.dart';

@RoutePage()
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _account = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordAgain = TextEditingController();
  final StringSelectStore store = StringSelectStore(); // 使用 MobX 管理的 store
  late String _date = ''; // 日期默认值
  late String _gender = 'm';

  @override
  void dispose() {
    _username.dispose();
    _account.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  void _register() async {
    if (!mounted) return;

    eventBus.fire(ToastMessage(ToastType.info, "正在注册..."));

    try {
      final result = await register(
        _date,
        _account.text,
        _gender,
        _username.text,
        _password.text,
      );

      logger.d(result.toString());

      debugPrint(_username.text);
      debugPrint(_account.text);
      debugPrint(_password.text);
      bikaSetting.setAccount(_account.text);
      bikaSetting.setPassword(_password.text);

      eventBus.fire(ToastMessage(ToastType.success, "注册成功，正在跳转登录..."));
      Future.delayed(
        const Duration(seconds: 2),
        () {
          // 检查State是否仍然挂载
          if (!mounted) return;
          AutoRouter.of(context).maybePop();
        },
      );
    } catch (e) {
      logger.e(e);
      if (!mounted) return;
      if (e.toString().contains("birthday adult only")) {
        eventBus.fire(ToastMessage(ToastType.error, "未成年人请勿注册！"));
        return;
      }
      if (e.toString().contains("name is already exist")) {
        eventBus.fire(ToastMessage(ToastType.error, "用户名已被使用，请更换用户名！"));
        return;
      }
      if (e.toString().contains("email is already exist")) {
        eventBus.fire(ToastMessage(ToastType.error, "账号已被注册，请更换账号！"));
        return;
      }

      commonDialog(context, "注册失败", e.toString());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注册账号'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 子组件在水平方向上靠左对齐
          children: <Widget>[
            TextField(
              controller: _username,
              decoration: const InputDecoration(
                labelText: '用户名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // 用于添加空间
            TextField(
              controller: _account,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text, // 设置键盘类型为文本输入
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                // 只允许输入数字和字母
              ],
            ),
            const SizedBox(height: 20), // 用于添加空间
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码（至少8位）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20), // 用于添加空间
            TextField(
              controller: _passwordAgain,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认密码（至少8位）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10), // 用于添加空间

            Row(
              children: <Widget>[
                SizedBox(width: 10),
                Text(
                  "请选择您的性别: ",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // 用于添加空间
            Row(
              children: <Widget>[
                Expanded(
                  child: ToggleSwitch(
                    initialLabelIndex: 0,
                    totalSwitches: 3,
                    minWidth: double.maxFinite,
                    inactiveBgColor: materialColorScheme.surfaceBright,
                    dividerColor: materialColorScheme.secondaryFixedDim,
                    borderColor: [materialColorScheme.secondaryFixedDim],
                    borderWidth: 1.0,
                    labels: ['绅士', '淑女', '机器人'],
                    onToggle: (index) {
                      debugPrint('switched to: $index');
                      if (index == 0) {
                        _gender = "m";
                      } else if (index == 1) {
                        _gender = "f";
                      } else {
                        _gender = "bot";
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                SizedBox(width: 10),
                Text(
                  "选择您的出生日期: ",
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                // 使用 Observer 来监听 store 中 date 的变化
                Observer(
                  builder: (_) {
                    // 当 MobX store 中的日期更新时，同时更新 _date
                    _date = store.date;
                    debugPrint('date changed to: ${store.date}');

                    return Text(
                      store.date,
                      style: TextStyle(fontSize: 16),
                    );
                  }, // 显示 MobX 管理的日期
                ),
                Expanded(
                  child: Container(),
                ),
                TextButton(
                  onPressed: () async {
                    var result = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                    );
                    if (result != null) {
                      // 使用 MobX store 的 action 方法来更新日期
                      store.setDate(result.toString().split(' ')[0]);
                    }
                  },
                  child: Text('日期选择'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_username.text.isEmpty) {
            commonDialog(
              context,
              "警告",
              "用户名不能为空，请重新输入！",
            );
            return;
          }
          if (_account.text.isEmpty) {
            commonDialog(
              context,
              "警告",
              "账号不能为空，请重新输入！",
            );
            return;
          }
          if (_password.text.isEmpty) {
            commonDialog(
              context,
              "警告",
              "密码不能为空，请重新输入！",
            );
            return;
          }
          if (_password.text.length < 8) {
            commonDialog(
              context,
              "警告",
              "密码长度至少8位，请重新输入！",
            );
            return;
          }
          if (_password.text != _passwordAgain.text) {
            commonDialog(
              context,
              "警告",
              "输入的两次密码不一致，请重新输入！",
            );
            return;
          }
          if (_gender.isEmpty) {
            commonDialog(
              context,
              "警告",
              "请选择您的性别！",
            );
            return;
          }
          if (_date.isEmpty) {
            commonDialog(
              context,
              "警告",
              "请选择您的出生日期！",
            );
            return;
          }
          _register();
        },
        label: Text('注册'),
      ),
    );
  }
}
