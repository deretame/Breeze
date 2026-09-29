import 'dart:convert';

import 'package:zephyr/main.dart';

List<String> mirrorBaseUrls = [
  "https://v4.gh-proxy.org/",
  "https://gh-proxy.org/",
  "https://v6.gh-proxy.org/",
  "https://cdn.gh-proxy.org/",
];

const breezeLatestReleaseApi = 'https://api.windy-78.site/breeze';
const breezeGithubApi = 'https://api.windy-78.site/github';

const _breezeLatestReleaseUrl =
    'https://api.github.com/repos/deretame/Breeze/releases/latest';

bool isGithubApiUrl(String fullUrl) {
  final uri = Uri.tryParse(fullUrl.trim());
  if (uri == null) {
    return false;
  }
  return uri.host == 'api.github.com' || uri.host == 'www.api.github.com';
}

/// 传入 release 信息 URL。
///
/// - GitHub API（`api.github.com`）：自动走 gh-proxy 加速并回退直连
/// - 其它 URL：不走加速，直接请求（要求返回结构类似 GitHub Release API）
///
/// 示例输入: https://api.github.com/repos/deretame/Breeze/releases/latest
Future<Map<String, dynamic>> fetchReleaseData(String fullUrl) async {
  final resolvedUrl = fullUrl.trim();
  if (resolvedUrl.isEmpty) {
    throw ArgumentError('release URL 不能为空');
  }

  final List<String> urls;
  if (isGithubApiUrl(resolvedUrl)) {
    final repoPath = "/${resolvedUrl.split("api.github.com/")[1]}";
    final isBreezeLatest =
        resolvedUrl == _breezeLatestReleaseUrl ||
        repoPath == '/repos/deretame/Breeze/releases/latest';

    urls = [
      if (isBreezeLatest) breezeLatestReleaseApi,
      ...mirrorBaseUrls.map((base) => "${base}https://api.github.com$repoPath"),
      "https://api.github.com$repoPath",
    ];
  } else {
    // 非 GitHub API：禁止套代理，避免错误拼接加速路径
    urls = [resolvedUrl];
  }

  // GitHub API 强制要求 User-Agent，缺失会直接 403；同时声明 JSON。
  const headers = {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'Breeze',
  };

  dynamic lastError;
  dynamic firstDefinitive;
  dynamic firstNotFound;
  dynamic firstRateLimited;

  for (String url in urls) {
    try {
      final response = await fetch(url, headers: headers);

      if (response.ok) {
        final data = response.json;
        if (data is Map<String, dynamic>) {
          return data;
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        lastError = StateError('release 响应格式错误: $url');
      } else {
        final body = response.text.trim();
        final apiMessage = _extractGithubApiMessage(body);
        final snippet = body.replaceAll(RegExp(r'\s+'), ' ');
        final truncated = snippet.length > 200
            ? '${snippet.substring(0, 200)}…'
            : snippet;
        if (apiMessage != null && apiMessage.isNotEmpty) {
          final rateLimited = _isGithubRateLimitResponse(
            status: response.status,
            message: apiMessage,
            reset: response.header('x-ratelimit-reset'),
            remaining: response.header('x-ratelimit-remaining'),
            retryAfter: response.header('retry-after'),
          );
          final resetHint = _formatRateLimitResetHint(
            response.header('x-ratelimit-reset'),
            response.header('retry-after'),
          );
          final marker = rateLimited ? 'GitHub API 限流' : apiMessage;
          lastError = StateError(
            'HTTP ${response.status} $marker'
            '${resetHint.isEmpty ? '' : ' $resetHint'}: $url',
          );
          // GitHub 返回的 JSON 定论（404 不存在 / 403 限流）比代理通道的
          // 连接错误更有信息量，优先作为最终错误透出；404 不存在优先于限流，
          // 因为能到达 GitHub 并返回 404 的通道已经证明远端确实缺失。
          if (_isDefinitiveGithubStatus(response.status)) {
            firstDefinitive ??= lastError;
            final isNotFound =
                response.status == 404 &&
                apiMessage.toLowerCase().contains('not found');
            if (isNotFound) {
              firstNotFound ??= lastError;
            } else if (rateLimited) {
              firstRateLimited ??= lastError;
            }
          }
        } else {
          lastError = StateError('HTTP ${response.status}: $url');
        }
        logger.w(
          'release 通道 HTTP 异常: $url status=${response.status} $truncated',
        );
      }
    } catch (e) {
      logger.e(e);
      lastError = e;
      continue;
    }
  }

  throw Exception(
    '所有加速通道均失效。末次错误: '
    '${firstNotFound ?? firstRateLimited ?? firstDefinitive ?? lastError}',
  );
}

/// 从 GitHub Release 类 API 的错误正文提取 message 字段。
///
/// 仓库/release 不存在返回 `{"message":"Not Found",...}`（HTTP 404）；
/// IP 被限流或触发滥用检测返回 403 且 message 含 rate limit/abuse。
String? _extractGithubApiMessage(String body) {
  if (body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      final message = decoded['message']?.toString().trim() ?? '';
      return message.isEmpty ? null : message;
    }
  } catch (_) {
    // 非 JSON（代理的 HTML 错误页等）：无 message 可提取。
  }
  return null;
}

