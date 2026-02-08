import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../bookshelf/models/events.dart';
import 'widgets.dart';

@RoutePage()
class BikaSettingPage extends StatefulWidget {
  const BikaSettingPage({super.key});

  @override
  State<BikaSettingPage> createState() => _BikaSettingPageState();
}

class _BikaSettingPageState extends State<BikaSettingPage> {
  final List<String> shuntList = ["1", "2", "3"];
  final Map<String, String> shunt = {"1": "1", "2": "2", "3": "3"};
  final List<String> imageQualityList = ["low", "medium", "high", "original"];
  final Map<String, String> imageQuality = {
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

  @override
  Widget build(BuildContext context) {
    var route = context.router;

    final bikaCubit = context.watch<BikaSettingCubit>();
    final state = bikaCubit.state;

    return Scaffold(
      appBar: AppBar(title: const Text('哔咔设置')),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          changeProfilePicture(route),
          const SizedBox(height: 15),
          changeBriefIntroduction(context),
          const SizedBox(height: 15),
          changePassword(context),
          const SizedBox(height: 10),
          DividerWidget(),
          _shuntWidget(state, bikaCubit),
          _imageQualityWidget(state, bikaCubit),
          DividerWidget(),
          const SizedBox(height: 10),
          changeShieldedCategories(context, "home"),
          const SizedBox(height: 15),
          changeShieldedCategories(context, "categories"),
          const SizedBox(height: 10),
          DividerWidget(),
          _brevityWidget(state, bikaCubit),
          DividerWidget(),
          _slowDownloadWidget(state, bikaCubit),
          DividerWidget(),
          Center(
            child: ElevatedButton(
              onPressed: () {
                bikaCubit.resetAuthorization();
                route.push(LoginRoute());
              },
              child: const Text("退出登录"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shuntWidget(BikaSettingState state, BikaSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("分流设置", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: state.proxy.toString(), // 直接使用 state
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              cubit.updateProxy(int.parse(value));
            }
          },
          items: shuntList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(shunt[value]!),
            );
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _imageQualityWidget(BikaSettingState state, BikaSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("图片质量", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: state.imageQuality, // 直接使用 state
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            if (value != null) {
              cacheInterceptor.clear();
              cubit.updateImageQuality(value);
            }
          },
          items: imageQualityList.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(imageQuality[value]!),
            );
          }).toList(),
          style: TextStyle(color: context.textColor, fontSize: 18),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _brevityWidget(BikaSettingState state, BikaSettingCubit cubit) {
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("漫画列表简略模式", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.brevity,
          onChanged: (bool value) {
            cubit.updateBrevity(value);
            eventBus.fire(HistoryEvent(EventType.refresh, false));
            eventBus.fire(DownloadEvent(EventType.refresh, false));
            eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 1));
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _slowDownloadWidget(BikaSettingState state, BikaSettingCubit cubit) {
    final theme = context.theme;
    return Row(
      children: [
        const SizedBox(width: 10),
        const Text("慢速下载", style: TextStyle(fontSize: 18)),
        const SizedBox(width: 5),
        Tooltip(
          message: "慢速下载会降低下载图片的速度，以减少对低配手机的负担。",
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(
            Icons.help_outline,
            size: 20,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        const Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: state.slowDownload, // 直接使用 state
          onChanged: (bool value) {
            cubit.updateSlowDownload(value);
          },
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
