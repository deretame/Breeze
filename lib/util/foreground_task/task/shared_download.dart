import 'package:pool/pool.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/type/enum.dart';
import '../../download/download_progress_reporter.dart';

class DownloadImageJob {
  const DownloadImageJob({
    required this.url,
    required this.path,
    required this.cartoonId,
    required this.chapterId,
  });

  final String url;
  final String path;
  final String cartoonId;
  final String chapterId;
}

Future<String> downloadCoverAsset({
  required String from,
  required String url,
  required String path,
  required String cartoonId,
  required String qjsName,
  required String qjsTaskGroupKey,
}) {
  return downloadPicture(
    from: from,
    url: url,
    path: path,
    cartoonId: cartoonId,
    pictureType: PictureType.cover,
    qjsName: qjsName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );
}

Future<void> downloadImageJobs({
  required String from,
  required List<DownloadImageJob> jobs,
  int? concurrency,
  required String qjsRuntimeName,
  required String qjsTaskGroupKey,
  required Future<void> Function() ensureTaskRunning,
  required DownloadProgressReporter reporter,
  Future<void> Function(Object error, DownloadImageJob job)? onError,
}) async {
  void updateProgress(int progress, String message) {
    reporter.updateMessage(message);
  }

  if (jobs.isEmpty) {
    updateProgress(100, '漫画下载进度: 100%');
    return;
  }

  final pool = Pool(concurrency ?? 5);
  var progress = 0;
  var lastReportedPercent = 0;

  final tasks = jobs.map((job) {
    return pool.withResource(() async {
      await ensureTaskRunning();
      await _downloadSingleJob(
        from: from,
        job: job,
        qjsRuntimeName: qjsRuntimeName,
        qjsTaskGroupKey: qjsTaskGroupKey,
        onError: onError,
        pictureType: PictureType.page,
      );
      progress++;
      final currentPercent = (progress / jobs.length * 100).floor();
      if (currentPercent > lastReportedPercent) {
        lastReportedPercent = currentPercent;
        updateProgress(currentPercent, '漫画下载进度: $currentPercent%');
      }
      await ensureTaskRunning();
    });
  }).toList();

  await Future.wait(tasks, eagerError: true);
}

Future<void> _downloadSingleJob({
  required String from,
  required DownloadImageJob job,
  required String qjsRuntimeName,
  required String qjsTaskGroupKey,
  Future<void> Function(Object error, DownloadImageJob job)? onError,
  PictureType pictureType = PictureType.comic,
}) async {
  try {
    await downloadPicture(
      from: from,
      url: job.url,
      path: job.path,
      cartoonId: job.cartoonId,
      chapterId: job.chapterId,
      pictureType: pictureType,
      qjsName: qjsRuntimeName,
      qjsTaskGroupKey: qjsTaskGroupKey,
    );
  } catch (error) {
    if (onError != null) {
      await onError(error, job);
      return;
    }
    rethrow;
  }
}
