import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../bookshelf/models/events.dart';
import 'bika/widgets.dart';

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
  bool _brevity = bikaSetting.brevity;

  @override
  Widget build(BuildContext context) {
    var route = context.router;
    return Scaffold(
      appBar: AppBar(title: const Text('哔咔设置')),
      body: Observer(
        builder: (context) {
          return Column(
            children: [
              SizedBox(height: 10),
              changeProfilePicture(route),
              SizedBox(height: 15),
              changeBriefIntroduction(context),
              SizedBox(height: 15),
              changePassword(context),
              SizedBox(height: 10),
              divider(),
              _shuntWidget(),
              _imageQualityWidget(),
              divider(),
              SizedBox(height: 10),
              changeShieldedCategories(context, "home"),
              SizedBox(height: 15),
              changeShieldedCategories(context, "categories"),
              SizedBox(height: 10),
              divider(),
              _brevityWidget(),
              divider(),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // bikaSetting.deleteAuthorization();
                    route.push(LoginRoute(from: From.jm));
                  },
                  child: Text("退出登录"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _shuntWidget() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text("分流设置", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: bikaSetting.getProxy().toString(),
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            setState(() {
              bikaSetting.setProxy(int.parse(value!));
            });
          },
          items:
              shuntList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(shunt[value]!),
                );
              }).toList(),
          style: TextStyle(color: globalSetting.textColor, fontSize: 18),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _imageQualityWidget() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text("图片质量", style: TextStyle(fontSize: 18)),
        Expanded(child: Container()),
        DropdownButton<String>(
          value: bikaSetting.getImageQuality(),
          icon: const Icon(Icons.expand_more),
          onChanged: (String? value) {
            setState(() {
              // 删除缓存避免出问题
              cacheInterceptor.clear();
              bikaSetting.setImageQuality(value!);
            });
          },
          items:
              imageQualityList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(imageQuality[value]!),
                );
              }).toList(),
          style: TextStyle(color: globalSetting.textColor, fontSize: 18),
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _brevityWidget() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text("漫画列表简略模式", style: TextStyle(fontSize: 18)),
        SizedBox(width: 5), // 添加间距
        Spacer(),
        Switch(
          thumbIcon: thumbIcon,
          value: _brevity,
          onChanged: (bool value) {
            setState(() => _brevity = !_brevity);
            bikaSetting.setBrevity(_brevity);

            eventBus.fire(HistoryEvent(EventType.refresh));
            eventBus.fire(DownloadEvent(EventType.refresh));
            eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 1));
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }
}
