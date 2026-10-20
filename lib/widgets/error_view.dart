import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';

class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  /// 登录错误对应的插件 uuid（空 = 非登录错误）。
  /// 非空时显示“登录/重试”两个按钮，登录进 LoginRoute，回来后由 onRetry 拉数据。
  /// 只有压住全局 NeedLogin 的调用方（新两页）会传本参数，
  /// 其他页走全局登录确认框，本参数恒空。
  final String loginPluginId;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.loginPluginId = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            errorMessage,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (loginPluginId.isNotEmpty)
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    await context.pushRoute(LoginRoute(from: loginPluginId));
                    onRetry();
                  },
                  icon: const Icon(Icons.login_outlined),
                  label: Text(t.login.loginButton),
                ),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.common.reload),
                ),
              ],
            )
          else
            ElevatedButton(onPressed: onRetry, child: Text(t.common.reload)),
        ],
      ),
    );
  }
}
