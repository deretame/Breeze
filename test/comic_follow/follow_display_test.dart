import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_follow/view/follow_display.dart';

ComicFollow _follow({
  String cover = '',
  String creator = '',
  int detected = 10,
}) {
  final now = DateTime.utc(2026, 9, 30, 12);
  return ComicFollow(
    uniqueKey: 'test:1',
    source: 'test',
    comicId: '1',
    title: 't',
    description: '',
    cover: cover,
    creator: creator,
    titleMeta: '[]',
    metadata: '[]',
    lastChapterCount: 0,
    detectedChapterCount: detected,
    detectedChapterTitle: '',
    hasUpdate: false,
    updateTime: now,
    deleted: false,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

void main() {
  test('resolveFollowCover falls back on bad json', () {
    final cover = resolveFollowCover(_follow(cover: 'not-json'));
    expect(cover.id, '1');
    expect(cover.url, isEmpty);
  });

  test('parseFollowCreatorName reads name and tolerates bad json', () {
    expect(
      parseFollowCreatorName(
        '{"id":"1","name":"  alice ","avatar":{"id":"","url":"","name":""},"extern":{}}',
      ),
      'alice',
    );
    expect(parseFollowCreatorName('not-json'), isNull);
    expect(parseFollowCreatorName(''), isNull);
  });

  test('formatFollowCheckTime shortens same day', () {
    final now = DateTime(2026, 9, 30, 20, 5);
    expect(
      formatFollowCheckTime(DateTime(2026, 9, 30, 9, 4), now: now),
      '09:04',
    );
    expect(
      formatFollowCheckTime(DateTime(2026, 9, 29, 9, 4), now: now),
      '9-29 09:04',
    );
    expect(
      formatFollowCheckTime(DateTime(2025, 12, 1, 9, 4), now: now),
      '2025-12-1 09:04',
    );
  });

  test('followReadProgress clamps', () {
    expect(followReadProgress(readOrder: 5, detectedTotal: 10), 0.5);
    expect(followReadProgress(readOrder: 0, detectedTotal: 10), 0);
    expect(followReadProgress(readOrder: 12, detectedTotal: 10), 1.0);
    expect(followReadProgress(readOrder: 5, detectedTotal: 0), 0);
  });
}
