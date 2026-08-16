import 'package:zephyr/cs/domain/cs_connection_settings.dart';
import 'package:zephyr/cs/domain/cs_library_record.dart';

abstract interface class LibraryRepository {
  Future<List<CsLibraryRecord>> list(
    String kind, {
    bool includeDeleted = false,
  });

  Future<CsLibraryRecord> save(String kind, CsLibraryRecord record);

  Future<void> remove(String kind, String uniqueKey);
}

/// 在业务层统一选择本地或 CS Repository，避免页面散落模式分支。
class ModeAwareLibraryRepository implements LibraryRepository {
  ModeAwareLibraryRepository({
    required this.settings,
    required this.local,
    required this.remote,
  });

  final Future<CsConnectionSettings> Function() settings;
  final LibraryRepository local;
  final LibraryRepository remote;

  Future<LibraryRepository> _active() async {
    final current = await settings();
    return current.isCsMode ? remote : local;
  }

  @override
  Future<List<CsLibraryRecord>> list(
    String kind, {
    bool includeDeleted = false,
  }) async {
    return (await _active()).list(kind, includeDeleted: includeDeleted);
  }

  @override
  Future<CsLibraryRecord> save(String kind, CsLibraryRecord record) async {
    return (await _active()).save(kind, record);
  }

  @override
  Future<void> remove(String kind, String uniqueKey) async {
    return (await _active()).remove(kind, uniqueKey);
  }
}
