import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';

@RoutePage()
class BikaSettingPage extends StatefulWidget {
  const BikaSettingPage({super.key});

  @override
  State<BikaSettingPage> createState() => _BikaSettingPageState();
}

class _BikaSettingPageState extends State<BikaSettingPage> {
  late final List<String> shuntList = ["1", "2", "3"];
  late final Map<String, String> shunt = {
    "1": "1",
    "2": "2",
    "3": "3",
  };
  late final List<String> imageQualityList = [
    "low",
    "medium",
    "high",
    "original"
  ];
  late final Map<String, String> imageQuality = {
    "low": "低画质",
    "medium": "中画质",
    "high": "高画质",
    "original": "原图",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔设置'),
      ),
      body: Observer(builder: (context) {
        return Column(
          children: [
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  "分流设置",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                Expanded(child: Container()),
                DropdownButton<String>(
                  value: bikaSetting.getProxy().toString(),
                  icon: const Icon(Icons.expand_more),
                  onChanged: (String? value) {
                    setState(
                      () {
                        bikaSetting.setProxy(int.parse(value!));
                      },
                    );
                  },
                  items: shuntList.map<DropdownMenuItem<String>>(
                    (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(shunt[value]!),
                      );
                    },
                  ).toList(),
                  style: TextStyle(
                    color: globalSetting.textColor,
                    fontSize: 18,
                  ),
                ),
                SizedBox(width: 10),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 10),
                Text(
                  "图片质量",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                Expanded(child: Container()),
                DropdownButton<String>(
                  value: bikaSetting.getImageQuality(),
                  icon: const Icon(Icons.expand_more),
                  onChanged: (String? value) {
                    setState(
                      () {
                        // 删除缓存避免出问题
                        cacheInterceptor.clear();
                        bikaSetting.setImageQuality(value!);
                      },
                    );
                  },
                  items: imageQualityList.map<DropdownMenuItem<String>>(
                    (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(imageQuality[value]!),
                      );
                    },
                  ).toList(),
                  style: TextStyle(
                    color: globalSetting.textColor,
                    fontSize: 18,
                  ),
                ),
                SizedBox(width: 10),
              ],
            )
          ],
        );
      }),
    );
  }
}