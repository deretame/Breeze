import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../bookshelf/models/events.dart';
import 'widgets.dart';

@RoutePage()
class BikaSettingPage extends StatefulWidget {
  const BikaSettingPage({super.key});

  @override
  State<BikaSettingPage> createState() => _BikaSettingPageState();
}

class _BikaSettingPageState extends State<BikaSettingPage> {
  late final List<String> shuntList = ["1", "2", "3"];
  late final Map<String, String> shunt = {"1": "1", "2": "2", "3": "3"};
  late final List<String> imageQualityList = [
    "low",
    "medium",
    "high",
    "original",
  ];
  late final Map<String, String> imageQuality = {
    "low": "低画质",
    "medium": "中画质",
    "high": "高画质",
    "original": "原图",
  };

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

  late bool _brevity;
  late bool _slowDownload;

  @override
  void initState() {
    super.initState();
    _brevity = SettingsHiveUtils.bikaBrevity;
    _slowDownload = SettingsHiveUtils.bikaSlowDownload;
  }

  @override
  Widget build(BuildContext context) {
    var route = context.router;
    final bikaCubit = context.read<BikaSettingCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('哔咔设置')),
      body: ListView(
        children: [
          SizedBox(height: 10),
          changeProfilePicture(route),
          SizedBox(height: 15),
          changeBriefIntroduction(context),
          SizedBox(height: 15),
          changePassword(context),
          SizedBox(height: 10),
          DividerWidget(),
          _shuntWidget(),
          _imageQualityWidget(),
          DividerWidget(),
          SizedBox(height: 10),
          changeShieldedCategories(context, "home"),
          SizedBox(height: 15),
          changeShieldedCategories(context, "categories"),
          SizedBox(height: 10),
          DividerWidget(),
          _brevityWidget(bikaCubit),
          DividerWidget(),
          _slowDownloadWidget(bikaCubit),
          DividerWidget(),
          Center(
            child: ElevatedButton(
              onPressed: () {
                bikaCubit.resetAuthorization();
                route.push(LoginRoute());
              },
              child: Text("退出登录"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shuntWidget() {
    final bikaCubit = context.read<BikaSettingCubit>();
    final bikaState = context.watch<BikaSettingCubit>().state;
    return Row(
      children: [
        SizedBox(width: 10),
        Text("分流设置", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: bikaState.proxy.toString(),
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            bikaCubit.updateProxy(int.parse(value!));
          },
          items: shuntList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(shunt[value]!),
            );
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _imageQualityWidget() {
    final bikaCubit = context.read<BikaSettingCubit>();
    final bikaState = context.watch<BikaSettingCubit>().state;
    return Row(
      children: [
        SizedBox(width: 10),
        Text("图片质量", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: bikaState.imageQuality,
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            cacheInterceptor.clear();
            bikaCubit.updateImageQuality(value!);
          },
          items: imageQualityList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(imageQuality[value]!),
            );
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _brevityWidget(BikaSettingCubit bikaCubit) {
    return Row(
      children: [
        SizedBox(width: 10),
        Text("漫画列表简略模式", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _brevity, // 使用本地 state
          onChanged: (bool value) {
            setState(() => _brevity = value);
            bikaCubit.updateBrevity(value);

            eventBus.fire(HistoryEvent(EventType.refresh, false));
            eventBus.fire(DownloadEvent(EventType.refresh, false));
            eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 1));
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _slowDownloadWidget(BikaSettingCubit bikaCubit) {
    final theme = context.theme;
    return Row(
      children: [
        SizedBox(width: 10),
        Text("慢速下载", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5),
        Tooltip(
          message: "慢速下载会降低下载图片的速度，以减少对低配手机的负担。",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.help_outline,
            size: 20,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _slowDownload,
          onChanged: (bool value) {
            setState(() => _slowDownload = value);
            bikaCubit.updateSlowDownload(value);
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }
}
