import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/page/more/more.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
import 'package:zephyr/widgets/toast.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  List<Widget> widgets = [];

  // 用于清理 EventBus 监听
  StreamSubscription? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    if (!SettingsHiveUtils.disableBika) {
      // 使用 Hive 快照
      widgets.addAll([BikaUserInfoWidget(), Delimiter()]);
    }

    widgets.addAll([JMUserInfoWidget(), Delimiter(), SettingsWidget()]);

    _refreshSubscription = eventBus.on<RefreshEvent>().listen((event) async {
      await _onRefreshEvent();
    });
  }

  @override
  void dispose() {
    // 清理 EventBus 监听器
    _refreshSubscription?.cancel();
    super.dispose();
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

  Future<void> _onRefreshEvent() async {
    if (!mounted) return;

    final jmCubit = context.read<JmSettingCubit>();
    final jmState = jmCubit.state;

    if (jmState.account.isEmpty || jmState.password.isEmpty) {
      showErrorToast("禁漫账号或密码为空，无法重新登录");
      return;
    }

    jmCubit.updateLoginStatus(LoginStatus.loggingIn);

    try {
      final value = await login(jmState.account, jmState.password);

      if (!mounted) return;

      jmCubit.updateUserInfo(value.let(replaceNestedNull).let(jsonEncode));
      jmCubit.updateLoginStatus(LoginStatus.login);
      logger.d(jmCubit.state.userInfo);
    } catch (e, s) {
      if (!mounted) return;

      logger.e(e, stackTrace: s);
      jmCubit.updateLoginStatus(LoginStatus.logout);
      showErrorToast("重新登录禁漫失败: ${e.toString()}");
    }
  }
}
