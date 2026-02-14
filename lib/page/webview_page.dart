import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // 换成 inappwebview
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/bika/bika_setting.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(info[0]),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              final Uri uri = Uri.parse(url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('无法打开链接: $url')));
                }
              }
            },
          ),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
          isInspectable: true,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
