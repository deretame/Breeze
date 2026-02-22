import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/network/http/jm/http_request.dart' as jm;
import 'package:zephyr/page/more/json/jm/jm_user_info_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/toast.dart';

Future<void> bikaSignIn(BuildContext context) async {
  final globalState = context.read<GlobalSettingCubit>().state;
  if (globalState.disableBika) return;

  if (!context.mounted) return;

  final bikaCubit = context.read<BikaSettingCubit>();

  while (true) {
    try {
      var result = await signIn();
      if (result == '签到成功') {
        showSuccessToast("哔咔自动签到成功！");

        bikaCubit.updateSignIn(true);

        break;
      } else {
        logger.d('哔咔自动签到成功！');
        break;
      }
    } catch (e) {
      logger.e(e);
      await Future.delayed(Duration(seconds: 1));
      continue;
    }
  }
}

Future<void> jmLogin(BuildContext context) async {
  final jmCubit = context.read<JmSettingCubit>();
  final jmState = jmCubit.state;

  if (jmState.account.isEmpty || jmState.password.isEmpty) {
    return;
  }

  jmCubit.updateUserInfo('');
  jmCubit.updateLoginStatus(LoginStatus.loggingIn);

  while (true) {
    try {
      final result = await jm.login(jmState.account, jmState.password);
      jmCubit.updateUserInfo(result.let(jsonEncode));
      jmCubit.updateLoginStatus(LoginStatus.login);

      if (!context.mounted) return;
      await _jmSignIn(context); // 登录成功后自动签到
      break;
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      await Future.delayed(Duration(seconds: 1));
      continue;
    }
  }
}

Future<void> _jmSignIn(BuildContext context) async {
  final jmCubit = context.read<JmSettingCubit>();
  final jmState = jmCubit.state;
  int retryCount = 0;
  const max = 3; // 最大重试次数
  while (true) {
    retryCount++;
    if (retryCount > max) {
      logger.d("签到失败");
      break;
    }

    try {
      var dailyList = await jm.getDailyList();
      final id = (List<Map<String, dynamic>>.from(
        dailyList['list'].map((item) => item as Map<String, dynamic>),
      ).last['id']);
      final userId = jmUserInfoJsonFromJson(jmState.userInfo).uid;
      int retryCount2 = 0;
      const max2 = 3; // 最大重试次数
      while (true) {
        try {
          if (retryCount2 > max2) {
            logger.e("签到失败");
            break;
          }
          final result = await jm.dailyChk(userId, id);
          logger.d(result);
          if (result['msg'] != '今天已经签到过了') {
            showSuccessToast("禁漫自动签到成功！");
          }
          break;
        } catch (e, s) {
          logger.e(e, stackTrace: s);
          await Future.delayed(Duration(seconds: 1));
          retryCount2++;
          continue;
        }
      }
      break;
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      await Future.delayed(Duration(seconds: 5));
      retryCount++;
      continue;
    }
  }
}
