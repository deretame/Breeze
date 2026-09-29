import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/utils/github_proxy.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/json/json_value.dart';

const _cloudPluginListDirectUrl =
    'https://raw.githubusercontent.com/deretame/Breeze-plugin-list/main/plugins_data.json';

const cloudPluginListApi = 'https://api.windy-78.site/plugin-list';

const _cdnMirrors = [
  'https://jsdelivr.topthink.com/',
  'https://cdn.jsdmirror.com/',
  'https://cdn.jsdmirror.cn/',
  'https://www.webcache.cn/',
  'https://jsd.onmicrosoft.cn/',
  'https://cdn.jsdelivr.net/',
];

const _ghCdnMirrors = [
  'https://cdn.jsdmirror.com/',
  'https://cdn.jsdmirror.cn/',
  'https://jsd.onmicrosoft.cn/',
  'https://cdn.jsdelivr.net/',
];

Future<String> fetchCloudPluginListWithCdnFallback() async {
  final client = WindHttp(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 15),
  );

  try {
    logger.d('尝试使用自建 API: $cloudPluginListApi');
    final response = await client.fetch(
      cloudPluginListApi,
      headers: {'Accept': 'application/json, text/plain, */*'},
    );
    final body = response.text.trim();
    if (response.ok && body.isNotEmpty) {
      return body;
    }
  } catch (e, stackTrace) {
    logger.w(
      '自建 API 通道失败: $cloudPluginListApi',
      error: e,
      stackTrace: stackTrace,
    );
  }

  var version = 'latest';

  try {
    final temp = await client.fetch(
      'https://breeze-version.s3.bitiful.net/plugin-list-version.json',
    );
    final data = temp.json;
    version = (data is Map ? data['version'] : null) ?? 'latest';
  } catch (e) {
    logger.e(e);
    return fetchCloudPluginListPayload(_cloudPluginListDirectUrl);
  }

  for (final mirror in _ghCdnMirrors) {
    final url =
        '${mirror}gh/deretame/Breeze-plugin-list@$version/plugins_data.json';
    logger.d('尝试使用 GitHub CDN 镜像: $url');
    try {
      final response = await client.fetch(
        url,
        headers: {'Accept': 'application/json, text/plain, */*'},
      );
      final body = response.text.trim();
      if (response.ok && body.isNotEmpty) {
        return body;
      }
    } catch (e, stackTrace) {
      logger.w('CDN 镜像通道失败: $url', error: e, stackTrace: stackTrace);
    }
  }

  return fetchCloudPluginListPayload(_cloudPluginListDirectUrl);
}

Future<String> fetchCloudPluginListPayload(String sourceUrl) async {
  final requestUrls = buildCloudRequestCandidates(sourceUrl);
  final client = WindHttp(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  );

  Object? lastError;
  for (final requestUrl in requestUrls) {
    try {
      final response = await client.fetch(
        requestUrl,
        headers: {'Accept': 'application/json, text/plain, */*'},
      );
      final body = response.text.trim();
      if (response.ok && body.isNotEmpty) {
        return body;
      }
      lastError = response.ok
          ? StateError('空响应: $requestUrl')
          : StateError('HTTP ${response.status}: $requestUrl');
      logger.w(
        '云端插件列表通道失败: $requestUrl status=${response.status} '
        'ok=${response.ok}',
      );
    } catch (e, stackTrace) {
      lastError = e;
      logger.w('云端插件列表通道失败: $requestUrl', error: e, stackTrace: stackTrace);
    }
  }

  throw StateError('所有云端插件列表通道都不可用: $lastError');
}

List<String> buildCloudRequestCandidates(String sourceUrl) {
  final mirrorBaseUrls = [
    'https://v4.gh-proxy.org/',
    'https://gh-proxy.org/',
    'https://v6.gh-proxy.org/',
    'https://cdn.gh-proxy.org/',
  ];
  final uri = Uri.tryParse(sourceUrl);
  final result = <String>[];
  if (sourceUrl == _cloudPluginListDirectUrl) {
    result.add(cloudPluginListApi);
  }
  if (uri != null) {
    final isGithubHost =
        uri.host == 'raw.githubusercontent.com' ||
        uri.host == 'github.com' ||
        uri.host == 'www.github.com';
    if (isGithubHost) {
      for (final baseUrl in mirrorBaseUrls) {
        result.add('$baseUrl/$sourceUrl');
      }
    }
  }
  result.add(sourceUrl);
  return result.toSet().toList();
}

