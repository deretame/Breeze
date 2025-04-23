import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';

import '../../../util/update/check_update.dart';

@RoutePage()
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  var version = "";

  @override
  void initState() {
    super.initState();
    getAppVersion().then((value) {
      logger.i("App version: $value");
      version = value;
      setState(() {
        version = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('关于')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 作者头像和名字
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                "https://avatars.githubusercontent.com/u/81013544",
              ),
            ),
            SizedBox(height: 16),
            Text(
              'windy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            // 项目地址
            _buildSection(
              title: '项目地址',
              content: 'GitHub 仓库',
              onTap: () {
                _launchURL('https://github.com/deretame/Breeze');
              },
            ),
            SizedBox(height: 16),

            // 联系方式
            _buildSection(
              title: '联系方式',
              content: '电报: https://t.me/breeze_zh_cn',
              onTap: () {
                _launchURL('https://t.me/breeze_zh_cn');
              },
            ),
            SizedBox(height: 16),

            // 支持与感谢
            _buildSection(
              title: '支持与感谢',
              content: '如果你喜欢这个项目，请点个 Star ⭐️ 支持一下！',
              onTap: () {
                _launchURL('https://github.com/deretame/Breeze');
              },
            ),
            SizedBox(height: 16),

            // 反馈入口
            _buildSection(
              title: '反馈与建议',
              content: '发现问题或有建议？点击这里反馈',
              onTap: () {
                _launchURL('https://github.com/deretame/Breeze/issues');
              },
            ),
            SizedBox(height: 32),

            // 免责声明
            TextButton(
              onPressed: () {
                _showDisclaimerDialog(context);
              },
              child: Text('免责声明', style: TextStyle(color: Colors.blue)),
            ),

            Spacer(),
            Text('版本号: $version', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // 构建每个部分的 UI
  Widget _buildSection({
    required String title,
    required String content,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Text(
            content,
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ),
      ],
    );
  }

  // 打开链接
  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw '无法打开链接: $url';
    }
  }

  // 显示免责声明对话框
  void _showDisclaimerDialog(BuildContext context) {
    final String disclaimerMarkdown = '''
# **开源项目免责声明**

1. **项目性质与声明**  
   本项目为开源软件，由本人独立开发并维护。项目以“原样”形式提供，开发者不对项目的功能完整性、稳定性、安全性或适用性作出任何明示或暗示的担保。

2. **责任限制**  
   开发者对因使用、修改或分发本项目（包括但不限于直接使用、二次开发或集成至其他项目）而导致的任何直接、间接、特殊、附带或后果性损害不承担任何责任。这些损害可能包括但不限于数据丢失、设备损坏、业务中断、利润损失或其他经济损失。

3. **用户责任**  
   用户在使用本项目时，应自行评估其适用性并承担所有风险。用户须确保其使用行为符合所在国家或地区的法律法规及道德规范。开发者不对用户因违反法律法规或不当使用本项目而导致的任何后果负责。

4. **第三方依赖与资源**  
   本项目可能依赖或引用第三方库、工具、服务或其他资源。开发者不对这些第三方资源的内容、功能、安全性或合法性负责。用户应自行评估并承担使用第三方资源的风险。

5. **无担保声明**  
   开发者明确声明不对本项目提供任何形式的担保，包括但不限于：
    - 适销性担保；
    - 特定用途适用性担保；
    - 不侵犯第三方权利担保；
    - 无错误或无中断运行担保。

6. **项目修改与终止**  
   开发者保留随时修改、暂停或终止本项目的权利，且无需提前通知用户。开发者不对因项目修改、暂停或终止而导致的任何后果负责。

7. **贡献者责任**  
   如果本项目接受外部贡献，贡献者的行为仅代表其个人立场，不代表开发者的观点或立场。开发者对贡献者的行为及其贡献内容不承担责任。

8. **法律合规性**  
   用户在使用本项目时，应确保其行为符合所在国家或地区的法律法规。开发者不对用户因违反法律法规而导致的任何后果负责。

---

**重要提示**  
在使用本项目之前，请仔细阅读并理解本免责声明。如果您不同意本声明的任何条款，请立即停止使用本项目。继续使用本项目即表示您已阅读、理解并同意本免责声明的全部内容。
''';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('免责声明'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite, // 设置最大宽度
              child: MarkdownBody(data: disclaimerMarkdown),
            ),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: Text('关闭')),
          ],
        );
      },
    );
  }
}
