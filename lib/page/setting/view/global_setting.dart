import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

import '../../../util/event/event.dart';
import '../../../util/router/router.gr.dart';
import 'global/widgets.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class Test {
  ObjectBox objectbox;
  RootIsolateToken rootToken;

  Test(this.objectbox, this.rootToken);
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
  List<Map<String, dynamic>>? _backgroundData;
  bool _isLoading = false;
  String _status = "等待操作, 喵~";

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
                      final RootIsolateToken? rootToken =
                          RootIsolateToken.instance;
                      if (!mounted) return; // 检查 widget 是否还在树中

                      if (rootToken == null) {
                        logger.e("糟糕喵！在主 Isolate 中无法获取 RootIsolateToken！");
                        setState(() {
                          _status = "无法获取 RootIsolateToken!";
                        });
                        return;
                      }

                      logger.d(
                        "UI: 准备在后台 Isolate 中运行 performBackgroundDbOperations 函数，喵~",
                      );
                      setState(() {
                        _isLoading = true;
                        _status = "后台任务运行中...";
                        _backgroundData = null;
                      });

                      try {
                        // 调用 compute
                        final List<Map<String, dynamic>>?
                        resultData = await compute(
                          performBackgroundDbOperations,
                          rootToken, // 参数1: RootIsolateToken
                          // 如果 performBackgroundDbOperations 需要其他参数，可以在这里加
                          // 例如：(String, int){'dbPath': objectbox.store.directoryPath, 'someValue': 42}
                          // 然后 performBackgroundDbOperations 接收一个 Map<String, dynamic>
                        );

                        if (!mounted) return;

                        if (resultData != null) {
                          logger.d("UI: 从后台获取到的数据 (转换后): $resultData");
                          setState(() {
                            _backgroundData = resultData;
                            _status = "后台任务成功返回 ${resultData.length} 条数据, 喵!";
                          });
                        } else {
                          logger.d("UI: 后台任务没有返回数据或出错了，喵。");
                          setState(() {
                            _status = "后台任务执行完毕，但没有数据或出错。";
                          });
                        }
                      } catch (e, s) {
                        if (!mounted) return;
                        logger.e(
                          "UI: 调用 compute 时捕获到错误:",
                          error: e,
                          stackTrace: s,
                        );
                        setState(() {
                          _status = "调用 compute 时出错: $e";
                        });
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                        logger.d("UI: compute 调用流程执行完毕，喵!");
                      }
                    },
                    child: Text('执行后台 ObjectBox 操作'),
                  ),
                ],
              ],
            ),
      ),
    );
  }

  // 这个函数将在后台 Isolate 中运行
  static Future<List<Map<String, dynamic>>?> performBackgroundDbOperations(
    RootIsolateToken rootToken, // 参数1: RootIsolateToken
    // 你也可以传递其他简单参数，比如 String dbPath (如果路径不是固定的)
  ) async {
    ObjectBox? localObxInstance;
    try {
      // 1. 初始化后台 Isolate 的 BinaryMessenger
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
      logger.d("[Background] BinaryMessenger 初始化成功，喵!");

      // 2. 在后台 Isolate 中创建自己的 ObjectBox 实例
      // 这里会调用我们修改过的 ObjectBox.create()
      localObxInstance = await ObjectBox.create();
      logger.d(
        "[Background] ObjectBox 实例创建成功 (Store isOpen: ${Store.isOpen(localObxInstance.store.directoryPath)}), 准备读取数据，喵!",
      );

      // 3. 执行数据库操作
      final bikaHistoryBox = localObxInstance.bikaHistoryBox;
      final List<BikaComicHistory> data = await bikaHistoryBox.getAllAsync();
      logger.d("[Background] 从 ObjectBox 获取到的原始数据条数: ${data.length}，喵!");

      // 4. 将结果数据转换为可发送的格式
      final List<Map<String, dynamic>> sendableData =
          data.map((historyItem) {
            return {
              'id': historyItem.id, // 假设 BikaComicHistory 有 id 属性
              'title': historyItem.title, // 假设 BikaComicHistory 有 title 属性
              // ... 其他需要返回的字段 ...
            };
          }).toList();

      logger.d("[Background] 数据转换完毕，准备返回，喵!");
      return sendableData;
    } catch (e, stackTrace) {
      logger.e("[Background] 后台函数中发生错误:", error: e, stackTrace: stackTrace);
      return null;
    } finally {
      // 5. 至关重要：关闭在后台 Isolate 中打开的 ObjectBox Store 实例！
      if (localObxInstance != null) {
        final storePath = localObxInstance.store.directoryPath;
        localObxInstance.store.close();
        logger.d(
          "[Background] 后台 ObjectBox Store 实例已关闭 (Path: $storePath). Is still open? ${Store.isOpen(storePath)}",
        );
      }
    }
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
