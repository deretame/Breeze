import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/utils/github_proxy.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/json/json_value.dart';

const _cloudPluginListDirectUrl =
    'https://raw.githubusercontent.com/deretame/Breeze-plugin-list/main/plugins_data.json';

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
  final client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  var version = 'latest';

  try {
    final temp = await client.get<Map<String, dynamic>>(
      'https://breeze-version.s3.bitiful.net/plugin-list-version.json',
    );

    version = temp.data?['version'] ?? 'latest';
  } catch (e) {
    logger.e(e);
    return fetchCloudPluginListPayload(_cloudPluginListDirectUrl);
  }

  for (final mirror in _ghCdnMirrors) {
    final url =
        '${mirror}gh/deretame/Breeze-plugin-list@$version/plugins_data.json';
    logger.d('尝试使用 GitHub CDN 镜像: $url');
    try {
      final response = await client.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json, text/plain, */*'},
        ),
      );
      final body = response.data?.trim() ?? '';
      if ((response.statusCode ?? 0) == 200 && body.isNotEmpty) {
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
  final client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  Object? lastError;
  for (final requestUrl in requestUrls) {
    try {
      final response = await client.get<String>(
        requestUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json, text/plain, */*'},
        ),
      );
      final body = response.data?.trim() ?? '';
      if ((response.statusCode ?? 0) == 200 && body.isNotEmpty) {
        return body;
      }
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

Future<Response<List<int>>> downloadPluginAssetWithFallback(
  String sourceUrl,
) async {
  final requestUrls = buildCloudRequestCandidates(sourceUrl);
  final client = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
    ),
  );

  Object? lastError;
  for (final requestUrl in requestUrls) {
    try {
      final response = await client.get<List<int>>(
        requestUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );
      final body = response.data ?? const <int>[];
      if (body.isNotEmpty) {
        return response;
      }
      lastError = StateError('空响应: $requestUrl');
    } catch (e, stackTrace) {
      lastError = e;
      logger.w('插件资源下载通道失败: $requestUrl', error: e, stackTrace: stackTrace);
    }
  }

  throw StateError('插件资源下载失败: $lastError');
}

Future<String> decodeDownloadedPluginScript({
  required Response<List<int>> response,
  required String resolvedUrl,
}) async {
  final body = response.data ?? const <int>[];
  if (body.isEmpty) {
    return '';
  }

  final lowerUrl = resolvedUrl.toLowerCase();
  final contentEncoding = (response.headers.value('content-encoding') ?? '')
      .toLowerCase();
  final shouldUseBrotli =
      lowerUrl.endsWith('.br') || contentEncoding.contains('br');
  return decodePluginScriptFromBytes(
    bytes: body,
    shouldUseBrotli: shouldUseBrotli,
  );
}

Future<String> decodePluginScriptFromBytes({
  required List<int> bytes,
  required bool shouldUseBrotli,
}) async {
  if (bytes.isEmpty) {
    return '';
  }
  final decodedBytes = shouldUseBrotli
      ? await decompressExtreme(data: bytes)
      : bytes;
  return utf8.decode(decodedBytes, allowMalformed: true);
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
  final raw = await qjsCallOnce(
    runtimeName: 'global',
    bundleJs: bundleJs,
    fnPath: 'getInfo',
    argsJson: '{}',
  );
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
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        return status >= 500 || status == 429 || status == 408;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }
  final text = error.toString().toLowerCase();
  return text.contains('socketexception') ||
      text.contains('timed out') ||
      text.contains('timeout') ||
      text.contains('connection reset') ||
      text.contains('connection refused') ||
      text.contains('network');
}
