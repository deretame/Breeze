import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/more/more.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json_dispose.dart';
import 'package:zephyr/widgets/toast.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  List<Widget> widgets = [];

  @override
  void initState() {
    super.initState();
    if (!globalSetting.disableBika) {
      widgets.addAll([BikaUserInfoWidget(), Delimiter()]);
    }
    eventBus.on<RefreshEvent>().listen((event) {
      jmSetting.setLoginStatus(LoginStatus.loggingIn);
      login(jmSetting.account, jmSetting.password)
          .then((value) {
            jmSetting.setUserInfo(value.let(replaceNestedNull).let(jsonEncode));
            jmSetting.setLoginStatus(LoginStatus.login);
            logger.d(jmSetting.userInfo);
          })
          .catchError((e, s) {
            logger.e(e, stackTrace: s);
            jmSetting.setLoginStatus(LoginStatus.logout);
            showErrorToast("重新登录禁漫失败: ${e.toString()}");
          });
    });
    widgets.addAll([JMUserInfoWidget(), Delimiter(), settings(context)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('更多')),
      body: RefreshIndicator(
        onRefresh: () async {
          eventBus.fire(RefreshEvent());
        },
        child: ListView.builder(
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            return widgets[index];
          },
        ),
      ),
    );
  }
}
