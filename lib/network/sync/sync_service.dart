import 'dart:convert';

import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';

import 'comic_sync_core.dart';
import 's3_sync_service.dart';
import 'webdav_sync_service.dart';

bool isSyncServiceConfigured(GlobalSettingState state) {
  switch (state.syncSetting.syncServiceType) {
    case SyncServiceType.none:
      return false;
    case SyncServiceType.webdav:
      return WebDavSyncService.isConfigured(state);
    case SyncServiceType.s3:
      return S3SyncService.isConfigured(state);
  }
}

ComicSyncRemoteAdapter? createSyncAdapter(GlobalSettingState state) {
  if (!isSyncServiceConfigured(state)) {
    return null;
  }

  switch (state.syncSetting.syncServiceType) {
    case SyncServiceType.none:
      return null;
    case SyncServiceType.webdav:
      return WebDavSyncService(state);
    case SyncServiceType.s3:
      return S3SyncService(state);
  }
}

Future<void> autoSync(
  GlobalSettingState state, {
  GlobalSettingCubit? globalSettingCubit,
}) async {
  final adapter = createSyncAdapter(state);
  if (adapter == null) {
    return;
  }

  await runComicSync(adapter);

  if (!state.syncSetting.syncSettings) {
    logger.d('设置同步未启用，跳过设置同步');
    return;
  }

  await _syncSettings(
    adapter,
    globalSettingCubit: globalSettingCubit,
    currentGlobalSetting: state,
  );
}

Future<void> _syncSettings(
  ComicSyncRemoteAdapter adapter, {
  required GlobalSettingState currentGlobalSetting,
  GlobalSettingCubit? globalSettingCubit,
}) async {
  final localGlobal = globalSettingCubit?.state ?? currentGlobalSetting;
  var localSyncTime = localGlobal.syncSetting.settingsSyncTime;
  if (localSyncTime <= 0) {
    localSyncTime = DateTime.now().toUtc().millisecondsSinceEpoch;
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: localSyncTime,
      globalSettingCubit: globalSettingCubit,
    );
  }

  final localPayload = _buildSettingsPayload(localGlobal, localSyncTime);
  final localBytes = await ComicSyncCore.encodeEncryptedPayload(
    utf8.encode(jsonEncode(localPayload)),
  );
  final localMd5 = ComicSyncCore.calculateMd5(localBytes);

  final allRemote = await adapter.listRemoteDataFiles();
  final legacyFiles = allRemote
      .where(ComicSyncCore.isLegacyRemotePath)
      .toList();
  if (legacyFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(legacyFiles);
  }
  final syncRootFiles = allRemote.where(ComicSyncCore.isSyncRootPath).toList();

  final remoteMd5 = await _downloadRemoteText(
    adapter,
    _remoteSettingsMd5Path,
    returnEmptyIfMissing: true,
  );

  logger.d(
    '[sync][settings] precheck localTime=$localSyncTime localMd5=$localMd5 remoteMd5=$remoteMd5 remoteFiles=${syncRootFiles.length}',
  );

  if (remoteMd5.isNotEmpty && remoteMd5 == localMd5) {
    logger.d('[sync][settings] decision=skip reason=md5_equal');
    return;
  }

  final remoteData = await _selectLatestRemoteSettingsData(
    adapter,
    syncRootFiles,
    remoteMd5,
  );

  if (remoteMd5.isEmpty || remoteData == null) {
    logger.d('[sync][settings] decision=upload reason=remote_missing');
    await _uploadSettingsPayload(
      adapter,
      payloadBytes: localBytes,
      payloadMd5: localMd5,
      syncTime: localSyncTime,
    );
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: localSyncTime,
      globalSettingCubit: globalSettingCubit,
    );
    await _cleanupRemoteSettingsFiles(adapter);
    return;
  }

  final remotePayload = await _decodeSettingsPayload(remoteData.bytes);
  final remoteSyncTime = _extractSyncTimeFromPayload(
    remotePayload,
    fallbackFromFileName: remoteData.timestamp,
  );

  logger.d(
    '[sync][settings] compare localTime=$localSyncTime remoteTime=$remoteSyncTime '
    'localMd5=$localMd5 remoteMd5=$remoteMd5 remoteFileTs=${remoteData.timestamp}',
  );

  if (localSyncTime > remoteSyncTime && localMd5 != remoteMd5) {
    logger.d('[sync][settings] decision=upload reason=local_newer');
    await _uploadSettingsPayload(
      adapter,
      payloadBytes: localBytes,
      payloadMd5: localMd5,
      syncTime: localSyncTime,
    );
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: localSyncTime,
      globalSettingCubit: globalSettingCubit,
    );
    await _cleanupRemoteSettingsFiles(adapter);
    return;
  }

  if (localSyncTime < remoteSyncTime) {
    logger.d('[sync][settings] decision=apply_remote reason=remote_newer');
    await _applyRemoteSettingsPayload(
      remotePayload,
      remoteSyncTime: remoteSyncTime,
      globalSettingCubit: globalSettingCubit,
    );
    await _cleanupRemoteSettingsFiles(adapter);
    return;
  }

  if (localMd5 != remoteMd5) {
    logger.d(
      '[sync][settings] decision=upload reason=same_time_local_preferred',
    );
    await _uploadSettingsPayload(
      adapter,
      payloadBytes: localBytes,
      payloadMd5: localMd5,
      syncTime: localSyncTime,
    );
    await _updateLocalSettingsSyncTime(
      localGlobal,
      syncTime: localSyncTime,
      globalSettingCubit: globalSettingCubit,
    );
    await _cleanupRemoteSettingsFiles(adapter);
    return;
  }

  await _updateLocalSettingsSyncTime(
    localGlobal,
    syncTime: remoteSyncTime,
    globalSettingCubit: globalSettingCubit,
  );
  await _cleanupRemoteSettingsFiles(adapter);
  logger.d('[sync][settings] decision=skip reason=content_equal_after_compare');
}

