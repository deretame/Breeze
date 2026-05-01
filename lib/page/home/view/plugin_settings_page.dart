import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/setting/common/plugin_user_info_card.dart';
import 'package:zephyr/page/setting/common/setting_ui.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/util/event/webview_observe_bus.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/sundry.dart';
import 'package:zephyr/widgets/multi_choice_list_dialog.dart';
import 'package:zephyr/widgets/toast.dart';
import 'package:zephyr/util/error_filter.dart';

@RoutePage()
class PluginSettingsPage extends StatefulWidget {
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
  State<PluginSettingsPage> createState() => _PluginSettingsPageState();
}

class _PluginSettingsPageState extends State<PluginSettingsPage> {
  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _sections = const [];
  List<Map<String, dynamic>> _actions = const [];
  Map<String, dynamic> _values = const {};
  Map<String, dynamic> _userInfo = const {};
  bool _canShowUserInfo = false;
  bool _loadingUserInfo = false;
  String _userInfoError = '';
  StreamSubscription<WebViewObserveEvent>? _webLoginSub;
  _PluginWebLoginFlowConfig? _activeWebLogin;
  bool _submittingWebCookie = false;
  bool _externalFallbackTriggered = false;
  bool _externalLoginPolling = false;
  Timer? _externalCookiePollTimer;
  _ExternalChromiumLoginSession? _externalChromiumSession;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final settingsResponse = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: 'getSettingsBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final settingsEnvelope = UnifiedPluginEnvelope.fromMap(settingsResponse);
      final settingsSections = asJsonList(
        settingsEnvelope.scheme['sections'],
      ).map((item) => asJsonMap(item)).toList();
      final values = asMap(settingsEnvelope.data['values']);
      final canShowUserInfo = settingsEnvelope.data['canShowUserInfo'] == true;

