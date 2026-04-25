import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:desktop_webview_linux/desktop_webview_linux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class WebViewPage extends StatefulWidget {
  final List<String> info;

  const WebViewPage({super.key, required this.info});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  Webview? _linuxWebview;

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux) {
      _openLinuxWebView();
    }
  }

  Future<void> _openLinuxWebView() async {
    final url = widget.info[1];
    final webview = await WebviewWindow.create();
    webview.launch(url);
    _linuxWebview = webview;

    // 当独立窗口关闭时自动返回上一页
    webview.onClose.then((_) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _linuxWebview?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String url = widget.info[1];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.info[0]),
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
      body: Platform.isLinux
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.open_in_new, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '网页已在独立窗口中打开',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    url,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : InAppWebView(
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
