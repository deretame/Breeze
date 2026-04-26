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
  bool _isWebviewClosed = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isLinux) {
      _openLinuxWebView();
    }
  }

  Future<void> _openLinuxWebView() async {
    final url = widget.info[1];
    final webview = await WebviewWindow.create(
      configuration: CreateConfiguration(
        title: widget.info[0],
        titleBarHeight: 0,
      ),
    );

    // Linux WebView 常用能力示例（按需取消注释）：
    // 1) 获取当前页面相关的 Cookie（默认行为）
    // final cookies = await webview.getAllCookies();
    //
    // 2) 获取所有域名的 Cookie（插件扩展能力）
    // final allCookies = await webview.getAllCookies(allDomains: true);
    //
    // 3) 监听 URL 变化（导航请求触发）
    // String? lastUrl;
    // webview.setOnUrlRequestCallback((nextUrl) {
    //   final changed = nextUrl != lastUrl;
    //   if (changed) {
    //     lastUrl = nextUrl;
    //     debugPrint('URL changed: $nextUrl');
    //   }
    //   return true; // 仅监听，不拦截导航
    // });
    //
    // 建议先注册 URL 回调，再调用 launch，避免错过首次跳转事件。
    webview.launch(url);
    _linuxWebview = webview;

    // 监听 WebView 窗口关闭，更新状态，避免 dispose 时二次 close 导致崩溃
    webview.onClose.then((_) {
      if (mounted) {
        setState(() => _isWebviewClosed = true);
      }
    });
  }

  @override
  void dispose() {
    // Linux 下绝不能重复调用 close()。
    // 用户点击 WebView 窗口自带的关闭按钮后，底层 C++ 对象已释放，
    // 若此时 dispose() 再调用 close() 会操作野指针，触发 segfault。
    if (Platform.isLinux && !_isWebviewClosed && _linuxWebview != null) {
      _linuxWebview!.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String url = widget.info[1];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.info[0]),
        actions: <Widget>[
          if (Platform.isLinux && !_isWebviewClosed)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '关闭 WebView 窗口',
              onPressed: () {
                _linuxWebview?.close();
                if (mounted) {
                  setState(() => _isWebviewClosed = true);
                }
              },
            ),
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
                  Icon(
                    _isWebviewClosed
                        ? Icons.check_circle_outline
                        : Icons.open_in_new,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isWebviewClosed ? 'WebView 窗口已关闭' : '网页已在独立窗口中打开',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      url,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_isWebviewClosed) ...[
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('返回'),
                    ),
                  ],
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
