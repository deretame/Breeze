import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/utils/github_proxy.dart';
import 'package:zephyr/plugin/utils/plugin_cloud_download_utils.dart';
import 'package:zephyr/util/json/json_value.dart';

/// 从 getInfo 结果读取 npmName。
String readNpmNameFromInfo(Map<String, dynamic> info) {
  final npmName = info['npmName']?.toString().trim() ?? '';
  if (npmName.isNotEmpty) {
    return npmName;
  }
  return asJsonMap(info['data'])['npmName']?.toString().trim() ?? '';
}

/// 从 getInfo 结果读取 updateUrl。
String readUpdateUrlFromInfo(Map<String, dynamic> info) {
  final updateUrl = info['updateUrl']?.toString().trim() ?? '';
  if (updateUrl.isNotEmpty) {
    return updateUrl;
  }
  return asJsonMap(info['data'])['updateUrl']?.toString().trim() ?? '';
}

/// 解析 getInfo JSON 字符串。
Map<String, dynamic>? parseGetInfoJson(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  try {
    return requireJsonMap(jsonDecode(text), message: 'getInfoJson 格式错误');
  } catch (e, st) {
    logger.w('解析 getInfoJson 失败', error: e, stackTrace: st);
    return null;
  }
}

String encodeGetInfoJson(Map<String, dynamic> info) {
  return jsonEncode(info);
}

/// 按 npmmirror → jsdelivr → npm 官方 顺序查询 latest 版本。
Future<String> fetchNpmLatestVersion(String npmName) async {
  final name = npmName.trim();
  if (name.isEmpty) {
    throw ArgumentError('npmName 不能为空');
  }

  final encoded = Uri.encodeComponent(name);
  final candidates = <_NpmLatestCandidate>[
    _NpmLatestCandidate(
      url: 'https://registry.npmmirror.com/$encoded',
      readLatest: _readDistTagsLatest,
      label: 'npmmirror',
    ),
    _NpmLatestCandidate(
      url: 'https://data.jsdelivr.com/v1/package/npm/$encoded',
      readLatest: _readJsdelivrTagsLatest,
      label: 'jsdelivr',
    ),
    _NpmLatestCandidate(
      url: 'https://registry.npmjs.org/$encoded',
      readLatest: _readDistTagsLatest,
      label: 'npmjs',
    ),
  ];

  final client = WindHttp(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  );

  Object? lastError;
  for (final candidate in candidates) {
    try {
      final response = await client.fetch(
        candidate.url,
        headers: {'Accept': 'application/json'},
      );
      if (!response.ok) {
        throw StateError('HTTP ${response.status}');
      }
      final data = response.json;
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final latest = candidate.readLatest(map).trim();
      if (latest.isEmpty) {
        throw StateError('未返回 latest 版本');
      }
      logger.d('npm latest 命中: ${candidate.label} $name@$latest');
      return latest;
    } catch (e, st) {
      lastError = e;
      logger.w(
        'npm latest 查询失败: ${candidate.label} $name',
        error: e,
        stackTrace: st,
      );
    }
  }

  throw StateError('无法获取 npm latest 版本: $name, error: $lastError');
}

/// 通过 updateUrl 获取远端版本（GitHub Release 类 API 的 tag_name）。
Future<String> fetchUpdateUrlLatestVersion(String updateUrl) async {
  final release = await fetchReleaseData(updateUrl);
  final tagName = release['tag_name']?.toString().trim() ?? '';
  if (tagName.isNotEmpty) {
    return tagName;
  }
  final name = release['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) {
    return name;
  }
  throw StateError('release 响应缺少 tag_name/name: $updateUrl');
}

/// 解析插件自身更新通道的远端版本。
///
/// 优先 npmName；否则走 updateUrl。
Future<String> fetchSelfChannelLatestVersion({
  required String npmName,
  required String updateUrl,
}) async {
  final resolvedNpm = npmName.trim();
  if (resolvedNpm.isNotEmpty) {
    return fetchNpmLatestVersion(resolvedNpm);
  }
  final resolvedUrl = updateUrl.trim();
  if (resolvedUrl.isNotEmpty) {
    return fetchUpdateUrlLatestVersion(resolvedUrl);
  }
  throw StateError('插件未提供 npmName 或 updateUrl，无法检查更新');
}

/// 通过自身通道下载插件脚本。
Future<String> downloadPluginFromSelfChannel({
  required String npmName,
  required String updateUrl,
  required String remoteVersion,
}) async {
  return downloadFromJsdelivrOrGitHub(
    npmName: npmName.trim(),
    cloudVersion: remoteVersion.trim(),
    updateUrl: updateUrl.trim(),
  );
}

String _readDistTagsLatest(Map<String, dynamic> json) {
  return asJsonMap(json['dist-tags'])['latest']?.toString() ?? '';
}

String _readJsdelivrTagsLatest(Map<String, dynamic> json) {
  return asJsonMap(json['tags'])['latest']?.toString() ?? '';
}

class _NpmLatestCandidate {
  const _NpmLatestCandidate({
    required this.url,
    required this.readLatest,
    required this.label,
  });

  final String url;
  final String Function(Map<String, dynamic> json) readLatest;
  final String label;
}
