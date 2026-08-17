import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/domain/cs_connection_settings.dart';

void main() {
  test('persists a pending mode in connection settings', () {
    const settings = CsConnectionSettings(
      serverUrl: 'http://localhost:8787',
      pendingMode: CsRunMode.cs,
      downloadDataMigrated: true,
    );
    final restored = CsConnectionSettings.fromJson(settings.toJson());

    expect(restored.mode, CsRunMode.local);
    expect(restored.pendingMode, CsRunMode.cs);
    expect(restored.hasPendingMode, isTrue);
    expect(restored.downloadDataMigrated, isTrue);
  });

  test('migration import response decodes imported counts', () {
    final result = CsMigrationImportResult.fromJson({
      'imported': true,
      'counts': {'favorites': 3, 'downloads': 2},
    });

    expect(result.counts['favorites'], 3);
    expect(result.counts['downloads'], 2);
  });
}
