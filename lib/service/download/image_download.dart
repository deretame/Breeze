import 'package:pool/pool.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/service/download/download_progress_reporter.dart';
import 'package:zephyr/service/download/download_retry.dart';
import 'package:zephyr/type/enum.dart';

class DownloadImageJob {
  const DownloadImageJob({
    required this.url,
    required this.path,
    required this.cartoonId,
    required this.chapterId,
    this.storageChapterId = '',
    this.extern = const <String, dynamic>{},
  });

  final String url;
  final String path;
  final String cartoonId;
  final String chapterId;
  final String storageChapterId;
  final Map<String, dynamic> extern;
}

class DownloadImageJobException implements Exception {
  const DownloadImageJobException({required this.job, required this.result});

  final DownloadImageJob job;
  final DownloadPictureResult result;

  @override
  String toString() {
    final processedError = result.error?.toString().trim() ?? 'null';
    final rawError = _formatRawDownloadError(result.error);
    final rawStackTrace = result.errorStackTrace?.toString().trim();
    final stackSuffix = rawStackTrace == null || rawStackTrace.isEmpty
        ? ''
        : '\nrawStackTrace:\n$rawStackTrace';
    return '图片下载失败 path=${job.path} url=${job.url} '
        'status=${result.status.name}\n'
        'processedError=$processedError\n'
        'rawError=$rawError$stackSuffix';
  }
}

String _formatRawDownloadError(Object? error) {
  if (error == null) return 'null';

  final buffer = StringBuffer('${error.runtimeType}: $error');
  if (error is DownloadPictureNotFoundException) {
    final cause = error.cause;
    if (cause != null) {
      buffer.write('\nrawCause=${cause.runtimeType}: $cause');
    }
  }
  return buffer.toString();
}

class DownloadImageJobsResult {
  const DownloadImageJobsResult({
    required this.completed,
    required this.downloaded,
    required this.reused,
    required this.skipped,
  });

  final int completed;
  final int downloaded;
  final int reused;

  /// 真 404 / 空数据而跳过的图片数（不计入失败，不阻塞完成）。
  final int skipped;
}

Future<String> downloadCoverAsset({
  required String from,
  required String url,
  required String path,
  required String cartoonId,
  required String qjsName,
  required String qjsTaskGroupKey,
  bool Function()? shouldRetryUntilSuccess,
}) {
  return downloadPicture(
    from: from,
    url: url,
    path: path,
    cartoonId: cartoonId,
    pictureType: PictureType.cover,
    retry: true,
    shouldRetryUntilSuccess: shouldRetryUntilSuccess,
    qjsName: qjsName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );
}

/// 图片下载并发数：优先调用插件 `getDownloadConcurrency` 获取
///（插件返回 `{concurrency: number}`），插件未实现、返回非法或调用失败时回落为 5。
Future<int> resolveDownloadConcurrency({
  required String from,
  String? pluginId,
}) async {
  const fallback = 5;
  try {
    final data = await callUnifiedComicPlugin(
      from: from,
      pluginId: pluginId,
      fnPath: 'getDownloadConcurrency',
      core: const <String, dynamic>{},
    );
    Object? raw = data['concurrency'] ?? data['value'];
    if (raw == null && data['data'] is Map) {
      final nested = Map<String, dynamic>.from(data['data'] as Map);
      raw = nested['concurrency'] ?? nested['value'];
    }
    final parsed = int.tryParse(raw?.toString().trim() ?? '');
    if (parsed == null) return fallback;
    return parsed.clamp(1, 32);
  } catch (_) {
    return fallback;
  }
}

