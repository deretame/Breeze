import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 1. 导入 Bloc
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// 2. 导入你的 Cubit (确保路径正确)
import 'package:zephyr/config/bika/bika_setting.dart';
// import '../main.dart'; // 2. 移除旧的 main.dart 导入

@RoutePage()
class WebViewPage extends StatelessWidget {
  final List<String> info;

  const WebViewPage({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    final bikaState = context.watch<BikaSettingCubit>().state;

    String url = info[1];

    if (info[0] == "嗶咔畫廊") {
      var authorization = bikaState.authorization;
      url = "$url?token=$authorization";
    }

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      appBar: AppBar(
        title: Text(info[0]),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw Exception('Could not launch $uri');
              }
            },
          ),
        ],
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
