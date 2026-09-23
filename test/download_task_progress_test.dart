import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/service/download/download_task_progress.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';

DownloadTaskJson _payload({int completed = 0, int total = 0}) {
  return DownloadTaskJson(
    from: 'plugin-a',
    comicId: 'comic/1',
    comicName: '测试漫画',
    chapterRef: const DownloadChapterTaskRef(
      chapterId: 'chapter-1',
      title: '第 1 话',
      order: 1,
    ),
    completedImages: completed,
    totalImages: total,
  );
}

void main() {
  test('图片进度换算', () {
    expect(
      downloadTaskProgressFraction(completedImages: 5, totalImages: 10),
      0.5,
    );
    expect(
      downloadTaskProgressFraction(completedImages: 0, totalImages: 10),
      0.0,
    );
    expect(
      downloadTaskProgressFraction(completedImages: 10, totalImages: 10),
      1.0,
    );
  });

  test('进度钳制在 0~1 之间', () {
    expect(
      downloadTaskProgressFraction(completedImages: 12, totalImages: 10),
      1.0,
    );
    expect(
      downloadTaskProgressFraction(completedImages: -2, totalImages: 10),
      0.0,
    );
  });

  test('总数未知时返回 null / 空文案', () {
    expect(
      downloadTaskProgressFraction(completedImages: 0, totalImages: 0),
      isNull,
    );
    expect(downloadTaskPayloadProgressFraction(_payload()), isNull);
    expect(downloadTaskPayloadProgressMessage(_payload()), '');
  });

  test('payload 进度换算', () {
    expect(
      downloadTaskPayloadProgressFraction(
        _payload(completed: 3, total: 4),
      ),
      0.75,
    );
  });
}
