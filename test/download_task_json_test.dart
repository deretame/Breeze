import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';

void main() {
  test('单章节任务 payload 往返', () {
    final task = DownloadTaskJson(
      from: 'plugin-a',
      comicId: 'comic/1',
      comicName: '测试漫画',
      chapterRef: const DownloadChapterTaskRef(
        chapterId: 'chapter-1',
        logicalKey: 'logical-1',
        requestId: 'request-1',
        storageChapterId: 'storage-1',
        title: '第 1 话',
        order: 1,
      ),
      stateCode: 'running',
      phaseCode: 'downloadingChapter',
      completedImages: 3,
      reusedImages: 1,
      totalImages: 10,
      imagePaths: const ['1.img', '2.img', '3.img'],
    );

    final restored = DownloadTaskJson.fromJson(
      jsonDecode(jsonEncode(task.toJson())) as Map<String, dynamic>,
    );

    expect(restored.schemaVersion, currentDownloadTaskSchemaVersion);
    expect(restored.stateCode, 'running');
    expect(restored.phaseCode, 'downloadingChapter');
    expect(restored.completedImages, 3);
    expect(restored.reusedImages, 1);
    expect(restored.totalImages, 10);
    expect(restored.imagePaths, ['1.img', '2.img', '3.img']);
    expect(restored.chapterRef.logicalKey, 'logical-1');
  });

  test('章节 key 按 logicalKey > chapterId > requestId 解析', () {
    expect(
      downloadChapterKeyOfRef(
        const DownloadChapterTaskRef(
          chapterId: 'chapter-1',
          logicalKey: 'logical-1',
          requestId: 'request-1',
        ),
      ),
      'logical-1',
    );
    expect(
      downloadChapterKeyOfRef(
        const DownloadChapterTaskRef(chapterId: 'chapter-1'),
      ),
      'chapter-1',
    );
    expect(
      downloadChapterKeyOfRef(const DownloadChapterTaskRef(order: 7)),
      '7',
    );
  });

  test('任务 key 精确到章节且 storage key 不参与', () {
    final task = DownloadTaskJson(
      from: 'plugin-a',
      comicId: 'comic/1',
      comicName: '测试漫画',
      chapterRef: const DownloadChapterTaskRef(
        chapterId: 'chapter-1',
        logicalKey: 'logical-1',
        requestId: 'request-1',
        storageChapterId: 'Gallery',
        title: '第 1 话',
        order: 1,
      ),
    );

    expect(task.chapterKey, 'logical-1');
    expect(task.taskKey, 'plugin-a:comic/1:logical-1');
    expect(task.taskKey.contains('Gallery'), isFalse);
  });
}