Future<DownloadImageJobsResult> downloadImageJobs({
  required String from,
  required List<DownloadImageJob> jobs,
  int? concurrency,
  required String qjsRuntimeName,
  required String qjsTaskGroupKey,
  required Future<void> Function() ensureTaskRunning,
  bool Function()? shouldRetryUntilSuccess,
  required DownloadProgressReporter reporter,
  Future<void> Function(Object error, DownloadImageJob job)? onError,
  Future<void> Function(
    int completed,
    int downloaded,
    int reused,
    DownloadImageJob completedJob,
    bool jobSkipped,
  )?
  onProgress,
}) async {
  void updateProgress(String message) {
    reporter.updateMessage(message);
  }

  if (jobs.isEmpty) {
    if (onProgress == null) {
      updateProgress(t.download.statusDownloadProgressComplete);
    }
    return const DownloadImageJobsResult(
      completed: 0,
      downloaded: 0,
      reused: 0,
      skipped: 0,
    );
  }

  final pool = Pool(concurrency ?? 5);
  final workerCount = concurrency ?? 5;
  var progress = 0;
  var downloaded = 0;
  var reused = 0;
  var skipped = 0;
  var lastReportedPercent = 0;
  var nextIndex = 0;
  Object? firstError;
  StackTrace? firstErrorStackTrace;

  Future<void> runWorker() async {
    try {
      while (firstError == null) {
        await ensureTaskRunning();
        DownloadImageJob? job;
        await pool.withResource(() async {
          if (nextIndex >= jobs.length) {
            return;
          }
          job = jobs[nextIndex];
          nextIndex += 1;
        });
        final currentJob = job;
        if (currentJob == null) {
          return;
        }
        var jobSkipped = false;
        try {
          final result = await _downloadSingleJob(
            from: from,
            job: currentJob,
            qjsRuntimeName: qjsRuntimeName,
            qjsTaskGroupKey: qjsTaskGroupKey,
            ensureTaskRunning: ensureTaskRunning,
            shouldRetryUntilSuccess: shouldRetryUntilSuccess,
            onError: onError,
            pictureType: PictureType.page,
          );
          progress++;
          if (result.status == DownloadPictureResultStatus.existing) {
            reused++;
          } else {
            downloaded++;
          }
        } on DownloadImageJobException catch (e) {
          // 真 404 / 空数据：记跳过，不失败整章。
          if (e.result.status == DownloadPictureResultStatus.notFound ||
              e.result.status == DownloadPictureResultStatus.emptyData) {
            progress++;
            skipped++;
            jobSkipped = true;
          } else {
            rethrow;
          }
        }
        if (onProgress != null) {
          await onProgress(
            progress,
            downloaded,
            reused,
            currentJob,
            jobSkipped,
          );
        }
        final currentPercent = (progress / jobs.length * 100).floor();
        if (onProgress == null && currentPercent > lastReportedPercent) {
          lastReportedPercent = currentPercent;
          updateProgress(
            t.download.statusDownloadProgress(percent: currentPercent),
          );
        }
        await ensureTaskRunning();
      }
    } catch (error, stackTrace) {
      firstError ??= error;
      firstErrorStackTrace ??= stackTrace;
    }
  }

  final tasks = List.generate(workerCount, (_) => runWorker());

  await Future.wait(tasks);
  if (firstError != null) {
    Error.throwWithStackTrace(firstError!, firstErrorStackTrace!);
  }
  return DownloadImageJobsResult(
    completed: progress,
    downloaded: downloaded,
    reused: reused,
    skipped: skipped,
  );
}

Future<DownloadPictureResult> _downloadSingleJob({
  required String from,
  required DownloadImageJob job,
  required String qjsRuntimeName,
  required String qjsTaskGroupKey,
  required Future<void> Function() ensureTaskRunning,
  bool Function()? shouldRetryUntilSuccess,
  Future<void> Function(Object error, DownloadImageJob job)? onError,
  PictureType pictureType = PictureType.comic,
}) async {
  try {
    final result = await retryDownloadOperation<DownloadPictureResult>(
      operation: '下载图片 ${job.path}',
      ensureTaskRunning: ensureTaskRunning,
      shouldRetryUntilSuccess: shouldRetryUntilSuccess,
      shouldRetry: (error) {
        if (error is! DownloadImageJobException) return true;
        return error.result.status != DownloadPictureResultStatus.notFound &&
            error.result.status != DownloadPictureResultStatus.emptyData;
      },
      action: () async {
        final result = await downloadPictureResult(
          from: from,
          url: job.url,
          path: job.path,
          cartoonId: job.cartoonId,
          chapterId: job.chapterId,
          storageChapterId: job.storageChapterId,
          pictureType: pictureType,
          // 外层负责整张图片的重试，避免网络层 10 次重试后才进入
          // 保存/解码失败的重试流程。
          retry: false,
          qjsName: qjsRuntimeName,
          qjsTaskGroupKey: qjsTaskGroupKey,
          extern: job.extern,
        );
        if (!result.isSuccess) {
          throw DownloadImageJobException(job: job, result: result);
        }
        return result;
      },
    );
    return result;
  } catch (error, stackTrace) {
    if (onError != null) {
      await onError(error, job);
      return DownloadPictureResult(
        status: DownloadPictureResultStatus.failed,
        error: error,
        errorStackTrace: stackTrace,
      );
    }
    rethrow;
  }
}
