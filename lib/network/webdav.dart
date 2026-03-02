import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/comic_sync_core.dart';
import 'package:zephyr/network/sync/webdav_sync_service.dart';

Future<void> testWebDavServer() async {
  final settings = objectbox.userSettingBox.get(1)!.globalSetting;
  final service = WebDavSyncService(settings);
  await service.testConnection();
}

Future<void> syncWithWebDav() async {
  final settings = objectbox.userSettingBox.get(1)!.globalSetting;
  final service = WebDavSyncService(settings);
  await runComicSync(service);
}
