import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../util/event/event.dart';
import '../../../util/router/router.gr.dart';
import 'widgets.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  final List<String> systemThemeList = ["跟随系统", "浅色模式", "深色模式"];
  final Map<String, int> systemTheme = {"跟随系统": 0, "浅色模式": 1, "深色模式": 2};
  final List<String> splashPageList = ["首页", "排行", "书架", "更多"];
  final Map<String, int> splashPage = {"首页": 0, "排行": 1, "书架": 2, "更多": 3};

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

  @override
  Widget build(BuildContext context) {
    final globalSettingCubit = context.watch<GlobalSettingCubit>();
    final state = globalSettingCubit.state;

    return Scaffold(
      appBar: AppBar(title: const Text('全局设置')),
      body: ListView(
        children: [
          _systemTheme(state, globalSettingCubit),
          _dynamicColor(state, globalSettingCubit),
          if (!state.dynamicColor) ...[
            const SizedBox(height: 11),
            changeThemeColor(context),
            const SizedBox(height: 11),
          ],
          _comicReadTopContainer(state, globalSettingCubit),
          _shade(state, globalSettingCubit),
          _isAMOLED(state, globalSettingCubit),
          DividerWidget(),
          const SizedBox(height: 11),
          editMaskedKeywords(context),
          const SizedBox(height: 11),
          DividerWidget(),
          const SizedBox(height: 11),
          socks5ProxyEdit(context, state.socks5Proxy),
          const SizedBox(height: 11),
          const SizedBox(height: 11),
          webdavSync(context),
          const SizedBox(height: 11),
          if (state.webdavHost.isNotEmpty) ...[
            _autoSync(state, globalSettingCubit),
          ],
          if (state.webdavHost.isNotEmpty && state.autoSync) ...[
            _syncNotify(state, globalSettingCubit),
          ],
          DividerWidget(),
          _splashPage(state, globalSettingCubit),
          _disableBika(state, globalSettingCubit),
          _enableMemoryDebug(state, globalSettingCubit),
          if (kDebugMode) ...[
            ElevatedButton(
              onPressed: () {
                AutoRouter.of(context).push(ShowColorRoute());
              },
              child: const Text("整点颜色看看"),
            ),
            ElevatedButton(
              onPressed: () async {
                // jmSetting.deleteUserInfo();
              },
              child: const Text('测试禁漫登录'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _systemTheme(GlobalSettingState state, GlobalSettingCubit cubit) {
    String currentTheme = "";
    switch (state.themeMode) {
      case ThemeMode.system:
        currentTheme = "跟随系统";
        break;
      case ThemeMode.light:
        currentTheme = "浅色模式";
        break;
      case ThemeMode.dark:
        currentTheme = "深色模式";
        break;
    }

    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("主题模式", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: currentTheme,
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              switch (value) {
                case "跟随系统":
                  cubit.updateThemeMode(ThemeMode.system);
                  break;
                case "浅色模式":
                  cubit.updateThemeMode(ThemeMode.light);
                  break;
                case "深色模式":
                  cubit.updateThemeMode(ThemeMode.dark);
                  break;
              }
            }
          },
          items: systemThemeList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _dynamicColor(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("动态取色", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        Tooltip(
          message:
              "动态取色是一种根据图片或内容自动调整界面主题颜色的功能。\n"
              "启用后，系统会分析当前页面的主要颜色，并自动调整界面元素的颜色以匹配整体风格，提供更一致的视觉体验。",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.help_outline,
            size: 20,
            color: context.theme.colorScheme.outlineVariant,
          ),
        ),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.dynamicColor, // 直接使用 state 中的值
          onChanged: (bool value) {
            // 不需要 setState，Cubit 发出新状态后会自动刷新
            cubit.updateDynamicColor(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _isAMOLED(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("纯黑模式", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        Tooltip(
          message:
              "纯黑模式专为 AMOLED 屏幕设计。\n"
              "由于 AMOLED 屏幕的像素点可以单独发光，显示纯黑色时像素点会完全关闭，从而达到省电的效果。\n"
              "如果您的设备不是 AMOLED 屏幕，开启此模式将不会有明显的省电效果。",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.help_outline,
            size: 20,
            color: context.theme.colorScheme.outlineVariant,
          ),
        ),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.isAMOLED,
          onChanged: (bool value) {
            cubit.updateIsAMOLED(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _autoSync(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("自动同步", style: TextStyle(fontSize: 18)),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.autoSync,
          onChanged: (bool value) {
            cubit.updateAutoSync(value);
            if (value) eventBus.fire(NoticeSync());
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _syncNotify(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("自动同步通知", style: TextStyle(fontSize: 18)),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state
              .syncNotify, // 假设 state 中叫 syncNotify，原代码是 SettingsHiveUtils.syncNotify
          onChanged: (bool value) {
            cubit.updateSyncNotify(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _shade(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("夜间模式遮罩", style: TextStyle(fontSize: 18)),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.shade,
          onChanged: (bool value) {
            cubit.updateShade(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _comicReadTopContainer(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("异形屏适配", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        Tooltip(
          message: "在漫画阅读界面，会在最顶层生成一个状态栏高度的占位容器来避免摄像头遮挡内容。",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.help_outline,
            size: 20,
            color: context.theme.colorScheme.outlineVariant,
          ),
        ),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.comicReadTopContainer,
          onChanged: (bool value) {
            cubit.updateComicReadTopContainer(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _splashPage(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("开屏页", style: TextStyle(fontSize: 18)),
        const Spacer(),
        DropdownButton<String>(
          // 注意：这里假设 GlobalSettingState 中有 welcomePageNum 字段
          // 如果 state 中没有，可能需要检查 Cubit 是否同步了该字段，或者这里暂时保持使用 SettingsHiveUtils (不推荐)
          value: splashPageList[state.welcomePageNum],
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              showSuccessToast("设置成功，重启生效");
              cubit.updateWelcomePageNum(splashPage[value]!);
            }
          },
          items: splashPageList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _disableBika(GlobalSettingState state, GlobalSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("禁用哔咔相关功能", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.disableBika,
          onChanged: (bool value) {
            cubit.updateDisableBika(value);
            cubit.updateComicChoice(2);
            showSuccessToast("设置成功，重启生效");
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _enableMemoryDebug(
    GlobalSettingState state,
    GlobalSettingCubit cubit,
  ) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("启用内存调试", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.enableMemoryDebug,
          onChanged: (bool value) {
            cubit.updateEnableMemoryDebug(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