/// GitHub 返回的 JSON 错误是否属于“定论”（应优先透出而非被代理错误覆盖）。
bool _isDefinitiveGithubStatus(int status) {
  return status == 401 ||
      status == 403 ||
      status == 404 ||
      status == 422 ||
      status == 429;
}

/// 判断 release 错误是否为 GitHub API 限流/滥用拦截。
///
/// 典型 message：`API rate limit exceeded`、`You have exceeded a secondary rate
/// limit`、`abuse detection mechanism`；同时看 `x-ratelimit-remaining: 0`。
bool _isGithubRateLimitResponse({
  required int status,
  required String message,
  String? reset,
  String? remaining,
  String? retryAfter,
}) {
  if (status == 429) return true;
  if (retryAfter != null && retryAfter.trim().isNotEmpty) return true;
  final remainingValue = int.tryParse((remaining ?? '').trim());
  if (remainingValue != null && remainingValue <= 0) return true;
  if (status != 403) return false;
  final lower = message.toLowerCase();
  return lower.contains('rate limit') ||
      lower.contains('rate-limit') ||
      lower.contains('ratelimit') ||
      lower.contains('abuse') ||
      lower.contains('too many requests') ||
      lower.contains('exceeded');
}

/// 由 `x-ratelimit-reset`（秒时间戳）或 `retry-after` 生成“n 分钟后重试”提示。
String _formatRateLimitResetHint(String? resetRaw, String? retryAfterRaw) {
  final retryAfterSeconds = int.tryParse((retryAfterRaw ?? '').trim());
  if (retryAfterSeconds != null && retryAfterSeconds > 0) {
    final minutes = (retryAfterSeconds / 60).ceil();
    return '约 $minutes 分钟后可重试';
  }
  final resetSeconds = int.tryParse((resetRaw ?? '').trim());
  if (resetSeconds == null || resetSeconds <= 0) return '';
  final wait = DateTime.fromMillisecondsSinceEpoch(
    resetSeconds * 1000,
    isUtc: true,
  ).difference(DateTime.now().toUtc());
  if (wait.isNegative || wait.inSeconds <= 0) return '';
  final minutes = (wait.inSeconds / 60).ceil();
  return '约 $minutes 分钟后可重试';
}

/// 自动加速下载函数
Future<void> smartDownload(String url, String savePath) async {
  final client = WindHttp(
    connectTimeout: const Duration(seconds: 15),
    followRedirects: true,
  );

  final githubRegex = RegExp(
    r'^https://github\.com/[\w.-]+/[\w.-]+/releases/download/[\w.-]+/.*$',
    caseSensitive: false,
  );

  final List<String> downloadUrls = githubRegex.hasMatch(url)
      ? [...mirrorBaseUrls.map((base) => "$base$url"), url]
      : [url];

  if (githubRegex.hasMatch(url)) {
    logger.d("检测到 GitHub Release 链接，已规划加速路径");
  } else {
    logger.d("非标准下载链接，跳过代理直接请求");
  }

  dynamic lastError;

  for (String downloadUrl in downloadUrls) {
    try {
      logger.d("正在尝试下载通道: $downloadUrl");
      await client.download(downloadUrl, savePath);
      logger.d("✅ 下载成功，保存至: $savePath");
      return;
    } catch (e) {
      lastError = e;
      logger.w("⚠️ 通道失败 ($downloadUrl): $e");
      continue;
    }
  }

  logger.e("🚨 所有下载通道均已尝试失败");
  throw Exception("Download failed after all attempts. Last error: $lastError");
}
