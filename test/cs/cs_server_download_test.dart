import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/cs/data/cs_server_download.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';

void main() {
  test(
    'server manifest keeps chapter metadata and separates same-name pages',
    () {
      final manifest = CsServerDownloadManifest.fromJson({
        'plugin_id': 'plugin-1',
        'comic_id': 'comic-1',
        'options': {
          'title': '测试漫画',
          'chapter_refs': [
            {'chapterId': 'chapter-2', 'title': '第二话', 'order': 2},
            {'chapterId': 'chapter-1', 'title': '第一话', 'order': 1},
          ],
        },
        'cover_asset': {'asset_id': 'cover-1'},
        'pages': [
          {'asset_id': 'page-2', 'chapter_id': 'chapter-2', 'name': '1.jpg'},
          {'asset_id': 'page-1', 'chapter_id': 'chapter-1', 'name': '1.jpg'},
        ],
      });

      expect(manifest.title, '测试漫画');
      expect(manifest.chapters.map((chapter) => chapter.title), ['第一话', '第二话']);
      expect(manifest.chapters[0].images.single.path, 'cs-asset:page-1');
      expect(manifest.chapters[1].images.single.path, 'cs-asset:page-2');
      expect(
        manifest.toUnifiedComicDownload().cover,
        contains('cs-asset:cover-1'),
      );
    },
  );

  test('server download converts into the existing download model', () {
    final model = CsServerDownloadManifest.fromJson({
      'plugin_id': 'plugin-1',
      'comic_id': 'comic-1',
      'options': {
        'title': '测试漫画',
        'chapter_refs': [
          {'chapterId': 'chapter-1', 'title': '第一话', 'order': 1},
        ],
      },
      'pages': [
        {'asset_id': 'page-1', 'chapter_id': 'chapter-1', 'name': '1.jpg'},
      ],
    }).toUnifiedComicDownload();

    final chapters = resolveDownloadChapters(model);
    expect(model.uniqueKey, 'plugin-1:comic-1');
    expect(chapters.single.displayName, '第一话');
    expect(chapters.single.images.single.path, 'cs-asset:page-1');
    expect(jsonDecode(model.chapters), isA<List<dynamic>>());
  });
}
