import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/plugin_settings/method/plugin_settings_web_login.dart';
import 'package:zephyr/page/plugin_settings/cubit/plugin_settings_cubit.dart';
import 'package:zephyr/page/plugin_settings/widgets/plugin_settings_content.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/util/event/webview_observe_bus.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class PluginSettingsPage extends StatelessWidget {
  const PluginSettingsPage({
    super.key,
    required this.from,
    required this.pluginUuid,
    required this.pluginRuntimeName,
    required this.pluginDisplayName,
  });

  final String from;
  final String pluginUuid;
  final String pluginRuntimeName;
  final String pluginDisplayName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PluginSettingsCubit()..load(from),
      child: _PluginSettingsPageView(
        from: from,
        pluginUuid: pluginUuid,
        pluginRuntimeName: pluginRuntimeName,
        pluginDisplayName: pluginDisplayName,
      ),
    );
  }
}

class _PluginSettingsPageView extends StatefulWidget {
  const _PluginSettingsPageView({
    required this.from,
    required this.pluginUuid,
    required this.pluginRuntimeName,
    required this.pluginDisplayName,
  });

  final String from;
  final String pluginUuid;
  final String pluginRuntimeName;
  final String pluginDisplayName;

  @override
  State<_PluginSettingsPageView> createState() =>
      _PluginSettingsPageViewState();
}

