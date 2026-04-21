import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/github_proxy.dart';
import 'package:zephyr/util/json/json_value.dart';

class PluginRuntimeState {
  const PluginRuntimeState({
    required this.uuid,
    required this.version,
    required this.originScript,
    required this.isEnabled,
    required this.isDeleted,
    required this.debug,
    required this.debugUrl,
    required this.lastLoadSuccess,
    required this.lastLoadError,
    required this.insertedAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  final String uuid;
  final String version;
  final String originScript;
  final bool isEnabled;
  final bool isDeleted;
  final bool debug;
  final String? debugUrl;
  final bool lastLoadSuccess;
  final String? lastLoadError;
  final DateTime insertedAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isActive => isEnabled && !isDeleted;

  PluginRuntimeState copyWith({
    String? version,
    String? originScript,
    bool? isEnabled,
    bool? isDeleted,
    bool? debug,
    String? debugUrl,
    bool? lastLoadSuccess,
    String? lastLoadError,
    DateTime? insertedAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return PluginRuntimeState(
      uuid: uuid,
      version: version ?? this.version,
      originScript: originScript ?? this.originScript,
      isEnabled: isEnabled ?? this.isEnabled,
      isDeleted: isDeleted ?? this.isDeleted,
      debug: debug ?? this.debug,
      debugUrl: debugUrl ?? this.debugUrl,
      lastLoadSuccess: lastLoadSuccess ?? this.lastLoadSuccess,
      lastLoadError: lastLoadError,
      insertedAt: insertedAt ?? this.insertedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt,
    );
  }
}

class PluginRegistryService {
  PluginRegistryService._();

  static final PluginRegistryService I = PluginRegistryService._();
  static const String _cloudPluginListUrl =
      'https://raw.githubusercontent.com/deretame/Breeze-plugin-list/main/plugins_data.json';

  final Map<String, PluginRuntimeState> _states = {};
  final _streamController =
      StreamController<Map<String, PluginRuntimeState>>.broadcast();
  ObjectBox? _objectbox;
  final Map<String, Map<String, dynamic>> _pluginInfoCache = {};
  final Set<String> _pluginInitDone = <String>{};
  Timer? _silentCloudUpdateTimer;
  bool _silentCloudUpdateScheduled = false;
  bool _silentCloudUpdateRunning = false;

  Stream<Map<String, PluginRuntimeState>> get stream =>
      _streamController.stream;

  Map<String, PluginRuntimeState> get snapshot => Map.unmodifiable(_states);

  PluginRuntimeState? getByUuid(String uuid) => _states[uuid];

  Map<String, dynamic>? getCachedPluginInfo(String uuid) =>
      _pluginInfoCache[uuid];

  Future<void> init() async {
    _objectbox = objectbox;
    await refreshFromDb();
  }

  Future<void> refreshFromDb() async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    final list = objectbox.pluginInfoBox.getAll();
    _states
      ..clear()
      ..addEntries(list.map((item) => MapEntry(item.uuid, _toState(item))));
    _emit();
  }

  Future<void> reconcileAfterExternalSync({
    Map<String, PluginRuntimeState>? previousSnapshot,
  }) async {
    final previous = Map<String, PluginRuntimeState>.from(
      previousSnapshot ?? snapshot,
    );
    logger.d('[plugin-sync] reconcile_start previous=${previous.length}');

    await refreshFromDb();

    final current = snapshot;
    final affected = <String>{...previous.keys, ...current.keys}.where((uuid) {
      final before = previous[uuid];
      final after = current[uuid];
      if (before == null || after == null) {
        return true;
      }
      return before.version != after.version ||
          before.originScript != after.originScript ||
          before.isEnabled != after.isEnabled ||
          before.isDeleted != after.isDeleted ||
          before.debug != after.debug ||
          before.debugUrl != after.debugUrl;
    }).toList();
    logger.d(
      '[plugin-sync] reconcile_diff current=${current.length} '
      'affected=${affected.length} uuids=${affected.join(',')}',
    );

    for (final uuid in affected) {
      _pluginInfoCache.remove(uuid);
      _pluginInitDone.remove(uuid);

      final runtimeName = resolveRuntimeName(uuid);
      try {
        final runtimeReady = await isQjsRuntimeInitialized(name: runtimeName);
        if (runtimeReady) {
          await qjsDropRuntime(runtimeName: runtimeName);
        }
      } catch (e, st) {
        logger.w('同步后清理插件 runtime 失败: $uuid', error: e, stackTrace: st);
      }
    }

    for (final uuid in affected) {
      final plugin = current[uuid];
      if (plugin == null || !plugin.isActive) {
        continue;
      }

      final runtimeName = resolveRuntimeName(uuid);
      try {
        await _ensurePluginRuntimeReady(plugin, runtimeName: runtimeName);
        await _runPluginInitIfNeeded(plugin, runtimeName: runtimeName);
      } catch (e, st) {
        logger.w('同步后重建插件 runtime 失败: $uuid', error: e, stackTrace: st);
      }
    }
    logger.d(
      '[plugin-sync] reconcile_done active=${current.values.where((e) => e.isActive).length}',
    );
  }

  Future<void> initializeGlobalRuntime() async {
    const globalRuntimeName = 'global';
    final ready = await isQjsRuntimeInitialized(name: globalRuntimeName);
    if (!ready) {
      await initQjsRuntime(name: globalRuntimeName);
    }
  }

  Future<void> initializeActivePluginRuntimes() async {
    final plugins = updateCheckTargets();
    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        await _ensurePluginRuntimeReady(plugin, runtimeName: runtimeName);
      }),
      eagerError: false,
    );

    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        await _runPluginInitIfNeeded(plugin, runtimeName: runtimeName);
      }),
      eagerError: false,
    );
  }

  Future<void> warmupPluginInfos() async {
    await initializeGlobalRuntime();
    final plugins = updateCheckTargets();
    await Future.wait(
      plugins.map((plugin) async {
        final runtimeName = resolveRuntimeName(plugin.uuid);
        try {
          await fetchPluginInfo(uuid: plugin.uuid, runtimeName: runtimeName);
        } catch (e) {
          await updateLoadResult(
            plugin.uuid,
            success: false,
            error: e.toString(),
          );
        }
      }),
      eagerError: false,
    );
  }

  void scheduleSilentCloudUpdate({
    Duration delay = const Duration(minutes: 5),
  }) {
    if (_silentCloudUpdateScheduled) {
      return;
    }
    _silentCloudUpdateScheduled = true;
    _silentCloudUpdateTimer?.cancel();
    _silentCloudUpdateTimer = Timer(delay, () {
      unawaited(_runSilentCloudUpdateOnce());
    });
  }

  Future<void> _runSilentCloudUpdateOnce() async {
    if (_silentCloudUpdateRunning) {
      return;
    }
    _silentCloudUpdateRunning = true;
    try {
      await _silentUpdateFromCloud();
    } catch (e, st) {
      logger.w('静默更新插件失败', error: e, stackTrace: st);
    } finally {
      _silentCloudUpdateRunning = false;
    }
  }

  Future<void> _silentUpdateFromCloud() async {
    final localPlugins = _states.values
        .where((item) => !item.isDeleted)
        .toList();
    if (localPlugins.isEmpty) {
      return;
    }

    final cloudItems = await _fetchCloudPluginCatalog();
    if (cloudItems.isEmpty) {
      return;
    }

    final cloudByUuid = <String, _CloudPluginCatalogItem>{
      for (final item in cloudItems)
        if (item.manifest.uuid.trim().isNotEmpty)
          item.manifest.uuid.trim(): item,
    };

    int updatedCount = 0;
    for (final local in localPlugins) {
      final cloud = cloudByUuid[local.uuid];
      if (cloud == null) {
        continue;
      }
      final updateUrl = cloud.manifest.updateUrl.trim();
      if (updateUrl.isEmpty) {
        continue;
      }
      if (!_shouldUpdateVersion(
        localVersion: local.version,
        cloudVersion: cloud.manifest.version,
      )) {
        continue;
      }

      try {
        final payload = await _downloadCloudPluginUpdate(
          repo: cloud.repo,
          updateUrl: updateUrl,
          expectedUuid: local.uuid,
          cloudVersion: cloud.manifest.version,
        );
        await _applyPluginUpdate(local: local, payload: payload);
        updatedCount++;
        logger.i(
          '插件静默更新成功: ${local.uuid} -> ${payload.version} (${payload.sourceLabel})',
        );
      } catch (e, st) {
        logger.w('插件静默更新失败: ${local.uuid}', error: e, stackTrace: st);
      }
    }

    if (updatedCount > 0) {
      logger.i('插件静默更新完成，共更新 $updatedCount 个插件');
    }
  }

  Future<Map<String, dynamic>> fetchPluginInfo({
    required String uuid,
    required String runtimeName,
  }) async {
    final plugin = _states[uuid];
    if (plugin == null || plugin.isDeleted) {
      throw StateError('插件不可用: $uuid');
    }

    final onceRuntimeName = 'plugin_info_${uuid.replaceAll('-', '_')}';
    final bundleJs = await _resolveBundleJs(plugin);
    final raw = await qjsCallOnce(
      runtimeName: onceRuntimeName,
      bundleJs: bundleJs,
      fnPath: 'getInfo',
      argsJson: '{}',
    );
    final decoded = requireJsonMap(jsonDecode(raw));
    _pluginInfoCache[uuid] = decoded;
    await updateLoadResult(uuid, success: true, error: null);
    return decoded;
  }

  List<PluginRuntimeState> activePlugins() {
    return _states.values.where((item) => item.isActive).toList()
      ..sort((a, b) => a.insertedAt.compareTo(b.insertedAt));
  }

  List<PluginRuntimeState> updateCheckTargets() {
    return activePlugins();
  }

  Future<void> runForUpdateTargets(
    Future<void> Function(PluginRuntimeState plugin) task,
  ) async {
    final targets = updateCheckTargets();
    for (final plugin in targets) {
      await task(plugin);
    }
  }

  Future<List<_CloudPluginCatalogItem>> _fetchCloudPluginCatalog() async {
    final payload = await _fetchCloudPluginListPayload(_cloudPluginListUrl);
    final decoded = jsonDecode(payload);
    return asJsonList(decoded)
        .map((item) => _CloudPluginCatalogItem.fromJson(asJsonMap(item)))
        .where((item) => item.manifest.uuid.trim().isNotEmpty)
        .toList();
  }

  Future<String> _fetchCloudPluginListPayload(String sourceUrl) async {
    final requestUrls = _buildCloudRequestCandidates(sourceUrl);
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
      } catch (e, st) {
        lastError = e;
        logger.w('云端插件列表通道失败: $requestUrl', error: e, stackTrace: st);
      }
    }

    throw StateError('云端插件列表全部通道不可用: $lastError');
  }

  List<String> _buildCloudRequestCandidates(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    final result = <String>[];
    if (uri != null) {
      final isGithubHost =
          uri.host == 'raw.githubusercontent.com' ||
          uri.host == 'github.com' ||
          uri.host == 'www.github.com';
      if (isGithubHost) {
        result.add('https://gh-proxy.org/$sourceUrl');
      }
    }
    result.add(sourceUrl);
    return result.toSet().toList();
  }

  bool _shouldUpdateVersion({
    required String localVersion,
    required String cloudVersion,
  }) {
    return _compareVersion(cloudVersion, localVersion) > 0;
  }

  int _compareVersion(String leftRaw, String rightRaw) {
    final left = _tokenizeVersion(leftRaw);
    final right = _tokenizeVersion(rightRaw);
    final max = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < max; i++) {
      final leftToken = i < left.length ? left[i] : 0;
      final rightToken = i < right.length ? right[i] : 0;

      if (leftToken is int && rightToken is int) {
        if (leftToken != rightToken) {
          return leftToken.compareTo(rightToken);
        }
        continue;
      }
      if (leftToken is String && rightToken is String) {
        final cmp = leftToken.compareTo(rightToken);
        if (cmp != 0) {
          return cmp;
        }
        continue;
      }

      if (leftToken is int && rightToken is String) {
        return 1;
      }
      if (leftToken is String && rightToken is int) {
        return -1;
      }
    }
    return 0;
  }

  List<Object> _tokenizeVersion(String raw) {
    var normalized = raw.trim();
    if (normalized.isEmpty) {
      return const <Object>[0];
    }
    if (normalized.length >= 2 &&
        (normalized.startsWith('v') || normalized.startsWith('V')) &&
        RegExp(r'[0-9A-Za-z]').hasMatch(normalized[1])) {
      normalized = normalized.substring(1);
    }
    final parts = RegExp(
      r'[0-9]+|[A-Za-z]+',
    ).allMatches(normalized).map((match) => match.group(0)!).toList();
    if (parts.isEmpty) {
      return <Object>[normalized.toLowerCase()];
    }
    return parts
        .map((part) => int.tryParse(part) ?? part.toLowerCase())
        .toList();
  }

  Future<_PluginUpdatePayload> _downloadCloudPluginUpdate({
    required String repo,
    required String updateUrl,
    required String expectedUuid,
    required String cloudVersion,
  }) async {
    final release = await fetchReleaseData(updateUrl);
    final asset = _pickPreferredPluginAsset(asJsonList(release['assets']));
    if (asset == null) {
      throw StateError('未找到可安装资产（只支持 .cjs.br 或 .cjs）');
    }

    final assetName = asset['name']?.toString().trim() ?? '';
    final downloadUrl = asset['browser_download_url']?.toString().trim() ?? '';
    if (downloadUrl.isEmpty) {
      throw StateError('release 资产缺少 browser_download_url');
    }

    final response = await _downloadPluginAssetWithFallback(downloadUrl);
    final script = await _decodeDownloadedPluginScript(
      response: response,
      resolvedUrl: downloadUrl,
    );
    final trimmed = script.trim();
    if (trimmed.isEmpty) {
      throw StateError('下载到的插件脚本为空');
    }

    final info = await _callGetInfoByGlobalQjs(trimmed);
    final resolvedUuid = _readUuidFromInfo(info);
    if (resolvedUuid != expectedUuid) {
      throw StateError('更新脚本 uuid 不匹配，期望=$expectedUuid, 实际=$resolvedUuid');
    }
    final resolvedVersion = _readVersionFromInfo(info);

    return _PluginUpdatePayload(
      uuid: resolvedUuid,
      version: resolvedVersion.isNotEmpty ? resolvedVersion : cloudVersion,
      script: trimmed,
      sourceLabel: '静默更新: $repo${assetName.isNotEmpty ? '/$assetName' : ''}',
    );
  }

  Map<String, dynamic>? _pickPreferredPluginAsset(List<dynamic> rawAssets) {
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

  Future<Response<List<int>>> _downloadPluginAssetWithFallback(
    String sourceUrl,
  ) async {
    final requestUrls = _buildCloudRequestCandidates(sourceUrl);
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
      } catch (e, st) {
        lastError = e;
        logger.w('插件下载通道失败: $requestUrl', error: e, stackTrace: st);
      }
    }

    throw StateError('插件下载失败: $lastError');
  }

  Future<String> _decodeDownloadedPluginScript({
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
    return _decodePluginScriptFromBytes(
      bytes: body,
      shouldUseBrotli: shouldUseBrotli,
    );
  }

  Future<String> _decodePluginScriptFromBytes({
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

  Future<Map<String, dynamic>> _callGetInfoByGlobalQjs(String bundleJs) async {
    await initializeGlobalRuntime();
    final raw = await qjsCallOnce(
      runtimeName: 'global',
      bundleJs: bundleJs,
      fnPath: 'getInfo',
      argsJson: '{}',
    );
    return requireJsonMap(jsonDecode(raw), message: 'getInfo 返回格式错误');
  }

  String _readUuidFromInfo(Map<String, dynamic> info) {
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

  String _readVersionFromInfo(Map<String, dynamic> info) {
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

  Future<void> _applyPluginUpdate({
    required PluginRuntimeState local,
    required _PluginUpdatePayload payload,
  }) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(local.uuid))
        .build()
        .findFirst();
    final now = DateTime.now().toUtc();
    final toSave = PluginInfo(
      id: found?.id ?? 0,
      uuid: payload.uuid,
      version: payload.version,
      originScript: payload.script,
      insertedAt: found?.insertedAt ?? local.insertedAt,
      updatedAt: now,
      isEnabled: found?.isEnabled ?? local.isEnabled,
      isDeleted: false,
      deletedAt: null,
      lastLoadSuccess: false,
      lastLoadError: null,
      debug: found?.debug ?? local.debug,
      debugUrl: found?.debugUrl ?? local.debugUrl,
    );
    await upsert(toSave);
    _pluginInfoCache.remove(payload.uuid);
    _pluginInitDone.remove(payload.uuid);

    final latest = _states[payload.uuid];
    if (latest == null) {
      return;
    }

    if (latest.isEnabled) {
      final runtimeName = resolveRuntimeName(payload.uuid);
      await _ensurePluginRuntimeReady(latest, runtimeName: runtimeName);
      await _runPluginInitIfNeeded(latest, runtimeName: runtimeName);
    }
  }

  Future<void> upsert(PluginInfo info) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    objectbox.pluginInfoBox.put(info);
    _states[info.uuid] = _toState(info);
    if (info.isDeleted) {
      _pluginInfoCache.remove(info.uuid);
    }
    _emit();
  }

  Future<void> setEnabled(String uuid, bool enabled) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      return;
    }
    found.isEnabled = enabled;
    found.updatedAt = DateTime.now().toUtc();
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _emit();

    if (enabled) {
      final runtimeName = resolveRuntimeName(uuid);
      await _ensurePluginRuntimeReady(_states[uuid]!, runtimeName: runtimeName);
      await _runPluginInitIfNeeded(_states[uuid]!, runtimeName: runtimeName);
    }
  }

  Future<void> updateLoadResult(
    String uuid, {
    required bool success,
    String? error,
  }) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      return;
    }
    found.lastLoadSuccess = success;
    found.lastLoadError = error;
    found.updatedAt = DateTime.now().toUtc();
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _emit();
  }

  Future<void> updateDebugConfig(
    String uuid, {
    required bool debug,
    String? debugUrl,
  }) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      return;
    }
    found.debug = debug;
    found.debugUrl = debugUrl?.trim().isEmpty == true ? null : debugUrl?.trim();
    found.updatedAt = DateTime.now().toUtc();
    objectbox.pluginInfoBox.put(found);
    _states[uuid] = _toState(found);
    _pluginInfoCache.remove(uuid);
    _pluginInitDone.remove(uuid);
    _emit();
  }

  Future<void> deletePlugin(String uuid) async {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }
    final found = objectbox.pluginInfoBox
        .query(PluginInfo_.uuid.equals(uuid))
        .build()
        .findFirst();
    if (found == null) {
      throw StateError('插件不存在: $uuid');
    }

    await _deletePluginDownloadFolders(uuid);
    _deletePluginRelatedData(uuid);

    final runtimeName = resolveRuntimeName(uuid);
    try {
      final runtimeReady = await isQjsRuntimeInitialized(name: runtimeName);
      if (runtimeReady) {
        await qjsDropRuntime(runtimeName: runtimeName);
      }
    } catch (_) {
      // runtime 失败不阻断删除主流程
    }

    objectbox.pluginInfoBox.remove(found.id);
    _states.remove(uuid);
    _pluginInfoCache.remove(uuid);
    _pluginInitDone.remove(uuid);
    _emit();
  }

  Future<void> _deletePluginDownloadFolders(String uuid) async {
    final downloadRoot = await getDownloadPath();
    final root = p.join(downloadRoot, uuid);
    final directory = Directory(root);
    final exists = await directory.exists();
    if (!exists) {
      return;
    }
    try {
      await directory.delete(recursive: true);
    } catch (e) {
      throw StateError('删除下载目录失败: $root, error: $e');
    }
  }

  void _deletePluginRelatedData(String uuid) {
    final objectbox = _objectbox;
    if (objectbox == null) {
      return;
    }

    _deletePluginConfigs(objectbox, uuid);
    objectbox.unifiedFavoriteBox
        .query(UnifiedComicFavorite_.source.equals(uuid))
        .build()
        .remove();
    objectbox.unifiedHistoryBox
        .query(UnifiedComicHistory_.source.equals(uuid))
        .build()
        .remove();
    objectbox.unifiedDownloadBox
        .query(UnifiedComicDownload_.source.equals(uuid))
        .build()
        .remove();
  }

  void _deletePluginConfigs(ObjectBox objectbox, String uuid) {
    final candidateNames = _buildPluginConfigNameCandidates(uuid);
    if (candidateNames.isEmpty) {
      return;
    }

    final idsToDelete = objectbox.pluginConfigBox
        .getAll()
        .where((item) => candidateNames.contains(item.name.trim()))
        .map((item) => item.id)
        .toList();
    if (idsToDelete.isEmpty) {
      return;
    }
    objectbox.pluginConfigBox.removeMany(idsToDelete);
  }

  Set<String> _buildPluginConfigNameCandidates(String uuid) {
    final candidates = <String>{};
    for (final raw in <String>{uuid, resolveRuntimeName(uuid)}) {
      for (final normalized in _normalizePluginNameCandidates(raw)) {
        candidates.add(normalized);
        candidates.add('($normalized)');
        final onceRuntime = 'plugin_info_${normalized.replaceAll('-', '_')}';
        candidates.add(onceRuntime);
        candidates.add('($onceRuntime)');
      }
    }
    return candidates.where((item) => item.trim().isNotEmpty).toSet();
  }

  Set<String> _normalizePluginNameCandidates(String raw) {
    final names = <String>{};
    var value = raw.trim();
    if (value.isEmpty) {
      return names;
    }
    names.add(value);

    while (value.length >= 2 && value.startsWith('(') && value.endsWith(')')) {
      value = value.substring(1, value.length - 1).trim();
      if (value.isEmpty) {
        break;
      }
      names.add(value);
    }

    return names;
  }

  String resolveRuntimeName(String uuid) {
    return uuid;
  }

  Future<void> _ensurePluginRuntimeReady(
    PluginRuntimeState plugin, {
    required String runtimeName,
  }) async {
    final bundleJs = await _resolveBundleJs(plugin);
    await initQjsRuntimeWithBundle(
      runtimeName: runtimeName,
      bundleName: runtimeName,
      bundleJs: bundleJs,
    );
    _pluginInitDone.remove(plugin.uuid);
  }

  Future<void> _runPluginInitIfNeeded(
    PluginRuntimeState plugin, {
    required String runtimeName,
  }) async {
    if (_pluginInitDone.contains(plugin.uuid)) {
      return;
    }

    try {
      await callUnifiedComicPlugin(
        pluginId: runtimeName,
        fnPath: 'init',
        core: {},
      );
      _pluginInitDone.add(plugin.uuid);
      await updateLoadResult(plugin.uuid, success: true, error: null);
    } catch (e) {
      final err = e.toString();
      if (err.contains('target is not function: init')) {
        _pluginInitDone.add(plugin.uuid);
        logger.w('插件未实现 init，已跳过: ${plugin.uuid}');
        return;
      }
      await updateLoadResult(
        plugin.uuid,
        success: false,
        error: 'init 执行失败: $e',
      );
      logger.w('插件 init 执行失败: ${plugin.uuid}', error: e);
    }
  }

  Future<String> _resolveBundleJs(PluginRuntimeState plugin) async {
    if (plugin.debug && (plugin.debugUrl?.trim().isNotEmpty ?? false)) {
      try {
        final response = await directDio.get(plugin.debugUrl!.trim());
        final debugBundle = response.data?.toString() ?? '';
        if (debugBundle.trim().isNotEmpty) {
          logger.d('[plugin-bundle] source=debugUrl plugin=${plugin.uuid}');
          return debugBundle;
        }
        throw StateError('debug bundle 为空');
      } catch (e) {
        await updateLoadResult(
          plugin.uuid,
          success: false,
          error: 'debug bundle 拉取失败: $e',
        );
        logger.w('debug bundle 拉取失败，回退数据库: ${plugin.uuid}', error: e);
      }
    }

    final dbBundle = _loadPluginBundleFromDb(plugin.uuid);
    if (dbBundle != null) {
      logger.d('[plugin-bundle] source=db plugin=${plugin.uuid}');
      return dbBundle;
    }

    throw StateError('bundle_js不能为空: ${plugin.uuid}');
  }

  String? _loadPluginBundleFromDb(String pluginId) {
    final text = _states[pluginId]?.originScript ?? '';
    if (text.trim().isEmpty) {
      return null;
    }
    return text;
  }

  PluginRuntimeState _toState(PluginInfo item) {
    return PluginRuntimeState(
      uuid: item.uuid,
      version: item.version,
      originScript: item.originScript,
      isEnabled: item.isEnabled,
      isDeleted: item.isDeleted,
      debug: item.debug,
      debugUrl: item.debugUrl,
      lastLoadSuccess: item.lastLoadSuccess,
      lastLoadError: item.lastLoadError,
      insertedAt: item.insertedAt,
      updatedAt: item.updatedAt,
      deletedAt: item.deletedAt,
    );
  }

  void _emit() {
    _streamController.add(snapshot);
  }
}

class _CloudPluginCatalogItem {
  const _CloudPluginCatalogItem({required this.repo, required this.manifest});

  final String repo;
  final _CloudPluginManifest manifest;

  factory _CloudPluginCatalogItem.fromJson(Map<String, dynamic> json) {
    return _CloudPluginCatalogItem(
      repo: json['repo']?.toString().trim() ?? '',
      manifest: _CloudPluginManifest.fromJson(asJsonMap(json['manifest'])),
    );
  }
}

class _CloudPluginManifest {
  const _CloudPluginManifest({
    required this.uuid,
    required this.version,
    required this.updateUrl,
  });

  final String uuid;
  final String version;
  final String updateUrl;

  factory _CloudPluginManifest.fromJson(Map<String, dynamic> json) {
    return _CloudPluginManifest(
      uuid: json['uuid']?.toString().trim() ?? '',
      version: json['version']?.toString().trim() ?? '',
      updateUrl: json['updateUrl']?.toString().trim() ?? '',
    );
  }
}

class _PluginUpdatePayload {
  const _PluginUpdatePayload({
    required this.uuid,
    required this.version,
    required this.script,
    required this.sourceLabel,
  });

  final String uuid;
  final String version;
  final String script;
  final String sourceLabel;
}