Future<String> downloadFromJsdelivrOrGitHub({
  required String npmName,
  required String cloudVersion,
  required String updateUrl,
}) async {
  if (npmName.isNotEmpty) {
    for (final ext in ['.cjs.br', '.cjs']) {
      final assetPath = 'npm/$npmName@$cloudVersion/dist/$npmName.bundle$ext';
      for (final mirror in _cdnMirrors) {
        final url = '$mirror$assetPath';
        try {
          final response = await downloadPluginAssetWithFallback(url);
          final script = await decodeDownloadedPluginScript(
            response: response,
            resolvedUrl: url,
          );
          final trimmed = script.trim();
          if (trimmed.isNotEmpty) {
            return trimmed;
          }
        } catch (e) {
          logger.w('CDN 下载尝试失败: $url', error: e);
        }
      }
    }
    logger.w('所有 CDN 镜像下载失败，回退 GitHub release: $npmName');
  }

  final release = await fetchReleaseData(updateUrl);
  final asset = pickPreferredPluginAsset(asJsonList(release['assets']));
  if (asset == null) {
    throw StateError('未找到可安装资源（仅支持 .cjs.br 或 .cjs）');
  }

  final downloadUrl = asset['browser_download_url']?.toString().trim() ?? '';
  if (downloadUrl.isEmpty) {
    throw StateError('release 资产缺少 browser_download_url');
  }

  final response = await downloadPluginAssetWithFallback(downloadUrl);
  final script = await decodeDownloadedPluginScript(
    response: response,
    resolvedUrl: downloadUrl,
  );
  final trimmed = script.trim();
  if (trimmed.isEmpty) {
    throw StateError('下载到的插件脚本为空');
  }
  return trimmed;
}

Future<FetchResponse> downloadPluginAssetWithFallback(String sourceUrl) async {
  final requestUrls = buildCloudRequestCandidates(sourceUrl);
  final client = WindHttp(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 30),
    followRedirects: true,
  );

  Object? lastError;
  for (final requestUrl in requestUrls) {
    try {
      final response = await client.fetch(
        requestUrl,
        headers: {'Accept': '*/*'},
      );
      if (!response.ok) {
        lastError = StateError('HTTP ${response.status}: $requestUrl');
        logger.w('插件资源下载通道 HTTP 异常: $requestUrl status=${response.status}');
        continue;
      }
      if (response.body.isEmpty) {
        lastError = StateError('空响应: $requestUrl');
        continue;
      }
      final htmlReason = _detectHtmlPluginResponse(response);
      if (htmlReason != null) {
        lastError = StateError('$htmlReason: $requestUrl');
        logger.w('插件资源下载通道返回网页: $requestUrl ($htmlReason)');
        continue;
      }
      return response;
    } catch (e, stackTrace) {
      lastError = e;
      logger.w('插件资源下载通道失败: $requestUrl', error: e, stackTrace: stackTrace);
    }
  }

  throw StateError('插件资源下载失败: $lastError');
}

Future<String> decodeDownloadedPluginScript({
  required FetchResponse response,
  required String resolvedUrl,
}) async {
  final body = response.body;
  if (body.isEmpty) {
    return '';
  }

  final lowerUrl = resolvedUrl.toLowerCase();
  final contentEncoding = (response.header('content-encoding') ?? '')
      .toLowerCase();
  final shouldUseBrotli =
      lowerUrl.endsWith('.br') || contentEncoding.contains('br');
  final script = await decodePluginScriptFromBytes(
    bytes: body,
    shouldUseBrotli: shouldUseBrotli,
  );
  if (script.trim().isNotEmpty && _isHtmlDocumentText(script)) {
    throw StateError('$_htmlInsteadOfScriptReason: $resolvedUrl');
  }
  return script;
}

Future<String> decodePluginScriptFromBytes({
  required List<int> bytes,
  required bool shouldUseBrotli,
}) async {
  if (bytes.isEmpty) {
    return '';
  }
  if (!shouldUseBrotli) {
    return utf8.decode(bytes, allowMalformed: true);
  }
  try {
    final decodedBytes = await decompressExtreme(data: bytes);
    return utf8.decode(decodedBytes, allowMalformed: true);
  } catch (e) {
    throw StateError('插件文件解压失败，可能已损坏或不是有效的压缩包: $e');
  }
}

