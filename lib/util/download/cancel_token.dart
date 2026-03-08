import 'dart:async';

/// 下载任务取消令牌
///
/// 通过 [cancel] 方法发出取消信号，下载任务在适当的检查点
/// 调用 [throwIfCancelled] 以响应取消请求。
class CancelToken {
  final Completer<void> _completer = Completer<void>();

  /// 是否已被取消
  bool get isCancelled => _completer.isCompleted;

  /// 发出取消信号（幂等，多次调用无副作用）
  void cancel() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  /// 如果已取消则抛出 [TaskCancelledException]
  void throwIfCancelled() {
    if (isCancelled) {
      throw TaskCancelledException();
    }
  }

  /// 返回一个在取消时完成的 Future，可用于 race 并发
  Future<void> get future => _completer.future;
}

/// 任务被取消时抛出的异常
class TaskCancelledException implements Exception {
  @override
  String toString() => 'TaskCancelledException: 下载任务已被用户取消';
}
