import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

import 'comic_sync_core.dart';
import 's3_sync_service.dart';
import 'webdav_sync_service.dart';

bool isSyncServiceConfigured(GlobalSettingState state) {
  switch (state.syncServiceType) {
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

  switch (state.syncServiceType) {
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
  BikaSettingCubit? bikaSettingCubit,
  JmSettingCubit? jmSettingCubit,
}) async {
  final adapter = createSyncAdapter(state);
  if (adapter == null) {
    return;
  }

  await runComicSync(adapter);

  final syncSettingsEnabled =
      state.syncSettings &&
      globalSettingCubit != null &&
      bikaSettingCubit != null &&
      jmSettingCubit != null;
  if (!syncSettingsEnabled) {
    logger.d('设置同步未启用或上下文不完整，跳过设置同步');
    return;
  }

  await _syncSettings(
    adapter,
    globalSettingCubit: globalSettingCubit,
    bikaSettingCubit: bikaSettingCubit,
    jmSettingCubit: jmSettingCubit,
  );
}

Future<void> _syncSettings(
  ComicSyncRemoteAdapter adapter, {
  required GlobalSettingCubit globalSettingCubit,
  required BikaSettingCubit bikaSettingCubit,
  required JmSettingCubit jmSettingCubit,
}) async {
  final localPayload = _buildSettingsPayload(
    globalSettingCubit.state,
    bikaSettingCubit.state,
    jmSettingCubit.state,
  );
  final localBytes = _encodeSettingsPayload(localPayload);
  final localMd5 = ComicSyncCore.calculateMd5(localBytes);
  final localSyncState = await _readLocalSettingsSyncState();

  final remoteMd5 = await _downloadRemoteText(
    adapter,
    _remoteSettingsMd5Path,
    returnEmptyIfMissing: true,
  );

  logger.d(
    '设置同步状态: remoteMd5=$remoteMd5, '
    'lastRemoteMd5=${localSyncState.lastRemoteMd5}, '
    'localMd5=$localMd5, '
    'lastLocalMd5=${localSyncState.lastLocalMd5}',
  );

  if (remoteMd5.isEmpty) {
    logger.d('设置同步决策: 远端不存在设置，上传本地设置');
    await _uploadSettingsPayload(adapter, localBytes, localMd5);
    await _writeLocalSettingsSyncState(
      _LocalSettingsSyncState(lastRemoteMd5: localMd5, lastLocalMd5: localMd5),
    );
    return;
  }

  if (remoteMd5 == localSyncState.lastRemoteMd5) {
    if (localMd5 != localSyncState.lastLocalMd5) {
      logger.d('设置同步决策: 远端未变且本地已变，上传本地设置');
      await _uploadSettingsPayload(adapter, localBytes, localMd5);
      await _writeLocalSettingsSyncState(
        _LocalSettingsSyncState(
          lastRemoteMd5: localMd5,
          lastLocalMd5: localMd5,
        ),
      );
    } else {
      logger.d('设置同步决策: 本地远端均未变，跳过设置同步');
    }
    return;
  }

  final localChangedSinceLastSync =
      localSyncState.lastLocalMd5.isNotEmpty &&
      localMd5 != localSyncState.lastLocalMd5;
  if (localChangedSinceLastSync) {
    logger.d('设置同步决策: 检测到双端可能冲突，按本地优先上传覆盖远端');
    await _uploadSettingsPayload(adapter, localBytes, localMd5);
    await _writeLocalSettingsSyncState(
      _LocalSettingsSyncState(lastRemoteMd5: localMd5, lastLocalMd5: localMd5),
    );
    return;
  }

  final remoteBytes = await _downloadRemoteBytes(
    adapter,
    _remoteSettingsJsonPath,
    returnEmptyIfMissing: true,
  );
  if (remoteBytes.isEmpty) {
    logger.w('设置同步决策: 远端 md5 存在但 settings.json 缺失，回填本地设置');
    await _uploadSettingsPayload(adapter, localBytes, localMd5);
    await _writeLocalSettingsSyncState(
      _LocalSettingsSyncState(lastRemoteMd5: localMd5, lastLocalMd5: localMd5),
    );
    return;
  }

  final remotePayloadMd5 = ComicSyncCore.calculateMd5(remoteBytes);
  if (remotePayloadMd5 != remoteMd5) {
    logger.w('设置同步决策: 远端 settings.json 校验失败，回填本地设置');
    await _uploadSettingsPayload(adapter, localBytes, localMd5);
    await _writeLocalSettingsSyncState(
      _LocalSettingsSyncState(lastRemoteMd5: localMd5, lastLocalMd5: localMd5),
    );
    return;
  }

  logger.d('设置同步决策: 远端已更新且本地未改，应用远端设置到本地');

  final remotePayload = _decodeSettingsPayload(remoteBytes);
  final globalSettingJson = _toJsonMap(remotePayload['globalSetting']);
  if (globalSettingJson.isNotEmpty) {
    final remoteGlobalSetting = GlobalSettingState.fromJson(
      globalSettingJson,
    ).syncLegacyAndNested();
    globalSettingCubit.updateState((_) => remoteGlobalSetting);
  }

  final bikaSettingJson = _toJsonMap(remotePayload['bikaSetting']);
  if (bikaSettingJson.isNotEmpty) {
    final localAuthorization = bikaSettingCubit.state.authorization;
    bikaSettingCubit.applySyncedState(
      BikaSettingState.fromJson(
        bikaSettingJson,
      ).copyWith(authorization: localAuthorization),
    );
  }

  final jmSettingJson = _toJsonMap(remotePayload['jmSetting']);
  if (jmSettingJson.isNotEmpty) {
    final localLoginStatus = jmSettingCubit.state.loginStatus;
    jmSettingCubit.applySyncedState(
      JmSettingState.fromJson(
        jmSettingJson,
      ).copyWith(loginStatus: localLoginStatus),
    );
  }

  final appliedPayload = _buildSettingsPayload(
    globalSettingCubit.state,
    bikaSettingCubit.state,
    jmSettingCubit.state,
  );
  final appliedLocalMd5 = ComicSyncCore.calculateMd5(
    _encodeSettingsPayload(appliedPayload),
  );
  await _writeLocalSettingsSyncState(
    _LocalSettingsSyncState(
      lastRemoteMd5: remoteMd5,
      lastLocalMd5: appliedLocalMd5,
    ),
  );
  logger.d('设置同步完成: 已应用远端设置并刷新本地同步状态');
}

Map<String, dynamic> _buildSettingsPayload(
  GlobalSettingState globalSetting,
  BikaSettingState bikaSetting,
  JmSettingState jmSetting,
) {
  return {
    'globalSetting': globalSetting.copyWith(md5: '').toJson(),
    'bikaSetting': () {
      final json = Map<String, dynamic>.from(bikaSetting.toJson());
      json.remove('authorization');
      return json;
    }(),
    'jmSetting': () {
      final json = Map<String, dynamic>.from(jmSetting.toJson());
      json.remove('loginStatus');
      return json;
    }(),
  };
}

List<int> _encodeSettingsPayload(Map<String, dynamic> payload) {
  final source = jsonEncode(payload);
  final key = Key.fromUtf8('XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN');
  final iv = IV.fromUtf8('7qFwTxwH&iyuw35f');
  final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
  final encrypted = encrypter.encrypt(source, iv: iv);
  final encoded = utf8.encode(encrypted.base64);
  return GZipEncoder().encode(encoded);
}

Map<String, dynamic> _decodeSettingsPayload(List<int> payloadBytes) {
  try {
    final jsonString = _decompressAndDecryptSettings(payloadBytes);
    final payloadRaw = jsonDecode(jsonString);
    return _toJsonMap(payloadRaw);
  } catch (_) {
    final payloadRaw = jsonDecode(utf8.decode(payloadBytes));
    return _toJsonMap(payloadRaw);
  }
}

String _decompressAndDecryptSettings(List<int> payloadBytes) {
  final decodedBytes = GZipDecoder().decodeBytes(payloadBytes);
  final encryptedText = utf8.decode(decodedBytes);
  final key = Key.fromUtf8('XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN');
  final iv = IV.fromUtf8('7qFwTxwH&iyuw35f');
  final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
  return encrypter.decrypt64(encryptedText, iv: iv);
}

Future<void> _uploadSettingsPayload(
  ComicSyncRemoteAdapter adapter,
  List<int> payloadBytes,
  String payloadMd5,
) async {
  await adapter.uploadRemoteFile(_remoteSettingsJsonPath, payloadBytes);
  await adapter.uploadRemoteFile(
    _remoteSettingsMd5Path,
    utf8.encode(payloadMd5),
    contentType: 'text/plain; charset=utf-8',
  );
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

Future<_LocalSettingsSyncState> _readLocalSettingsSyncState() async {
  final file = await _localSettingsSyncStateFile();
  if (!await file.exists()) {
    return const _LocalSettingsSyncState();
  }

  try {
    final text = await file.readAsString();
    if (text.trim().isEmpty) {
      return const _LocalSettingsSyncState();
    }
    final raw = jsonDecode(text);
    return _LocalSettingsSyncState.fromJson(_toJsonMap(raw));
  } catch (_) {
    return const _LocalSettingsSyncState();
  }
}

Future<void> _writeLocalSettingsSyncState(_LocalSettingsSyncState state) async {
  final file = await _localSettingsSyncStateFile();
  await file.writeAsString(jsonEncode(state.toJson()), flush: true);
}

Future<File> _localSettingsSyncStateFile() async {
  final dbPath = await getDbPath();
  return File(p.join(dbPath, 'settings_sync_state.json'));
}

String get _remoteSettingsBaseDir => '${appName}_setting';

String get _remoteSettingsJsonPath => '$_remoteSettingsBaseDir/settings.json';

String get _remoteSettingsMd5Path => '$_remoteSettingsBaseDir/settings.md5';

Map<String, dynamic> _toJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }

  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }

  return <String, dynamic>{};
}

class _LocalSettingsSyncState {
  const _LocalSettingsSyncState({
    this.lastRemoteMd5 = '',
    this.lastLocalMd5 = '',
  });

  final String lastRemoteMd5;
  final String lastLocalMd5;

  factory _LocalSettingsSyncState.fromJson(Map<String, dynamic> json) {
    return _LocalSettingsSyncState(
      lastRemoteMd5: (json['lastRemoteMd5'] ?? '').toString(),
      lastLocalMd5: (json['lastLocalMd5'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'lastRemoteMd5': lastRemoteMd5, 'lastLocalMd5': lastLocalMd5};
  }
}