Map<String, dynamic>? pickPreferredPluginAsset(List<dynamic> rawAssets) {
  final assets = rawAssets
      .map((item) => asJsonMap(item))
      .where(
        (item) =>
            (item['browser_download_url']?.toString().trim().isNotEmpty ??
                false) &&
            (item['name']?.toString().trim().isNotEmpty ?? false),
      )
      .toList();
  if (assets.isEmpty) {
    return null;
  }

  Map<String, dynamic>? findByExt(String ext) {
    for (final asset in assets) {
      final name = asset['name']?.toString().toLowerCase().trim() ?? '';
      if (name.endsWith(ext)) {
        return asset;
      }
    }
    return null;
  }

  return findByExt('.cjs.br') ?? findByExt('.cjs');
}

Future<Map<String, dynamic>> callGetInfoByGlobalQjs(String bundleJs) async {
  await PluginRegistryService.I.initializeGlobalRuntime();
  final bytes = await qjsTaskCall(
    runtimeName: 'global',
    taskGroupKey: '',
    isOnce: true,
    bundleJs: bundleJs,
    fnPath: 'getInfo',
    argsJson: '{}',
  );
  final raw = utf8.decode(bytes, allowMalformed: true);
  return requireJsonMap(jsonDecode(raw), message: 'getInfo 返回格式错误');
}

String readUuidFromInfo(Map<String, dynamic> info) {
  final uuid = info['uuid']?.toString().trim() ?? '';
  if (uuid.isNotEmpty) {
    return uuid;
  }
  final dataUuid = asJsonMap(info['data'])['uuid']?.toString().trim() ?? '';
  if (dataUuid.isNotEmpty) {
    return dataUuid;
  }
  return '';
}

String readVersionFromInfo(Map<String, dynamic> info) {
  final version = info['version']?.toString().trim() ?? '';
  if (version.isNotEmpty) {
    return version;
  }
  final dataVersion =
      asJsonMap(info['data'])['version']?.toString().trim() ?? '';
  if (dataVersion.isNotEmpty) {
    return dataVersion;
  }
  return '0.0.0';
}

bool isNetworkRetryableError(Object error) {
  if (error is TimeoutException ||
      error is SocketException ||
      error is HandshakeException) {
    return true;
  }
  final text = error.toString().toLowerCase();
  // 远端文件缺失 / 脚本非法：重试无意义，直接失败以便提示用户检查更新地址。
  // GitHub 限流相反：适合等配额恢复后重试，静默更新保持可重试。
  if (_looksLikeRateLimitText(text)) {
    return true;
  }
  const nonRetryable = [
    '远端返回了网页',
    'http 404',
    'http 401',
    'http 403',
    'bad status 404',
    'bad status 401',
    'bad status 403',
    '未找到可安装资源',
    '缺少 browser_download_url',
    'getinfo',
    '缺少 uuid',
    '脚本内容为空',
    '脚本为空',
    '插件已存在',
    'id 不一致',
    '请更换插件id',
  ];
  for (final marker in nonRetryable) {
    if (text.contains(marker)) {
      return false;
    }
  }
  return text.contains('socketexception') ||
      text.contains('timed out') ||
      text.contains('timeout') ||
      text.contains('connection reset') ||
      text.contains('connection refused') ||
      text.contains('network') ||
      text.contains('fetch failed') ||
      text.contains('download failed');
}

/// 远端返回网页时的统一原因文案（同时被错误归一识别）。
const _htmlInsteadOfScriptReason = '远端返回了网页而非插件文件';

/// 粗略判断文本是否为 HTML 文档（404 页面、CDN 错误页等）。
bool _isHtmlDocumentText(String text) {
  final lower = text.trimLeft().toLowerCase();
  return lower.startsWith('<!doctype html') ||
      lower.startsWith('<html') ||
      lower.startsWith('<head') ||
      lower.startsWith('<body');
}

/// 检测插件资源响应是否为 HTML 错误页；是则返回原因，否则返回 null。
String? _detectHtmlPluginResponse(FetchResponse response) {
  final contentType = (response.header('content-type') ?? '').toLowerCase();
  final declaresHtml =
      contentType.contains('text/html') ||
      contentType.contains('application/xhtml');
  final prefixLength = response.body.length > 2048
      ? 2048
      : response.body.length;
  final prefix = utf8.decode(
    response.body.sublist(0, prefixLength),
    allowMalformed: true,
  );
  if (_isHtmlDocumentText(prefix)) {
    return _htmlInsteadOfScriptReason;
  }
  if (declaresHtml && prefix.trimLeft().startsWith('<')) {
    return _htmlInsteadOfScriptReason;
  }
  return null;
}

int? _extractHttpStatusCode(String text) {
  final httpMatch = RegExp(
    r'http\s+(\d{3})',
    caseSensitive: false,
  ).firstMatch(text);
  if (httpMatch != null) {
    return int.tryParse(httpMatch.group(1)!);
  }
  final badStatusMatch = RegExp(
    r'bad status\s+(\d{3})',
    caseSensitive: false,
  ).firstMatch(text);
  return badStatusMatch == null ? null : int.tryParse(badStatusMatch.group(1)!);
}

