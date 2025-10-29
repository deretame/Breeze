import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zephyr/main.dart';

import '../../../util/update/check_update.dart';

@RoutePage()
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final WebViewController _controller;
  String _htmlContent = "";
  bool _isLoading = true;
  String _appVersion = "加载中...";

  @override
  void initState() {
    super.initState();
    _loadAppVersionAndHtml();
  }

  Future<void> _loadAppVersionAndHtml() async {
    // 1. 获取App版本号
    _appVersion = await getAppVersion();
    logger.i("App version: $_appVersion");

    // 2. 加载HTML内容
    _htmlContent = await rootBundle.loadString(
      'asset/about_page.html',
    ); // 从assets加载

    // 3. 初始化WebView控制器
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000)) // 透明背景，让HTML的背景生效
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // 页面加载完成后，将版本号注入到HTML中
            _controller.runJavaScript('setAppVersion("$_appVersion")');
          },
          onWebResourceError: (WebResourceError error) {
            logger.e("WebView Error: ${error.description}");
          },
          onNavigationRequest: (NavigationRequest request) async {
            // 拦截所有 http/https 链接
            if (request.url.startsWith('http://') ||
                request.url.startsWith('https://')) {
              // 使用外部浏览器打开链接
              await _launchURL(request.url);
              // 阻止 WebView 内部加载
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_htmlContent, baseUrl: null);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FFFF)),
            )
          : WebViewWidget(controller: _controller),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