Map<String, dynamic> _buildSettingsPayload(
  GlobalSettingState globalSetting,
  int syncTime,
) {
  final sanitizedGlobal = globalSetting.copyWith(
    syncSetting: globalSetting.syncSetting.copyWith(settingsSyncTime: 0),
  );

  final pluginConfigs = objectbox.pluginConfigBox.getAll().map((item) {
    final json = item.toJson();
    json.remove('id');
    return json;
  }).toList();

  final pluginInfos = objectbox.pluginInfoBox.getAll().map((item) {
    final json = item.toJson();
    json.remove('id');
    return json;
  }).toList();

  return {
    'version': syncDataVersion,
    'syncTime': syncTime,
    'globalSetting': sanitizedGlobal.toJson(),
    'pluginConfigs': pluginConfigs,
    'pluginInfos': pluginInfos,
  };
}

Future<void> _applyRemoteSettingsPayload(
  Map<String, dynamic> remotePayload, {
  required int remoteSyncTime,
  required GlobalSettingCubit? globalSettingCubit,
}) async {
  final localGlobal =
      globalSettingCubit?.state ??
      objectbox.userSettingBox.get(1)!.globalSetting;
  final globalSettingJson = _toJsonMap(remotePayload['globalSetting']);
  final pluginConfigJsonList = _toJsonMapList(remotePayload['pluginConfigs']);
  final pluginInfoJsonList = _toJsonMapList(remotePayload['pluginInfos']);

  final remoteGlobal = globalSettingJson.isEmpty
      ? localGlobal
      : GlobalSettingState.fromJson(globalSettingJson);
  final mergedGlobal = remoteGlobal.copyWith(
    syncSetting: remoteGlobal.syncSetting.copyWith(
      settingsSyncTime: remoteSyncTime,
    ),
  );

  if (globalSettingCubit != null) {
    globalSettingCubit.applySyncedState(mergedGlobal);
  } else {
    final user = objectbox.userSettingBox.get(1);
    if (user != null) {
      user.globalSetting = mergedGlobal;
      objectbox.userSettingBox.put(user);
    }
  }

  final remotePluginConfigs = pluginConfigJsonList
      .map(PluginConfig.fromJson)
      .map((item) => PluginConfig(name: item.name, config: item.config))
      .toList();
  objectbox.pluginConfigBox.removeAll();
  if (remotePluginConfigs.isNotEmpty) {
    objectbox.pluginConfigBox.putMany(remotePluginConfigs);
  }

  final remotePluginInfos = pluginInfoJsonList
      .map(PluginInfo.fromJson)
      .map(
        (item) => PluginInfo(
          uuid: item.uuid,
          version: item.version,
          originScript: item.originScript,
          insertedAt: item.insertedAt,
          updatedAt: item.updatedAt,
          isEnabled: item.isEnabled,
          isDeleted: item.isDeleted,
          deletedAt: item.deletedAt,
          lastLoadSuccess: item.lastLoadSuccess,
          lastLoadError: item.lastLoadError,
          debug: item.debug,
          debugUrl: item.debugUrl,
        ),
      )
      .toList();
  objectbox.pluginInfoBox.removeAll();
  if (remotePluginInfos.isNotEmpty) {
    objectbox.pluginInfoBox.putMany(remotePluginInfos);
  }
}

Future<void> _updateLocalSettingsSyncTime(
  GlobalSettingState localGlobal, {
  required int syncTime,
  required GlobalSettingCubit? globalSettingCubit,
}) async {
  final merged = localGlobal.copyWith(
    syncSetting: localGlobal.syncSetting.copyWith(settingsSyncTime: syncTime),
  );
  if (globalSettingCubit != null) {
    globalSettingCubit.applySyncedState(merged);
  } else {
    final user = objectbox.userSettingBox.get(1);
    if (user != null) {
      user.globalSetting = merged;
      objectbox.userSettingBox.put(user);
    }
  }
}

