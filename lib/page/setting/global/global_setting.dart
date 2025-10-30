import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
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
  late final List<String> systemThemeList = ["跟随系统", "浅色模式", "深色模式"];
  late final Map<String, int> systemTheme = {"跟随系统": 0, "浅色模式": 1, "深色模式": 2};
  late final List<String> splashPageList = ["首页", "排行", "书架", "更多"];
  late final Map<String, int> splashPage = {"首页": 0, "排行": 1, "书架": 2, "更多": 3};

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });
  bool _dynamicColorValue = SettingsHiveUtils.dynamicColor;
  bool _isAMOLEDValue = SettingsHiveUtils.isAMOLED;
  bool _autoSyncValue = SettingsHiveUtils.autoSync;
  bool _autoSyncNotifyValue = SettingsHiveUtils.syncNotify;
  bool _shadeValue = SettingsHiveUtils.shade;
  bool _comicReadTopContainerValue = SettingsHiveUtils.comicReadTopContainer;
  bool _disableBikaValue = SettingsHiveUtils.disableBika;
  final keywordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全局设置')),
      body: ListView(
        children: [
          _systemTheme(),
          _dynamicColor(),
          if (!SettingsHiveUtils.dynamicColor) ...[
            SizedBox(height: 11),
            changeThemeColor(context),
            SizedBox(height: 11),
          ],
          _comicReadTopContainer(),
          _shade(),
          _isAMOLED(),
          DividerWidget(),
          SizedBox(height: 11),
          editMaskedKeywords(context, keywordController),
          SizedBox(height: 11),
          DividerWidget(),
          SizedBox(height: 11),
          socks5ProxyEdit(context),
          SizedBox(height: 11),
          SizedBox(height: 11),
          webdavSync(context),
          SizedBox(height: 11),
          if (SettingsHiveUtils.webdavHost.isNotEmpty) ...[_autoSync()],
          if (SettingsHiveUtils.webdavHost.isNotEmpty &&
              SettingsHiveUtils.autoSync) ...[
            _syncNotify(),
          ],
          DividerWidget(),
          _splashPage(),
          _disableBika(),
          if (kDebugMode) ...[
            ElevatedButton(
              onPressed: () {
                AutoRouter.of(context).push(ShowColorRoute());
              },
              child: Text("整点颜色看看"),
            ),
            ElevatedButton(
              onPressed: () async {
                // jmSetting.deleteUserInfo();
              },
              child: Text('测试禁漫登录'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _systemTheme() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    String currentTheme = "";

    // 通过 int 类型的主题模式获取对应的字符串
    switch (globalSettingState.themeMode) {
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
        SizedBox(width: 10),
        Text("主题模式", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: currentTheme,
          // 根据获取的主题设置当前值
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              switch (value) {
                case "跟随系统":
                  globalSettingCubit.updateThemeMode(ThemeMode.system);
                  break;
                case "浅色模式":
                  globalSettingCubit.updateThemeMode(ThemeMode.light);
                  break;
                case "深色模式":
                  globalSettingCubit.updateThemeMode(ThemeMode.dark);
                  break;
              }
            }
          },
          items: systemThemeList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _dynamicColor() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    return Row(
      children: [
        SizedBox(width: 10),
        Text("动态取色", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5), // 添加间距
        Tooltip(
          message:
              "动态取色是一种根据图片或内容自动调整界面主题颜色的功能。\n"
              "启用后，系统会分析当前页面的主要颜色，并自动调整界面元素的颜色以匹配整体风格，提供更一致的视觉体验。",
          triggerMode: TooltipTriggerMode.tap, // 点击触发
          child: Icon(
            Icons.help_outline, // 问号图标
            size: 20,
            color: context.theme.colorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _dynamicColorValue,
          onChanged: (bool value) {
            setState(() => _dynamicColorValue = !_dynamicColorValue);
            globalSettingCubit.updateDynamicColor(_dynamicColorValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _isAMOLED() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("纯黑模式", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5), // 添加间距
        Tooltip(
          message:
              "纯黑模式专为 AMOLED 屏幕设计。\n"
              "由于 AMOLED 屏幕的像素点可以单独发光，显示纯黑色时像素点会完全关闭，从而达到省电的效果。\n"
              "如果您的设备不是 AMOLED 屏幕，开启此模式将不会有明显的省电效果。",
          triggerMode: TooltipTriggerMode.tap, // 点击触发
          child: Icon(
            Icons.help_outline, // 问号图标
            size: 20,
            color: context.theme.colorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _isAMOLEDValue,
          onChanged: (bool value) {
            setState(() => _isAMOLEDValue = !_isAMOLEDValue);
            globalSettingCubit.updateIsAMOLED(_isAMOLEDValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _autoSync() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("自动同步", style: TextStyle(fontSize: 18)),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _autoSyncValue,
          onChanged: (bool value) {
            setState(() => _autoSyncValue = !_autoSyncValue);
            globalSettingCubit.updateAutoSync(_autoSyncValue);
            if (_autoSyncValue) eventBus.fire(NoticeSync());
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _syncNotify() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("自动同步通知", style: TextStyle(fontSize: 18)),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _autoSyncNotifyValue,
          onChanged: (bool value) {
            setState(() => _autoSyncNotifyValue = !_autoSyncNotifyValue);
            globalSettingCubit.updateAutoSync(_autoSyncNotifyValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _shade() {
    logger.d(SettingsHiveUtils.shade);
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("夜间模式遮罩", style: TextStyle(fontSize: 18)),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _shadeValue,
          onChanged: (bool value) {
            setState(() => _shadeValue = !_shadeValue);
            globalSettingCubit.updateShade(_shadeValue);
            logger.d(globalSettingCubit);
            logger.d(SettingsHiveUtils.shade);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _comicReadTopContainer() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("异形屏适配", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5), // 添加间距
        Tooltip(
          message: "在漫画阅读界面，会在最顶层生成一个状态栏高度的占位容器来避免摄像头遮挡内容。",
          triggerMode: TooltipTriggerMode.tap, // 点击触发
          child: Icon(
            Icons.help_outline, // 问号图标
            size: 20,
            color: context.theme.colorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _comicReadTopContainerValue,
          onChanged: (bool value) {
            setState(
              () => _comicReadTopContainerValue = !_comicReadTopContainerValue,
            );
            globalSettingCubit.updateComicReadTopContainer(
              _comicReadTopContainerValue,
            );
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _splashPage() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("开屏页", style: TextStyle(fontSize: 18)),
        Spacer(),
        DropdownButton<String>(
          value: splashPageList[SettingsHiveUtils.welcomePageNum],
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              showSuccessToast("设置成功，重启生效");
              globalSettingCubit.updateWelcomePageNum(splashPage[value]!);
            }
          },
          items: splashPageList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _disableBika() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    return Row(
      children: [
        SizedBox(width: 10),
        Text("关闭哔咔", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5), // 添加间距
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _disableBikaValue,
          onChanged: (bool value) {
            setState(() => _disableBikaValue = !_disableBikaValue);
            globalSettingCubit.updateDisableBika(_disableBikaValue);
            globalSettingCubit.updateComicChoice(2);
            showSuccessToast("设置成功，重启生效");
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }
}
