import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';

import '../../../util/router/router.gr.dart';
import '../../navigation_bar.dart';
import 'global/widgets.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  late final List<String> systemThemeList = ["跟随系统", "浅色模式", "深色模式"];
  late final Map<String, int> systemTheme = {"跟随系统": 0, "浅色模式": 1, "深色模式": 2};

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });
  bool _dynamicColorValue = globalSetting.dynamicColor;
  bool _isAMOLEDValue = globalSetting.isAMOLED;
  bool _autoSyncValue = globalSetting.autoSync;
  bool _autoSyncNotifyValue = globalSetting.syncNotify;
  bool _shadeValue = globalSetting.shade;
  bool _comicReadTopContainerValue = globalSetting.comicReadTopContainer;
  final keywordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('全局设置')),
      body: Observer(
        builder:
            (context) => Column(
              children: [
                _systemTheme(),
                _dynamicColor(),
                if (!globalSetting.dynamicColor) ...[
                  SizedBox(height: 11),
                  changeThemeColor(context),
                  SizedBox(height: 11),
                ],
                _comicReadTopContainer(),
                _shade(),
                _isAMOLED(),
                divider(),
                SizedBox(height: 11),
                editMaskedKeywords(context, keywordController),
                SizedBox(height: 11),
                divider(),
                SizedBox(height: 11),
                socks5ProxyEdit(context),
                SizedBox(height: 11),
                SizedBox(height: 11),
                webdavSync(context),
                SizedBox(height: 11),
                if (globalSetting.webdavHost.isNotEmpty) ...[_autoSync()],
                if (globalSetting.webdavHost.isNotEmpty &&
                    globalSetting.autoSync) ...[
                  _syncNotify(),
                ],
                if (kDebugMode) ...[
                  ElevatedButton(
                    onPressed: () {
                      AutoRouter.of(context).push(ShowColorRoute());
                    },
                    child: Text("整点颜色看看"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final data =
                          r'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';
                      final ts = '1744957156';
                      final secret = '185Hcomic3PAPP7R';
                      final result = decodeRespData(data, ts, secret);
                      logger.d(json.decode(result));
                      // objectbox.bikaHistoryBox.removeAll();
                      // var result = await objectbox.bikaHistoryBox.getAllAsync();
                      // var temp = result.map((e) => e.toJson()).toList();
                      // var json = jsonEncode(temp);
                      // await Clipboard.setData(ClipboardData(text: json));
                    },
                    child: Text("测试用的玩意儿"),
                  ),
                ],
              ],
            ),
      ),
    );
  }

  String decodeRespData(String data, String ts, [String? secret]) {
    final actualSecret = secret ?? '185Hcomic3PAPP7R';

    // 1. Base64解码
    final dataB64 = base64.decode(data);

    // 2. AES-ECB解密
    final key = md5.convert(utf8.encode('$ts$actualSecret')).toString();
    final encrypter = encrypt.Encrypter(
      encrypt.AES(encrypt.Key(utf8.encode(key)), mode: encrypt.AESMode.ecb),
    );
    final dataAes = encrypter.decryptBytes(encrypt.Encrypted(dataB64));

    // 3. 解码为字符串 (json)
    return utf8.decode(dataAes);
  }

  Widget _systemTheme() {
    String currentTheme = "";

    // 通过 int 类型的主题模式获取对应的字符串
    switch (globalSetting.getThemeMode()) {
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
        Observer(
          builder: (context) {
            return DropdownButton<String>(
              value: currentTheme,
              // 根据获取的主题设置当前值
              icon: const Icon(Icons.expand_more),
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    // 根据选择的主题更新设置
                    globalSetting.setThemeMode(systemTheme[value]!);
                  });
                }
              },
              items:
                  systemThemeList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              style: TextStyle(color: globalSetting.textColor, fontSize: 18),
            );
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _dynamicColor() {
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
            color: materialColorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _dynamicColorValue,
          onChanged: (bool value) {
            setState(() => _dynamicColorValue = !_dynamicColorValue);
            globalSetting.setDynamicColor(_dynamicColorValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _isAMOLED() {
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
            color: materialColorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _isAMOLEDValue,
          onChanged: (bool value) {
            setState(() => _isAMOLEDValue = !_isAMOLEDValue);
            globalSetting.setIsAMOLED(_isAMOLEDValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _autoSync() {
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
            globalSetting.setAutoSync(_autoSyncValue);
            if (_autoSyncValue) eventBus.fire(NoticeSync());
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _syncNotify() {
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
            globalSetting.setSyncNotify(_autoSyncNotifyValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _shade() {
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
            globalSetting.setShade(_shadeValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _comicReadTopContainer() {
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
            color: materialColorScheme.outlineVariant,
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
            globalSetting.setComicReadTopContainer(_comicReadTopContainerValue);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }
}
