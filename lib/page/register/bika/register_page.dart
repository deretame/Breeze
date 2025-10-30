import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../network/http/bika/http_request.dart';
import '../../../util/dialog.dart';

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
  late String _gender = 'm';

  @override
  void dispose() {
    _username.dispose();
    _account.dispose();
    _password.dispose();
    _passwordAgain.dispose();
    super.dispose();
  }

  void _register(BuildContext context) async {
    if (!mounted) return;

    // 4. (修改) 在方法开始时获取 Cubit 实例和状态
    final bikaCubit = context.read<BikaSettingCubit>();
    final dateCubit = context.read<StringSelectCubit>(); // 获取日期 Cubit
    final selectedDate = dateCubit.state; // 获取当前选择的日期

    if (_username.text.isEmpty) {
      commonDialog(context, "警告", "用户名不能为空，请重新输入！");
      return;
    }
    if (_account.text.isEmpty) {
      commonDialog(context, "警告", "账号不能为空，请重新输入！");
      return;
    }
    if (_password.text.isEmpty) {
      commonDialog(context, "警告", "密码不能为空，请重新输入！");
      return;
    }
    if (_password.text.length < 8) {
      commonDialog(context, "警告", "密码长度至少8位，请重新输入！");
      return;
    }
    if (_password.text != _passwordAgain.text) {
      commonDialog(context, "警告", "输入的两次密码不一致，请重新输入！");
      return;
    }
    if (_gender.isEmpty) {
      commonDialog(context, "警告", "请选择您的性别！");
      return;
    }
    if (selectedDate.isEmpty) {
      commonDialog(context, "警告", "请选择您的出生日期！");
      return;
    }

    showInfoToast("正在注册...");

    try {
      final result = await register(
        selectedDate,
        _account.text,
        _gender,
        _username.text,
        _password.text,
      );

      logger.d(result.toString());
      logger.d({
        'username': _username.text,
        'account': _account.text,
        'password': _password.text,
      });
      if (!context.mounted) return;
      bikaCubit.updateAccount(_account.text);
      bikaCubit.updatePassword(_password.text);
      showSuccessToast("注册成功，正在跳转登录...");
      Future.delayed(const Duration(seconds: 2), () {
        // 检查State是否仍然挂载
        if (!context.mounted) return;
        AutoRouter.of(context).maybePop();
      });
    } catch (e) {
      logger.e(e);
      if (!mounted) return;
      if (e.toString().contains("birthday adult only")) {
        showErrorToast("未成年人请勿注册！");
        return;
      }
      if (e.toString().contains("name is already exist")) {
        showErrorToast("用户名已被使用，请更换用户名！");
        return;
      }
      if (e.toString().contains("email is already exist")) {
        showErrorToast("账号已被注册，请更换账号！");
        return;
      }

      commonDialog(context, "注册失败", e.toString());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocProvider(
      create: (_) => StringSelectCubit(), // 默认值是 ''
      child: Scaffold(
        appBar: AppBar(title: const Text('注册账号')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Builder(
            // 使用 Builder 获取 BlocProvider 下的 context
            builder: (innerContext) {
              // 使用 innerContext 避免 shadowing
              return Column(
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
                      Text("请选择您的性别: ", style: TextStyle(fontSize: 16)),
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
                          inactiveBgColor: theme.colorScheme.surfaceBright,
                          dividerColor: theme.colorScheme.secondaryFixedDim,
                          borderColor: [theme.colorScheme.secondaryFixedDim],
                          borderWidth: 1.0,
                          labels: ['绅士', '淑女', '机器人'],
                          onToggle: (index) {
                            logger.d('switched to: $index');
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
                      Text("选择您的出生日期: ", style: TextStyle(fontSize: 16)),
                      BlocBuilder<StringSelectCubit, String>(
                        builder: (cubitContext, selectedDate) {
                          logger.d('date changed to: $selectedDate');
                          return Text(
                            selectedDate.isEmpty ? "未选择" : selectedDate,
                            style: TextStyle(fontSize: 16),
                          );
                        },
                      ),
                      Expanded(child: Container()),
                      TextButton(
                        onPressed: () async {
                          var result = await showDatePicker(
                            context: innerContext, // 使用 Builder 的 context
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (result != null) {
                            if (!innerContext.mounted) return;
                            innerContext.read<StringSelectCubit>().setDate(
                              result.toString().split(' ')[0],
                            );
                          }
                        },
                        child: Text('日期选择'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _register(context);
          },
          label: Text('注册'),
        ),
      ),
    );
  }
}