class _PluginSettingsPageViewState extends State<_PluginSettingsPageView> {
  StreamSubscription<WebViewObserveEvent>? _webLoginSub;
  PluginWebLoginFlowConfig? _activeWebLogin;
  bool _submittingWebCookie = false;
  bool _externalFallbackTriggered = false;
  bool _externalLoginPolling = false;
  Timer? _externalCookiePollTimer;
  ExternalChromiumLoginSession? _externalChromiumSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<PluginSettingsCubit>();
      if (cubit.state.canShowUserInfo) {
        cubit.loadUserInfo(widget.from);
      }
    });
  }

  @override
  void dispose() {
    final sub = _webLoginSub;
    _webLoginSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    _stopExternalChromiumLoginFlow();
    super.dispose();
  }

  Future<bool> _maybeHandleWebLoginResult(Map<String, dynamic> result) async {
    final config = _parseWebLoginFlowConfig(result);
    if (config == null) {
      return false;
    }
    await _startWebLoginFlow(config);
    return true;
  }

  PluginWebLoginFlowConfig? _parseWebLoginFlowConfig(
    Map<String, dynamic> result,
  ) {
    final merged = Map<String, dynamic>.from(result);
    merged.addAll(asJsonMap(result['data']));

    final action = asJsonMap(merged['action']);
    final actionPayload = asJsonMap(action['payload']);

    final openUrl =
        (merged['openUrl']?.toString() ??
                actionPayload['url']?.toString() ??
                '')
            .trim();
    final setCookieFnPath = (merged['setCookieFnPath']?.toString() ?? '')
        .trim();
    if (openUrl.isEmpty || setCookieFnPath.isEmpty) {
      return null;
    }

    final openUri = Uri.tryParse(openUrl);
    if (openUri == null || !openUri.hasScheme || openUri.host.isEmpty) {
      return null;
    }

    final redirectWatchUrl = (merged['redirectWatchUrl']?.toString() ?? '')
        .trim();
    final parsedRedirectWatchUri = redirectWatchUrl.isEmpty
        ? null
        : Uri.tryParse(redirectWatchUrl);
    final redirectWatchUri =
        parsedRedirectWatchUri != null &&
            parsedRedirectWatchUri.hasScheme &&
            parsedRedirectWatchUri.host.isNotEmpty
        ? parsedRedirectWatchUri
        : null;

    final ignoreCookieNames = <String>{
      'cf_clearance',
      ...asJsonList(merged['ignoreCookieNames'])
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty),
    };
    final cookiePollIntervalMs = toPositiveInt(
      merged['cookiePollIntervalMs'],
      fallback: 500,
    );
    final openTitle =
        (merged['openTitle']?.toString() ??
                actionPayload['title']?.toString() ??
                '${widget.pluginDisplayName} 登录')
            .trim();

    return PluginWebLoginFlowConfig(
      openTitle: openTitle.isEmpty
          ? '${widget.pluginDisplayName} 登录'
          : openTitle,
      openUrl: openUrl,
      openUri: openUri,
      redirectWatchUrl: redirectWatchUrl,
      redirectWatchUri: redirectWatchUri,
      setCookieFnPath: setCookieFnPath,
      cookiePollIntervalMs: cookiePollIntervalMs,
      ignoreCookieNames: ignoreCookieNames,
    );
  }

  Future<void> _startWebLoginFlow(PluginWebLoginFlowConfig config) async {
    await _stopWebLoginFlow();
    _stopExternalChromiumLoginFlow();
    _activeWebLogin = config;
    _submittingWebCookie = false;
    _externalFallbackTriggered = false;
    _externalLoginPolling = false;

    _webLoginSub = WebViewObserveBus.stream.listen(
      (event) => unawaited(_handleWebLoginObserveEvent(event)),
    );

    if (!mounted) {
      await _stopWebLoginFlow();
      return;
    }
    unawaited(
      context.pushRoute(WebViewRoute(info: [config.openTitle, config.openUrl])),
    );
    showSuccessToast('请在网页中完成登录，宿主会自动同步 Cookie');
  }

  Future<void> _stopWebLoginFlow() async {
    final sub = _webLoginSub;
    _webLoginSub = null;
    if (sub != null) {
      await sub.cancel();
    }
    _activeWebLogin = null;
    _submittingWebCookie = false;
  }

  void _stopExternalChromiumLoginFlow() {
    _externalCookiePollTimer?.cancel();
    _externalCookiePollTimer = null;
    _externalChromiumSession = null;
    _externalLoginPolling = false;
  }

  Future<void> _handleWebLoginObserveEvent(WebViewObserveEvent event) async {
    final config = _activeWebLogin;
    if (config == null) {
      return;
    }
    if (!_isRelevantWebLoginEvent(event, config)) {
      return;
    }

    if (_shouldFallbackToExternalChromium(event)) {
      await _startExternalChromiumFallback(config);
      return;
    }

    if (config.redirectWatchUrl.isNotEmpty &&
        matchesRedirectWatchUrl(event.url, config.redirectWatchUrl)) {
      await _submitWebLoginCookie(event);
    }
  }

  bool _shouldFallbackToExternalChromium(WebViewObserveEvent event) {
    if (_externalFallbackTriggered) {
      return false;
    }
    if (event.trigger == 'http_error') {
      final code = event.statusCode ?? 0;
      return code == 403 || code == 429 || code == 503;
    }
    if (event.trigger == 'load_error') {
      return true;
    }
    return false;
  }

  Future<void> _startExternalChromiumFallback(
    PluginWebLoginFlowConfig config,
  ) async {
    if (_externalFallbackTriggered) {
      return;
    }
    _externalFallbackTriggered = true;

    await _stopWebLoginFlow();
    _stopExternalChromiumLoginFlow();

    if (!mounted) {
      return;
    }
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      showErrorToast('当前平台不支持外部 Chromium 自动登录回退');
      return;
    }

    showErrorToast('内置 WebView 登录受限，正在切换外部浏览器...');
    unawaited(context.router.maybePop());

    final session = await ExternalChromiumLoginSession.start(
      openUrl: config.openUrl,
    );
    if (session == null) {
      debugPrint(
        '[WebLoginFallback] session start failed, open chrome download',
      );
      showErrorToast('未检测到 Chromium 浏览器，请先安装 Chrome');
      unawaited(
        launchUrl(
          Uri.parse(ExternalChromiumLoginSession.chromeDownloadUrl),
          mode: LaunchMode.externalApplication,
        ),
      );
      return;
    }

    _externalChromiumSession = session;
    debugPrint(
      '[WebLoginFallback] external chromium ready: ${session.browserName} port=${session.debugPort}',
    );
    showSuccessToast('已切换到 ${session.browserName}，登录完成后会自动同步 Cookie');
    _externalCookiePollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_pollExternalChromiumCookie(config)),
    );
    unawaited(_pollExternalChromiumCookie(config));
  }

  Future<void> _pollExternalChromiumCookie(
    PluginWebLoginFlowConfig config,
  ) async {
    final session = _externalChromiumSession;
    if (session == null || _externalLoginPolling) {
      return;
    }
    if (_submittingWebCookie) {
      return;
    }
    _externalLoginPolling = true;
    try {
      debugPrint(
        '[WebLoginFallback] polling cookies from ${session.browserName} port=${session.debugPort}',
      );
      final cookies = await session.fetchCookies();
      debugPrint('[WebLoginFallback] fetched cookies count=${cookies.length}');
      if (cookies.isEmpty) {
        return;
      }
      if (config.redirectWatchUrl.isNotEmpty) {
        final urls = await session.fetchOpenPageUrls();
        debugPrint('[WebLoginFallback] open pages count=${urls.length}');
        final reached = urls.any(
          (url) => matchesRedirectWatchUrl(url, config.redirectWatchUrl),
        );
        debugPrint(
          '[WebLoginFallback] redirect target reached=$reached target=${config.redirectWatchUrl}',
        );
        if (!reached) {
          return;
        }
      }

      final snapshots = cookies
          .map(
            (item) => WebViewCookieSnapshot(
              name: item['name']?.toString() ?? '',
              value: item['value']?.toString() ?? '',
              domain: item['domain']?.toString(),
              path: item['path']?.toString(),
              expiresDate: toOptionalInt(item['expires']),
              isSecure: item['secure'] == true,
              isHttpOnly: item['httpOnly'] == true,
              isSessionOnly: item['session'] == true,
            ),
          )
          .toList(growable: false);
      final cookie = buildCookieHeader(
        snapshots,
        config,
        nameOf: (snapshot) => snapshot.name as String,
        valueOf: (snapshot) => snapshot.value as String,
        domainOf: (snapshot) => snapshot.domain as String?,
      );
      if (cookie.isEmpty) {
        debugPrint('[WebLoginFallback] cookie header is empty after filtering');
        return;
      }

      final submitUrl = config.redirectWatchUrl.isNotEmpty
          ? config.redirectWatchUrl
          : config.openUrl;
      await _submitCookieWithConfig(config, cookie: cookie, url: submitUrl);
    } catch (e) {
      debugPrint('[PluginSettings] External chromium cookie poll failed: $e');
    } finally {
      _externalLoginPolling = false;
    }
  }

  bool _isRelevantWebLoginEvent(
    WebViewObserveEvent event,
    PluginWebLoginFlowConfig config,
  ) {
    final uri = Uri.tryParse(event.url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }
    if (matchesHost(uri.host, config.openUri.host)) {
      return true;
    }
    final watchHost = config.redirectWatchUri?.host ?? '';
    if (watchHost.isNotEmpty && matchesHost(uri.host, watchHost)) {
      return true;
    }
    return false;
  }

  Future<void> _submitWebLoginCookie(WebViewObserveEvent? event) async {
    final config = _activeWebLogin;
    if (config == null || event == null || _submittingWebCookie) {
      return;
    }

    final cookie = buildCookieHeader(
      event.cookies,
      config,
      nameOf: (snapshot) => snapshot.name as String,
      valueOf: (snapshot) => snapshot.value as String,
      domainOf: (snapshot) => snapshot.domain as String?,
    );
    if (cookie.isEmpty) {
      return;
    }

    await _submitCookieWithConfig(config, cookie: cookie, url: event.url);
  }

  Future<void> _submitCookieWithConfig(
    PluginWebLoginFlowConfig config, {
    required String cookie,
    required String url,
  }) async {
    if (_submittingWebCookie) {
      return;
    }
    final cookieNames = extractCookieNames(cookie);
    debugPrint(
      '[PluginSettings] setCookie fn=${config.setCookieFnPath} '
      'count=${cookieNames.length} names=${cookieNames.join(',')}',
    );
    _submittingWebCookie = true;
    try {
      final result = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: config.setCookieFnPath,
        core: {'cookie': cookie, 'url': url},
        extern: const <String, dynamic>{},
      );
      final message = result['message']?.toString().trim();
      showSuccessToast(
        message?.isNotEmpty == true ? message! : '登录 Cookie 已同步',
      );
      await _stopWebLoginFlow();
      _stopExternalChromiumLoginFlow();
      if (mounted) {
        await context.read<PluginSettingsCubit>().load(widget.from);
      }
    } catch (e) {
      debugPrint('[PluginSettings] Web login cookie sync failed: $e');
    } finally {
      _submittingWebCookie = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pluginState = context
        .watch<PluginRegistryCubit>()
        .state[widget.pluginUuid];
    final debugEnabled = pluginState?.debug ?? false;
    final debugUrl = pluginState?.debugUrl ?? '';
    final deleted = pluginState?.isDeleted == true;
    final state = context.watch<PluginSettingsCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pluginDisplayName} 设置'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: PluginSettingsContent(
            from: widget.from,
            pluginRuntimeName: widget.pluginRuntimeName,
            state: state,
            debugEnabled: debugEnabled,
            debugUrl: debugUrl,
            deleted: deleted,
            colorScheme: colorScheme,
            onUpdateDebugConfig: _updateDebugConfig,
            onConfirmDeletePlugin: _confirmDeletePlugin,
            onCommitField: _commitField,
            onRunAction: (action) => _runAction(context, action),
          ),
        ),
      ),
    );
  }

  Future<void> _updateDebugConfig({
    required bool enabled,
    required String url,
  }) async {
    await PluginRegistryService.I.updateDebugConfig(
      widget.pluginUuid,
      debug: enabled,
      debugUrl: url,
    );
    if (!mounted) return;
    showSuccessToast('插件调试配置已更新');
  }

  Future<void> _confirmDeletePlugin() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除插件'),
        content: const Text('确认删除该插件？此操作将删除插件及其相关数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }
    try {
      await PluginRegistryService.I.deletePlugin(widget.pluginUuid);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showErrorToast('删除失败: $e');
      return;
    }
    if (!mounted) {
      return;
    }
    showSuccessToast('插件已删除');
    Navigator.of(context).pop();
  }

  Future<void> _runAction(
    BuildContext context,
    Map<String, dynamic> action,
  ) async {
    final fnPath = action['fnPath']?.toString() ?? '';
    if (fnPath.isEmpty) {
      return;
    }
    try {
      final result = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: fnPath,
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final startedWebLogin = await _maybeHandleWebLoginResult(result);
      if (!startedWebLogin) {
        final message = result['message']?.toString() ?? '执行成功';
        showSuccessToast(message);
      }
      if (!mounted) return;
      if (fnPath == 'clearPluginSession') {
        this.context.router.push(LoginRoute(from: widget.from));
      }
    } catch (e) {
      showErrorToast('执行失败: $e');
    }
  }

  Future<void> _commitField(Map<String, dynamic> field, dynamic value) async {
    final key = field['key']?.toString() ?? '';
    final fnPath = field['fnPath']?.toString().trim() ?? '';
    final persist = field['persist'] != false;
    var startedWebLogin = false;

    if (fnPath.isNotEmpty) {
      final result = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: fnPath,
        core: {'key': key, 'value': value},
        extern: const <String, dynamic>{},
      );
      startedWebLogin = await _maybeHandleWebLoginResult(result);
    }

    if (persist && key.isNotEmpty) {
      await savePluginConfigValue(widget.pluginRuntimeName, key, value);
    }

    await _saveFieldState(key, value, showToast: !startedWebLogin);
  }

  Future<void> _saveFieldState(
    String key,
    dynamic value, {
    bool showToast = true,
  }) async {
    if (!mounted) return;

    if (key.isNotEmpty) {
      context.read<PluginSettingsCubit>().saveFieldValue(key, value);
    }
    if (showToast) {
      showSuccessToast('已保存');
    }
  }
}
