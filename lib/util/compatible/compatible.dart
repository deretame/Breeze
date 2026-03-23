import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/util/get_path.dart';

import 'migration_v1_to_v2.dart';

const _defaultCompatibleVersion = 'v1';
const _latestCompatibleVersion = 'v2';

Future<void> ensureCompatibleMigration(ObjectBox objectbox) async {
  final version = await getCompatibleVersion();
  if (version == 'v1') {
    await migrateV1ToV2(objectbox);
    await setCompatibleVersion(_latestCompatibleVersion);
  }
}

Future<String> getCompatibleVersion() async {
  final file = await _getCompatibleFile();
  if (!await file.exists()) {
    return _defaultCompatibleVersion;
  }

  try {
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final version = json['compatible_version']?.toString().trim();
    if (version == null || version.isEmpty) {
      return _defaultCompatibleVersion;
    }
    return version;
  } catch (_) {
    return _defaultCompatibleVersion;
  }
}

Future<void> setCompatibleVersion(String version) async {
  final file = await _getCompatibleFile();
  final data = jsonEncode({'compatible_version': version});
  await file.writeAsString(data);
}

Future<File> _getCompatibleFile() async {
  final basePath = await getFilePath();
  final compatiblePath = p.join(basePath, 'compatible');
  final directory = Directory(compatiblePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return File(p.join(compatiblePath, 'compatible.json'));
}
