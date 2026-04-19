import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';

/// 传入标准的 GitHub API URL，函数自动处理降级和代理
/// 示例输入: https://api.github.com/repos/deretame/Breeze/releases/latest
Future<Map<String, dynamic>> fetchReleaseData(String fullUrl) async {
  final dio = Dio();

  String repoPath = fullUrl;
  if (fullUrl.contains("api.github.com")) {
    repoPath = "/${fullUrl.split("api.github.com/")[1]}";
  }

  final List<String> urls = [
    "https://api.windy-78.xyz/proxy?path=$repoPath", // 私有加速 (Rust)
    "https://gh-proxy.org/https://api.github.com$repoPath", // 公共代理
    "https://api.github.com$repoPath", // 官方直连
  ];

  dynamic lastError;

  for (String url in urls) {
    try {
      final response = await dio.get(
        url,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      logger.e(e);
      lastError = e;
      continue; // 失败则尝试列表中的下一个
    }
  }

  throw Exception("所有加速通道均失效。末次错误: $lastError");
}

/// 自动加速下载函数
/// [url] 原始 GitHub 下载链接
/// [savePath] 本地保存路径
Future<void> smartDownload(String url, String savePath) async {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      followRedirects: true,
    ),
  );

  // 正则匹配：GitHub Release 下载直链
  final githubRegex = RegExp(
    r'^https://github\.com/[\w.-]+/[\w.-]+/releases/download/[\w.-]+/.*$',
    caseSensitive: false,
  );

  List<String> downloadUrls = [];

  if (githubRegex.hasMatch(url)) {
    downloadUrls = ["https://gh-proxy.org/$url", url];
    logger.d("检测到 GitHub Release 链接，已规划加速路径");
  } else {
    downloadUrls = [url];
    logger.d("非标准下载链接，跳过代理直接请求");
  }

  dynamic lastError;

  for (String downloadUrl in downloadUrls) {
    try {
      logger.d("正在尝试下载通道: $downloadUrl");

      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {}
        },
      );

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
