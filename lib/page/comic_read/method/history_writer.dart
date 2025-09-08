import 'dart:isolate';
import 'dart:async';
import 'dart:ui';

import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/method/history_isolate.dart';
import 'package:zephyr/page/comic_read/method/history_isolate_messages.dart';
import 'package:zephyr/type/enum.dart';

class HistoryWriter {
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final _receivePort = ReceivePort();

  bool get isRunning => _isolate != null;

  // 启动 Isolate
  Future<void> start() async {
    if (isRunning) return;

    // 1. 获取主 Isolate 的 token
    final token = RootIsolateToken.instance;
    if (token == null) {
      logger.e("Error: Could not get RootIsolateToken.");
      return;
    }

    final completer = Completer<void>();
    _receivePort.listen((message) {
      if (message is SendPort) {
        _isolateSendPort = message;
        // 当我们收到后台 Isolate 的 SendPort 时，代表初始化成功
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    // 2. 将 token 和主 Isolate 的 SendPort 一起传过去
    final context = {'mainSendPort': _receivePort.sendPort, 'token': token};
    _isolate = await Isolate.spawn(historyIsolateEntrypoint, context);

    return completer.future; // 等待初始化完成
  }

  // 发送更新任务
  void updateBikaHistory(dynamic data) {
    if (!isRunning) return;
    _isolateSendPort?.send(UpdateHistoryMessage(data, From.bika));
  }

  void updateJmHistory(dynamic data) {
    if (!isRunning) return;
    _isolateSendPort?.send(UpdateHistoryMessage(data, From.jm));
  }

  // 停止 Isolate
  void stop() {
    if (!isRunning) return;
    _isolateSendPort?.send(ShutdownMessage());
    Future.delayed(Duration(milliseconds: 200), () {
      _isolate?.kill(priority: Isolate.immediate); // 作为备用，强制终止
    });
    _isolate = null;
    _receivePort.close();
  }
}
