import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/domain/cs_library_record.dart';
import 'package:zephyr/cs/domain/library_repository.dart';

class RemoteLibraryRepository implements LibraryRepository {
  const RemoteLibraryRepository(this.client);

  final CsApiClient client;

  @override
  Future<List<CsLibraryRecord>> list(
    String kind, {
    bool includeDeleted = false,
  }) {
    return client.listLibrary(kind, includeDeleted: includeDeleted);
  }

  @override
  Future<CsLibraryRecord> save(String kind, CsLibraryRecord record) {
    return client.saveLibrary(kind, record);
  }

  @override
  Future<void> remove(String kind, String uniqueKey) {
    return client.deleteLibrary(kind, uniqueKey);
  }
}
