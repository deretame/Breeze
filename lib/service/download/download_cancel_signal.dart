import 'dart:async';

const downloadTaskCancelledMessage = '__DOWNLOAD_TASK_CANCELLED__';

class DownloadTaskCancelledException implements Exception {
  const DownloadTaskCancelledException();

  @override
  String toString() => downloadTaskCancelledMessage;
}

final Map<String, Completer<void>> _downloadCancelSignals = {};

void prepareDownloadCancelSignal(String comicId) {
  _downloadCancelSignals.remove(comicId);
}

void triggerDownloadCancelSignal(String comicId) {
  final completer = _downloadCancelSignals.putIfAbsent(
    comicId,
    () => Completer<void>(),
  );
  if (!completer.isCompleted) {
    completer.complete();
  }
}

void clearDownloadCancelSignal(String comicId) {
  _downloadCancelSignals.remove(comicId);
}

bool isDownloadCancelSignaled(String comicId) {
  final completer = _downloadCancelSignals[comicId];
  return completer?.isCompleted ?? false;
}

Future<T> raceWithDownloadCancel<T>(String comicId, Future<T> future) async {
  if (isDownloadCancelSignaled(comicId)) {
    throw const DownloadTaskCancelledException();
  }

  final completer = _downloadCancelSignals.putIfAbsent(
    comicId,
    () => Completer<void>(),
  );
  return Future.any([
    future,
    completer.future.then<T>(
      (_) => throw const DownloadTaskCancelledException(),
    ),
  ]);
}
