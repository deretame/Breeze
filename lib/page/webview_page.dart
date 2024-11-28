import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../main.dart';

@RoutePage()
class WebViewPage extends StatelessWidget {
  final List<String> info;

  const WebViewPage({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    if (info[0] == "嗶咔畫廊") {
      var authorization = bikaSetting.authorization;
      info[1] = "${info[1]}?token=$authorization";
    }

    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(info[1]));

    return Scaffold(
      appBar: AppBar(
        title: Text(info[0]),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri url = Uri.parse(info[1]);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                throw Exception('Could not launch $url');
              }
            },
          ),
        ],
      ),
      body: WebViewWidget(
        controller: controller,
      ),
    );
  }
}
