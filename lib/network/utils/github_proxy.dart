import 'package:zephyr/main.dart';

List<String> mirrorBaseUrls = [
  "https://v4.gh-proxy.org/",
  "https://gh-proxy.org/",
  "https://v6.gh-proxy.org/",
  "https://cdn.gh-proxy.org/",
];

const breezeLatestReleaseApi = 'https://api.windy-78.site/breeze';

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

  dynamic lastError;

  for (String url in urls) {
    try {
      final response = await fetch(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.ok) {
        final data = response.json;
        if (data is Map<String, dynamic>) {
          return data;
        }
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      logger.e(e);
      lastError = e;
      continue;
    }
  }

  throw Exception("所有加速通道均失效。末次错误: $lastError");
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