      List<Map<String, dynamic>> actions = const [];
      try {
        final capabilityResponse = await callUnifiedComicPlugin(
          from: widget.from,
          fnPath: 'getCapabilitiesBundle',
          core: const <String, dynamic>{},
          extern: const <String, dynamic>{},
        );
        final capabilityEnvelope = UnifiedPluginEnvelope.fromMap(
          capabilityResponse,
        );
        actions = asJsonList(capabilityEnvelope.scheme['actions'])
            .map((item) => asJsonMap(item))
            .where((item) => item['fnPath']?.toString() != 'dumpRuntimeInfo')
            .toList();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _sections = settingsSections;
        _values = values;
        _userInfo = const <String, dynamic>{};
        _canShowUserInfo = canShowUserInfo;
        _userInfoError = '';
        _actions = actions;
        _loading = false;
      });
      if (canShowUserInfo) {
        _loadUserInfo();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = normalizeSearchErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    if (_loadingUserInfo) {
      return;
    }
    setState(() {
      _loadingUserInfo = true;
      _userInfoError = '';
    });
    try {
      final response = await callUnifiedComicPlugin(
        from: widget.from,
        fnPath: 'getUserInfoBundle',
        core: const <String, dynamic>{},
        extern: const <String, dynamic>{},
      );
      final envelope = UnifiedPluginEnvelope.fromMap(response);
      if (!mounted) return;
      setState(() {
        _userInfo = asMap(envelope.data);
        _loadingUserInfo = false;
        _userInfoError = '';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingUserInfo = false;
        _userInfoError = '用户信息加载失败';
      });
    }
  }

  Future<bool> _maybeHandleWebLoginResult(Map<String, dynamic> result) async {
    final config = _parseWebLoginFlowConfig(result);
    if (config == null) {
      return false;
    }
    await _startWebLoginFlow(config);
    return true;
  }

  _PluginWebLoginFlowConfig? _parseWebLoginFlowConfig(
    Map<String, dynamic> result,
  ) {
    final merged = Map<String, dynamic>.from(result);
    merged.addAll(asMap(result['data']));

    final action = asMap(merged['action']);
    final actionPayload = asMap(action['payload']);

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
    final cookiePollIntervalMs = _toPositiveInt(
      merged['cookiePollIntervalMs'],
      fallback: 500,
    );
    final openTitle =
        (merged['openTitle']?.toString() ??
                actionPayload['title']?.toString() ??
                '${widget.pluginDisplayName} 登录')
            .trim();

    return _PluginWebLoginFlowConfig(
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

  Future<void> _startWebLoginFlow(_PluginWebLoginFlowConfig config) async {
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
        _matchesRedirectWatchUrl(event.url, config.redirectWatchUrl)) {
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
    _PluginWebLoginFlowConfig config,
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

    final session = await _ExternalChromiumLoginSession.start(
      openUrl: config.openUrl,
    );
    if (session == null) {
      debugPrint(
        '[WebLoginFallback] session start failed, open chrome download',
      );
      showErrorToast('未检测到 Chromium 浏览器，请先安装 Chrome');
      unawaited(
        launchUrl(
          Uri.parse(_ExternalChromiumLoginSession.chromeDownloadUrl),
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
    _PluginWebLoginFlowConfig config,
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
          (url) => _matchesRedirectWatchUrl(url, config.redirectWatchUrl),
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
              expiresDate: _toOptionalInt(item['expires']),
              isSecure: item['secure'] == true,
              isHttpOnly: item['httpOnly'] == true,
              isSessionOnly: item['session'] == true,
            ),
          )
          .toList(growable: false);
      final cookie = _buildCookieHeader(snapshots, config);
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
    _PluginWebLoginFlowConfig config,
  ) {
    final uri = Uri.tryParse(event.url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }
    if (_matchesHost(uri.host, config.openUri.host)) {
      return true;
    }
    final watchHost = config.redirectWatchUri?.host ?? '';
    if (watchHost.isNotEmpty && _matchesHost(uri.host, watchHost)) {
      return true;
    }
    return false;
  }

  bool _matchesRedirectWatchUrl(String currentUrl, String watchUrl) {
    final current = currentUrl.trim();
    final watch = watchUrl.trim();
    if (current.isEmpty || watch.isEmpty) {
      return false;
    }
    if (current == watch) {
      return true;
    }
    final currentUri = Uri.tryParse(current);
    final watchUri = Uri.tryParse(watch);
    if (currentUri == null || watchUri == null) {
      return false;
    }
    if (!_matchesHost(currentUri.host, watchUri.host)) {
      return false;
    }
    if (currentUri.path != watchUri.path) {
      return false;
    }
    if (watch.contains('?') && watchUri.query.isEmpty) {
      return currentUri.query.isEmpty;
    }
    if (watchUri.query.isNotEmpty) {
      return currentUri.query == watchUri.query;
    }
    return true;
  }

  bool _matchesHost(String host, String expectedDomain) {
    final normalizedHost = host.trim().toLowerCase();
    final normalizedDomain = expectedDomain.trim().toLowerCase().replaceFirst(
      RegExp(r'^\.+'),
      '',
    );
    if (normalizedHost.isEmpty || normalizedDomain.isEmpty) {
      return false;
    }
    return normalizedHost == normalizedDomain ||
        normalizedHost.endsWith('.$normalizedDomain');
  }

  Future<void> _submitWebLoginCookie(WebViewObserveEvent? event) async {
    final config = _activeWebLogin;
    if (config == null || event == null || _submittingWebCookie) {
      return;
    }

    final cookie = _buildCookieHeader(event.cookies, config);
    if (cookie.isEmpty) {
      return;
    }

    await _submitCookieWithConfig(config, cookie: cookie, url: event.url);
  }

  Future<void> _submitCookieWithConfig(
    _PluginWebLoginFlowConfig config, {
    required String cookie,
    required String url,
  }) async {
    if (_submittingWebCookie) {
      return;
    }
    final cookieNames = _extractCookieNames(cookie);
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
        await _load();
      }
    } catch (e) {
      debugPrint('[PluginSettings] Web login cookie sync failed: $e');
    } finally {
      _submittingWebCookie = false;
    }
  }

  String _buildCookieHeader(
    List<WebViewCookieSnapshot> snapshots,
    _PluginWebLoginFlowConfig config,
  ) {
    if (snapshots.isEmpty) {
      return '';
    }
    final targetHost = config.redirectWatchUri?.host.isNotEmpty == true
        ? config.redirectWatchUri!.host
        : config.openUri.host;
    final selected = <String, String>{};
    for (final snapshot in snapshots) {
      final name = snapshot.name.trim();
      if (name.isEmpty) {
        continue;
      }
      if (config.ignoreCookieNames.contains(name.toLowerCase())) {
        continue;
      }
      final domain = (snapshot.domain ?? '').trim();
      if (domain.isNotEmpty && !_matchesHost(targetHost, domain)) {
        continue;
      }
      selected[name] = snapshot.value;
    }
    if (selected.isEmpty) {
      return '';
    }
    return selected.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  int _toPositiveInt(dynamic value, {required int fallback}) {
    if (value is num) {
      final parsed = value.toInt();
      return parsed > 0 ? parsed : fallback;
    }
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }

  int? _toOptionalInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  List<String> _extractCookieNames(String cookieHeader) {
    final names = <String>[];
    for (final segment in cookieHeader.split(';')) {
      final trimmed = segment.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final eqIndex = trimmed.indexOf('=');
      if (eqIndex <= 0) {
        continue;
      }
      final name = trimmed.substring(0, eqIndex).trim();
      if (name.isEmpty) {
        continue;
      }
      names.add(name);
    }
    return names;
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SchemeSectionCard(
                  title: '插件管理',
                  colorScheme: colorScheme,
                  children: [
                    _FieldRow(
                      title: '调试模式',
                      subtitle: debugEnabled ? '已开启' : '已关闭',
                      trailing: Switch(
                        value: debugEnabled,
                        thumbIcon: kSettingSwitchThumbIcon,
                        onChanged: deleted
                            ? null
                            : (next) => _updateDebugConfig(
                                enabled: next,
                                url: debugUrl,
                              ),
                      ),
                      onTap: deleted
                          ? null
                          : () => _updateDebugConfig(
                              enabled: !debugEnabled,
                              url: debugUrl,
                            ),
                    ),
                    _FieldRow(
                      title: '调试地址',
                      subtitle: debugEnabled
                          ? (debugUrl.isNotEmpty ? debugUrl : '未设置')
                          : '请先开启调试模式',
                      trailing: Icon(
                        debugEnabled ? Icons.edit_outlined : Icons.lock_outline,
                        size: 18,
                      ),
                      onTap: deleted || !debugEnabled
                          ? null
                          : () async {
                              final next = await _showInputDialog(
                                context,
                                title: '调试地址',
                                initialValue: debugUrl,
                                obscure: false,
                              );
                              if (next == null) return;
                              await _updateDebugConfig(
                                enabled: debugEnabled,
                                url: next.trim(),
                              );
                            },
                    ),
                    _FieldRow(
                      title: '删除插件',
                      subtitle: '彻底删除插件，并删除相关数据',
                      trailing: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: deleted
                            ? colorScheme.outline
                            : colorScheme.error,
                      ),
                      onTap: deleted ? null : _confirmDeletePlugin,
                    ),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _SchemeSectionCard(
                    title: '插件设置',
                    colorScheme: colorScheme,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_error),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: _load,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_canShowUserInfo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SchemeSectionCard(
                      title: _userInfo['title']?.toString() ?? '用户信息',
                      colorScheme: colorScheme,
                      children: _loadingUserInfo
                          ? const [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ]
                          : _userInfoError.isNotEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(_userInfoError)),
                                    OutlinedButton(
                                      onPressed: _loadUserInfo,
                                      child: const Text('重试'),
                                    ),
                                  ],
                                ),
                              ),
                            ]
                          : _userInfo.isNotEmpty
                          ? [
                              PluginUserInfoCard(
                                from: widget.from,
                                avatarUrl:
                                    asMap(
                                      _userInfo['avatar'],
                                    )['url']?.toString() ??
                                    '',
                                avatarPath:
                                    asMap(
                                      _userInfo['avatar'],
                                    )['path']?.toString() ??
                                    '',
                                lines: asJsonList(_userInfo['lines'])
                                    .map((item) => item?.toString() ?? '')
                                    .toList(),
                              ),
                            ]
                          : const [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('暂无用户信息'),
                              ),
                            ],
                    ),
                  ),
                for (final section in _sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SchemeSectionCard(
                      title: section['title']?.toString() ?? '',
                      colorScheme: colorScheme,
                      children: asJsonList(section['fields'])
                          .map((item) => asJsonMap(item))
                          .map((field) => _buildField(context, field))
                          .toList(),
                    ),
                  ),
                if (_actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _SchemeSectionCard(
                      title: '操作',
                      colorScheme: colorScheme,
                      children: _actions
                          .map((action) => _buildAction(context, action))
                          .toList(),
                    ),
                  ),
              ],
            ],
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

  Widget _buildField(BuildContext context, Map<String, dynamic> field) {
    final key = field['key']?.toString() ?? '';
    final kind = field['kind']?.toString() ?? 'text';
    final label = field['label']?.toString() ?? key;
    final value = _values[key];

    if (kind == 'switch') {
      final current = value == true;
      return _FieldRow(
        title: label,
        subtitle: current ? '已开启' : '已关闭',
        trailing: Switch(
          value: current,
          thumbIcon: kSettingSwitchThumbIcon,
          onChanged: (next) => _commitField(field, next),
        ),
        onTap: () => _commitField(field, !current),
      );
    }

    if (kind == 'select' || kind == 'choice') {
      final options = _normalizeOptions(field['options']);
      final selected = value;
      final selectedLabel = options
          .firstWhere(
            (item) => item.value.toString() == selected?.toString(),
            orElse: () =>
                _OptionPair(label: selected?.toString() ?? '', value: selected),
          )
          .label;
      final triggerKey = GlobalKey();
      return _FieldRow(
        title: label,
        subtitle: '',
        trailing: _buildSelectTrigger(
          context,
          key: triggerKey,
          label: selectedLabel,
        ),
        onTap: () async {
          final picked = await _showChoiceMenu(
            context,
            triggerKey,
            options,
            selected,
          );
          if (picked == null) return;
          await _commitField(field, picked);
        },
      );
    }

    if (kind == 'multiChoice') {
      final options = _normalizeOptions(field['options']);
      final current = _asStringList(value);
      return _FieldRow(
        title: label,
        subtitle: current.isEmpty ? '未选择' : '已选 ${current.length} 项',
        trailing: const Icon(Icons.tune, size: 18),
        onTap: () async {
          final picked = await showMultiChoiceListDialog(
            context,
            title: label,
            options: options
                .map(
                  (item) => MultiChoiceDialogOption(
                    label: item.label,
                    value: item.value.toString(),
                  ),
                )
                .toList(),
            initialSelected: current,
            confirmText: '保存',
          );
          if (picked == null) return;
          await _commitField(field, picked.toList());
        },
      );
    }

    final text = value?.toString() ?? '';
    final display = kind == 'password' && text.isNotEmpty
        ? '*' * text.length.clamp(6, 24)
        : text;
    return _FieldRow(
      title: label,
      subtitle: display,
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () async {
        final next = await _showInputDialog(
          context,
          title: label,
          initialValue: text,
          obscure: kind == 'password',
        );
        if (next == null) return;
        await _commitField(field, next);
      },
    );
  }

  Widget _buildAction(BuildContext context, Map<String, dynamic> action) {
    final title = action['title']?.toString() ?? '未命名操作';
    final fnPath = action['fnPath']?.toString() ?? '';
    return _FieldRow(
      title: title,
      subtitle: fnPath,
      trailing: const Icon(Icons.play_arrow, size: 18),
      onTap: fnPath.isEmpty
          ? null
          : () async {
              try {
                final result = await callUnifiedComicPlugin(
                  from: widget.from,
                  fnPath: fnPath,
                  core: const <String, dynamic>{},
                  extern: const <String, dynamic>{},
                );
                final startedWebLogin = await _maybeHandleWebLoginResult(
                  result,
                );
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
            },
    );
  }

  Widget _buildSelectTrigger(
    BuildContext context, {
    required GlobalKey key,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: key,
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 16),
        ],
      ),
    );
  }

  Future<dynamic> _showChoiceMenu(
    BuildContext context,
    GlobalKey triggerKey,
    List<_OptionPair> options,
    dynamic selected,
  ) async {
    final triggerContext = triggerKey.currentContext;
    if (triggerContext == null) return null;
    final box = triggerContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return null;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    return showMenu<dynamic>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      constraints: const BoxConstraints(minWidth: 180),
      items: options
          .map(
            (option) => PopupMenuItem<dynamic>(
              value: option.value,
              child: Row(
                children: [
                  Expanded(child: Text(option.label)),
                  if (selected?.toString() == option.value?.toString())
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
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
      setState(() {
        _values = Map<String, dynamic>.from(_values)..[key] = value;
      });
    }
    if (showToast) {
      showSuccessToast('已保存');
    }
  }

  List<_OptionPair> _normalizeOptions(dynamic raw) {
    return asJsonList(raw).map((item) {
      if (item is Map) {
        final map = asJsonMap(item);
        return _OptionPair(
          label: map['label']?.toString() ?? map['value']?.toString() ?? '',
          value: map['value'],
        );
      }
      return _OptionPair(label: item.toString(), value: item);
    }).toList();
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is Map) {
      return value.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Future<String?> _showInputDialog(
    BuildContext context, {
    required String title,
    required String initialValue,
    required bool obscure,
  }) {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _SchemeSectionCard extends StatelessWidget {
  const _SchemeSectionCard({
    required this.title,
    required this.colorScheme,
    required this.children,
  });

  final String title;
  final ColorScheme colorScheme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _OptionPair {
  const _OptionPair({required this.label, required this.value});

  final String label;
  final dynamic value;
}

class _PluginWebLoginFlowConfig {
  const _PluginWebLoginFlowConfig({
    required this.openTitle,
    required this.openUrl,
    required this.openUri,
    required this.redirectWatchUrl,
    required this.redirectWatchUri,
    required this.setCookieFnPath,
    required this.cookiePollIntervalMs,
    required this.ignoreCookieNames,
  });

  final String openTitle;
  final String openUrl;
  final Uri openUri;
  final String redirectWatchUrl;
  final Uri? redirectWatchUri;
  final String setCookieFnPath;
  final int cookiePollIntervalMs;
  final Set<String> ignoreCookieNames;
}

class _ExternalChromiumLoginSession {
  _ExternalChromiumLoginSession._({
    required this.browserName,
    required this.browserExecutable,
    required this.useHostSpawn,
    required this.debugPort,
    required this.openUrl,
  });

  static const String chromeDownloadUrl = 'https://www.google.com/chrome/';
  static const List<String> _linuxCandidates = <String>[
    'google-chrome',
    'microsoft-edge',
    'brave-browser',
    'chromium',
    'chromium-browser',
  ];
  static const List<String> _windowsCandidates = <String>[
    'chrome.exe',
    'brave.exe',
    'msedge.exe',
    'chromium.exe',
  ];
  static const List<_WindowsPathCandidate>
  _windowsPathCandidates = <_WindowsPathCandidate>[
    _WindowsPathCandidate(
      name: 'Google Chrome',
      relativePath: <String>['Google', 'Chrome', 'Application', 'chrome.exe'],
    ),
    _WindowsPathCandidate(
      name: 'Brave',
      relativePath: <String>[
        'BraveSoftware',
        'Brave-Browser',
        'Application',
        'brave.exe',
      ],
    ),
    _WindowsPathCandidate(
      name: 'Microsoft Edge',
      relativePath: <String>['Microsoft', 'Edge', 'Application', 'msedge.exe'],
    ),
    _WindowsPathCandidate(
      name: 'Chromium',
      relativePath: <String>['Chromium', 'Application', 'chrome.exe'],
    ),
  ];
  static const List<String> _macCandidates = <String>[
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
  ];

  final String browserName;
  final String browserExecutable;
  final bool useHostSpawn;
  final int debugPort;
  final String openUrl;

  static bool get _isFlatpakLinux {
    if (!Platform.isLinux) {
      return false;
    }
    final flatpakId = Platform.environment['FLATPAK_ID'] ?? '';
    return flatpakId.trim().isNotEmpty;
  }

  static Future<_ExternalChromiumLoginSession?> start({
    required String openUrl,
  }) async {
    debugPrint('[WebLoginFallback] start requested url=$openUrl');
    final browser = await _detectBrowser();
    if (browser == null) {
      debugPrint('[WebLoginFallback] no chromium browser detected');
      return null;
    }
    debugPrint(
      '[WebLoginFallback] browser detected: ${browser.name} -> ${browser.executable}',
    );
    final debugPort = await _allocateFreePort();
    final userDataDir = await _resolveUserDataDir(
      debugPort,
      browser.useHostSpawn,
    );
    final args = <String>[
      '--remote-debugging-port=$debugPort',
      '--new-window',
      '--no-first-run',
      '--no-default-browser-check',
      '--user-data-dir=$userDataDir',
      openUrl,
    ];

    final started = await _startProcess(
      executable: browser.executable,
      args: args,
      useHostSpawn: browser.useHostSpawn,
    );
    if (!started) {
      debugPrint(
        '[WebLoginFallback] failed to start browser: ${browser.executable}',
      );
      return null;
    }
    debugPrint('[WebLoginFallback] browser launched, debugPort=$debugPort');
    return _ExternalChromiumLoginSession._(
      browserName: browser.name,
      browserExecutable: browser.executable,
      useHostSpawn: browser.useHostSpawn,
      debugPort: debugPort,
      openUrl: openUrl,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCookies() async {
    final wsUrl = await _fetchBrowserWsUrl(debugPort);
    if (wsUrl == null || wsUrl.isEmpty) {
      debugPrint(
        '[WebLoginFallback] cdp ws endpoint unavailable on port=$debugPort',
      );
      return const [];
    }
    try {
      final ws = await WebSocket.connect(wsUrl);
      ws.add(jsonEncode({'id': 1, 'method': 'Storage.getCookies'}));
      final completer = Completer<List<Map<String, dynamic>>>();
      final timeout = Timer(const Duration(seconds: 4), () {
        if (!completer.isCompleted) {
          completer.complete(const <Map<String, dynamic>>[]);
        }
      });

      ws.listen(
        (event) {
          if (completer.isCompleted) {
            return;
          }
          final map = _safeDecodeMap(event);
          if (map == null || map['id'] != 1) {
            return;
          }
          final result = _asMap(map['result']);
          final rawCookies = _asList(result['cookies']);
          final cookies = rawCookies.map(_asMap).toList(growable: false);
          completer.complete(cookies);
        },
        onError: (_) {
          if (!completer.isCompleted) {
            completer.complete(const <Map<String, dynamic>>[]);
          }
        },
      );

      final cookies = await completer.future;
      timeout.cancel();
      unawaited(ws.close());
      return cookies;
    } catch (e) {
      debugPrint('[WebLoginFallback] fetchCookies websocket failed: $e');
      return const [];
    }
  }

  Future<List<String>> fetchOpenPageUrls() async {
    final uri = Uri.parse('http://127.0.0.1:$debugPort/json/list');
    final data = await _fetchJsonList(uri);
    return data
        .map(_asMap)
        .map((item) => item['url']?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  static Future<_BrowserCandidate?> _detectBrowser() async {
    if (Platform.isWindows) {
      final resolvedFromPath = await _detectWindowsBrowserFromKnownPaths();
      if (resolvedFromPath != null) {
        debugPrint(
          '[WebLoginFallback] browser from known paths: ${resolvedFromPath.executable}',
        );
        return resolvedFromPath;
      }
      final resolvedFromRegistry = await _detectWindowsBrowserFromRegistry();
      if (resolvedFromRegistry != null) {
        debugPrint(
          '[WebLoginFallback] browser from registry: ${resolvedFromRegistry.executable}',
        );
        return resolvedFromRegistry;
      }
      for (final candidate in _windowsCandidates) {
        final resolved = await _which(candidate, useHostSpawn: false);
        if (resolved != null && resolved.isNotEmpty) {
          debugPrint('[WebLoginFallback] browser from PATH: $resolved');
          return _BrowserCandidate(name: candidate, executable: resolved);
        }
      }
      return null;
    }

    if (Platform.isMacOS) {
      for (final candidate in _macCandidates) {
        if (await File(candidate).exists()) {
          return _BrowserCandidate(
            name: _basename(candidate),
            executable: candidate,
          );
        }
      }
      for (final candidate in <String>[
        'google-chrome',
        'microsoft-edge',
        'chromium',
        'brave',
      ]) {
        final resolved = await _which(candidate, useHostSpawn: false);
        if (resolved != null && resolved.isNotEmpty) {
          return _BrowserCandidate(name: candidate, executable: resolved);
        }
      }
      return null;
    }

    if (Platform.isLinux) {
      final useHostSpawn = _isFlatpakLinux;
      for (final candidate in _linuxCandidates) {
        final resolved = await _which(candidate, useHostSpawn: useHostSpawn);
        if (resolved != null && resolved.isNotEmpty) {
          return _BrowserCandidate(
            name: candidate,
            executable: resolved,
            useHostSpawn: useHostSpawn,
          );
        }
      }
      return null;
    }

    return null;
  }

  static Future<_BrowserCandidate?>
  _detectWindowsBrowserFromKnownPaths() async {
    final env = Platform.environment;
    final roots = <String>[
      env['ProgramFiles'] ?? '',
      env['ProgramFiles(x86)'] ?? '',
      env['LOCALAPPDATA'] ?? '',
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    for (final candidate in _windowsPathCandidates) {
      for (final root in roots) {
        final executable = _joinWindowsPath(root, candidate.relativePath);
        if (await File(executable).exists()) {
          return _BrowserCandidate(
            name: candidate.name,
            executable: executable,
          );
        }
      }
    }
    return null;
  }

  static Future<_BrowserCandidate?> _detectWindowsBrowserFromRegistry() async {
    for (final candidate in _windowsCandidates) {
      final path = await _queryWindowsAppPath(candidate);
      if (path != null && path.isNotEmpty && await File(path).exists()) {
        return _BrowserCandidate(name: candidate, executable: path);
      }
    }
    return null;
  }

  static Future<String?> _queryWindowsAppPath(String executableName) async {
    const roots = <String>[
      r'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
      r'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths',
      r'HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\App Paths',
    ];
    for (final root in roots) {
      final key = '$root\\$executableName';
      try {
        final result = await Process.run('reg', <String>['query', key, '/ve']);
        if (result.exitCode != 0) {
          continue;
        }
        final raw = '${result.stdout}'.trim();
        if (raw.isEmpty) {
          continue;
        }
        final path = _extractRegistryDefaultValue(raw);
        if (path != null && path.isNotEmpty) {
          return path;
        }
      } catch (_) {}
    }
    return null;
  }

  static String? _extractRegistryDefaultValue(String raw) {
    final lines = raw.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      final normalized = line.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final idx = normalized.indexOf('REG_');
      if (idx < 0) {
        continue;
      }
      final value = normalized
          .substring(idx)
          .replaceFirst(RegExp(r'^REG_\w+\s+'), '')
          .trim();
      if (value.isEmpty) {
        continue;
      }
      return value.replaceAll('"', '').trim();
    }
    return null;
  }

  static String _joinWindowsPath(String root, List<String> segments) {
    final normalizedRoot = root.replaceAll(RegExp(r'[\\/]+$'), '');
    if (segments.isEmpty) {
      return normalizedRoot;
    }
    return '$normalizedRoot\\${segments.join('\\')}';
  }

  static Future<bool> _startProcess({
    required String executable,
    required List<String> args,
    required bool useHostSpawn,
  }) async {
    try {
      if (useHostSpawn) {
        await Process.start('flatpak-spawn', <String>[
          '--host',
          executable,
          ...args,
        ], mode: ProcessStartMode.detached);
        return true;
      }
      await Process.start(executable, args, mode: ProcessStartMode.detached);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> _allocateFreePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  static Future<String> _resolveUserDataDir(int port, bool useHostSpawn) async {
    if (useHostSpawn && Platform.isLinux) {
      return '/tmp/breeze-chromium-cdp-$port';
    }
    final directory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}breeze-chromium-cdp-$port',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  static Future<String?> _which(
    String executable, {
    required bool useHostSpawn,
  }) async {
    try {
      final result = await _runProcess(
        executable: Platform.isWindows ? 'where' : 'which',
        args: <String>[executable],
        useHostSpawn: useHostSpawn,
      );
      if (result.exitCode != 0) {
        return null;
      }
      final output = '${result.stdout}'.trim();
      if (output.isEmpty) {
        return null;
      }
      return output
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    } catch (_) {
      return null;
    }
  }

  static Future<ProcessResult> _runProcess({
    required String executable,
    required List<String> args,
    required bool useHostSpawn,
  }) async {
    if (useHostSpawn) {
      return Process.run('flatpak-spawn', <String>[
        '--host',
        executable,
        ...args,
      ]);
    }
    return Process.run(executable, args);
  }

  static Future<String?> _fetchBrowserWsUrl(int debugPort) async {
    final uri = Uri.parse('http://127.0.0.1:$debugPort/json/version');
    final data = await _fetchJsonMap(uri);
    final ws = data['webSocketDebuggerUrl']?.toString().trim();
    if (ws == null || ws.isEmpty) {
      debugPrint(
        '[WebLoginFallback] /json/version has no webSocketDebuggerUrl',
      );
      return null;
    }
    return ws;
  }

  static Future<Map<String, dynamic>> _fetchJsonMap(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      return _asMap(decoded);
    } catch (_) {
      return const <String, dynamic>{};
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<dynamic>> _fetchJsonList(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      final decoded = jsonDecode(body);
      return _asList(decoded);
    } catch (_) {
      return const <dynamic>[];
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (entry) => MapEntry(entry.key.toString(), entry.value),
        ),
      );
    }
    return const <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return const <dynamic>[];
  }

  static Map<String, dynamic>? _safeDecodeMap(dynamic payload) {
    try {
      if (payload is String) {
        final decoded = jsonDecode(payload);
        return _asMap(decoded);
      }
      return _asMap(payload);
    } catch (_) {
      return null;
    }
  }

  static String _basename(String path) {
    final segments = path
        .split(RegExp(r'[\\/]+'))
        .where((item) => item.isNotEmpty);
    return segments.isEmpty ? path : segments.last;
  }
}

class _BrowserCandidate {
  const _BrowserCandidate({
    required this.name,
    required this.executable,
    this.useHostSpawn = false,
  });

  final String name;
  final String executable;
  final bool useHostSpawn;
}

class _WindowsPathCandidate {
  const _WindowsPathCandidate({required this.name, required this.relativePath});

  final String name;
  final List<String> relativePath;
}
