import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';

void main() {
  group('GlobalSettingState compatibility', () {
    test('migrates legacy flat fields into nested sync/read settings', () {
      final state = GlobalSettingState.fromJson({
        'syncServiceType': 'webdav',
        'webdavHost': 'https://dav.example.com',
        'webdavUsername': 'user-a',
        'webdavPassword': 'pass-a',
        'autoSync': false,
        'syncNotify': false,
        'comicReadTopContainer': false,
        'readMode': 2,
      });

      expect(state.syncSetting.syncServiceType, SyncServiceType.webdav);
      expect(state.syncSetting.webdavSetting.host, 'https://dav.example.com');
      expect(state.syncSetting.webdavSetting.username, 'user-a');
      expect(state.syncSetting.webdavSetting.password, 'pass-a');
      expect(state.syncSetting.autoSync, isFalse);
      expect(state.syncSetting.syncNotify, isFalse);
      expect(state.readSetting.comicReadTopContainer, isFalse);
      expect(state.readSetting.readMode, 2);

      expect(state.autoSync, isFalse);
      expect(state.syncNotify, isFalse);
      expect(state.comicReadTopContainer, isFalse);
      expect(state.readMode, 2);
    });

    test('backfills legacy fields when only nested settings are present', () {
      final state = GlobalSettingState.fromJson({
        'syncSetting': {
          'syncServiceType': 'webdav',
          'webdavSetting': {
            'host': 'https://dav.nested.com',
            'username': 'nested-user',
            'password': 'nested-pass',
          },
          'autoSync': false,
          'syncNotify': false,
        },
        'readSetting': {'comicReadTopContainer': false, 'readMode': 1},
      });

      expect(state.autoSync, isFalse);
      expect(state.syncNotify, isFalse);
      expect(state.comicReadTopContainer, isFalse);
      expect(state.readMode, 1);
      expect(state.webdavHost, 'https://dav.nested.com');
      expect(state.webdavUsername, 'nested-user');
      expect(state.webdavPassword, 'nested-pass');
    });

    test('syncLegacyAndNested keeps legacy and nested in sync', () {
      final previous = const GlobalSettingState();

      final changedLegacy = previous.copyWith(autoSync: false);
      final syncedFromLegacy = changedLegacy.syncLegacyAndNested(
        previous: previous,
      );
      expect(syncedFromLegacy.autoSync, isFalse);
      expect(syncedFromLegacy.syncSetting.autoSync, isFalse);

      final changedNested = previous.copyWith(
        syncSetting: previous.syncSetting.copyWith(syncNotify: false),
      );
      final syncedFromNested = changedNested.syncLegacyAndNested(
        previous: previous,
      );
      expect(syncedFromNested.syncNotify, isFalse);
      expect(syncedFromNested.syncSetting.syncNotify, isFalse);

      final changedReadLegacy = previous.copyWith(readMode: 2);
      final syncedReadLegacy = changedReadLegacy.syncLegacyAndNested(
        previous: previous,
      );
      expect(syncedReadLegacy.readMode, 2);
      expect(syncedReadLegacy.readSetting.readMode, 2);

      final changedReadNested = previous.copyWith(
        readSetting: previous.readSetting.copyWith(
          comicReadTopContainer: false,
        ),
      );
      final syncedReadNested = changedReadNested.syncLegacyAndNested(
        previous: previous,
      );
      expect(syncedReadNested.comicReadTopContainer, isFalse);
      expect(syncedReadNested.readSetting.comicReadTopContainer, isFalse);
    });
  });
}
