import 'package:zephyr/config/global/global_setting.dart';

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

Future<void> autoSync(GlobalSettingState state) async {
  final adapter = createSyncAdapter(state);
  if (adapter == null) {
    return;
  }
  await runComicSync(adapter);
}