Future<void> _uploadSettingsPayload(
  ComicSyncRemoteAdapter adapter, {
  required List<int> payloadBytes,
  required String payloadMd5,
  required int syncTime,
}) async {
  final fileName = ComicSyncCore.buildSettingsDataFileName(syncTime);
  await adapter.uploadRemoteFile(fileName, payloadBytes);
  await adapter.uploadRemoteFile(
    _remoteSettingsMd5Path,
    utf8.encode(payloadMd5),
    contentType: 'text/plain; charset=utf-8',
  );
  logger.d('[sync][settings] uploaded file=$fileName md5=$payloadMd5');
}

Future<void> _cleanupRemoteSettingsFiles(ComicSyncRemoteAdapter adapter) async {
  final allRemote = await adapter.listRemoteDataFiles();

  final legacyFiles = allRemote
      .where(ComicSyncCore.isLegacyRemotePath)
      .toList();
  if (legacyFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(legacyFiles);
  }

  final syncRootFiles = allRemote.where(ComicSyncCore.isSyncRootPath).toList();
  final settingsFiles = syncRootFiles.where((path) {
    final fileName = ComicSyncCore.extractFileName(path);
    return ComicSyncCore.isSettingsDataFileName(fileName);
  }).toList();
  final sorted = ComicSyncCore.sortSettingsFilesByTimestampDesc(settingsFiles);

  final keep = <String>{
    '${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.settingsMd5FileName}',
  };
  for (var i = 0; i < sorted.length; i++) {
    if (i < 3) {
      keep.add(ComicSyncCore.normalizeRemotePathNoLeadingSlash(sorted[i]));
    }
  }

  final stale = settingsFiles.where((path) {
    final normalized = ComicSyncCore.normalizeRemotePathNoLeadingSlash(path);
    return !keep.contains(normalized);
  }).toList();
  if (stale.isNotEmpty) {
    await adapter.deleteRemoteFiles(stale);
  }
}

Future<_RemoteSettingsData?> _selectLatestRemoteSettingsData(
  ComicSyncRemoteAdapter adapter,
  List<String> remotePaths,
  String remoteMd5,
) async {
  final sorted = ComicSyncCore.sortSettingsFilesByTimestampDesc(remotePaths);
  if (sorted.isEmpty || remoteMd5.isEmpty) {
    return null;
  }

  for (final path in sorted) {
    try {
      final bytes = await adapter.downloadRemoteFile(path);
      final md5 = ComicSyncCore.calculateMd5(bytes);
      if (md5 == remoteMd5) {
        return _RemoteSettingsData(
          bytes: bytes,
          timestamp:
              ComicSyncCore.extractSettingsTimestampFromRemotePath(path) ?? 0,
        );
      }
    } catch (e) {
      logger.w('远端设置文件读取失败，尝试更旧版本: $path, error: $e');
    }
  }

  return null;
}

Future<Map<String, dynamic>> _decodeSettingsPayload(
  List<int> payloadBytes,
) async {
  final raw = await ComicSyncCore.decodeEncryptedPayload(payloadBytes);
  final payloadRaw = jsonDecode(utf8.decode(raw));
  return _toJsonMap(payloadRaw);
}

int _extractSyncTimeFromPayload(
  Map<String, dynamic> payload, {
  required int fallbackFromFileName,
}) {
  final syncTime = int.tryParse(payload['syncTime']?.toString() ?? '') ?? 0;
  if (syncTime > 0) {
    return syncTime;
  }
  return fallbackFromFileName;
}

Future<String> _downloadRemoteText(
  ComicSyncRemoteAdapter adapter,
  String remotePath, {
  bool returnEmptyIfMissing = false,
}) async {
  final bytes = await _downloadRemoteBytes(
    adapter,
    remotePath,
    returnEmptyIfMissing: returnEmptyIfMissing,
  );
  if (bytes.isEmpty) {
    return '';
  }
  return utf8.decode(bytes).trim();
}

Future<List<int>> _downloadRemoteBytes(
  ComicSyncRemoteAdapter adapter,
  String remotePath, {
  bool returnEmptyIfMissing = false,
}) async {
  try {
    return await adapter.downloadRemoteFile(remotePath);
  } catch (e) {
    if (returnEmptyIfMissing && _isNotFoundError(e)) {
      return const [];
    }
    rethrow;
  }
}

bool _isNotFoundError(Object error) {
  final message = error.toString();
  final lower = message.toLowerCase();
  return message.contains('404') ||
      message.contains('NoSuchKey') ||
      message.contains('NoSuchObject') ||
      message.contains('NotFound') ||
      lower.contains('does not exist') ||
      lower.contains('specified key') ||
      lower.contains('no such key');
}

Map<String, dynamic> _toJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _toJsonMapList(Object? value) {
  final raw = (value as List? ?? const []);
  return raw
      .map((item) {
        if (item is Map<String, dynamic>) {
          return Map<String, dynamic>.from(item);
        }
        if (item is Map) {
          return item.map((key, val) => MapEntry(key.toString(), val));
        }
        return <String, dynamic>{};
      })
      .where((item) => item.isNotEmpty)
      .toList();
}

String get _remoteSettingsMd5Path =>
    '${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.settingsMd5FileName}';

class _RemoteSettingsData {
  const _RemoteSettingsData({required this.bytes, required this.timestamp});

  final List<int> bytes;
  final int timestamp;
}
