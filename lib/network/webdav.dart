import 'package:zephyr/database/database.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/network/sync/webdav_sync_service.dart';

Future<void> testWebDavServer() async {
  final settings = database.userSettings.get(1)!.globalSetting;
  final service = WebDavSyncService(settings);
  await service.testConnection();
}

Future<void> syncWithWebDav() async {
  final settings = database.userSettings.get(1)!.globalSetting;
  await autoSync(settings);
}