/// 文本是否在说 GitHub API 限流（与 [github_proxy] 的判定保持同义词）。
bool _isRateLimitText(String text) {
  return _looksLikeRateLimitText(text.toLowerCase());
}

bool _looksLikeRateLimitText(String lower) {
  return lower.contains('github api 限流') ||
      lower.contains('rate limit') ||
      lower.contains('rate-limit') ||
      lower.contains('ratelimit') ||
      lower.contains('abuse') ||
      lower.contains('too many requests') ||
      ((lower.contains('http 403') || lower.contains('http 429')) &&
          lower.contains('exceeded'));
}

String _rawPluginErrorText(Object error) {
  final text = switch (error) {
    AnyhowException(message: final message) => message,
    StateError(message: final message) => message,
    _ => error.toString(),
  };
  var result = text.trim();
  const prefixes = [
    'Bad state: ',
    'Exception: ',
    'Invalid argument(s): ',
    'FormatException: ',
  ];
  final anyhowWrapper = RegExp(r'^AnyhowException\((.*)\)$', dotAll: true);
  var changed = true;
  while (changed) {
    changed = false;
    for (final prefix in prefixes) {
      if (result.startsWith(prefix)) {
        result = result.substring(prefix.length).trim();
        changed = true;
        break;
      }
    }
    final wrapped = anyhowWrapper.firstMatch(result);
    if (wrapped != null) {
      result = wrapped.group(1)!.trim();
      changed = true;
    }
  }
  return result;
}

String _truncateErrorDetail(String text) {
  final singleLine = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (singleLine.length <= 240) {
    return singleLine;
  }
  return '${singleLine.substring(0, 240)}…';
}

/// 将插件下载/安装异常转换为面向用户的友好提示。
///
/// 仅在 UI 展示层调用；重试判定仍应使用原始异常（见
/// [isNetworkRetryableError]），避免把 404 等不可重试错误误判为网络抖动。
String normalizePluginInstallErrorMessage(Object error) {
  final raw = _rawPluginErrorText(error);
  if (raw.isEmpty) {
    return t.error.operationFailed;
  }
  final lower = raw.toLowerCase();

  // 远端文件缺失：CDN / release / 直链返回了网页或 404。
  if (raw.contains(_htmlInsteadOfScriptReason) ||
      _isHtmlDocumentText(raw) ||
      lower.contains('<html') ||
      lower.contains('<!doctype')) {
    return t.plugin.remoteReturnedWebPage;
  }
  final httpStatus = _extractHttpStatusCode(raw);
  // 限流优先于 403/404 判定：GitHub IP 限流、滥用拦截、次级限流都是 403/429，
  // 文案必须提示稍后重试，而非让用户去检查更新地址。
  if (_isRateLimitText(raw)) {
    return t.plugin.githubRateLimited;
  }
  if (httpStatus != null) {
    if (httpStatus == 404) {
      return t.plugin.remoteAssetNotFound;
    }
    if (httpStatus == 401 || httpStatus == 403) {
      return t.plugin.remoteAccessDenied(status: httpStatus);
    }
    if (httpStatus >= 500 && httpStatus < 600) {
      return t.plugin.remoteServerError(status: httpStatus);
    }
    return t.plugin.remoteHttpError(status: httpStatus);
  }
  if (raw.contains('空响应') || lower.contains('脚本为空') || lower.contains('内容为空')) {
    return t.plugin.remoteEmptyResponse;
  }
  // HTML 被当成脚本执行：QJS 报 unexpected token '<' 等。
  if (lower.contains('unexpected token') ||
      lower.contains('unexpected character') ||
      lower.contains('unexpected end') ||
      lower.contains('syntaxerror') ||
      lower.contains('parse error') ||
      lower.contains('failed to parse')) {
    return t.plugin.downloadedScriptInvalid;
  }
  if (lower.contains('brotli') ||
      lower.contains('decompress') ||
      lower.contains('解压') ||
      lower.contains('corrupt') ||
      lower.contains('不是有效的压缩')) {
    return t.plugin.downloadedScriptCorrupted;
  }
  if (lower.contains('getinfo') || lower.contains('缺少 uuid')) {
    return t.plugin.downloadedScriptInvalid;
  }
  if (isNetworkRetryableError(error)) {
    return t.plugin.networkUnstableRetry;
  }
  return _truncateErrorDetail(raw);
}
