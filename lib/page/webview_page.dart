import 'package:auto_route/annotations.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // 换成 inappwebview
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/widgets/app_scaffold_page.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class WebViewPage extends StatelessWidget {
  final List<String> info;

  const WebViewPage({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    String url = info[1];

    return AppScaffoldPage(
      title: Text(info[0]),
      commandBar: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(FluentIcons.open_in_new_window),
            onPressed: () async {
              final Uri uri = Uri.parse(url);
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                showErrorToast('无法打开链接: $url');
              }
            },
          ),
        ],
      ),
      content: InAppWebView(
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
