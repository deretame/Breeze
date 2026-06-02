import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/src/rust/api/webdav.dart' as rust_webdav;

import 'comic_sync_core.dart';

class WebDavSyncService implements ComicSyncRemoteAdapter {
  WebDavSyncService(this._settings) {
    if (!isConfigured(_settings)) {
      throw Exception('WebDAV 配置不完整');
    }
  }

  final GlobalSettingState _settings;

  static bool isConfigured(GlobalSettingState settings) {
    return settings.syncSetting.webdavSetting.host.trim().isNotEmpty &&
        settings.syncSetting.webdavSetting.username.trim().isNotEmpty &&
        settings.syncSetting.webdavSetting.password.isNotEmpty;
  }

  @override
  Future<void> testConnection() {
    return rust_webdav.webdavTestConnection(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
    );
  }

  @override
  Future<void> ensureRemoteReady() {
    return rust_webdav.webdavEnsureRemoteReady(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      syncRootName: ComicSyncCore.syncRemoteRootName,
    );
  }

  @override
  Future<String> downloadRemoteMd5() {
    return rust_webdav.webdavDownloadText(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      syncRootName: ComicSyncCore.syncRemoteRootName,
      legacyDataRootName: ComicSyncCore.legacyDataRootName,
      legacySettingsRootName: ComicSyncCore.legacySettingsRootName,
      remotePath: _remoteMd5Path,
    );
  }

  @override
  Future<void> uploadRemoteMd5(String value) {
    return rust_webdav.webdavUploadText(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      syncRootName: ComicSyncCore.syncRemoteRootName,
      legacyDataRootName: ComicSyncCore.legacyDataRootName,
      legacySettingsRootName: ComicSyncCore.legacySettingsRootName,
      remotePath: _remoteMd5Path,
      value: value,
    );
  }

  @override
  Future<List<String>> listRemoteDataFiles() {
    return rust_webdav.webdavListRemoteDataFiles(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      syncRootName: ComicSyncCore.syncRemoteRootName,
      legacyDataRootName: ComicSyncCore.legacyDataRootName,
      legacySettingsRootName: ComicSyncCore.legacySettingsRootName,
    );
  }

  @override
  Future<List<int>> downloadRemoteFile(String remotePath) {
    return rust_webdav.webdavDownloadFile(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      syncRootName: ComicSyncCore.syncRemoteRootName,
      legacyDataRootName: ComicSyncCore.legacyDataRootName,
      legacySettingsRootName: ComicSyncCore.legacySettingsRootName,
      remotePath: remotePath,
    );
  }

  @override
  Future<void> uploadRemoteFile(
    String remotePath,
    List<int> data, {
    String contentType = 'application/octet-stream',
  }) {
    return rust_webdav.webdavUploadBytes(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      syncRootName: ComicSyncCore.syncRemoteRootName,
      legacyDataRootName: ComicSyncCore.legacyDataRootName,
      legacySettingsRootName: ComicSyncCore.legacySettingsRootName,
      remotePath: remotePath,
      data: data,
      contentType: contentType,
    );
  }

  @override
  Future<void> deleteRemoteFiles(List<String> remotePaths) {
    return rust_webdav.webdavDeleteRemoteFiles(
      host: _settings.syncSetting.webdavSetting.host,
      username: _settings.syncSetting.webdavSetting.username,
      password: _settings.syncSetting.webdavSetting.password,
      remotePaths: remotePaths,
      syncRootName: ComicSyncCore.syncRemoteRootName,
      legacyDataRootName: ComicSyncCore.legacyDataRootName,
      legacySettingsRootName: ComicSyncCore.legacySettingsRootName,
    );
  }

  String get _remoteMd5Path =>
      '/${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.comicMd5FileName}';
}
