import 'package:zephyr/main.dart';

Future<void> migrateV2ToV3() async {
  final removed = objectbox.downloadTaskBox.removeAll();
  logger.d('[migration_v2_to_v3] removed DownloadTask rows: $removed');
}
