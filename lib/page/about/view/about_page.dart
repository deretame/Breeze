import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../util/update/check_update.dart';

@RoutePage()
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _htmlContent = "";
  bool _isLoading = true;
  String _appVersion = "加载中...";

  @override
  void initState() {
    super.initState();
    _loadAppVersionAndHtml();
  }

  Future<void> _loadAppVersionAndHtml() async {
    _appVersion = await getAppVersion();
    _htmlContent = await rootBundle.loadString('asset/about_page.html');

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
          : InAppWebView(
              // 初始化配置
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
                supportZoom: false,
                useShouldOverrideUrlLoading: true,
              ),
              initialData: InAppWebViewInitialData(data: _htmlContent),

              onWebViewCreated: (controller) {},

              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(
                  source: 'setAppVersion("$_appVersion")',
                );
              },

              shouldOverrideUrlLoading: (controller, navigationAction) async {
                var uri = navigationAction.request.url;
                if (uri != null &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  await _launchURL(uri.toString());
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },
            ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
