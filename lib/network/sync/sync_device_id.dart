import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String _prefsKey = 'sync.device_id';

String? _cachedDeviceId;

/// 获取当前设备的同步 ID。
///
/// 首次调用时从 SharedPreferences 读取，若不存在则生成一个 UUIDv4 并缓存。
/// 该 ID 只保存在本地，不同步到云端。
Future<String> ensureSyncDeviceId() async {
  if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
    return _cachedDeviceId!;
  }

  final prefs = await SharedPreferences.getInstance();
  var id = prefs.getString(_prefsKey);
  if (id == null || id.isEmpty) {
    id = const Uuid().v4();
    await prefs.setString(_prefsKey, id);
  }
  _cachedDeviceId = id;
  return id;
}

/// 同步获取设备 ID。调用前应先通过 [ensureSyncDeviceId] 初始化，
/// 否则返回占位值 `device_default`。
String get syncDeviceId => _cachedDeviceId ?? 'device_default';

/// 直接设置缓存的设备 ID。用于在子 Isolate 中复用主 Isolate 已生成的 ID。
set syncDeviceId(String value) {
  _cachedDeviceId = value;
}
